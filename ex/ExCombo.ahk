; 自动连招：触发键热键驱动；同一时刻只跑一个序列，循环配置在序列结束后若仍按住则重启。

class ExCombo {
    static _ctx := 0

    static Run() {
        presetName := LoadLastPresetTrimmed()
        if (presetName = "" || !LoadPreset(presetName, "ComboState", false)) {
            return
        }
        profiles := ComboLoadProfilesFromPreset(presetName)
        runtimeProfiles := []
        loop profiles.Length {
            if !profiles.Has(A_Index) {
                continue
            }
            runtime := ComboBuildRuntimeProfile(profiles[A_Index], runtimeProfiles.Length + 1)
            if IsObject(runtime) {
                runtimeProfiles.Push(runtime)
            }
        }
        if (runtimeProfiles.Length = 0) {
            return
        }
        this._ctx := {
            profiles: runtimeProfiles,
            runningProfileIdx: 0,
            wasActive: WinActive("ahk_group DNF") != 0
        }
        OnExit(ObjBindMethod(ExCombo, "OnExit"))
        this._EnableHooks()
        Suspend(false)
        loop {
            this._WatchFocusLoss()
            Sleep(50)
        }
    }

    static _EnableHooks() {
        for profile in this._ctx.profiles {
            HotIfWinActive("ahk_group DNF")
            Hotkey("~$" profile.scID, profile.downFn, "On")
            Hotkey("~$" profile.scID " up", profile.upFn, "On")
            HotIf()
        }
    }

    static _DisableHooks() {
        ctx := this._ctx
        if !IsObject(ctx) {
            return
        }
        for profile in ctx.profiles {
            try SetTimer(profile.startFn, 0)
            try {
                HotIfWinActive("ahk_group DNF")
                try Hotkey("~$" profile.scID, "Off")
                try Hotkey("~$" profile.scID " up", "Off")
                HotIf()
            } catch {
                try HotIf()
            }
        }
    }

    static Down(profileIdx, *) {
        ctx := this._ctx
        profile := ctx.profiles[profileIdx]
        if profile.isHeld {
            return
        }
        profile.isHeld := true
        if (ctx.runningProfileIdx != 0) {
            return
        }
        SetTimer(profile.startFn, -1)
    }

    static Up(profileIdx, *) {
        profile := this._ctx.profiles[profileIdx]
        profile.isHeld := false
    }

    static StartProfile(profileIdx, *) {
        ctx := this._ctx
        if !IsObject(ctx) || ctx.runningProfileIdx != 0 {
            return
        }
        profile := ctx.profiles[profileIdx]
        if !profile.isHeld || !WinActive("ahk_group DNF") {
            return
        }
        ctx.runningProfileIdx := profileIdx
        try {
            this._RunProfile(profile)
        } finally {
            ctx.runningProfileIdx := 0
        }
        if (profile.loop && profile.isHeld && WinActive("ahk_group DNF")) {
            SetTimer(profile.startFn, -1)
        }
    }

    static _RunProfile(profile) {
        for item in profile.skills {
            if (profile.loop && !profile.isHeld) {
                return
            }
            if !WinActive("ahk_group DNF") {
                return
            }
            SendIP_Tap(item.sendToken)
            if (item.delay <= 0) {
                continue
            }
            beginTick := A_TickCount
            while (A_TickCount - beginTick < item.delay) {
                if !WinActive("ahk_group DNF") {
                    return
                }
                if (profile.loop && !profile.isHeld) {
                    return
                }
                Sleep(1)
            }
        }
    }

    static _WatchFocusLoss() {
        ctx := this._ctx
        if !IsObject(ctx) {
            return
        }
        isActive := WinActive("ahk_group DNF") != 0
        if (ctx.wasActive && !isActive) {
            for profile in ctx.profiles {
                profile.isHeld := false
            }
        }
        ctx.wasActive := isActive
    }

    static OnExit(exitReason, exitCode) {
        this._DisableHooks()
    }
}

ExCombo_Run() {
    ExCombo.Run()
}

ComboBuildRuntimeProfile(profile, profileIdx) {
    if !IsObject(profile) || !IsObject(profile.skills) || profile.skills.Length = 0 {
        return 0
    }
    triggerKey := GetKeycode.CanonMainKey(Trim(profile.trigger))
    if (triggerKey = "") {
        return 0
    }
    scID := GetKeycode.ToRouterId(triggerKey)
    if (scID = "") {
        return 0
    }
    skills := []
    for item in profile.skills {
        if !IsObject(item) {
            continue
        }
        skillKey := GetKeycode.CanonMainKey(item.key)
        if (skillKey = "") {
            continue
        }
        sendToken := GetKeycode.ToSendToken(skillKey)
        if (sendToken = "") {
            continue
        }
        delayMs := Round(item.delay + 0)
        if (delayMs < 20) {
            delayMs := 20
        } else if (delayMs > 3000) {
            delayMs := 3000
        }
        skills.Push({ sendToken: sendToken, delay: delayMs })
    }
    if (skills.Length = 0) {
        return 0
    }
    return {
        scID: scID,
        loop: profile.loop ? true : false,
        isHeld: false,
        skills: skills,
        startFn: ObjBindMethod(ExCombo, "StartProfile", profileIdx),
        downFn: ObjBindMethod(ExCombo, "Down", profileIdx),
        upFn: ObjBindMethod(ExCombo, "Up", profileIdx)
    }
}
