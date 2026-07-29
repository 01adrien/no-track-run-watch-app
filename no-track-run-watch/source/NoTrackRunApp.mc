import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Communications;
import Toybox.Timer;
import Toybox.Application;
using Toybox.Position;
using Toybox.System;
import Toybox.Attention;


const SENDING_TIMEOUT  as Number  = 5;
const GPS_STABLE_TICKS as Number  = 5;
const SIMULATOR        as Boolean = false;
const DEBUG            as Boolean = true;

const VIBE_BLOCK_CHANGE as Array<Attention.VibeProfile> = [
    new Attention.VibeProfile(50, 300),
    new Attention.VibeProfile(0, 200),
    new Attention.VibeProfile(50, 300)
];

const VIBE_FIELD_CHANGE as Array<Attention.VibeProfile> = [
    new Attention.VibeProfile(50, 300),
];

const VIBE_SESSION_END as Array<Attention.VibeProfile> = [
    new Attention.VibeProfile(50, 300),
    new Attention.VibeProfile(0, 200),
    new Attention.VibeProfile(50, 300),
    new Attention.VibeProfile(0, 200),
    new Attention.VibeProfile(50, 300)
];

class NoTrackRunApp extends Application.AppBase {

    var sm              as StateManager = new StateManager();
    var rm              as RunManager   = new RunManager(sm);
    var timer           as Timer.Timer  = new Timer.Timer();
    var sendingTime     as Number       = 0;
    var errorMsg        as String       = "";
    var gpsGoodStreak   as Number       = 0;

    function initialize() { AppBase.initialize();}

    function exit() as Void {  System.exit();}

    function onStart(state as Dictionary?) as Void {
        Communications.registerForPhoneAppMessages(method(:onPhoneMessage));
        timer.start(method(:onTick), 1000, true);
        rm.onBlockAdvance = method(:onBlockChanged);
        rm.onFieldAdvance = method(:onFieldChanged);
        rm.onSessionEnd = method(:onSessionEnded); 
        if (getSession() != null) {sm.handle(EVENT_NEED_SYNC);}
        Position.enableLocationEvents(
            {
                :acquisitionType => Position.LOCATION_CONTINUOUS,
                :mode => Position.POSITIONING_MODE_NORMAL
            },
            method(:onPosition)
        );
    }

    function onStop(state as Dictionary?) as Void {
        timer.stop();
        Position.enableLocationEvents(Position.LOCATION_DISABLE, null);
    }


    function onPhoneMessage(msg as Communications.PhoneAppMessage) as Void {
        if (!canReceiveMsg() || !Validator.isValidMsg(msg.data)) {
            return;
        }
        var data = msg.data as Dictionary;
        var type = data["type"] as String;

        if (type.equals("SEND_SESSION")) {
            sm.handle(handleSendSession(data));
        } else if (type.equals("ACK_RESULTS")) {
            sm.handle(handleAckResults(data));
        } else {
            errorMsg = type;
            sm.handle(EVENT_ERROR);
        }
    }

    function handleAckResults(data as Dictionary) as AppEvent {
        var payload = data["payload"] as Dictionary;
        if (!Validator.isValidAckPayload(payload)) {
            errorMsg = "Invalid msg format";
            return EVENT_ERROR;
        }

        if (payload["status"].equals("OK")) {
            return EVENT_SYNCED_OK;
        }

        errorMsg = "Invalid session";
        return EVENT_ERROR;
    }

    function handleSendSession(data as Dictionary) as AppEvent {
        if (getSession() != null || rm.hasSessionData()) {
            sendAck("ACK_SESSION", false, "Already a session on the watch");
            return EVENT_NONE; 
        }

        var payload = data["payload"] as Dictionary;
        if (!Validator.isValidSessionPayload(payload)) {
            errorMsg = "Invalid msg format";
            return EVENT_ERROR;
        }

        rm.init(payload);
        sendAck("ACK_SESSION", true, null);
        return EVENT_SESSION_RECEIVED;
    }

    function onPosition(info as Position.Info) as Void { 
        // Keep alive GPS 
    }

    function startSession() as Void {
        gpsGoodStreak = 0;
        rm.initRunning();
    }

    function onTick() as Void { sm.tick();}

    function isGpsReady() as Boolean {
        if (SIMULATOR || DEBUG){ return true;}
        var info = Activity.getActivityInfo();

        if (info == null ||
            info.currentLocation == null ||
            info.currentLocationAccuracy == null
        ) {
            gpsGoodStreak = 0;
            return false;
        }

        if (info.currentLocationAccuracy >= Position.QUALITY_GOOD) {
            gpsGoodStreak += 1;
        } else {
            gpsGoodStreak = 0;
        }

        return gpsGoodStreak >= GPS_STABLE_TICKS;
    }

    function isTimeoutSending() as Boolean {
        if (sendingTime >= SENDING_TIMEOUT) {
            errorMsg = "Send timeout";
            return true;
        }
        sendingTime += 1;
        return false;
    }

    function needQuitConfirm() as Boolean {
        switch (sm._state) {
            case STATE_IDLE:
            case STATE_ERROR:
            case STATE_SYNCED:
            case STATE_NEED_SYNC:
                return false;
            default:
                return true;
        }
    }

    function canReceiveMsg() as Boolean {
         switch (sm._state) {
            case STATE_IDLE:
            case STATE_SENDING:
                return true;
            default:
                return false;
        }
    }

    function sendSession() as Void {
        sendingTime = 0;
        if (SIMULATOR) {return;}
        Communications.transmit(
            {
                "type"    =>  "SEND_RESULTS",
                "payload" => getSession(), 
            },
            null, 
            new TransmitCallback(self)
        );
    }

    function sendAck(type as String, ok as Boolean, error as String?) as Void {
        if (SIMULATOR) {return;}
        var payload = { "status" => ok ? "OK" : "ERROR" };
        if (error != null) { payload["error"] = error; }

        Communications.transmit(
            { "type" => type, "payload" => payload },
            null,
            new TransmitCallback(self)
        );
    }

    function getSession() as Dictionary? {
        return Application.Storage.getValue("session@notrackrun");
    }

    function deleteSession() as Void {
        Application.Storage.deleteValue("session@notrackrun");
    }

    function vibe(pattern as Array<Attention.VibeProfile>) as Void {
        if (Attention has :vibrate) { Attention.vibrate(pattern);}
    }

    function onBlockChanged() as Void { vibe(VIBE_BLOCK_CHANGE);}
    
    function onFieldChanged() as Void { vibe(VIBE_FIELD_CHANGE);}

    function onSessionEnded() as Void { vibe(VIBE_SESSION_END);}

    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [ new NoTrackRunView(), new NoTrackRunDelegate() ];
    }

}

function getApp() as NoTrackRunApp {
    return Application.getApp() as NoTrackRunApp;
}


class TransmitCallback extends Communications.ConnectionListener {

        var app;

        function initialize(a) {
            ConnectionListener.initialize();
            app = a;
        }

        function onComplete() as Void {}

        function onError() as Void {
            // If bluetooth is off on the mobile
            app.sm.handle(EVENT_SYNCED_KO);
            app.errorMsg = "Phone unreachable";
        }
}