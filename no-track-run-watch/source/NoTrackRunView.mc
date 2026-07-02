import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Timer;
  
class NoTrackRunView extends WatchUi.View {
    
    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Dc) as Void {}

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        var app = getApp();
        var state = app.sm.state;
        switch (state) {
            case STATE_IDLE:
                drawIdle(dc, app);
                break;
            case STATE_SUMMARY:
                drawSummary(dc, app);
                break;
            case STATE_COUNTDOWN:
                drawCountdown(dc, app);
                break;
            case STATE_RUNNING:
                drawRunning(dc, app);
                break;
            case STATE_FINISHED:
                drawFinished(dc, app);
                break;
            case STATE_NEED_SYNC:
                break;
            case STATE_SYNCED:
                drawSynced(dc, app);
                break;
            case STATE_SENDING:
                drawMessage(dc, app, "Sending session...");
                break;
            case STATE_GPS_FIXING:
                drawMessage(dc, app, "Acquiring GPS...");
                break;
            case STATE_ERROR:
                drawError(dc, app);
                break;
        }
    }


    // ---------------
    // -- IDLE VIEW -- 
    //----------------
    function drawIdle(dc as Dc, app as NoTrackRunApp) as Void {
        var cx = dc.getWidth()  / 2;
        var cy = dc.getHeight() / 2;

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - 20, Graphics.FONT_SMALL, 
                        "Waiting for session..", Graphics.TEXT_JUSTIFY_CENTER);
        
    }


    // --------------------------
    // -- SESSION SUMMARY VIEW -- 
    //---------------------------
    function drawSummary(dc as Dc, app as NoTrackRunApp) as Void {
        var cx = dc.getWidth()  / 2;
        var y  = 50;

        // ── Titre session ──
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        var label = app.rm.sessionData["label"] as String;
        dc.drawText(cx, y, Graphics.FONT_MEDIUM, label, Graphics.TEXT_JUSTIFY_CENTER);
        y += 35;

        // ── Date ──
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        var date = app.rm.sessionData["date"] as String;
        dc.drawText(cx, y, Graphics.FONT_SMALL, date, Graphics.TEXT_JUSTIFY_CENTER);
        y += 35;

        // ── Blocs ──
        var blocks = app.rm.sessionData["blocks"] as Array;
        var totalDistance = app.rm.sessionData["distance"];
        var totalDuration = app.rm.sessionData["duration"];

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, Graphics.FONT_SMALL, blocks.size().toString() + " blocks", Graphics.TEXT_JUSTIFY_CENTER);
        y += 28;

        dc.drawText(cx, y, Graphics.FONT_SMALL, formatDistance(totalDistance)
                        , Graphics.TEXT_JUSTIFY_CENTER);
        y += 28;

        dc.drawText(cx, y, Graphics.FONT_SMALL, formatTime(totalDuration)
                        , Graphics.TEXT_JUSTIFY_CENTER);
        y += 40;
    }


    // ------------------
    // -- MESSAGE VIEW -- 
    // ------------------
    function drawMessage(dc as Dc, app as NoTrackRunApp, msg as String) as Void {

        var cx = dc.getWidth()  / 2;
        var cy = dc.getHeight() / 2;

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);

        dc.drawText(
            cx,
            cy - 20,
            Graphics.FONT_SMALL,
            msg,
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }


    // ----------------
    // -- ERROR VIEW -- 
    // ----------------
    function drawError(dc as Dc, app as NoTrackRunApp) as Void {

        var cx = dc.getWidth()  / 2;
        var cy = dc.getHeight() / 3;

        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            cx,
            cy - 30,
            Graphics.FONT_LARGE,
            "Error",
            Graphics.TEXT_JUSTIFY_CENTER
        );
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            cx,
            cy + 10,
            Graphics.FONT_SMALL,
            app.errorMsg,
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }


    // --------------------
    // -- COUNTDOWN VIEW -- 
    // --------------------
    function drawCountdown(dc as Dc, app as NoTrackRunApp) as Void {
        var cx = dc.getWidth()  / 2;
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        if (app.rm.countdown == 0) {
                dc.drawText(cx, dc.getHeight() / 2, Graphics.FONT_LARGE, "GO", Graphics.TEXT_JUSTIFY_CENTER);
        } else {
        dc.drawText(cx, 50, Graphics.FONT_NUMBER_THAI_HOT,
            app.rm.countdown.toString(), 
            Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    // ------------------
    // -- RUNNING VIEW -- 
    //-------------------
    function drawRunning(dc as Dc, app as NoTrackRunApp) as Void {
        var cx = dc.getWidth()  / 2;
        var w  = dc.getWidth();
        var y  = 40;

        var block = app.rm.getCurrentBlock();
        var field = app.rm.getCurrentField();

        // ── Nom du bloc ──
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        var blkLabel = block["label"] as String;
        dc.drawText(cx, y, Graphics.FONT_MEDIUM, blkLabel, Graphics.TEXT_JUSTIFY_CENTER);
        y += 40;

        // ── Pastilles de progression des fields ──
        var fields     = block["fields"] as Array;
        var dotSize    = 8;
        var dotSpacing = 18;
        var totalDots  = fields.size();
        var dotsWidth  = totalDots * dotSpacing - (dotSpacing - dotSize);
        var dotX       = (w - dotsWidth) / 2;
        for (var i = 0; i < totalDots; i++) {
            if (i < app.rm.currentFieldIdx) {
                dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
            } else if (i == app.rm.currentFieldIdx) {
                if (app.rm.fieldElapsed % 2 == 0) {
                    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                } else {
                    dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
                }
            } else {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            }
            dc.fillCircle(dotX + dotSize / 2, y + dotSize / 2, dotSize / 2);
            dotX += dotSpacing;
        }
        y += 20;

        // ── Valeur primaire restante (temps OU distance selon le type) ──
        var rem = app.rm.fieldRemaining();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        if (app.rm.getGoal() == GOAL_DISTANCE) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, y, Graphics.FONT_LARGE,
                formatDistance(rem * 1.0), Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            // Affiche le temps restant en grand
            dc.drawText(cx, y, Graphics.FONT_LARGE,
                formatTime(rem), Graphics.TEXT_JUSTIFY_CENTER);
        }
        y += 45;

        // ── Pace courant ──
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, Graphics.FONT_TINY,
            formatPace(app.rm.avgPace), Graphics.TEXT_JUSTIFY_CENTER);
        y += 28;

        // ── Pace cible ──
        var targetPace = field["pace"];
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, Graphics.FONT_TINY,
            "target " + formatPace(targetPace), Graphics.TEXT_JUSTIFY_CENTER);
    }

    // -------------------------
    // -- SESSION FINISH VIEW -- 
    //--------------------------
    function drawFinished(dc as Dc, app as NoTrackRunApp) as Void {
        var cx = dc.getWidth()  / 2;
        var y  = 40;

        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, Graphics.FONT_MEDIUM, "Finished"
                    ,Graphics.TEXT_JUSTIFY_CENTER);
        y += 40;

        // ── Calcul totaux ──
        var totalDist = 0.0;
        var totalTime = 0;
        var results   = app.rm.results as Array;
        for (var i = 0; i < results.size(); i++) {
            var r = results[i] as Dictionary;
            totalDist += (r["distance"] as Number);
            totalTime += (r["duration"]  as Number);
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, Graphics.FONT_SMALL,
            formatDistance(totalDist), Graphics.TEXT_JUSTIFY_CENTER);
        y += 28;

        dc.drawText(cx, y, Graphics.FONT_SMALL,
            formatTime(totalTime), Graphics.TEXT_JUSTIFY_CENTER);
        y += 28;

        var avgPace = (totalTime > 0) ? totalDist / totalTime : 0.0;
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, Graphics.FONT_SMALL,
            formatPace(avgPace), Graphics.TEXT_JUSTIFY_CENTER);
        y += 35;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, Graphics.FONT_SMALL, "press start to send", Graphics.TEXT_JUSTIFY_CENTER);

    }

    // -------------------------
    // -- SESSION SYNCED VIEW --
    //--------------------------
    function drawSynced(dc as Dc, app as NoTrackRunApp) as Void {
        var y  = 80;
        var cx = dc.getWidth()  / 2;

        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, Graphics.FONT_LARGE, "Session Send", Graphics.TEXT_JUSTIFY_CENTER);
        y += 50;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, Graphics.FONT_XTINY, "You can close the App", Graphics.TEXT_JUSTIFY_CENTER);

    }


    // ─────────────────────────────────────────
    //  FORMATERS
    // ─────────────────────────────────────────
    
    function formatPace(speedMs as Float) as String {
        if (speedMs <= 0.0) { return "-- min/km"; }
        var paceSkm = 1000.0 / speedMs;
        var minutes = (paceSkm / 60).toNumber();
        var seconds = (paceSkm - minutes * 60).toNumber();
        return minutes + ":" + (seconds < 10 ? "0" : "") + seconds + " min/km";
    }

    function formatTime(seconds as Number) as String {
        if (seconds < 0.0) { return "--:--"; }
        var m   = (seconds / 60).toNumber();
        var s   = (seconds - m * 60).toNumber();
        var str = (s < 10) ? "0" + s.toString() : s.toString();
        return m.toString() + ":" + str;
    }

    function formatDistance(dist as Float) as String {
        if (dist >= 1000.0) {
            return (dist / 1000.0).format("%.2f") + " km";
        }    
        return dist.format("%.0f") + " m";
    }



}