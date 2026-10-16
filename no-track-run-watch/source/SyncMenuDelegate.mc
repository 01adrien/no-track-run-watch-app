import Toybox.Lang;
import Toybox.WatchUi;

class SyncMenuDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        var sm = getApp().sm;
        WatchUi.popView(WatchUi.SLIDE_DOWN);

        if (id == :quit) {
            sm.transition(STATE_QUIT);       // la session est conservée
        } else if (id == :delete) {
            sm.confirm("Delete session ?", STATE_IDLE);
        }
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN); // ferme le menu, reste en NEED_SYNC
    }
}