import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Timer;
using Toybox.System;

const RATIO_TOP_Y       = 0.20;  // position de départ (header)
const RATIO_DOT_SIZE    = 0.035;
const RATIO_DOT_SPACING = 0.075;
const LINE_GAP_PADDING  = 8;    // espace ajouté entre lignes de texte


class NoTrackRunView extends WatchUi.View {
    
    var cachedBlockIdx     as Number = -1;
    var cachedBlockLabel   as String = "";
    var cachedSessionLabel as String = ""; 

    function initialize() {
        View.initialize();
    }


    function onLayout(dc as Dc) as Void {}

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        var app = getApp();
        var state = app.sm._state;
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
        var offset = (dc.getFontHeight(Graphics.FONT_SMALL) / 2) + LINE_GAP_PADDING;

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - offset, Graphics.FONT_SMALL, 
                        "Waiting for session..", Graphics.TEXT_JUSTIFY_CENTER);
    }


    // --------------------------
    // -- SESSION SUMMARY VIEW -- 
    //---------------------------
    function drawSummary(dc as Dc, app as NoTrackRunApp) as Void {
        var cx = dc.getWidth()  / 2;
        var h  = dc.getHeight();
        var y  = (h * RATIO_TOP_Y).toNumber();

        if (cachedSessionLabel.length() == 0) {
            var maxWidth = getUsableWidth(dc, y) - 20;
            cachedSessionLabel = truncateText(dc, app.rm.sessionData["label"] as String, Graphics.FONT_MEDIUM, maxWidth);
        }

        // ── Titre session ──
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, Graphics.FONT_MEDIUM, cachedSessionLabel, Graphics.TEXT_JUSTIFY_CENTER);
        y += dc.getFontHeight(Graphics.FONT_MEDIUM) + LINE_GAP_PADDING;

        // ── Date ──
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        var date = app.rm.sessionData["date"] as String;
        dc.drawText(cx, y, Graphics.FONT_SMALL, date, Graphics.TEXT_JUSTIFY_CENTER);
        y += dc.getFontHeight(Graphics.FONT_SMALL) + LINE_GAP_PADDING;

        // ── Blocs ──
        var blocks = app.rm.sessionData["blocks"] as Array;
        var blockCount = blocks.size();
        var fieldCount = 0;

        for (var i = 0; i < blockCount; i++) {
            var fields = blocks[i]["fields"] as Array;
            fieldCount += fields.size();
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, Graphics.FONT_SMALL,
            blockCount.toString() + " blocks", Graphics.TEXT_JUSTIFY_CENTER);
        y += dc.getFontHeight(Graphics.FONT_SMALL) + LINE_GAP_PADDING;

        dc.drawText(cx, y, Graphics.FONT_SMALL,
            fieldCount.toString() + " steps", Graphics.TEXT_JUSTIFY_CENTER);
    }


    // ------------------
    // -- MESSAGE VIEW -- 
    // ------------------
    function drawMessage(dc as Dc, app as NoTrackRunApp, msg as String) as Void {
        var cx = dc.getWidth()  / 2;
        var cy = dc.getHeight() / 2;
        var offset = (dc.getFontHeight(Graphics.FONT_SMALL) / 2) + LINE_GAP_PADDING;

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            cx,
            cy - offset,
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
        var halfGapLarge = (dc.getFontHeight(Graphics.FONT_LARGE) / 2) + LINE_GAP_PADDING;

        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            cx,
            cy - halfGapLarge,
            Graphics.FONT_LARGE,
            "Error",
            Graphics.TEXT_JUSTIFY_CENTER
        );
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            cx,
            cy + halfGapLarge,
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
        var h  = dc.getHeight();
        var y  = (h * RATIO_TOP_Y).toNumber();

        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        if (app.rm.countdown == 0) {
            dc.drawText(cx, h / 2, Graphics.FONT_LARGE, "GO", Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            dc.drawText(cx, y, Graphics.FONT_NUMBER_HOT,
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
        var h  = dc.getHeight();
        var y  = (h * RATIO_TOP_Y).toNumber();

        var block = app.rm.getCurrentBlock();

        if (app.rm.currentBlockIdx != cachedBlockIdx) {
            cachedBlockIdx = app.rm.currentBlockIdx;
            var maxWidth = getUsableWidth(dc, y) - 20;
            cachedBlockLabel = truncateText(dc, block["label"] as String, Graphics.FONT_MEDIUM, maxWidth);
        }

        var field = app.rm.getCurrentField();

        // ── Nom du bloc ──
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, Graphics.FONT_MEDIUM, cachedBlockLabel, Graphics.TEXT_JUSTIFY_CENTER);
        y += dc.getFontHeight(Graphics.FONT_MEDIUM) + LINE_GAP_PADDING;

        // ── Pastilles de progression des fields ──
        var fields     = block["fields"] as Array;
        var dotSize    = (w * RATIO_DOT_SIZE).toNumber();
        var dotSpacing = (w * RATIO_DOT_SPACING).toNumber();
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
        y += dotSize + LINE_GAP_PADDING + 4;

        // ── Valeur primaire restante (temps OU distance) ──
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var rem = app.rm.fieldRemaining();

        if (app.rm.getGoal() == GOAL_DISTANCE) {
            dc.drawText(cx, y, Graphics.FONT_LARGE,
                formatDistance(rem * 1.0), Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            dc.drawText(cx, y, Graphics.FONT_LARGE,
                formatTime(rem), Graphics.TEXT_JUSTIFY_CENTER);
        }
        y += dc.getFontHeight(Graphics.FONT_LARGE) + LINE_GAP_PADDING;

        // ── Pace courant ──
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, Graphics.FONT_TINY,
            formatPace(app.rm.smoothedSpeed), Graphics.TEXT_JUSTIFY_CENTER);
        y += dc.getFontHeight(Graphics.FONT_TINY) + LINE_GAP_PADDING;

        // ── Pace cible ──
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, Graphics.FONT_TINY,
            field["pace"], Graphics.TEXT_JUSTIFY_CENTER);
    }


    // -------------------------
    // -- SESSION FINISH VIEW -- 
    //--------------------------
    function drawFinished(dc as Dc, app as NoTrackRunApp) as Void {
        var cx = dc.getWidth()  / 2;
        var h  = dc.getHeight();
        var y  = (h * RATIO_TOP_Y).toNumber();

        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, Graphics.FONT_MEDIUM, "Finished", Graphics.TEXT_JUSTIFY_CENTER);
        y += dc.getFontHeight(Graphics.FONT_MEDIUM) + LINE_GAP_PADDING;

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
        y += dc.getFontHeight(Graphics.FONT_SMALL) + LINE_GAP_PADDING;

        dc.drawText(cx, y, Graphics.FONT_SMALL,
            formatTime(totalTime), Graphics.TEXT_JUSTIFY_CENTER);
        y += dc.getFontHeight(Graphics.FONT_SMALL) + LINE_GAP_PADDING;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, Graphics.FONT_SMALL, "press start to send", Graphics.TEXT_JUSTIFY_CENTER);
    }


    // -------------------------
    // -- SESSION SYNCED VIEW --
    //--------------------------
    function drawSynced(dc as Dc, app as NoTrackRunApp) as Void {
        var cx = dc.getWidth()  / 2;
        var h  = dc.getHeight();
        var y  = (h * RATIO_TOP_Y).toNumber();

        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, Graphics.FONT_LARGE, "Session Send", Graphics.TEXT_JUSTIFY_CENTER);
        y += dc.getFontHeight(Graphics.FONT_LARGE) + LINE_GAP_PADDING;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, Graphics.FONT_XTINY, "You can close the App", Graphics.TEXT_JUSTIFY_CENTER);
    }

    function truncateText(dc as Dc, text as String, font as FontType, maxWidth as Number) as String {
        if (dc.getTextWidthInPixels(text, font) <= maxWidth) {
            return text;
        }

        var ellipsis = "...";
        var truncated = text;

        while (truncated.length() > 0) {
            truncated = truncated.substring(0, truncated.length() - 1);
            var candidate = truncated + ellipsis;
            if (dc.getTextWidthInPixels(candidate, font) <= maxWidth) {
                return candidate;
            }
        }

        return ellipsis; // fallback si même "..." ne rentre pas
    }

function getUsableWidth(dc as Dc, y as Number) as Number {
    var settings = System.getDeviceSettings();
    if (settings.screenShape == System.SCREEN_SHAPE_ROUND) {
        var r = dc.getWidth() / 2;
        var centerY = dc.getHeight() / 2;
        var dy = (y - centerY).abs();
        if (dy >= r) { return 0; }
        // largeur de la corde du cercle à cette hauteur
        var halfChord = Math.sqrt((r * r - dy * dy).toFloat());
        return (halfChord * 2).toNumber();
    }
    return dc.getWidth();
}   


    // ─────────────────────────────────────────
    //  FORMATERS
    // ─────────────────────────────────────────
    
    function formatPace(speedMs as Float) as String {
        if (speedMs <= MOVING_THRESHOLD_MS) { return "-- min/km"; } // même seuil que RunManager.running()
        var paceSkm = 1000.0 / speedMs;
        var totalSeconds = Math.round(paceSkm).toNumber();
        var minutes = totalSeconds / 60;
        var seconds = totalSeconds % 60;
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