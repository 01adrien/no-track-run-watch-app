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
        var state = sm.state;
        switch (state) {
            case STATE_SUMMARY:
                if (key == WatchUi.KEY_ENTER || key == WatchUi.KEY_START) {
                    sm.handle(EVENT_SESSION_START);
                    return true;
                }
                break;
            case STATE_RUNNING:
                if (key == WatchUi.KEY_ENTER || key == WatchUi.KEY_START) {
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
}