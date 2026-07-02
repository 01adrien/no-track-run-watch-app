import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Communications;
import Toybox.Timer;
import Toybox.Application;
using Toybox.Position;


class NoTrackRunApp extends Application.AppBase {

    var sm              as StateManager = new StateManager();
    var rm              as RunManager   = new RunManager(sm);
    var timer           as Timer.Timer  = new Timer.Timer();
    var sendingTime     as Number       = 0;
    var errorMsg        as String       = "";

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

    function onPhoneMessage(msg as Communications.PhoneAppMessage) as Void {
        var data = msg.data;
        var event = EVENT_ERROR;
        if (data instanceof String) {
            if (data.equals("ACK")) {
                deleteSession();
                event = EVENT_SYNCED_OK;
            }
        }
        else if (data instanceof Dictionary) {
            if (getSession() == null) {
                rm.init(data as Dictionary);
                event = EVENT_SESSION_RECEIVED;
            } else { event = EVENT_NEED_SYNC; }
        }
        sm.handle(event);
    }

    function onPosition(info as Position.Info) as Void {
        if (info != null && info.speed != null) { rm.currentSpeed = info.speed;} 
        else { rm.currentSpeed = 0.0;}
    }
    
    function startSession() as Void {
        timer.start(method(:onTick), 1000, true);
    }

    function onTick() as Void {
        sm.tick();
    }

    function isGpsReady() as Boolean {
        // TODO remove 
        return true;
        var info = Position.getInfo();
        if (info == null)           { return false; }
        if (info.accuracy == null)  { return false; }
        return info.accuracy >= Position.QUALITY_POOR; 
    }

    function isTimeoutSending() as Boolean {
        if (sendingTime >= 10) {
            errorMsg = "Sync timeout";
            return true;
        }
        sendingTime += 1;
        return false;
    }

    function sendSession() as Void {
        sendingTime = 0;
        Communications.transmit(
            getSession(), 
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