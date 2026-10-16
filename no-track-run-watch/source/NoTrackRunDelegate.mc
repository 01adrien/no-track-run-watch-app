import Toybox.Lang;
import Toybox.WatchUi;

class NoTrackRunDelegate extends WatchUi.InputDelegate {

    function initialize() {
        InputDelegate.initialize();
    }

    function onKey(keyEvent as KeyEvent) as Boolean {
        var sm = getApp().sm;

        switch (keyEvent.getKey()) {
            case WatchUi.KEY_ESC:
                return sm.handle(EVENT_BACK);
            case WatchUi.KEY_ENTER:
            case WatchUi.KEY_START:
                return sm.handle(EVENT_CONFIRM);
            default:
                return false;
        }
    }
}