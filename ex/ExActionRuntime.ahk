#Requires AutoHotkey v2.0

; EX 输入动作运行时：统一承载战法、旅人、关羽、宠物技能、剑宗、修罗、自动奔跑和一键连招。
; 主键连发仍由 MainAutoFire 独立子进程承载，避免高频主连发被扩展动作影响。

class ExActionRuntime {
    static _ctx := 0

    static Run(presetName := "") {
        ProcessSetPriority("High")
        SetStoreCapsLockMode(false)
        RegisterGameWindowGroup()
        try InstallKeybdHook()
        try UnlockSystemTimeLimit()
        OnExit(ObjBindMethod(ExActionRuntime, "OnExit"))

        presetName := ResolvePresetName(presetName = "" ? LoadLastPreset() : presetName)
        rules := ExAction_BuildRules(presetName)
        comboProfiles := ExAction_BuildComboProfiles(presetName)
        autoRun := ExAction_BuildAutoRun(presetName)

        if (rules.Length = 0 && comboProfiles.Length = 0 && !IsObject(autoRun)) {
            return
        }

        this._ctx := {
            rules: rules,
            comboProfiles: comboProfiles,
            runningComboIdx: 0,
            autoRun: autoRun,
            wasActive: WinActive("ahk_group DNF") != 0
        }

        this._StartRuleTimers()
        this._EnableComboHooks()
        this._EnableAutoRunHooks()
        Suspend(false)

        loop {
            this._WatchFocusLoss()
            Sleep(50)
        }
    }

    static _StartRuleTimers() {
        ctx := this._ctx
        for rule in ctx.rules {
            rule.tickFn := ObjBindMethod(ExActionRuntime, "RuleTick", rule)
            SetTimer(rule.tickFn, rule.tickMs)
        }
    }

    static _StopRuleTimers() {
        ctx := this._ctx
        if !IsObject(ctx) {
            return
        }
        for rule in ctx.rules {
            try SetTimer(rule.tickFn, 0)
        }
    }

    static RuleTick(rule, *) {
        if (rule.busy) {
            return
        }
        rule.busy := true
        try {
            this._RuleTickCore(rule)
        } finally {
            rule.busy := false
        }
    }

    static _RuleTickCore(rule) {
        if !WinActive("ahk_group DNF") {
            if (rule.policy = "onceOnPressEdge") {
                rule.heldLast := ExAction_AnyHeld(rule.pressKeys)
            } else if (rule.policy = "onceAfterPressDelay") {
                ExAction_ResetHoldRule(rule)
                rule.heldLast := ExAction_AnyHeld(rule.pressKeys)
            } else if (!ExAction_AnyHeld(rule.pressKeys)) {
                ExAction_ResetHoldRule(rule)
            }
            return
        }

        anyHeld := ExAction_AnyHeld(rule.pressKeys)
        switch rule.policy {
        case "repeatWhileAnyHeld":
            if anyHeld {
                SendIP(rule.sendToken)
            }
        case "onceOnPressEdge":
            if (anyHeld && !rule.heldLast) {
                SendIP(rule.sendToken)
            }
            rule.heldLast := anyHeld
        case "onceAfterPressDelay":
            if (anyHeld && !rule.heldLast) {
                rule.pendingStartTick := A_TickCount
                rule.sentForHold := false
            }
            rule.heldLast := anyHeld
            if (rule.pendingStartTick != 0 && !rule.sentForHold && A_TickCount - rule.pendingStartTick >= rule.delayMs) {
                SendIP(rule.sendToken)
                rule.sentForHold := true
                rule.pendingStartTick := 0
            }
        case "repeatAfterHoldDelay":
            if !anyHeld {
                ExAction_ResetHoldRule(rule)
                rule.heldLast := false
            } else {
                if !rule.heldLast {
                    rule.pendingStartTick := A_TickCount
                    rule.heldLast := true
                    return
                }
                if (A_TickCount - rule.pendingStartTick >= rule.delayMs) {
                    SendIP(rule.sendToken)
                }
            }
        case "xiuLuoBurstRepeat":
            if !anyHeld {
                rule.heldLast := false
                rule.lastXTick := 0
                rule.lastWaveTick := 0
                return
            }
            nowTick := A_TickCount
            if (!rule.heldLast || rule.lastXTick = 0 || nowTick - rule.lastXTick >= rule.fastMs) {
                SendIP(rule.xSendToken)
                rule.lastXTick := nowTick
            }
            if (!rule.heldLast || rule.lastWaveTick = 0 || nowTick - rule.lastWaveTick >= rule.slowMs) {
                for sendToken in rule.waveSendTokens {
                    SendIP(sendToken)
                }
                rule.lastWaveTick := nowTick
            }
            rule.heldLast := true
        }
    }

