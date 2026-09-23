import Toybox.Lang;
import Toybox.WatchUi;
using Toybox.System;

class NoTrackRunDelegate extends WatchUi.InputDelegate {

    function initialize() {
        InputDelegate.initialize();
    }

    function onKey(keyEvent as KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        var app = getApp();
        var sm = app.sm;
        var state = sm._state;

        if (key == WatchUi.KEY_ESC) {
            switch (state) {
                case STATE_RUNNING : 
                    showConfirmation("Quit Run ?", STATE_SENDING);
                    break;
                case STATE_SUMMARY :
                    sm.backIdle();
                    break;
                case STATE_COUNTDOWN:
                case STATE_GPS_FIXING:
                    showConfirmation("False Start ?", STATE_SUMMARY);
                    break;
                case STATE_IDLE:
                case STATE_ERROR:
                case STATE_FINISHED:
                case STATE_NEED_SYNC:
                case STATE_SENDING:
                    showConfirmation("Quit App ?", STATE_QUIT);
                    break;
            }
            return true;
        }



        switch (state) {
            case STATE_SUMMARY:
                if (key == WatchUi.KEY_ENTER || key == WatchUi.KEY_START) {
                    sm.handle(EVENT_SESSION_START);
                    return true;
                }
                break;
            case STATE_RUNNING:
                if (
                       (key == WatchUi.KEY_ENTER || key == WatchUi.KEY_START) && 
                       (DEBUG || !app.rm.isRunningBlock())
                    ) 
                {
                    sm.handle(EVENT_NEXT_FIELD);
                    return true;
                }
                break;
            case STATE_FINISHED:
                if (key == WatchUi.KEY_ENTER || key == WatchUi.KEY_START) {
                    sm.handle(EVENT_SEND_RESULTS);
                    return true;
                }
                break;
            case STATE_NEED_SYNC:
            case STATE_SYNCED:
            case STATE_SENDING:
            case STATE_GPS_FIXING:
            case STATE_ERROR:
            case STATE_IDLE:
            case STATE_COUNTDOWN:
                break;
        }

        return false;
    }

    private function showConfirmation(msg as String, nextState as AppState) as Void {
        var confirmation = new WatchUi.Confirmation(msg);
        WatchUi.pushView(
            confirmation,
            new QuitConfirmationDelegate(nextState),
            WatchUi.SLIDE_IMMEDIATE
        );
    }
}