import Toybox.Lang;
import Toybox.WatchUi;
using Toybox.System;

class QuitConfirmationDelegate
    extends WatchUi.ConfirmationDelegate {

    private var _stateMachine;

    function initialize(stateMachine) {
        ConfirmationDelegate.initialize();
        _stateMachine = stateMachine;
    }

    function onResponse(response as WatchUi.Confirm) as Boolean {

        
        if (response == WatchUi.CONFIRM_YES) {
            _stateMachine.handle(EVENT_QUIT_APP);
        }
        
        return true;
    }
}