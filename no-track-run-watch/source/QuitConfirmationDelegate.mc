import Toybox.Lang;
import Toybox.WatchUi;
using Toybox.System;

class QuitConfirmationDelegate
    extends WatchUi.ConfirmationDelegate {

    private var _state;

    function initialize(state as AppState) {
        ConfirmationDelegate.initialize();
        _state = state;
    }

    function onResponse(response as WatchUi.Confirm) as Boolean {
        var app = getApp();
        if (response == WatchUi.CONFIRM_YES) {
            app.sm.transition(_state);
        }
        
        return true;
    }
}