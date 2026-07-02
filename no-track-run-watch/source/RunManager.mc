
import Toybox.Lang;
import Toybox.Application;

enum BlockGoal {
    GOAL_DISTANCE,
    GOAL_DURATION
}

class RunManager {
    var currentSpeed    as Float       = 0.0;
    var currentBlockIdx as Number      = 0;
    var currentFieldIdx as Number      = 0;
    var fieldElapsed    as Number      = 0;
    var fieldMovingTime as Number      = 0;
    var fieldDistance   as Float       = 0.0;
    var results         as Array       = [];
    var avgPace         as Float       = 0.0;
    var sessionData     as Dictionary  = {};
    var countdown       as Number      = 0;
    var sm              as StateManager;

    function initialize(_sm as StateManager) {
        sm = _sm;
    }

    function init(data as Dictionary) {
        sessionData = data;
    }

    function initRunning() as Void {
        currentBlockIdx = 0;
        currentFieldIdx = 0;
        avgPace         = 0.0;
        fieldElapsed    = 0;
        fieldDistance   = 0.0;
        fieldMovingTime = 0;
        results         = [];
        currentSpeed    = 0.0;
    }

   function running() {
        var moving = currentSpeed > 0.3;
        fieldElapsed  += 1; // sec
        fieldDistance += moving ? currentSpeed : 0.0 ; // m / s
        fieldMovingTime += moving ? 1 : 0;  
        if (fieldMovingTime > 0) {
            avgPace = fieldDistance / fieldMovingTime; // m/s sur temps réel
        }

        if (fieldRemaining() <= 0) { advanceField();}
    }

    function resetCountDown() as Void {
        countdown = 3;
    }

    function isCountDownOver() as Boolean {
        if (countdown == 0) { return true;}
        countdown -= 1;
        return false;
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
        return getCurrentField().hasKey("distance") ? GOAL_DISTANCE : GOAL_DURATION;
    }   

    function fieldRemaining() as Number {
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

    function advanceField() as Void {
        saveFieldResult();

        fieldElapsed  = 0;
        fieldDistance = 0.0;
        avgPace   = 0.0;

        var block  = getCurrentBlock();
        var fields = block["fields"] as Array;

        if (currentFieldIdx < fields.size() - 1) {
            currentFieldIdx += 1;
        } else {
            advanceBlock();
        }
    }

    function advanceBlock() as Void {
        var blocks = sessionData["blocks"] as Array;
        currentFieldIdx = 0;

        if (currentBlockIdx < blocks.size() - 1) {
            currentBlockIdx += 1;
        } else {
            sm.handle(EVENT_SESSION_END);
        }
    }

    function saveSessionLocally() as Void {
        if (results.size() == 0) { return; }   
        var store = Application.Storage;
        store.setValue("session@notrackrun", {
            "sessionId" => sessionData["id"],
            "date"      => sessionData["date"],
            "results"   => results
        });
    }

    function saveFieldResult() as Void {
        var block = getCurrentBlock();
        var field = getCurrentField();

        var targetPace = field["pace"];
        var realPace   = 0;

        if (fieldElapsed > 0) {
            realPace = fieldDistance / fieldElapsed; 
        }


        results.add({
            "blockId"  => block["id"],
            "index"    => currentFieldIdx,
            "distance" => fieldDistance,
            "duration" => fieldElapsed,
            "realPace" => realPace
        });
        saveSessionLocally();
    }

}