    static _EnableComboHooks() {
        ctx := this._ctx
        for profile in ctx.comboProfiles {
            HotIfWinActive("ahk_group DNF")
            Hotkey("~$" profile.scID, profile.downFn, "On")
            Hotkey("~$" profile.scID " up", profile.upFn, "On")
            HotIf()
        }
    }

    static _DisableComboHooks() {
        ctx := this._ctx
        if !IsObject(ctx) {
            return
        }
        for profile in ctx.comboProfiles {
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

    static ComboDown(profileIdx, *) {
        ctx := this._ctx
        profile := ctx.comboProfiles[profileIdx]
        if profile.isHeld {
            return
        }
        profile.isHeld := true
        if (ctx.runningComboIdx != 0) {
            return
        }
        SetTimer(profile.startFn, -1)
    }

    static ComboUp(profileIdx, *) {
        profile := this._ctx.comboProfiles[profileIdx]
        profile.isHeld := false
    }

    static ComboStart(profileIdx, *) {
        ctx := this._ctx
        if !IsObject(ctx) || ctx.runningComboIdx != 0 {
            return
        }
        profile := ctx.comboProfiles[profileIdx]
        if !profile.isHeld || !WinActive("ahk_group DNF") {
            return
        }
        ctx.runningComboIdx := profileIdx
        try {
            this._RunComboProfile(profile)
        } finally {
            ctx.runningComboIdx := 0
        }
        if (profile.loop && profile.isHeld && WinActive("ahk_group DNF")) {
            SetTimer(profile.startFn, -1)
        }
    }

    static _RunComboProfile(profile) {
        for item in profile.skills {
            if (profile.loop && !profile.isHeld) {
                return
            }
            if !WinActive("ahk_group DNF") {
                return
            }
            SendIP(item.sendToken)
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

    static _EnableAutoRunHooks() {
        ctx := this._ctx
        if !IsObject(ctx.autoRun) {
            return
        }
        ar := ctx.autoRun
        HotIfWinActive("ahk_group DNF")
        Hotkey("~" ar.rightKey, ObjBindMethod(ExActionRuntime, "AutoRunRightDown"), "On")
        Hotkey("~" ar.rightKey " Up", ObjBindMethod(ExActionRuntime, "AutoRunRightUp"), "On")
        Hotkey("~" ar.leftKey, ObjBindMethod(ExActionRuntime, "AutoRunLeftDown"), "On")
        Hotkey("~" ar.leftKey " Up", ObjBindMethod(ExActionRuntime, "AutoRunLeftUp"), "On")
        HotIf()
    }

    static _DisableAutoRunHooks() {
        ctx := this._ctx
        if !IsObject(ctx) || !IsObject(ctx.autoRun) {
            return
        }
        ar := ctx.autoRun
        try SetTimer(ar.rightTickFn, 0)
        try SetTimer(ar.leftTickFn, 0)
        try {
            HotIfWinActive("ahk_group DNF")
            try Hotkey("~" ar.rightKey, "Off")
            try Hotkey("~" ar.rightKey " Up", "Off")
            try Hotkey("~" ar.leftKey, "Off")
            try Hotkey("~" ar.leftKey " Up", "Off")
            HotIf()
        } catch {
            try HotIf()
        }
    }

    static _AutoRunStopActive(ar) {
        ar.pressingRight := false
        ar.pressingLeft := false
        ar.doubleRight := false
        ar.doubleLeft := false
        ar.rightCounter := 0
        ar.leftCounter := 0
        try SetTimer(ar.rightTickFn, 0)
        try SetTimer(ar.leftTickFn, 0)
    }

    static _AutoRunPauseHeld(ar) {
        return ar.pauseKey != "" && GetKeyState(Key2PressKey(GetOriginKeyName(ar.pauseKey)), "P")
    }

    static AutoRunRightDown(*) {
        ar := this._ctx.autoRun
        if this._AutoRunPauseHeld(ar) {
            return
        }
        if !ar.pressingRight {
            ar.pressingRight := true
            ar.doubleRight := false
            ar.rightCounter := 0
            SetTimer(ar.rightTickFn, ar.tickMs)
        }
    }

    static AutoRunRightUp(*) {
        ar := this._ctx.autoRun
        ar.pressingRight := false
        SetTimer(ar.rightTickFn, 0)
        SendEvent(ar.rightUpSend)
    }

    static AutoRunRightTick(*) {
        ar := this._ctx.autoRun
        if this._AutoRunPauseHeld(ar) {
            return
        }
        ar.rightCounter++
        if (ar.pressingRight && !ar.doubleRight) {
            SendEvent(ar.rightPulseSend)
            ar.doubleRight := true
        }
        if (ar.rightCounter >= 3) {
            SetTimer(ar.rightTickFn, 0)
        }
    }

    static AutoRunLeftDown(*) {
        ar := this._ctx.autoRun
        if this._AutoRunPauseHeld(ar) {
            return
        }
        if !ar.pressingLeft {
            ar.pressingLeft := true
            ar.doubleLeft := false
            ar.leftCounter := 0
            SetTimer(ar.leftTickFn, ar.tickMs)
        }
    }

    static AutoRunLeftUp(*) {
        ar := this._ctx.autoRun
        ar.pressingLeft := false
        SetTimer(ar.leftTickFn, 0)
        SendEvent(ar.leftUpSend)
    }

    static AutoRunLeftTick(*) {
        ar := this._ctx.autoRun
        if this._AutoRunPauseHeld(ar) {
            return
        }
        ar.leftCounter++
        if (ar.pressingLeft && !ar.doubleLeft) {
            SendEvent(ar.leftPulseSend)
            ar.doubleLeft := true
        }
        if (ar.leftCounter >= 3) {
            SetTimer(ar.leftTickFn, 0)
        }
    }

    static _WatchFocusLoss() {
        ctx := this._ctx
        if !IsObject(ctx) {
            return
        }
        isActive := WinActive("ahk_group DNF") != 0
        if (ctx.wasActive && !isActive) {
            for rule in ctx.rules {
                ExAction_ResetHoldRule(rule)
                if (rule.policy = "onceOnPressEdge") {
                    rule.heldLast := false
                } else if (rule.policy = "xiuLuoBurstRepeat") {
                    rule.heldLast := false
                    rule.lastXTick := 0
                    rule.lastWaveTick := 0
                }
            }
            for profile in ctx.comboProfiles {
                profile.isHeld := false
            }
            if IsObject(ctx.autoRun) {
                this._AutoRunStopActive(ctx.autoRun)
            }
        }
        ctx.wasActive := isActive
    }

    static OnExit(exitReason, exitCode) {
        this._StopRuleTimers()
        this._DisableComboHooks()
        this._DisableAutoRunHooks()
        try RestoreSystemTimeLimit()
    }
}

ExActionRuntime_Run(presetName := "") {
    ExActionRuntime.Run(presetName)
}

ExAction_BuildRules(presetName) {
    rules := []
    intervalMs := LoadAutoFireGlobalIntervalMs()
    if LoadPreset(presetName, "LvRenState", false) {
        ExAction_AddRepeatRule(rules, "LvRen", LvRenLoadKeys(presetName), LoadPreset(presetName, "LvRenShotKey", "Z"), intervalMs)
    }
    if LoadPreset(presetName, "ZhanFaState", false) {
        ExAction_AddRepeatRule(rules, "ZhanFa", ZhanFaLoadKeys(presetName), LoadPreset(presetName, "ZhanFaShotKey", "Space"), intervalMs)
        ExAction_AddEdgeRule(rules, "ZhanFaBig", ZhanFaLoadKeys(presetName), LoadPreset(presetName, "ZhanFaBigShotKey", ""))
    }
    if LoadPreset(presetName, "PetSkillState", false) {
        ExAction_AddEdgeRule(rules, "PetSkill", PetSkillLoadKeys(presetName), LoadPreset(presetName, "PetSkillShotKey", "Z"))
    }
    if LoadPreset(presetName, "GuanYuState", false) {
        delayMs := ExAction_Clamp(LoadPreset(presetName, "GuanYuDelay", 300), 0, 500)
        ExAction_AddDelayOnceRule(rules, "GuanYu", GuanYuLoadKeys(presetName), LoadPreset(presetName, "GuanYuShotKey", "Space"), delayMs)
    }
    if LoadPreset(presetName, "JianZongState", false) {
        skillKey := LoadPreset(presetName, "JianZongSkillKey", "A")
        delayMs := ExAction_Clamp(LoadPreset(presetName, "JianZongDelay", 200), 0, 3000)
        ExAction_AddDelayRepeatRule(rules, "JianZong", [skillKey], skillKey, delayMs, intervalMs)
    }
    if LoadPreset(presetName, "XiuLuoState", false) {
        ExAction_AddXiuLuoRule(
            rules,
            "XiuLuo",
            LoadPreset(presetName, "XiuLuoTriggerKey", ""),
            LoadPreset(presetName, "XiuLuoXKey", "X"),
            [
                LoadPreset(presetName, "XiuLuoWaveKey1", "1"),
                LoadPreset(presetName, "XiuLuoWaveKey2", "2"),
                LoadPreset(presetName, "XiuLuoWaveKey3", "3")
            ],
            intervalMs
        )
    }
    return rules
}

ExAction_AddRepeatRule(rules, name, triggerKeys, shotKey, intervalMs) {
    pressKeys := ExAction_BuildPressKeys(triggerKeys)
    sendToken := ExAction_SendToken(shotKey)
    if (pressKeys.Length = 0 || sendToken = "") {
        return
    }
    rules.Push({
        name: name,
        policy: "repeatWhileAnyHeld",
        pressKeys: pressKeys,
        sendToken: sendToken,
        tickMs: ClampAutoFireIntervalMs(intervalMs),
        busy: false,
        pendingStartTick: 0,
        sentForHold: false,
        heldLast: false
    })
}

ExAction_AddEdgeRule(rules, name, triggerKeys, shotKey) {
    pressKeys := ExAction_BuildPressKeys(triggerKeys)
    sendToken := ExAction_SendToken(shotKey)
    if (pressKeys.Length = 0 || sendToken = "") {
        return
    }
    rules.Push({
        name: name,
        policy: "onceOnPressEdge",
        pressKeys: pressKeys,
        sendToken: sendToken,
        tickMs: 5,
        busy: false,
        pendingStartTick: 0,
        sentForHold: false,
        heldLast: false
    })
}

ExAction_AddDelayOnceRule(rules, name, triggerKeys, shotKey, delayMs) {
    pressKeys := ExAction_BuildPressKeys(triggerKeys)
    sendToken := ExAction_SendToken(shotKey)
    if (pressKeys.Length = 0 || sendToken = "") {
        return
    }
    rules.Push({
        name: name,
        policy: "onceAfterPressDelay",
        pressKeys: pressKeys,
        sendToken: sendToken,
        tickMs: 5,
        busy: false,
        delayMs: delayMs,
        pendingStartTick: 0,
        sentForHold: false,
        heldLast: false
    })
}

ExAction_AddDelayRepeatRule(rules, name, triggerKeys, shotKey, delayMs, intervalMs) {
    pressKeys := ExAction_BuildPressKeys(triggerKeys)
    sendToken := ExAction_SendToken(shotKey)
    if (pressKeys.Length = 0 || sendToken = "") {
        return
    }
    rules.Push({
        name: name,
        policy: "repeatAfterHoldDelay",
        pressKeys: pressKeys,
        sendToken: sendToken,
        tickMs: ClampAutoFireIntervalMs(intervalMs),
        busy: false,
        delayMs: delayMs,
        pendingStartTick: 0,
        sentForHold: false,
        heldLast: false
    })
}

ExAction_AddXiuLuoRule(rules, name, triggerKey, xKey, waveKeys, intervalMs) {
    pressKeys := ExAction_BuildPressKeys([triggerKey])
    xSendToken := ExAction_SendToken(xKey)
    waveSendTokens := []
    for key in waveKeys {
        sendToken := ExAction_SendToken(key)
        if (sendToken != "") {
            waveSendTokens.Push(sendToken)
        }
    }
    if (pressKeys.Length = 0 || xSendToken = "" || waveSendTokens.Length = 0) {
        return
    }
    fastMs := ClampAutoFireIntervalMs(intervalMs)
    slowMs := ClampAutoFireIntervalMs(intervalMs * 3)
    rules.Push({
        name: name,
        policy: "xiuLuoBurstRepeat",
        pressKeys: pressKeys,
        xSendToken: xSendToken,
        waveSendTokens: waveSendTokens,
        tickMs: fastMs,
        fastMs: fastMs,
        slowMs: slowMs,
        lastXTick: 0,
        lastWaveTick: 0,
        busy: false,
        pendingStartTick: 0,
        sentForHold: false,
        heldLast: false
    })
}

ExAction_BuildComboProfiles(presetName) {
    if !LoadPreset(presetName, "ComboState", false) {
        return []
    }
    profiles := ComboLoadProfilesFromPreset(presetName)
    runtimeProfiles := []
    loop profiles.Length {
        if !profiles.Has(A_Index) {
            continue
        }
        runtime := ExAction_BuildComboProfile(profiles[A_Index], runtimeProfiles.Length + 1)
        if IsObject(runtime) {
            runtimeProfiles.Push(runtime)
        }
    }
    return runtimeProfiles
}

ExAction_BuildComboProfile(profile, profileIdx) {
    if (!IsObject(profile) || !IsObject(profile.skills) || profile.skills.Length == 0) {
        return 0
    }
    triggerKey := ComboCanonMainKey(Trim(String(profile.trigger)))
    if (triggerKey = "") {
        return 0
    }
    scID := Key2SC(GetOriginKeyName(triggerKey))
    if (scID = "") {
        return 0
    }
    skills := []
    for item in profile.skills {
        if !IsObject(item) {
            continue
        }
        skillKey := ComboCanonMainKey(item.key)
        if (skillKey = "") {
            continue
        }
        sendToken := ExAction_SendToken(skillKey)
        if (sendToken = "") {
            continue
        }
        skills.Push({ sendToken: sendToken, delay: ComboNormalizeDelay(item.delay) })
    }
    if (skills.Length = 0) {
        return 0
    }
    return {
        scID: scID,
        loop: profile.loop ? true : false,
        isHeld: false,
        skills: skills,
        startFn: ObjBindMethod(ExActionRuntime, "ComboStart", profileIdx),
        downFn: ObjBindMethod(ExActionRuntime, "ComboDown", profileIdx),
        upFn: ObjBindMethod(ExActionRuntime, "ComboUp", profileIdx)
    }
}

ExAction_BuildAutoRun(presetName) {
    if !LoadPreset(presetName, "AutoRunState", false) {
        return 0
    }
    leftKey := LoadPreset(presetName, "AutoRunLeftKey", "Left")
    rightKey := LoadPreset(presetName, "AutoRunRightKey", "Right")
    if (leftKey = "") {
        leftKey := "Left"
    }
    if (rightKey = "") {
        rightKey := "Right"
    }
    tickMs := ExAction_Clamp(LoadPreset(presetName, "AutoRunDelay", 30), 1, 400)
    pauseKey := Trim(LoadPreset(presetName, "AutoRunPauseKey", ""))
    if (pauseKey = leftKey || pauseKey = rightKey) {
        pauseKey := ""
    }
    ar := {
        leftKey: leftKey,
        rightKey: rightKey,
        pauseKey: pauseKey,
        tickMs: tickMs,
        rightPulseSend: "{" rightKey " Down}{" rightKey " Up}{" rightKey " Down}",
        rightUpSend: "{" rightKey " Up}",
        leftPulseSend: "{" leftKey " Down}{" leftKey " Up}{" leftKey " Down}",
        leftUpSend: "{" leftKey " Up}",
        pressingRight: false,
        doubleRight: false,
        rightCounter: 0,
        pressingLeft: false,
        doubleLeft: false,
        leftCounter: 0
    }
    ar.rightTickFn := ObjBindMethod(ExActionRuntime, "AutoRunRightTick")
    ar.leftTickFn := ObjBindMethod(ExActionRuntime, "AutoRunLeftTick")
    return ar
}

ExAction_BuildPressKeys(keys) {
    pressKeys := []
    if !IsObject(keys) {
        return pressKeys
    }
    for key in keys {
        key := Trim(String(key))
        if (key = "") {
            continue
        }
        pressKey := Key2PressKey(GetOriginKeyName(key))
        if (StrLen(pressKey) >= 4 && SubStr(pressKey, 1, 2) = "sc") {
            pressKey := Format("{:L}", pressKey)
        }
        pressKeys.Push(pressKey)
    }
    return pressKeys
}

ExAction_SendToken(key) {
    key := Trim(String(key))
    if (key = "") {
        return ""
    }
    return Key2NoVkSC(GetOriginKeyName(key))
}

ExAction_AnyHeld(pressKeys) {
    for pressKey in pressKeys {
        if (GetKeyState(pressKey, "P") || GetKeyState(pressKey)) {
            return true
        }
    }
    return false
}

ExAction_ResetHoldRule(rule) {
    rule.pendingStartTick := 0
    rule.sentForHold := false
}

ExAction_Clamp(value, minValue, maxValue) {
    value := Round(value + 0)
    if (value < minValue) {
        return minValue
    }
    if (value > maxValue) {
        return maxValue
    }
    return value
}

ExAction_LoadKeyList(presetName, configKey) {
    keys := []
    for item in StrSplit(LoadPreset(presetName, configKey), "|") {
        item := Trim(item)
        if (item != "") {
            keys.Push(item)
        }
    }
    return keys
}

LvRenLoadKeys(presetName) {
    return ExAction_LoadKeyList(presetName, "LvRenSkillKeys")
}

ZhanFaLoadKeys(presetName) {
    return ExAction_LoadKeyList(presetName, "ZhanFaSkillKeys")
}

PetSkillLoadKeys(presetName) {
    return ExAction_LoadKeyList(presetName, "PetSkillSkillKeys")
}

GuanYuLoadKeys(presetName) {
    return ExAction_LoadKeyList(presetName, "GuanYuSkillKeys")
}
