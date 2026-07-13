
import Toybox.Lang;
import Toybox.Application;

enum BlockGoal {
    GOAL_DISTANCE,
    GOAL_DURATION
}

// 0 = très lisse/lent, 1 = pas de lissage
const SPEED_SMOOTHING_ALPHA as Float = 0.3; 
const MOVING_THRESHOLD_MS   as Float = 0.3;

class RunManager {
    var currentSpeed    as Float       = 0.0;
    var smoothedSpeed   as Float       = 0.0;
    var currentBlockIdx as Number      = 0;
    var currentFieldIdx as Number      = 0;
    var fieldElapsed    as Number      = 0;
    var fieldMovingTime as Number      = 0;
    var fieldDistance   as Float       = 0.0;
    var results         as Array       = [];
    var avgSpeed        as Float       = 0.0;
    var sessionData     as Dictionary  = {};
    var countdown       as Number      = 0;
    var sm              as StateManager;
    

    function initialize(_sm as StateManager) { sm = _sm;}

    function init(data as Dictionary) { sessionData = data; }

    function initRunning() as Void {
        currentBlockIdx = 0;
        currentFieldIdx = 0;
        avgSpeed         = 0.0;
        fieldElapsed    = 0;
        fieldDistance   = 0.0;
        fieldMovingTime = 0;
        results         = [];
        currentSpeed    = 0.0;
    }

    // EMA (moyenne mobile exponentielle) : lisse une valeur bruitée sans
    // garder d'historique, juste 1 variable mise à jour à chaque tick.
    //
    // nouvelle_moyenne = α × mesure_brute + (1 - α) × ancienne_moyenne
    //
    // α proche de 1 → très réactif mais garde le bruit
    // α proche de 0 → très lisse mais réagit lentement aux vrais changements
    // α = 0.3 → la mesure brute pèse 30%, l'historique lissé pèse 70%
    function setSpeed(rawSpeed as Float) as Void {
        currentSpeed = rawSpeed;
        smoothedSpeed = (SPEED_SMOOTHING_ALPHA * rawSpeed)
                    + ((1.0 - SPEED_SMOOTHING_ALPHA) * smoothedSpeed);
    }
    
    function running() as Void {
        var moving = smoothedSpeed > MOVING_THRESHOLD_MS;
        fieldElapsed  += 1; // sec
        fieldDistance += moving ? smoothedSpeed : 0.0; // m / s
        fieldMovingTime += moving ? 1 : 0;
        if (fieldMovingTime > 0) {
            avgSpeed = fieldDistance / fieldMovingTime;
        }

        if (fieldRemaining() <= 0) { advanceField(); }
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
        return getCurrentField()["targetType"] == "DISTANCE" ? GOAL_DISTANCE : GOAL_DURATION;
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

        fieldElapsed  = 0;
        fieldMovingTime = 0;
        fieldDistance = 0.0;
        avgSpeed   = 0.0;

        var block  = getCurrentBlock();
        var fields = block["fields"] as Array;

        if (currentFieldIdx < fields.size() - 1) { currentFieldIdx += 1; } 
        else { advanceBlock(); }
    }

    function advanceBlock() as Void {
        var blocks = sessionData["blocks"] as Array;
        currentFieldIdx = 0;

        if (currentBlockIdx < blocks.size() - 1) { currentBlockIdx += 1; } 
        else { sm.handle(EVENT_SESSION_END); }
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
        results.add({
            "blockId"  => block["id"],
            "index"    => currentFieldIdx + 1,
            "distance" => fieldDistance,
            "duration" => fieldElapsed,
        });
        saveSessionLocally();
    }

}