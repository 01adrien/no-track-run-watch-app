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
        if (app.appState == STATE_IDLE) {
            _drawIdle(dc, app);
        }
        else if (app.appState == STATE_SUMMARY) {
            _drawSummary(dc, app);
        } else if (app.appState == STATE_COUNTDOWN) {
            _drawCountdown(dc, app);
        } else if (app.appState == STATE_RUNNING) {
            _drawRunning(dc, app);
        } else if (app.appState == STATE_FINISHED) {
            _drawFinished(dc, app);
        } else if (app.appState == STATE_NEED_SYNC_APP) {
            _drawNeedSync(dc, app);
        } else if (app.appState == STATE_SESSION_SYNC_APP) {
            _drawSyncOk(dc, app);
        } else if (app.appState == STATE_SENDING_SESSION) {
            _drawLoading(dc, app, "Sending...");
        } else if (app.appState == STATE_GPS_FIXING) {
            _drawLoading(dc, app, "Acquiring GPS...");
        } else if (app.appState == STATE_ERROR) {
            _drawLoading(dc, app, app.errorMsg);
        } 
    }

    // ─────────────────────────────────────────
    //  ÉCRAN 1 : Résumé de la session
    // ─────────────────────────────────────────
    function _drawSummary(dc as Dc, app as NoTrackRunWatchApp) as Void {
        var cx = dc.getWidth()  / 2;
        var y  = 50;

        // ── Titre session ──
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        var label = app.sessionData["label"] as String;
        dc.drawText(cx, y, Graphics.FONT_MEDIUM, label, Graphics.TEXT_JUSTIFY_CENTER);
        y += 35;

        // ── Date ──
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        var date = app.sessionData["date"] as String;
        dc.drawText(cx, y, Graphics.FONT_SMALL, date, Graphics.TEXT_JUSTIFY_CENTER);
        y += 35;

        // ── Blocs ──
        var blocks = app.sessionData["blocks"] as Array;
        var totalDistance = app.sessionData["distance"];
        var totalDuration = app.sessionData["duration"];

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


    // ─────────────────────────────────────────
    //  ÉCRAN 1b : Compte à rebours 3-2-1
    // ─────────────────────────────────────────
    function _drawCountdown(dc as Dc, app as NoTrackRunWatchApp) as Void {
        var cx = dc.getWidth()  / 2;

        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 50, Graphics.FONT_NUMBER_THAI_HOT,
            app.countdownValue.toString(), Graphics.TEXT_JUSTIFY_CENTER);
    }

    // ─────────────────────────────────────────
    //  ÉCRAN 2 : Bloc en cours
    // ─────────────────────────────────────────
    function _drawRunning(dc as Dc, app as NoTrackRunWatchApp) as Void {
        var cx = dc.getWidth()  / 2;
        var w  = dc.getWidth();
        var y  = 40;

        var block = app.getCurrentBlock();
        var field = app.getCurrentField();

        // ── Nom du bloc ──
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
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
            if (i < app.currentFieldIdx) {
                dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
            } else if (i == app.currentFieldIdx) {
                if (app.blinkOn) {
                    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                } else {
                    dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
                }
            } else {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            }
            dc.fillCircle(dotX + dotSize / 2, y + dotSize / 2, dotSize / 2);
            dotX += dotSpacing;
        }
        y += 20;

        // ── Valeur primaire restante (temps OU distance selon le type) ──
        var primary = app.primaryRemaining();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        if (app.getGoal() == GOAL_DISTANCE) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, y, Graphics.FONT_LARGE,
                formatDistance(primary * 1.0), Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            // Affiche le temps restant en grand
            dc.drawText(cx, y, Graphics.FONT_LARGE,
                formatTime(primary), Graphics.TEXT_JUSTIFY_CENTER);
        }
        y += 45;

        // ── Pace courant ──
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, Graphics.FONT_TINY,
            formatPace(app.avgPace), Graphics.TEXT_JUSTIFY_CENTER);
        y += 28;

        // ── Pace cible ──
        var targetPace = field["pace"];
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, Graphics.FONT_TINY,
            "target " + formatPace(targetPace), Graphics.TEXT_JUSTIFY_CENTER);
    }

    

    // ─────────────────────────────────────────
    //  ÉCRAN 3 : Session terminée
    // ─────────────────────────────────────────
    function _drawFinished(dc as Dc, app as NoTrackRunWatchApp) as Void {
        var cx = dc.getWidth()  / 2;
        var y  = 40;

        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, Graphics.FONT_MEDIUM, "Finished"
                    ,Graphics.TEXT_JUSTIFY_CENTER);
        y += 40;

        // ── Calcul totaux ──
        var totalDist = 0.0;
        var totalTime = 0;
        var results   = app.results as Array;
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

    // ─────────────────────────────────────────
    //  ÉCRAN 4 : En attente de session du mobile
    // ─────────────────────────────────────────
    function _drawIdle(dc as Dc, app as NoTrackRunWatchApp) as Void {
        var cx = dc.getWidth()  / 2;
        var cy = dc.getHeight() / 2;

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - 10, Graphics.FONT_SMALL, 
                        "Waiting for session..", Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        
    }


    // ─────────────────────────────────────────
    //  Need sync screen
    // ─────────────────────────────────────────
    function _drawNeedSync(dc as Dc, app as NoTrackRunWatchApp) as Void {
        var y  = 80;
        var cx = dc.getWidth()  / 2;

        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, Graphics.FONT_LARGE, "Sync Error", Graphics.TEXT_JUSTIFY_CENTER);
        y += 50;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, Graphics.FONT_XTINY, "Try again", Graphics.TEXT_JUSTIFY_CENTER);
    }



    // ─────────────────────────────────────────
    //   session synced OK screen
    // ─────────────────────────────────────────
    function _drawSyncOk(dc as Dc, app as NoTrackRunWatchApp) as Void {
        var y  = 80;
        var cx = dc.getWidth()  / 2;

        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, Graphics.FONT_LARGE, "Session Send", Graphics.TEXT_JUSTIFY_CENTER);
        y += 50;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, Graphics.FONT_XTINY, "You can close the App", Graphics.TEXT_JUSTIFY_CENTER);

    }

    // ─────────────────────────────────────────
    //   Loading SCREEN
    // ─────────────────────────────────────────
    function _drawLoading(dc as Dc, app as NoTrackRunWatchApp, msg as String) as Void {

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