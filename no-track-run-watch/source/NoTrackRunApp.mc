import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Communications;
import Toybox.Timer;
import Toybox.Application;
using Toybox.Position;
using Toybox.System;


const SENDING_TIMEOUT as Number = 8;

class NoTrackRunApp extends Application.AppBase {

    var sm              as StateManager = new StateManager();
    var rm              as RunManager   = new RunManager(sm);
    var timer           as Timer.Timer  = new Timer.Timer();
    var sendingTime     as Number       = 0;
    var errorMsg        as String       = "";
    var lastRawSpeed    as Float        = 0.0;

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
        Communications.registerForPhoneAppMessages(method(:onPhoneMessage));
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

    function exit() as Void { 
        System.exit(); 
    }

    function onPhoneMessage(msg as Communications.PhoneAppMessage) as Void {
        // TODO valider format de session payload
        if (canReceiveMsg() && msg.data != null) {
            var data = msg.data;
            var type = data["type"] as String;

            var event = EVENT_ERROR;
            if (type.equals("SEND_SESSION")) {
                if (getSession() == null) {
                    rm.init(data["payload"] as Dictionary);
                    event = EVENT_SESSION_RECEIVED;
                    sendAck("ACK_SESSION", true, null);
                }
                else  { 
                    sendAck("ACK_SESSION", false, "Already a session on the watch");
                }
                
            } else if (type.equals("ACK_RESULTS")) {
                var payload = data["payload"] as Dictionary;
                if (payload["status"].equals("OK")) {
                    event = EVENT_SYNCED_OK;
                } else {
                    errorMsg = "Invalid session";
                }
            } else { 
                errorMsg = type;
            }
            sm.handle(event);
        }
    }


    function onPosition(info as Position.Info) as Void {
        lastRawSpeed = (info != null && info.speed != null) ? info.speed : 0.0;
    }
    
    function startSession() as Void {
        timer.start(method(:onTick), 1000, true);
    }

    function onTick() as Void {
        sm.tick();
        rm.setSpeed(lastRawSpeed);
    }

    function isGpsReady() as Boolean {
        // TODO remove 
        //return true;
        var info = Position.getInfo();
        if (info == null)           { return false; }
        if (info.accuracy == null)  { return false; }
        return info.accuracy >= Position.QUALITY_POOR; 
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
        /*
        Communications.transmit(
            {
                "type"    =>  "SEND_RESULTS",
                "payload" => getSession(), 
            },
            null, 
            new TransmitCallback(self)
        );
        */
    }

    function sendAck(type as String, ok as Boolean, error as String?) as Void {
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

        function onComplete() as Void {
            // app.sm.handle(EVENT_SYNCED_OK);
        }

        function onError() as Void {
            // If bluetooth is off on the mobile
            app.sm.handle(EVENT_SYNCED_KO);
            app.errorMsg = "Phone unreachable";
        }
}