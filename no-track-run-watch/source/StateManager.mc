import Toybox.WatchUi;
import Toybox.Lang;

enum AppState {
    STATE_IDLE,
    STATE_SUMMARY,
    STATE_GPS_FIXING,
    STATE_COUNTDOWN,
    STATE_RUNNING,
    STATE_FINISHED,
    STATE_NEED_SYNC,
    STATE_SENDING,
    STATE_PENDING_ACK,
    STATE_SYNCED,
    STATE_ERROR,
    STATE_QUIT,
}

enum AppEvent {
    // Boutons
    EVENT_BACK,
    EVENT_CONFIRM,
    // Autres sources (RunManager, messages téléphone, timer)
    EVENT_SESSION_RECEIVED,
    EVENT_SESSION_END,
    EVENT_FIELD_SKIP,
    EVENT_ACK_RECEIVED,
    EVENT_SYNCED_OK,
    EVENT_SYNCED_KO,
    EVENT_PENDING_ACK,
    EVENT_BACK_IDLE,
    EVENT_INIT_GPS,
    EVENT_NEED_SYNC,
    EVENT_ERROR,
    EVENT_QUIT_APP,
    EVENT_NONE,
    EVENT_STOP_RUN,
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

    function handle(event as AppEvent) as Boolean {
        return onEvent(_state, event);
    }

    function tick() as Void {
        onTick(_state);
        WatchUi.requestUpdate();
    }

    function in(state as AppState) as Boolean {
        return _state == state;
    }

    // Retourne true si l'événement a été consommé
    function onEvent(state as AppState, e as AppEvent) as Boolean {
        var app = getApp();

        // Événements globaux
        if (e == EVENT_NONE)     { return false; }
        if (e == EVENT_ERROR)    { transition(STATE_ERROR); return true; }
        if (e == EVENT_QUIT_APP) { transition(STATE_QUIT); return true; }

        switch (state) {
            case STATE_IDLE:
                if (e == EVENT_SESSION_RECEIVED) { transition(STATE_SUMMARY); return true; }
                if (e == EVENT_NEED_SYNC)        { transition(STATE_NEED_SYNC); return true; }
                if (e == EVENT_BACK)             { confirm("Quit App ?", STATE_QUIT); return true; }
                break;

            case STATE_SUMMARY:
                if (e == EVENT_CONFIRM) { transition(STATE_GPS_FIXING); return true; }
                if (e == EVENT_BACK)    { confirm("Remove Session ?", STATE_IDLE); return true; }
                break;

            case STATE_GPS_FIXING:
            case STATE_COUNTDOWN:
                if (e == EVENT_BACK) { confirm("False Start ?", STATE_SUMMARY); return true; }
                break;

            case STATE_RUNNING:
                if (e == EVENT_CONFIRM) {
                    if (DEBUG || !app.rm.isRunningBlock()) {
                        app.rm.advanceField();
                        return true;
                    }
                    return false;
                }
                if (e == EVENT_SESSION_END) { transition(STATE_FINISHED); return true; }
                if (e == EVENT_BACK) {
                    if (!app.rm.hasResult()) { confirm("Abort Run ?", STATE_SUMMARY); }
                    else                     { confirm("Quit Run ?", STATE_SENDING); }
                    return true;
                }
                break;

            case STATE_FINISHED:
                if (e == EVENT_CONFIRM) { transition(STATE_SENDING); return true; }
                if (e == EVENT_BACK)    { confirm("Quit App ?", STATE_QUIT); return true; }
                break;
            case STATE_NEED_SYNC:
                if (e == EVENT_CONFIRM) { transition(STATE_SENDING); return true; }
                if (e == EVENT_BACK)    { openSyncMenu(); return true; }
                break;

            case STATE_SENDING:
                if (e == EVENT_SYNCED_OK)   { transition(STATE_SYNCED); return true; }
                if (e == EVENT_SYNCED_KO)   { transition(STATE_ERROR); return true; }
                if (e == EVENT_PENDING_ACK) { transition(STATE_PENDING_ACK); return true; }
                if (e == EVENT_BACK)        { confirm("Quit App ?", STATE_QUIT); return true; }
                break;

            case STATE_PENDING_ACK:
                if (e == EVENT_SYNCED_OK) { transition(STATE_SYNCED); return true; }
                if (e == EVENT_SYNCED_KO) { transition(STATE_ERROR); return true; }
                if (e == EVENT_CONFIRM)   { transition(STATE_SENDING); return true; } // Retry
                if (e == EVENT_BACK)      { confirm("Quit App ?", STATE_QUIT); return true; }
                break;

            case STATE_SYNCED:
            case STATE_ERROR:
                if (e == EVENT_BACK) { confirm("Quit App ?", STATE_QUIT); return true; }
                break;

            case STATE_QUIT:
                break;
        }
        return false;
    }

    function onTick(state as AppState) as Void {
        var app = getApp();
        switch (state) {
            case STATE_COUNTDOWN:
                if (app.rm.isCountDownOver()) { transition(STATE_RUNNING); }
                break;
            case STATE_RUNNING:
                app.rm.running();
                break;
            case STATE_SENDING:
                if (app.isTimeoutSending()) {
                    if (app.transmitted) {
                        handle(EVENT_PENDING_ACK);
                    } else {
                        app.errorMsg = "Phone unreachable";
                        transition(STATE_ERROR);
                    }
                }
                break;
            case STATE_GPS_FIXING:
                if (app.isGpsReady()) { transition(STATE_COUNTDOWN); }
                break;
            default:
                break;
        }
    }

    function onEnter(next as AppState, prev as AppState) as Void {
        var app = getApp();
        switch (next) {
            case STATE_COUNTDOWN:
                app.rm.resetCountDown();
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
                app.rm.stopActivitySession(false);
                app.exit();
                break;
            case STATE_IDLE:
                // Sortie de NEED_SYNC par "Delete session ?" : seul chemin NEED_SYNC -> IDLE
                if (prev == STATE_NEED_SYNC) { app.deleteSession(); }
                if (app.rm.sessionData != null) { app.rm.sessionData = {}; }
                if (app.isNeedSync()) { handle(EVENT_NEED_SYNC); }
                break;
            case STATE_SUMMARY:
                app.rm.stopActivitySession(false);
                if (app.getSession() != null) { app.deleteSession(); }
                break;
            case STATE_RUNNING:
                app.startRunVibe();
                break;
            default:
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
            case STATE_PENDING_ACK:
            case STATE_GPS_FIXING:
            case STATE_ERROR:
            case STATE_QUIT:
                break;
        }
    }

    function confirm(msg as String, nextState as AppState) as Void {
        WatchUi.pushView(
            new WatchUi.Confirmation(msg),
            new QuitConfirmationDelegate(nextState),
            WatchUi.SLIDE_IMMEDIATE
        );
    }

    function openSyncMenu() as Void {
        var menu = new WatchUi.Menu2({ :title => "Unsent results" });
        menu.addItem(new WatchUi.MenuItem("Quit app", "Keep session", :quit, null));
        menu.addItem(new WatchUi.MenuItem("Delete session", "Cannot be undone", :delete, null));
        WatchUi.pushView(menu, new SyncMenuDelegate(), WatchUi.SLIDE_UP);
    }
}