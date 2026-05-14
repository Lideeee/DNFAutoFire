#Requires AutoHotkey v2.0

class AutoFireMainKeyRuntime {
    static _ctx := 0

    static Run(keyName, intervalMs, pressDurationMs) {
        keyName := GetKeycode.CanonMainKey(keyName)
        if (keyName = "") {
            return
        }
        intervalMs := PresetManager.NormalizeInterval(intervalMs)
        pressDurationMs := PresetManager.NormalizePressDuration(pressDurationMs)
        probeKey := GetKeycode.ToProbeKey(keyName)
        sendToken := GetKeycode.ToSendToken(keyName)
        scID := GetKeycode.ToRouterId(keyName)
        if (probeKey = "" || sendToken = "" || scID = "") {
            return
        }
        this._ctx := {
            keyName: keyName,
            intervalMs: intervalMs,
            pressDurationMs: pressDurationMs,
            probeKey: probeKey,
            sendToken: sendToken,
            scID: scID,
            isHeld: false,
            isSending: false,
            nextDueAt: 0,
            wasActive: WinActive("ahk_group DNF") != 0,
            timerFn: ObjBindMethod(AutoFireMainKeyRuntime, "Tick"),
            downFn: ObjBindMethod(AutoFireMainKeyRuntime, "Down"),
            upFn: ObjBindMethod(AutoFireMainKeyRuntime, "Up")
        }
        OnExit(ObjBindMethod(AutoFireMainKeyRuntime, "OnExit"))
        this._EnableHooks()
        Suspend(false)
        loop {
            this._WatchFocusLoss()
            Sleep(50)
        }
    }

    static _EnableHooks() {
        ctx := this._ctx
        if !IsObject(ctx) {
            return
        }
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
        try SetTimer(ctx.timerFn, 0)
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
        if !IsObject(ctx) {
            return
        }
        if ctx.isHeld {
            return
        }
        ctx.isHeld := true
        ctx.nextDueAt := 0
        this._TryFireNow()
    }

    static Up(*) {
        ctx := this._ctx
        if !IsObject(ctx) {
            return
        }
        ctx.isHeld := false
        ctx.nextDueAt := 0
        try SetTimer(ctx.timerFn, 0)
        SendIP_Release(ctx.sendToken)
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
        if this._ShouldDeferTabChord() {
            this._QueueDelay(1)
            return false
        }
        if ctx.isSending {
            this._QueueDelay(1)
            return false
        }
        ctx.isSending := true
        startedAt := A_TickCount
        try {
            sent := SendIP_PulseHeld(ctx.sendToken, ctx.pressDurationMs)
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
        ctx := this._ctx
        if !IsObject(ctx) || !ctx.isHeld {
            return
        }
        delayMs := ctx.nextDueAt - A_TickCount
        if (delayMs < 1) {
            delayMs := 1
        }
        this._QueueDelay(delayMs)
    }

    static _QueueDelay(delayMs) {
        ctx := this._ctx
        if !IsObject(ctx) || !ctx.isHeld {
            return
        }
        if (delayMs < 1) {
            delayMs := 1
        }
        SetTimer(ctx.timerFn, -delayMs)
    }

    static _ShouldDeferTabChord() {
        ctx := this._ctx
        return ctx.probeKey = "Tab" && (GetKeyState("LAlt", "P") || GetKeyState("RAlt", "P"))
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
        try {
            ctx := this._ctx
            if IsObject(ctx) {
                SendIP_Release(ctx.sendToken)
            }
        }
    }
}

AutoFire_Run(keyName, intervalMs, pressDurationMs) {
    AutoFireMainKeyRuntime.Run(keyName, intervalMs, pressDurationMs)
}
