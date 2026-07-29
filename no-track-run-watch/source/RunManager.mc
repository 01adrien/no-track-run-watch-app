import Toybox.Lang;
import Toybox.Application;
import Toybox.ActivityRecording;
import Toybox.Activity;
import Toybox.Attention;

enum BlockGoal {
    GOAL_DISTANCE,
    GOAL_DURATION
}


class RunManager {
    var session               as ActivityRecording.Session?;
    var sm                    as StateManager;
    var currentSpeed          as Float      = 0.0;
    var currentBlockIdx       as Number     = 0;
    var currentFieldIdx       as Number     = 0;
    var fieldElapsed          as Number     = 0;
    var fieldDistance         as Float      = 0.0;
    var fieldStartDistance    as Float      = 0.0;  
    var results               as Array      = [];
    var sessionData           as Dictionary = {};
    var countdown             as Number     = 0;
    var onBlockAdvance        as Method?    = null;
    var onFieldAdvance        as Method?    = null;
    var onSessionEnd          as Method?    = null;
    var totalDistance         as Float      = 0.0;
    var totalDuration         as Number     = 0;
    var elevationGain         as Float      = 0.0;
    var averageSpeed          as Float      = 0.0;
    var runDateSec            as Number     = 0;

    function initialize(_sm as StateManager) { sm = _sm; }

    function init(data as Dictionary) { sessionData = data; }

    function initRunning() as Void {
        currentBlockIdx  = 0;
        currentFieldIdx  = 0;
        fieldElapsed     = 0;
        fieldDistance    = 0.0;
        fieldStartDistance = 0.0;
        results          = [];
        currentSpeed     = 0.0;
        elevationGain    = 0.0;
        totalDistance    = 0.0;   
        totalDuration    = 0;      
        averageSpeed     = 0.0;
        runDateSec       = Time.now().value();
        startActivitySession();
    }

    // ── Gestion du cycle de vie ActivityRecording ──

    function startActivitySession() as Void {
        if (session != null && session.isRecording()) {
            return;
        }
        session = ActivityRecording.createSession({
            :name     => "NoTrackRun",
            :sport    => Activity.SPORT_RUNNING,
            :subSport => Activity.SUB_SPORT_GENERIC
        });
        session.start();
    }

    function stopActivitySession(save as Boolean) as Void {
        if (session == null) { return; }
        if (session.isRecording()) { session.stop();}
        if (save) { session.save();} 
        else { session.discard();}
        session = null;
        sessionData = {} as Dictionary;
    }

    function running() as Void {
        var info = Activity.getActivityInfo();

        if (info == null || info.elapsedDistance == null) {
            return;
        }

        currentSpeed = info.currentSpeed != null
            ? info.currentSpeed
            : 0.0;

        elevationGain = info.totalAscent != null
            ? info.totalAscent
            : elevationGain;

        totalDistance = info.elapsedDistance;   

        totalDuration = info.timerTime != null
            ? (info.timerTime / 1000)           
            : totalDuration;


        fieldDistance = info.elapsedDistance - fieldStartDistance;

        if (fieldDistance < 0.0) { fieldDistance = 0.0; }

        fieldElapsed += 1;

        if (fieldRemaining() <= 0) { advanceField();}
    }

    function resetCountDown() as Void {
        countdown = 3;
    }

    function isCountDownOver() as Boolean {
        countdown -= 1;
        return countdown == 0;
    }

