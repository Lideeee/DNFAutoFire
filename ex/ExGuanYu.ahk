; 关羽：按下边沿后挂一次延时；到点触发一次，提前松开不取消。

class ExGuanYu {
    static _ctx := 0

    static Run() {
        presetName := LoadLastPresetTrimmed()
        if (presetName = "" || !LoadPreset(presetName, "GuanYuState", false)) {
            return
        }
        shotKey := GetKeycode.CanonMainKey(LoadPresetSafe(presetName, "GuanYuShotKey"))
        if (shotKey = "") {
            return
        }
        triggerKeys := GuanYuUniqueSkillKeysByPressKey(GuanYuLoadKeys(presetName))
        if (triggerKeys.Length = 0) {
            return
        }
        delayMs := Round(LoadPreset(presetName, "GuanYuDelay", 300) + 0)
        if (delayMs < 20) {
            delayMs := 20
        } else if (delayMs > 500) {
            delayMs := 500
        }
        sendToken := GetKeycode.ToSendToken(shotKey)
        if (sendToken = "") {
            return
        }
        entries := Map()
        for keyName in triggerKeys {
            canon := GetKeycode.CanonMainKey(keyName)
            scID := GetKeycode.ToRouterId(canon)
            if (scID = "") {
                continue
            }
            entries[scID] := {
                scID: scID,
                isHeld: false,
                timerFn: ObjBindMethod(ExGuanYu, "Fire", scID),
                downFn: ObjBindMethod(ExGuanYu, "Down", scID),
                upFn: ObjBindMethod(ExGuanYu, "Up", scID)
            }
        }
        if (entries.Count = 0) {
            return
        }
        this._ctx := {
            sendToken: sendToken,
            delayMs: delayMs,
            triggerEntries: entries,
            wasActive: WinActive("ahk_group DNF") != 0
        }
        OnExit(ObjBindMethod(ExGuanYu, "OnExit"))
        this._EnableHooks()
        Suspend(false)
        loop {
            this._WatchFocusLoss()
            Sleep(50)
        }
    }

    static _EnableHooks() {
        for _, entry in this._ctx.triggerEntries {
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
        for _, entry in ctx.triggerEntries {
            try SetTimer(entry.timerFn, 0)
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
        entry := this._ctx.triggerEntries.Get(scID, "")
        if !IsObject(entry) || entry.isHeld {
            return
        }
        entry.isHeld := true
        SetTimer(entry.timerFn, -this._ctx.delayMs)
    }

    static Up(scID, *) {
        entry := this._ctx.triggerEntries.Get(scID, "")
        if IsObject(entry) {
            entry.isHeld := false
        }
    }

    static Fire(scID, *) {
        ctx := this._ctx
        entry := ctx.triggerEntries.Get(scID, "")
        if !IsObject(entry) || !WinActive("ahk_group DNF") {
            return
        }
        SendIP_Tap(ctx.sendToken)
    }

    static _WatchFocusLoss() {
        ctx := this._ctx
        if !IsObject(ctx) {
            return
        }
        isActive := WinActive("ahk_group DNF") != 0
        if (ctx.wasActive && !isActive) {
            for _, entry in ctx.triggerEntries {
                entry.isHeld := false
                try SetTimer(entry.timerFn, 0)
            }
        }
        ctx.wasActive := isActive
    }

    static OnExit(exitReason, exitCode) {
        this._DisableHooks()
    }
}

ExGuanYu_Run() {
    ExGuanYu.Run()
}

GuanYuUniqueSkillKeysByPressKey(skillKeys) {
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

GuanYuLoadKeys(presetName) {
    skillKeysConfig := LoadPresetSafe(presetName, "GuanYuSkillKeys")
    keys := []
    for item in StrSplit(skillKeysConfig, "|") {
        item := Trim(item)
        if (item != "") {
            keys.Push(item)
        }
    }
    return keys
}
