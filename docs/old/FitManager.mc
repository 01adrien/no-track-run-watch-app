using Toybox.ActivityRecording;
using Toybox.FitContributor;
using Toybox.Activity;
import Toybox.Lang;

class FitManager {

    var session       as ActivityRecording.Session? = null;

    // ── LAP fields (écrits à chaque addLap()) ───────────────
    var _fBlockLabel  as FitContributor.Field? = null; // "Warm Up", "Cardio"...
    var _fTargetPace  as FitContributor.Field? = null; // pace cible du field (m/s)
    var _fRealPace    as FitContributor.Field? = null; // pace réelle mesurée (m/s)
    var _fGoalType    as FitContributor.Field? = null; // 0 = distance, 1 = duration
    var _fGoalValue   as FitContributor.Field? = null; // 1500m ou 150s selon type
    var _fSuccess     as FitContributor.Field? = null; // 1 = dans les clous, 0 = raté
    var _fBlockId     as FitContributor.Field? = null; // 


    // ── SESSION fields (écrits 1x après stop()) ─────────────
    var _fSessionId   as FitContributor.Field? = null; // id de la session JSON
    var _fSessionLabel as FitContributor.Field? = null; // "Training"

    // ── RECORD fields (écrits ~1x/sec pendant la course) ────
    var _fCurrentPace as FitContributor.Field? = null; // vitesse instantanée (m/s)

    // ────────────────────────────────────────────────────────

    function init() as Void {
        if (!(Toybox has :ActivityRecording)) { return; }

        session = ActivityRecording.createSession({
            :name     => "NoTrackRun",
            :sport    => Activity.SPORT_RUNNING,
            :subSport => Activity.SUB_SPORT_GENERIC
        });

        // LAP fields
        _fBlockLabel = session.createField(
            "block_label",
            0,
            FitContributor.DATA_TYPE_STRING,
            { :mesgType => FitContributor.MESG_TYPE_LAP, :count => 16 }
        );

        _fTargetPace = session.createField(
            "target_pace",
            1,
            FitContributor.DATA_TYPE_FLOAT,
            { :mesgType => FitContributor.MESG_TYPE_LAP, :units => "m/s" }
        );

        _fRealPace = session.createField(
            "real_pace",
            2,
            FitContributor.DATA_TYPE_FLOAT,
            { :mesgType => FitContributor.MESG_TYPE_LAP, :units => "m/s" }
        );

        _fGoalType = session.createField(
            "goal_type",
            3,
            FitContributor.DATA_TYPE_UINT8,
            { :mesgType => FitContributor.MESG_TYPE_LAP }
            // 0 = distance, 1 = duration
        );
        _fGoalValue = session.createField(
            "goal_value",
            4,
            FitContributor.DATA_TYPE_UINT32,
            { :mesgType => FitContributor.MESG_TYPE_LAP }
            // mètres si GOAL_DISTANCE, secondes si GOAL_DURATION
        );

        _fBlockId = session.createField(
            "block_id",
            4,
            FitContributor.DATA_TYPE_STRING,
            { :mesgType => FitContributor.MESG_TYPE_LAP, :count => 16 }
        );


        _fSuccess = session.createField(
            "success",
            5,
            FitContributor.DATA_TYPE_UINT8,
            { :mesgType => FitContributor.MESG_TYPE_LAP }
            // 1 = succès, 0 = raté
        );

        // SESSION fields
        _fSessionId = session.createField(
            "session_id",
            6,
            FitContributor.DATA_TYPE_UINT32,
            { :mesgType => FitContributor.MESG_TYPE_SESSION }
        );
        
        _fSessionLabel = session.createField(
            "session_label",
            7,
            FitContributor.DATA_TYPE_STRING,
            { :mesgType => FitContributor.MESG_TYPE_SESSION, :count => 16 }
        );

        // RECORD field
        _fCurrentPace = session.createField(
            "current_pace",
            8,
            FitContributor.DATA_TYPE_FLOAT,
            { :mesgType => FitContributor.MESG_TYPE_RECORD, :units => "m/s" }
        );
    }

    // ── appelé à chaque onTick() pendant STATE_RUNNING ──────

    function tick(currentSpeed as Float) as Void {
        if (session == null || !session.isRecording()) { return; }
        _fCurrentPace.setData(currentSpeed);
    }

    // ── appelé dans _saveFieldResult(), juste avant addLap() ─

    function recordLap(
        blockLabel  as String,
        targetPace  as Float,
        realPace    as Float,
        goalType    as Number,  // GOAL_DISTANCE = 0, GOAL_DURATION = 1
        goalValue   as Number,  // mètres ou secondes
        success     as Boolean
    ) as Void {
        if (session == null || !session.isRecording()) { return; }

        _fBlockLabel.setData(blockLabel);
        _fTargetPace.setData(targetPace);
        _fRealPace.setData(realPace);
        _fGoalType.setData(goalType);
        _fGoalValue.setData(goalValue);
        _fSuccess.setData(success ? 1 : 0);

        session.addLap();
    }

    // ── appelé dans onExit() de StateRunning ─────────────────

    function stopAndSave(sessionId as Number, sessionLabel as String) as Void {
        if (session == null) { return; }

        session.stop();

        // champs SESSION écrits après stop(), avant save()
        _fSessionId.setData(sessionId);
        _fSessionLabel.setData(sessionLabel);

        session.save();
        session = null; // libère la mémoire (important sur vieux VMs)
    }

    function discard() as Void {
        if (session == null) { return; }
        session.stop();
        session.discard();
        session = null;
    }
}