import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Timer;
import Toybox.Math;
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
            cachedSessionLabel = truncateText(dc, app.rm.getSessionLabel(), Graphics.FONT_MEDIUM, maxWidth);
        }

        // ── Titre session ──
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, Graphics.FONT_MEDIUM, cachedSessionLabel, Graphics.TEXT_JUSTIFY_CENTER);
        y += dc.getFontHeight(Graphics.FONT_MEDIUM) + LINE_GAP_PADDING;

        // ── Date ──
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        var date = app.rm.getSessionDate();
        dc.drawText(cx, y, Graphics.FONT_SMALL, date, Graphics.TEXT_JUSTIFY_CENTER);
        y += dc.getFontHeight(Graphics.FONT_SMALL) + LINE_GAP_PADDING;

        var blockCount = app.rm.getBlocksCount();
        var fieldCount = app.rm.getFieldsCount();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, Graphics.FONT_SMALL,
            blockCount.toString() + " blocks", Graphics.TEXT_JUSTIFY_CENTER);
        y += dc.getFontHeight(Graphics.FONT_SMALL) + LINE_GAP_PADDING;

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
        var cy = dc.getHeight() / 2;
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
        var maxWidth = getUsableWidth(dc, cy) - 20;
        var err = truncateText(dc, app.errorMsg , Graphics.FONT_XTINY, maxWidth);
        dc.drawText(
            cx,
            cy + halfGapLarge,
            Graphics.FONT_XTINY,
            err,
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
    var cy = dc.getHeight() / 2;
    var w  = dc.getWidth();

    var isRunningBlock = app.rm.isRunningBlock();
    var block          = app.rm.getCurrentBlock();
    var fields         = block["fields"] as Array;
    var exercices      = block["exercices"] as Array;
    var totalDots      = isRunningBlock
                        ? fields.size() * app.rm.getTargetReps()
                        : exercices.size();
    var fieldIndex     = isRunningBlock
                        ? ((app.rm.repCount - 1) * fields.size()) + app.rm.currentFieldIdx
                        : app.rm.currentExoIdx;

    // ── Arc de progression (autour de tout l'écran) ──
    var radius   = (w / 2) - 8;
    var penWidth = 5;
    dc.setPenWidth(penWidth);

    dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
    dc.drawArc(cx, cy, radius, Graphics.ARC_CLOCKWISE, 90, 90 - 359);

    if (totalDots > 0) {
        var progress   = fieldIndex.toFloat() / totalDots.toFloat();
        var sweepAngle = (progress * 360).toNumber();
        var endAngle   = 90 - sweepAngle;

        if (sweepAngle > 0) {
            dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
            dc.drawArc(cx, cy, radius, Graphics.ARC_CLOCKWISE, 90, endAngle);
        }

        var cursorSweep = (1.0 / totalDots) * 360;
        var cursorStart = endAngle;
        var cursorEnd   = endAngle - cursorSweep;
        var blinkColor  = (app.rm.fieldElapsed % 2 == 0) ? Graphics.COLOR_WHITE : Graphics.COLOR_YELLOW;
        dc.setColor(blinkColor, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(cx, cy, radius, Graphics.ARC_CLOCKWISE, cursorStart, cursorEnd);
    }

    // ── Séparateurs noirs entre segments ──
    if (totalDots > 1) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        var innerR = radius - (penWidth / 2);
        var outerR = radius + (penWidth / 2);

        for (var i = 0; i < totalDots; i++) {
            var angleDeg = 90 - (i * (360.0 / totalDots));
            var angleRad = Math.toRadians(angleDeg);
            var x1 = cx + (innerR * Math.cos(angleRad));
            var y1 = cy - (innerR * Math.sin(angleRad));
            var x2 = cx + (outerR * Math.cos(angleRad));
            var y2 = cy - (outerR * Math.sin(angleRad));
            dc.drawLine(x1, y1, x2, y2);
        }
    }

    dc.setPenWidth(1);

    // ── Préparation des textes ──
    var blockLabel = (app.rm.currentBlockIdx + 1).toString() + "/" + app.rm.getBlocksCount().toString();
    var hrLabel    = app.rm.getHeartRateFormatted();

    var rem   = app.rm.fieldRemaining();
    var field = app.rm.getCurrentField();
    var goal  = app.rm.getGoal();
    var mainLabel = "";
    if (goal == GOAL_DISTANCE) {
        mainLabel = formatDistance(rem * 1.0);
    } else if (goal == GOAL_DURATION) {
        mainLabel = formatTime(rem);
    } else {
        mainLabel = formatTime(app.rm.fieldElapsed);
    }

    var line3Label = "";
    var line4Label = "";
    if (isRunningBlock) {
        line3Label = formatPace(app.rm.currentSpeed);
        line4Label = field["pace"] as String;
    } else {
        var exercice = exercices[app.rm.currentExoIdx] as Dictionary;
        line3Label = exercice["label"] as String;
        line4Label = (exercice["reps"] as Number).toString() + " reps";
    }

    // ── Hauteurs des polices utilisées ──
    var hBlock = dc.getFontHeight(Graphics.FONT_TINY);
    var hMain  = dc.getFontHeight(Graphics.FONT_LARGE);
    var hLine3 = dc.getFontHeight(Graphics.FONT_TINY);
    var hLine4 = dc.getFontHeight(Graphics.FONT_TINY);
    var hHR    = dc.getFontHeight(Graphics.FONT_TINY);
    var gap    = LINE_GAP_PADDING;

    var totalHeight = hBlock + gap + hMain + gap + hLine3 + gap + hLine4 + gap + hHR;
    var y = cy - (totalHeight / 2);

    // ── Numéro de bloc (centré, en haut) ──
    dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
    dc.drawText(cx, y, Graphics.FONT_TINY, blockLabel, Graphics.TEXT_JUSTIFY_CENTER);
    y += hBlock + gap;

    // ── Métrique principale ──
    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    dc.drawText(cx, y, Graphics.FONT_LARGE, mainLabel, Graphics.TEXT_JUSTIFY_CENTER);
    y += hMain + gap;

    // ── Ligne secondaire ──
    dc.setColor(isRunningBlock ? Graphics.COLOR_BLUE : Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    dc.drawText(cx, y, Graphics.FONT_TINY, line3Label, Graphics.TEXT_JUSTIFY_CENTER);
    y += hLine3 + gap;

    // ── Ligne tertiaire ──
    dc.setColor(isRunningBlock ? Graphics.COLOR_DK_GRAY : Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    dc.drawText(cx, y, Graphics.FONT_TINY, line4Label, Graphics.TEXT_JUSTIFY_CENTER);
    y += hLine4 + gap;

    // ── HR en bas, avec pastille ronde ──
    var hrTextWidth  = dc.getTextWidthInPixels(hrLabel, Graphics.FONT_TINY);
    var dotRadius    = 4;
    var dotTextGap   = 4;
    var totalHrWidth = (dotRadius * 2) + dotTextGap + hrTextWidth;
    var hrStartX     = cx - (totalHrWidth / 2);

    dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
    dc.fillCircle(hrStartX + dotRadius, y + (hHR / 2), dotRadius);
    dc.drawText(hrStartX + (dotRadius * 2) + dotTextGap, y, Graphics.FONT_TINY,
                hrLabel, Graphics.TEXT_JUSTIFY_LEFT);
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
        dc.drawText(cx, y, Graphics.FONT_TINY, "press start to send", Graphics.TEXT_JUSTIFY_CENTER);
    }


    // -------------------------
    // -- SESSION SYNCED VIEW --
    //--------------------------
    function drawSynced(dc as Dc, app as NoTrackRunApp) as Void {
        var cx = dc.getWidth()  / 2;
        var cy = dc.getHeight() / 2;
        var halfGapLarge = (dc.getFontHeight(Graphics.FONT_LARGE) / 2) + LINE_GAP_PADDING;

        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            cx,
            cy - halfGapLarge,
            Graphics.FONT_LARGE,
            "Session send",
            Graphics.TEXT_JUSTIFY_CENTER
        );
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            cx,
            cy + halfGapLarge,
            Graphics.FONT_XTINY,
            "You can close the app",
            Graphics.TEXT_JUSTIFY_CENTER
        );
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
        var halfChord = Math.sqrt((r * r - dy * dy).toFloat());
        return (halfChord * 2).toNumber();
    }
    return dc.getWidth();
}   


    // ─────────────────────────────────────────
    //  FORMATERS
    // ─────────────────────────────────────────
    
    function formatPace(speedMs as Float) as String {
        if (speedMs <= 0.2) { return "-- min/km"; } // même seuil que RunManager.²²²()
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