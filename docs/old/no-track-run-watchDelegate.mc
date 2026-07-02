import Toybox.Lang;
import Toybox.WatchUi;
using Toybox.System;

// ─────────────────────────────────────────────
//  Delegate — gestion des touches
//
//  Mapping touches (Fenix / Forerunner standard) :
//   KEY_ENTER  (bouton START/STOP) → démarrer ou skip
//   KEY_DOWN   (bouton LAP)        → skip field
//   KEY_ESC    (bouton BACK)       → ignoré pendant session
// ─────────────────────────────────────────────
class NoTrackRunDelegate extends WatchUi.InputDelegate {

    function initialize() {
        InputDelegate.initialize();
    }

    function _resetToSummary() as Void {
        var app = getApp();
        app._resetState();
        WatchUi.requestUpdate();
    }

    function onKey(keyEvent as KeyEvent) as Boolean {
        var app = getApp();
        var key = keyEvent.getKey();

        if (app.appState == STATE_COUNTDOWN) {
            // On bloque tout pendant le countdown
            return true;
        }

        if (app.appState == STATE_SUMMARY) {
            // N'importe quelle touche START démarre
            if (key == WatchUi.KEY_ENTER || key == WatchUi.KEY_START) {
                app.startSession();
                WatchUi.requestUpdate();
                return true;
            }

            if (key == WatchUi.KEY_ESC) {
                app.backIdle();
                WatchUi.requestUpdate();
                return true;
            }
        }

        if (app.appState == STATE_RUNNING) {
            // LAP ou DOWN → skip le field courant
            if (key == WatchUi.KEY_LAP || key == WatchUi.KEY_DOWN) {
                app.skipCurrentField();
                return true;
            }
            if (key == WatchUi.KEY_ESC) {
                app.backIdle();
                return true;
            }
            if (key == WatchUi.KEY_ENTER || key == WatchUi.KEY_START) {
                app.endSession();
                return true;
            }
        }

        if (app.appState == STATE_FINISHED) {

            if (key == WatchUi.KEY_ENTER || key == WatchUi.KEY_START) {
                app._sendResultsToPhone();
                return true;
            }
        }

        if (app.appState == STATE_NEED_SYNC_APP) {

            if (key == WatchUi.KEY_ENTER || key == WatchUi.KEY_START) {
                app._sendResultsToPhone();
                return true;
            }
            if (key == WatchUi.KEY_DOWN) {
                app.backIdle();
                return true;
            }


        }

        if (app.appState == STATE_SESSION_SYNC_APP) {

            if (key == WatchUi.KEY_ESC) {
                app.backIdle();
                WatchUi.requestUpdate();
                return true;
            }
        }

        return false;
    }
}