import Toybox.Lang;

module Validator {
    function isValidMsg(msg as Object) as Boolean {
        if (!(msg instanceof Dictionary)) { return false; }
        if (!msg.hasKey("type") || !(msg["type"] instanceof String)) { return false; }
        if (!msg.hasKey("payload") || !(msg["payload"] instanceof Dictionary)) { return false; }
        return true;
    }

    function isValidAckPayload(payload as Dictionary) as Boolean {
        if (!payload.hasKey("status") || !(payload["status"] instanceof String)) { return false; }
        return true;
    }

    function isValidSessionPayload(payload as Dictionary) as Boolean {
        if (!payload.hasKey("id")    || !isPositiveNumber(payload["id"])) { return false; }
        if (!payload.hasKey("label") || !(payload["label"] instanceof String)) { return false; }
        if (!payload.hasKey("date")  || !(payload["date"] instanceof String)) { return false; }
        if (!payload.hasKey("blocks") || !(payload["blocks"] instanceof Array)) { return false; }

        var blocks = payload["blocks"] as Array;
        if (blocks.size() == 0) { return false; }

        for (var i = 0; i < blocks.size(); i++) {
            if (!isValidBlock(blocks[i])) { return false; }
        }
        return true;
    }

    function isValidBlock(block as Object) as Boolean {
        if (!(block instanceof Dictionary)) { return false; }
        var b = block as Dictionary;

        if (!b.hasKey("id")          || !isPositiveNumber(b["id"])) { return false; }
        if (!b.hasKey("order")       || !isPositiveNumber(b["order"])) { return false; }
        if (!b.hasKey("label")       || !(b["label"] instanceof String)) { return false; }
        if (!b.hasKey("type")        || !(b["type"] instanceof String)) { return false; }
        if (!b.hasKey("repetitions") || !isPositiveNumber(b["repetitions"])) { return false; }
        if (!b.hasKey("fields")      || !(b["fields"] instanceof Array)) { return false; }

        var blockType = b["type"] as String;
        if (!(blockType.equals("RUNNING") || blockType.equals("CONDITIONNING"))) { return false; }

        var fields = b["fields"] as Array;
        for (var i = 0; i < fields.size(); i++) {
            if (!isValidField(fields[i])) { return false; }
        }

        // exercices est optionnel structurellement, mais si présent, chaque item doit être valide
        var exercicesCount = 0;
        if (b.hasKey("exercices")) {
            if (!(b["exercices"] instanceof Array)) { return false; }
            var exercices = b["exercices"] as Array;
            exercicesCount = exercices.size();
            for (var j = 0; j < exercicesCount; j++) {
                if (!isValidExercise(exercices[j])) { return false; }
            }
        }

        // Il faut au moins un field OU un exercice non-vide
        if (fields.size() == 0 && exercicesCount == 0) { return false; }

        return true;
    }

    function isValidExercise(exercise as Object) as Boolean {
        if (!(exercise instanceof Dictionary)) { return false; }
        var e = exercise as Dictionary;

        if (!e.hasKey("order") || !isPositiveNumber(e["order"])) { return false; }
        if (!e.hasKey("label") || !(e["label"] instanceof String)) { return false; }
        if (!e.hasKey("reps")  || !isPositiveNumber(e["reps"])) { return false; }

        return true;
    }

    function isValidField(field as Object) as Boolean {
        if (!(field instanceof Dictionary)) { return false; }
        var f = field as Dictionary;

        if (!f.hasKey("role")        || !(f["role"] instanceof String)) { return false; }
        if (!f.hasKey("targetType")  || !(f["targetType"] instanceof String)) { return false; }
        if (!f.hasKey("targetValue") || !isNumeric(f["targetValue"])) { return false; }
        if (!f.hasKey("pace")        || !(f["pace"] instanceof String)) { return false; }

        var role = f["role"] as String;
        if (!(role.equals("EFFORT") || role.equals("RECOVERY"))) { return false; }

        var type = f["targetType"] as String;
        if (!(type.equals("DURATION") || type.equals("DISTANCE") || type.equals("NONE"))) { return false; }

        // targetValue doit être > 0 sauf si targetType == NONE
        if (!type.equals("NONE")) {
            if (!isPositiveNumber(f["targetValue"])) { return false; }
        }

        return true;
    }

    function isNumeric(val as Object) as Boolean {
        return (val instanceof Number) || (val instanceof Float);
    }

    function isPositiveNumber(val as Object) as Boolean {
        if (!(val instanceof Number)) { return false; }
        return (val as Number) > 0;
    }
}