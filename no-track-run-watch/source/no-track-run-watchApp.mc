import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Communications;
import Toybox.System;
import Toybox.Timer;
import Toybox.ActivityMonitor;
import Toybox.Sensor;

using Toybox.Position;
using Toybox.Sensor;
using Toybox.System;

enum AppState {
    STATE_IDLE,
    STATE_SUMMARY,
    STATE_COUNTDOWN,
    STATE_RUNNING,
    STATE_FINISHED,
    STATE_NEED_SYNC_APP,
    STATE_SESSION_SYNC_APP,
    STATE_LOADING,
    STATE_SENDING_SESSION,
    STATE_GPS_FIXING,
    STATE_ERROR,
}

enum BlockGoal {
    GOAL_DISTANCE,
    GOAL_DURATION
}

var SIMULATOR = false;


class NoTrackRunWatchApp extends Application.AppBase {

    var sessionData     as Dictionary  = {};
    var appState        as Number      = STATE_IDLE;
    var currentBlockIdx as Number      = 0;
    var currentFieldIdx as Number      = 0;
    var fieldElapsed    as Number      = 0;
    var fieldMovingTime as Number      = 0;
    var fieldDistance   as Float       = 0.0;
    var results         as Array       = [];
    var _timer          as Timer.Timer = new Timer.Timer();
    var avgPace         as Float       = 0.0;
    var countdownValue  as Number      = 3;
    var blinkOn         as Boolean     = true;
    var timerLoading    as Timer.Timer = new Timer.Timer();
    var sessionToSend   as Dictionary  = {};
    var currentSpeed    as Float       = 0.0;
    var errorMsg        as String      = "";
    var syncTimeout     as Number      = 10;
    var sendingTime     as Number      = 0;

    function initialize() {
        AppBase.initialize();
    }

    // ─────────────────────────────────────────
    //  App listeners
    // ─────────────────────────────────────────

    function onPhoneMessage(msg as Communications.PhoneAppMessage) as Void {

        var data = msg.data;

        if (data instanceof String) {
            if (data.equals("ACK")) {
                Application.Storage.deleteValue("session@notrackrun");
                errorMsg = data;
                appState = STATE_SESSION_SYNC_APP;
            }
        }

        else if (data instanceof Dictionary) {

            var d = data as Dictionary;
            var pending = Application.Storage.getValue("session@notrackrun");

            if (pending == null) {
                sessionData = d;
                appState = STATE_SUMMARY;
            } else {
                appState = STATE_NEED_SYNC_APP;
            }
        }
        else {
            appState = STATE_ERROR;
        }

        WatchUi.requestUpdate();
    }

    function onStart(state as Dictionary?) as Void {
        _retrySendIfPending();
        Communications.registerForPhoneAppMessages(method(:onPhoneMessage));
        // Sensor.enableSensorEvents(method(:onSensor));
        Position.enableLocationEvents(
            {
                :acquisitionType => Position.LOCATION_CONTINUOUS,
                :mode => Position.POSITIONING_MODE_NORMAL
            },
            method(:onPosition)
        );
    }

    function onStop(state as Dictionary?) as Void {
        _timer.stop();
        // Sensor.setEnabledSensors([] as Array);
        Position.enableLocationEvents(Position.LOCATION_DISABLE, null);
        System.println("Session terminée : " + results.toString());
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [ new NoTrackRunView(), new NoTrackRunDelegate() ];
    }

    // ─────────────────────────────────────────
    //  Helpers lecture session
    // ─────────────────────────────────────────

    function getCurrentBlock() as Dictionary {
        var blocks = sessionData["blocks"] as Array;
        return blocks[currentBlockIdx] as Dictionary;
    }

    function getCurrentField() as Dictionary {
        var block  = getCurrentBlock();
        var fields = block["fields"] as Array;
        return fields[currentFieldIdx] as Dictionary;
    }

    function getGoal() as BlockGoal {
        return getCurrentField().hasKey("distance") ? GOAL_DISTANCE : GOAL_DURATION;
    }   

    function _isFieldDone() as Boolean {
        var field    = getCurrentField();
        if (getGoal() == GOAL_DISTANCE) {
            var target   = (field["distance"] as Number);
            return fieldDistance >= target;
        } else {
            var target   = (field["duration"] as Number);
            return fieldElapsed >= target;
        }
    }

    function primaryRemaining() as Number {
        var field = getCurrentField();
        if (getGoal() == GOAL_DISTANCE) {
            var dist = (field["distance"] as Number);
            var rem  = dist - fieldDistance;
            return (rem < 0) ? 0 : rem;
        } else {
            var dur = (field["duration"] as Number);
            var rem = dur - fieldElapsed;
            return (rem < 0) ? 0 : rem;
        }
    }

    
    
    function onPosition(info as Position.Info) as Void {

        if (info != null && info.speed != null) {
             currentSpeed = info.speed;
        } else {
             currentSpeed = 0.0;
        }
    }

    // ─────────────────────────────────────────
    //  Contrôle session
    // ─────────────────────────────────────────

    function startSession() as Void {
        appState = STATE_GPS_FIXING;
        _timer.start(method(:onTick), 1000, true);
        WatchUi.requestUpdate();
    }

