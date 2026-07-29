import Toybox.Lang;

module Validator {
     function isValidMsg(msg as Object) as Boolean {
        if (!(msg instanceof Dictionary)) { return false; }
        if (!msg.hasKey("type") || !(msg["type"] instanceof String)) { return false; }
        if (!msg.hasKey("payload") || !(msg["payload"] instanceof Dictionary)) { return false; }
        return true;
        
    }

    function isValidAckPayload(payload as Dictionary) as Boolean {
        if (!payload.hasKey("status")    || !(payload["status"] instanceof String)) { return false; }
        return true;
    }

    function isValidSessionPayload(payload as Dictionary) as Boolean {

        if (!payload.hasKey("id")    || !(payload["id"] instanceof Number)) { return false; }
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
        if (!b.hasKey("id")    || !(b["id"] instanceof Number)) { return false; }
        if (!b.hasKey("label") || !(b["label"] instanceof String)) { return false; }
        if (!b.hasKey("fields") || !(b["fields"] instanceof Array)) { return false; }
        var fields = b["fields"] as Array;
        if (fields.size() == 0) { return false; }

        for (var i = 0; i < fields.size(); i++) {
            if (!isValidField(fields[i])) { return false;}
        }
        return true;
    }


    function isValidField(field as Object) as Boolean {
        if (!(field instanceof Dictionary)) { return false; }
        var f = field as Dictionary;

        if (!f.hasKey("index")      || !(f["index"] instanceof Number)) { return false; }
        if (!f.hasKey("targetType") || !(f["targetType"] instanceof String)) { return false; }
        if (!f.hasKey("targetValue")) { return false; } 
        if (!f.hasKey("minSpeed")   || !isNumeric(f["minSpeed"])) { return false; }
        if (!f.hasKey("maxSpeed")   || !isNumeric(f["maxSpeed"])) { return false; }
        if (!f.hasKey("pace")       || !(f["pace"] instanceof String)) { return false; }

        // targetType doit être une valeur connue
        var type = f["targetType"] as String;
        if (!(type.equals("DURATION") || type.equals("DISTANCE") || type.equals("NONE"))) { return false;}

        return true;
    }


    function isNumeric(val as Object) as Boolean {
        return (val instanceof Number) || (val instanceof Float);
    }
}