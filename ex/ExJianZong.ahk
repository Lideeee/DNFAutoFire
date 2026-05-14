; 剑宗：按下后先等待延时；仍按住则进入高频持续输出，松手或失焦后停止并释放。

class ExJianZong {
    static _ctx := 0

    static Run() {
        presetName := LoadLastPresetTrimmed()
        if (presetName = "" || !LoadPreset(presetName, "JianZongState", false)) {
            return
        }
        skillKey := GetKeycode.CanonMainKey(LoadPresetSafe(presetName, "JianZongSkillKey"))
        if (skillKey = "") {
            return
        }
        delayMs := Round(LoadPreset(presetName, "JianZongDelay", 200) + 0)
        if (delayMs < 20) {
            delayMs := 20
        } else if (delayMs > 3000) {
            delayMs := 3000
        }
        sendToken := GetKeycode.ToSendToken(skillKey)
        scID := GetKeycode.ToRouterId(skillKey)
        if (sendToken = "" || scID = "") {
            return
        }
        intervalMs := PresetManager.NormalizeInterval(LoadPreset(presetName, "MainAutoFireInterval", 20))
        this._ctx := {
            sendToken: sendToken,
            scID: scID,
            delayMs: delayMs,
            intervalMs: intervalMs,
            isHeld: false,
            isSending: false,
            nextDueAt: 0,
            wasActive: WinActive("ahk_group DNF") != 0,
            delayTimerFn: ObjBindMethod(ExJianZong, "DelayDone"),
            pulseTimerFn: ObjBindMethod(ExJianZong, "Tick"),
            downFn: ObjBindMethod(ExJianZong, "Down"),
            upFn: ObjBindMethod(ExJianZong, "Up")
        }
        OnExit(ObjBindMethod(ExJianZong, "OnExit"))
        this._EnableHooks()
        Suspend(false)
        loop {
            this._WatchFocusLoss()
            Sleep(50)
        }
    }

    static _EnableHooks() {
        ctx := this._ctx
        HotIfWinActive("ahk_group DNF")
        Hotkey("~$" ctx.scID, ctx.downFn, "On")
        Hotkey("~$" ctx.scID " up", ctx.upFn, "On")
        HotIf()
    }

    static _DisableHooks() {
        ctx := this._ctx
        if !IsObject(ctx) {
            return
        }
        try SetTimer(ctx.delayTimerFn, 0)
        try SetTimer(ctx.pulseTimerFn, 0)
        try {
            HotIfWinActive("ahk_group DNF")
            try Hotkey("~$" ctx.scID, "Off")
            try Hotkey("~$" ctx.scID " up", "Off")
            HotIf()
        } catch {
            try HotIf()
        }
    }

    static Down(*) {
        ctx := this._ctx
        if ctx.isHeld {
            return
        }
        ctx.isHeld := true
        ctx.nextDueAt := 0
        SetTimer(ctx.delayTimerFn, -ctx.delayMs)
    }

    static Up(*) {
        ctx := this._ctx
        if !IsObject(ctx) {
            return
        }
        ctx.isHeld := false
        ctx.nextDueAt := 0
        try SetTimer(ctx.delayTimerFn, 0)
        try SetTimer(ctx.pulseTimerFn, 0)
        SendIP_Release(ctx.sendToken)
    }

    static DelayDone(*) {
        ctx := this._ctx
        if !IsObject(ctx) || !ctx.isHeld || !WinActive("ahk_group DNF") {
            return
        }
        this._TryFireNow()
    }

    static Tick(*) {
        ctx := this._ctx
        if !IsObject(ctx) {
            return
        }
        if !ctx.isHeld || !WinActive("ahk_group DNF") {
            this.Up()
            return
        }
        if (ctx.nextDueAt > 0 && A_TickCount < ctx.nextDueAt) {
            this._QueueNext()
            return
        }
        this._TryFireNow()
    }

    static _TryFireNow() {
        ctx := this._ctx
        if !IsObject(ctx) || !ctx.isHeld || !WinActive("ahk_group DNF") {
            return false
        }
        if ctx.isSending {
            this._QueueDelay(1)
            return false
        }
        ctx.isSending := true
        startedAt := A_TickCount
        try {
            sent := SendIP_PulseHeld(ctx.sendToken)
        } finally {
            ctx.isSending := false
        }
        ctx.nextDueAt := startedAt + ctx.intervalMs
        if ctx.isHeld && WinActive("ahk_group DNF") {
            this._QueueNext()
        }
        return sent
    }

    static _QueueNext() {
        this._QueueDelay(this._ctx.nextDueAt - A_TickCount)
    }

    static _QueueDelay(delayMs) {
        ctx := this._ctx
        if !IsObject(ctx) || !ctx.isHeld {
            return
        }
        if (delayMs < 1) {
            delayMs := 1
        }
        SetTimer(ctx.pulseTimerFn, -delayMs)
    }

    static _WatchFocusLoss() {
        ctx := this._ctx
        if !IsObject(ctx) {
            return
        }
        isActive := WinActive("ahk_group DNF") != 0
        if (ctx.wasActive && !isActive) {
            this.Up()
        }
        ctx.wasActive := isActive
    }

    static OnExit(exitReason, exitCode) {
        this._DisableHooks()
        this.Up()
    }
}

ExJianZong_Run() {
    ExJianZong.Run()
}