    function onTick() as Void {

        if(appState == STATE_GPS_FIXING && isGpsReady(Position.getInfo())) {
            appState = STATE_COUNTDOWN;
            countdownValue = 4;
            WatchUi.requestUpdate();
        }

        if (appState == STATE_SENDING_SESSION) {

            if (sendingTime >= syncTimeout){
                appState = STATE_NEED_SYNC_APP;
                WatchUi.requestUpdate();
                return;
            }

            sendingTime += 1;
        }

        if (appState == STATE_COUNTDOWN) {
            countdownValue -= 1;
            if (countdownValue <= 0) {
                appState        = STATE_RUNNING;
                currentBlockIdx = 0;
                currentFieldIdx = 0;
                avgPace         = 0.0;
                fieldElapsed    = 0;
                fieldDistance   = 0.0;
                fieldMovingTime = 0;
                results         = [];
                currentSpeed    = 0.0;

            }
            WatchUi.requestUpdate();
            return;
        }

        if (appState != STATE_RUNNING) { return; }

        var moving = currentSpeed > 0.3;
        fieldElapsed  += 1; // sec
        fieldDistance += moving ? currentSpeed : 0.0 ; // m / s
        fieldMovingTime += moving ? 1 : 0;  
        if (fieldMovingTime > 0) {
            avgPace = fieldDistance / fieldMovingTime; // m/s sur temps réel
        }

        if (_isFieldDone()) {
            _saveFieldResult();
            _advanceField();
        }
        WatchUi.requestUpdate();
    }

    function _saveFieldResult() as Void {
        var block = getCurrentBlock();
        var field = getCurrentField();

        var targetPace = field["pace"];
        var realPace   = 0;

        if (fieldElapsed > 0) {
            realPace = fieldDistance / fieldElapsed; 
        }

        var tolerance = 0.1; 
        var success = true;// Math.abs(realPace - targetPace) <= (targetPace * tolerance);

        results.add({
            "blockId"  => block["id"],
            "index"    => currentFieldIdx,
            "distance" => fieldDistance,
            "duration" => fieldElapsed,
            "success"  => success,
            "realPace" => realPace
        });
        _saveSessionLocally();
    }

    function _saveSessionLocally() as Void {
        if (results.size() == 0) {
            return;
        }   
        var store = Application.Storage;
        store.setValue("session@notrackrun", {
            "sessionId" => sessionData["id"],
            "date"      => sessionData["date"],
            "results"   => results
        });
    }

    
    function _finishSession() as Void {
        // _timer.stop();
        appState = STATE_FINISHED;
        WatchUi.requestUpdate();
    }

    function _advanceField() as Void {
        fieldElapsed  = 0;
        fieldDistance = 0.0;
        avgPace   = 0.0;

        var block  = getCurrentBlock();
        var fields = block["fields"] as Array;

        if (currentFieldIdx < fields.size() - 1) {
            currentFieldIdx += 1;
        } else {
            _advanceBlock();
        }
    }

    function _advanceBlock() as Void {
        var blocks = sessionData["blocks"] as Array;
        currentFieldIdx = 0;

        if (currentBlockIdx < blocks.size() - 1) {
            currentBlockIdx += 1;
        } else {
            _finishSession();
        }
    }

    function skipCurrentField() as Void {
        if (appState != STATE_RUNNING) { return; }
        _saveFieldResult();
        _advanceField();
        WatchUi.requestUpdate();
    }


    function endSession() as Void {
        _finishSession();
    }


   function backIdle() as Void {
        sessionData = {};
        _timer.stop();
        appState    = STATE_IDLE;
    }
  
    function _resetState() as Void {
        appState        = STATE_SUMMARY;
        currentBlockIdx = 0;
        currentFieldIdx = 0;
        fieldElapsed    = 0;
        sessionToSend   = {};
        fieldDistance   = 0.0;
        results         = [];
        avgPace         = 0.0;
        fieldMovingTime = 0;
        sendingTime     = 0;
    }

    class TransmitCallback extends Communications.ConnectionListener {

        var _app;

        function initialize(app) {
            ConnectionListener.initialize();
            _app = app;
            WatchUi.requestUpdate();
        }

        function onComplete() as Void {
            // Application.Storage.deleteValue("session@notrackrun");
            // _app.backIdle();
            WatchUi.requestUpdate();
        }

        function onError() as Void {
            _app.appState = STATE_NEED_SYNC_APP;
            WatchUi.requestUpdate();
        }
    }

    function _sendResultsToPhone() as Void {
        var payload = {
            "date"      => sessionData["date"],
            "sessionId" => sessionData["id"],
            "results"   => results
        }; 
        
        _sendSession(payload);
        
    }


    function _retrySendIfPending() as Void {
        var pending = Application.Storage.getValue("session@notrackrun");
        if (pending != null) {
            _sendSession(pending);
        }
    }

    function _sendSession(session as Dictionary) as Void {
        sessionToSend = session;
        appState = STATE_SENDING_SESSION;
        sendingTime = 0;
        Communications.transmit(session, null, new TransmitCallback(self));
        // timerLoading.start(method(:finishLoading), 1000, false);
    }

    function finishLoading() as Void {
        Communications.transmit(sessionToSend, null, new TransmitCallback(self));
    }

    function isGpsReady(info as Position.Info) as Boolean {
        if (info == null) {
            return false;
        }
        if (info.accuracy == null) {
            return false;
        }
        return info.accuracy >= Position.QUALITY_USABLE;
    }
}





function getApp() as NoTrackRunWatchApp {
    return Application.getApp() as NoTrackRunWatchApp;
}