    function hasSessionData() as Boolean {
        return sessionData != null && sessionData.size() > 0;
    }

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
        return getCurrentField()["targetType"].equals("DISTANCE") ? GOAL_DISTANCE : GOAL_DURATION;
    }

    function getSessionLabel() as String {
        return sessionData["label"] as String;
    }

    function getSessionDate() as String {
        return sessionData["date"] as String;
    }

    function getBlocks() as Array {
        return sessionData["blocks"] as Array;
    }

    function getFieldsCount() as Number {
        var fieldsCount = 0;
        var blocks = getBlocks();
        var count = blocks.size();
        for (var i = 0; i < count; i++) {
            var fields = blocks[i]["fields"] as Array;
            fieldsCount += fields.size();
        }
        return fieldsCount;
    }

    function getBlocksCount() as Number {
        return getBlocks().size();
    }

    function fieldRemaining() as Number {
        var field = getCurrentField();
        if (getGoal() == GOAL_DISTANCE) {
            var dist = (field["targetValue"] as Number);
            var rem  = dist - fieldDistance;
            return (rem < 0) ? 0 : rem;
        } else {
            var dur = (field["targetValue"] as Number);
            var rem = dur - fieldElapsed;
            return (rem < 0) ? 0 : rem;
        }
    }

    function advanceField() as Void {
        saveFieldResult();


        var info = Activity.getActivityInfo();
        fieldStartDistance = (info != null && info.elapsedDistance != null) 
            ? info.elapsedDistance 
            : fieldStartDistance;

        fieldElapsed    = 0;
        fieldDistance   = 0.0;

        var block  = getCurrentBlock();
        var fields = block["fields"] as Array;

        if (currentFieldIdx < fields.size() - 1) { 
            if (onFieldAdvance != null) { onFieldAdvance.invoke();}
            currentFieldIdx += 1;
        }
        else { advanceBlock(); }
    }

    function advanceBlock() as Void {
        var blocks = sessionData["blocks"] as Array;
        currentFieldIdx = 0;


        if (currentBlockIdx < blocks.size() - 1) { 
            currentBlockIdx += 1;
            if (onBlockAdvance != null) { onBlockAdvance.invoke();} 
        }
        else {
            stopActivitySession(false);
            if (onSessionEnd != null) { onSessionEnd.invoke();}
            sm.handle(EVENT_SESSION_END);
        }
    }

    
     function getAveragePaceSecPerKm() as Number {
        if (averageSpeed <= 0.0) {return 0;}
        return (1000.0 / averageSpeed).toNumber();
    }


    function getAveragePaceFormatted() as String {
        var paceSec = getAveragePaceSecPerKm();
        if (paceSec <= 0) { return "--:--";}
        var minutes = paceSec / 60;
        var seconds = paceSec % 60;
        return minutes.toString() + ":" + seconds.format("%02d");
    }


    function saveSessionLocally() as Void {
        if (results.size() == 0) { return; }
        var store = Application.Storage;
        store.setValue("session@notrackrun", {
            "sessionId"      => sessionData["id"],
            "results"        => results,
            "elevationGain"  => elevationGain,
            "distance"       => totalDistance,   
            "duration"       => totalDuration,
            "avgPace"        => getAveragePaceFormatted(), 
            "date"           => runDateSec
        });
    }

    function saveFieldResult() as Void {
        var block = getCurrentBlock();
        var field = getCurrentField();

        var success = evaluateFieldSuccess(field, fieldDistance, fieldElapsed);

        results.add({
            "blockId"  => block["id"],
            "index"    => currentFieldIdx + 1,
            "distance" => fieldDistance,
            "duration" => fieldElapsed,
            "success"  => success,
        });
        saveSessionLocally();
    }

    function evaluateFieldSuccess(field as Dictionary, distance as Float, duration as Number) as Boolean {
        if (!targetReached(field, distance, duration)) {
            return false;
        }
        return paceIsValid(field, distance, duration);
    }

    function targetReached(field as Dictionary, distance as Float, duration as Number) as Boolean {
        if (getGoal() == GOAL_DISTANCE) {
            var target = field["targetValue"] as Number;
            return distance >= target;
        } else {
            var target = field["targetValue"] as Number;
            return duration >= target;
        }
    }

    function paceIsValid(field as Dictionary, distance as Float, duration as Number) as Boolean {
        var minSpeed = field["minSpeed"] as Float;
        var maxSpeed = field["maxSpeed"] as Float;

        if (minSpeed == 0.0 && maxSpeed == 0.0) {
            return true;
        }
        if (duration <= 0) {
            return false;
        }

        var avgFieldSpeed = distance / duration.toFloat();
        return avgFieldSpeed >= minSpeed && avgFieldSpeed <= maxSpeed;
    }
}

