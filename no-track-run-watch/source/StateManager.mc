import Toybox.WatchUi;
import Toybox.Lang;

enum AppState {
    STATE_IDLE,
    STATE_SUMMARY,
    STATE_COUNTDOWN,
    STATE_RUNNING,
    STATE_FINISHED,
    STATE_NEED_SYNC,
    STATE_SYNCED,
    STATE_SENDING,
    STATE_GPS_FIXING,
    STATE_ERROR,
    STATE_QUIT,
}

enum AppEvent {
    EVENT_SESSION_RECEIVED,
    EVENT_SESSION_START,
    EVENT_SESSION_END,
    EVENT_FIELD_SKIP,
    EVENT_SEND_RESULTS,
    EVENT_ACK_RECEIVED,
    EVENT_SYNCED_KO,
    EVENT_BACK_IDLE,
    EVENT_INIT_GPS,
    EVENT_NEXT_FIELD,
    EVENT_SYNCED_OK,
    EVENT_NEED_SYNC,
    EVENT_ERROR,
    EVENT_QUIT_APP
}

class StateManager {

    var _state as AppState = STATE_IDLE;

    function transition(next as AppState) as Void {
        var previous = _state;
        onExit(previous);
        _state = next;
        onEnter(next, previous);
        WatchUi.requestUpdate();
    }

    function handle(event as AppEvent) as Void {
        onEvent(_state, event);
    }

    function tick() as Void { 
        onTick(_state);
        WatchUi.requestUpdate();
    }


    function onEvent(state as AppState, e as AppEvent) as Void {
        var app = getApp();
        if (e == EVENT_ERROR) { transition(STATE_ERROR); return;}
        if (e == EVENT_QUIT_APP) { transition(STATE_QUIT); return;}
        switch (state) {
            case STATE_IDLE:
                if (e == EVENT_SESSION_RECEIVED) {transition(STATE_SUMMARY);}
                if (e == EVENT_NEED_SYNC) {transition(STATE_SENDING);}
                break;
            case STATE_SUMMARY:
                if (e == EVENT_SESSION_START) {transition(STATE_GPS_FIXING);}
                break;
            case STATE_RUNNING:
                if (e == EVENT_NEXT_FIELD) {app.rm.advanceField();}
                else if (e == EVENT_SESSION_END) {transition(STATE_FINISHED);}
                break;
            case STATE_FINISHED:
                if (e == EVENT_SEND_RESULTS) {transition(STATE_SENDING);}
                break;
            case STATE_SENDING:
                if (e == EVENT_SYNCED_KO) {transition(STATE_ERROR);}
                else if (e == EVENT_SYNCED_OK) {transition(STATE_SYNCED);}
                break;
            case STATE_NEED_SYNC:
            case STATE_SYNCED:
            case STATE_GPS_FIXING:
            case STATE_ERROR:
            case STATE_COUNTDOWN:
                break;
        }
    }

    function onTick(state as AppState) as Void {
        var app = getApp();
        switch (state) {
            case STATE_COUNTDOWN:
                if (app.rm.isCountDownOver()) { transition(STATE_RUNNING);}
                break;
            case STATE_RUNNING:
                app.rm.running();
                break;
            case STATE_SENDING:
                if (app.isTimeoutSending()) {transition(STATE_ERROR) ;}
                break;
            case STATE_GPS_FIXING:
                if (app.isGpsReady()) {transition(STATE_COUNTDOWN);}
                break;
            case STATE_FINISHED:
            case STATE_NEED_SYNC:
            case STATE_SYNCED:
            case STATE_IDLE:
            case STATE_SUMMARY:
            case STATE_ERROR:
                break;
        }
    }

   

    function onEnter(next as AppState, prev as AppState) as Void {
        var app = getApp();
        switch (next) {
            case STATE_COUNTDOWN:
                app.rm.resetCountDown();
                break;
            case STATE_RUNNING:
                app.rm.initRunning();
                break;
             case STATE_SYNCED:
                app.deleteSession();
                break;
            case STATE_SENDING:
                app.sendSession();
                break;
            case STATE_GPS_FIXING:
                app.startSession();
                break;
            case STATE_QUIT:
                if (prev == STATE_SENDING || prev == STATE_RUNNING) {
                    app.deleteSession();
                }
                app.exit();
                break;
            case STATE_FINISHED:
                app.rm.sessionData = {} as Dictionary;
                break;
            case STATE_IDLE:
            case STATE_SUMMARY:
            case STATE_NEED_SYNC:
            case STATE_ERROR:
                break;
        }
    }

    function onExit(state as AppState) as Void {
        return;
        var app = getApp();
        switch (state) {
            case STATE_IDLE:
            case STATE_SUMMARY:
            case STATE_COUNTDOWN:
            case STATE_RUNNING:
            case STATE_FINISHED:
            case STATE_NEED_SYNC:
            case STATE_SYNCED:
            case STATE_SENDING:
            case STATE_GPS_FIXING:
            case STATE_ERROR:
                break;
        }
    }
}