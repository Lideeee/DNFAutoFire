; 旅人：触发键热键驱动；任一监听键按住时按主间隔持续输出，全部抬起后释放。

class ExLvRen {
    static _ctx := 0

    static Run() {
        presetName := LoadLastPresetTrimmed()
        if (presetName = "" || !LoadPreset(presetName, "LvRenState", false)) {
            return
        }
        shotKey := GetKeycode.CanonMainKey(LoadPresetSafe(presetName, "LvRenShotKey"))
        if (shotKey = "") {
            return
        }
        triggerKeys := LvRenUniqueSkillKeysByPressKey(LvRenLoadKeys(presetName))
        if (triggerKeys.Length = 0) {
            return
        }
        sendToken := GetKeycode.ToSendToken(shotKey)
        if (sendToken = "") {
            return
        }
        intervalMs := PresetManager.NormalizeInterval(LoadPreset(presetName, "MainAutoFireInterval", 20))
        entries := Map()
        for keyName in triggerKeys {
            canon := GetKeycode.CanonMainKey(keyName)
            scID := GetKeycode.ToRouterId(canon)
            probeKey := GetKeycode.ToProbeKey(canon)
            if (scID = "" || probeKey = "") {
                continue
            }
            entries[scID] := {
                scID: scID,
                probeKey: probeKey,
                isHeld: false,
                downFn: ObjBindMethod(ExLvRen, "Down", scID),
                upFn: ObjBindMethod(ExLvRen, "Up", scID)
            }
        }
        if (entries.Count = 0) {
            return
        }
        this._ctx := {
            sendToken: sendToken,
            intervalMs: intervalMs,
            triggerEntries: entries,
            activeCount: 0,
            isSending: false,
            nextDueAt: 0,
            wasActive: WinActive("ahk_group DNF") != 0,
            timerFn: ObjBindMethod(ExLvRen, "Tick")
        }
        OnExit(ObjBindMethod(ExLvRen, "OnExit"))
        this._EnableHooks()
        Suspend(false)
        loop {
            this._WatchFocusLoss()
            Sleep(50)
        }
    }

    static _EnableHooks() {
        ctx := this._ctx
        for _, entry in ctx.triggerEntries {
            HotIfWinActive("ahk_group DNF")
            Hotkey("~$" entry.scID, entry.downFn, "On")
            Hotkey("~$" entry.scID " up", entry.upFn, "On")
            HotIf()
        }
    }

    static _DisableHooks() {
        ctx := this._ctx
        if !IsObject(ctx) {
            return
        }
        try SetTimer(ctx.timerFn, 0)
        for _, entry in ctx.triggerEntries {
            try {
                HotIfWinActive("ahk_group DNF")
                try Hotkey("~$" entry.scID, "Off")
                try Hotkey("~$" entry.scID " up", "Off")
                HotIf()
            } catch {
                try HotIf()
            }
        }
    }

    static Down(scID, *) {
        ctx := this._ctx
        entry := ctx.triggerEntries.Get(scID, "")
        if !IsObject(entry) || entry.isHeld {
            return
        }
        entry.isHeld := true
        ctx.activeCount += 1
        if (ctx.activeCount = 1) {
            ctx.nextDueAt := 0
            this._TryFireNow()
        }
    }

    static Up(scID, *) {
        ctx := this._ctx
        entry := ctx.triggerEntries.Get(scID, "")
        if !IsObject(entry) || !entry.isHeld {
            return
        }
        entry.isHeld := false
        if (ctx.activeCount > 0) {
            ctx.activeCount -= 1
        }
        if (ctx.activeCount <= 0) {
            ctx.activeCount := 0
            ctx.nextDueAt := 0
            try SetTimer(ctx.timerFn, 0)
            SendIP_Release(ctx.sendToken)
        }
    }

    static Tick(*) {
        ctx := this._ctx
        if !IsObject(ctx) {
            return
        }
        if (ctx.activeCount <= 0 || !WinActive("ahk_group DNF")) {
            this._ReleaseAll()
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
        if !IsObject(ctx) || ctx.activeCount <= 0 || !WinActive("ahk_group DNF") {
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
        if (ctx.activeCount > 0 && WinActive("ahk_group DNF")) {
            this._QueueNext()
        }
        return sent
    }

    static _QueueNext() {
        this._QueueDelay(this._ctx.nextDueAt - A_TickCount)
    }

    static _QueueDelay(delayMs) {
        ctx := this._ctx
        if !IsObject(ctx) || ctx.activeCount <= 0 {
            return
        }
        if (delayMs < 1) {
            delayMs := 1
        }
        SetTimer(ctx.timerFn, -delayMs)
    }

    static _ReleaseAll() {
        ctx := this._ctx
        if !IsObject(ctx) {
            return
        }
        for _, entry in ctx.triggerEntries {
            entry.isHeld := false
        }
        ctx.activeCount := 0
        ctx.nextDueAt := 0
        try SetTimer(ctx.timerFn, 0)
        SendIP_Release(ctx.sendToken)
    }

    static _WatchFocusLoss() {
        ctx := this._ctx
        if !IsObject(ctx) {
            return
        }
        isActive := WinActive("ahk_group DNF") != 0
        if (ctx.wasActive && !isActive) {
            this._ReleaseAll()
        }
        ctx.wasActive := isActive
    }

    static OnExit(exitReason, exitCode) {
        this._DisableHooks()
        this._ReleaseAll()
    }
}

ExLvRen_Run() {
    ExLvRen.Run()
}

LvRenUniqueSkillKeysByPressKey(skillKeys) {
    seen := Map()
    out := []
    if !IsObject(skillKeys) {
        return out
    }
    for sk in skillKeys {
        canon := GetKeycode.CanonMainKey(sk)
        if (canon = "") {
            continue
        }
        probeKey := GetKeycode.ToProbeKey(canon)
        if (probeKey = "" || seen.Has(probeKey)) {
            continue
        }
        seen[probeKey] := true
        out.Push(canon)
    }
    return out
}

LvRenLoadKeys(presetName) {
    skillKeysConfig := LoadPresetSafe(presetName, "LvRenSkillKeys")
    keys := []
    for item in StrSplit(skillKeysConfig, "|") {
        item := Trim(item)
        if (item != "") {
            keys.Push(item)
        }
    }
    return keys
}
