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

        presetName := presetName = "" ? ResolvePresetName(LoadLastPreset()) : NormalizePresetName(presetName)
        rules := ExAction_BuildRules(presetName)
        guanYuProfiles := ExAction_BuildGuanYuProfiles(presetName)
        comboProfiles := ExAction_BuildComboProfiles(presetName)
        autoRun := ExAction_BuildAutoRun(presetName)

        if (rules.Length = 0 && guanYuProfiles.Length = 0 && comboProfiles.Length = 0 && !IsObject(autoRun)) {
            return
        }

        this._ctx := {
            rules: rules,
            edgeHotkeyIds: [],
            guanYuProfiles: guanYuProfiles,
            guanYuHotkeyIds: [],
            comboProfiles: comboProfiles,
            comboHotkeyIds: [],
            runningComboIdx: 0,
            comboAbortRequested: false,
            comboPendingTimer: "",
            autoRun: autoRun,
            wasActive: WinActive("ahk_group DNF") != 0
        }

        this._StartRuleTimers()
        this._EnableEdgeHooks()
        this._EnableGuanYuHooks()
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
            if (rule.policy = "onceOnPressEdge") {
                continue
            }
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

    static _EnableEdgeHooks() {
        ctx := this._ctx
        seen := Map()
        for rule in ctx.rules {
            if (rule.policy != "onceOnPressEdge") {
                continue
            }
            for scID in rule.scIDs {
                if seen.Has(scID) {
                    continue
                }
                seen[scID] := true
                ctx.edgeHotkeyIds.Push(scID)
                HotIfWinActive("ahk_group DNF")
                Hotkey("~$" scID, ObjBindMethod(ExActionRuntime, "EdgeDownByScID", scID), "On")
                Hotkey("~$" scID " up", ObjBindMethod(ExActionRuntime, "EdgeUpByScID", scID), "On")
                HotIf()
            }
        }
    }

    static _DisableEdgeHooks() {
        ctx := this._ctx
        if !IsObject(ctx) {
            return
        }
        for rule in ctx.rules {
            if (rule.policy = "onceOnPressEdge") {
                rule.heldScIDs := Map()
            }
        }
        for scID in ctx.edgeHotkeyIds {
            try {
                HotIfWinActive("ahk_group DNF")
                try Hotkey("~$" scID, "Off")
                try Hotkey("~$" scID " up", "Off")
                HotIf()
            } catch {
                try HotIf()
            }
        }
        ctx.edgeHotkeyIds := []
    }

    static EdgeDownByScID(scID, *) {
        ctx := this._ctx
        if !IsObject(ctx) || !WinActive("ahk_group DNF") {
            return
        }
        for rule in ctx.rules {
            if (rule.policy != "onceOnPressEdge" || !ExAction_RuleHasScID(rule, scID)) {
                continue
            }
            if (rule.heldScIDs.Has(scID) && rule.heldScIDs[scID]) {
                continue
            }
            rule.heldScIDs[scID] := true
            SendIP(rule.sendToken)
        }
    }

    static EdgeUpByScID(scID, *) {
        ctx := this._ctx
        if !IsObject(ctx) {
            return
        }
        for rule in ctx.rules {
            if (rule.policy = "onceOnPressEdge" && rule.heldScIDs.Has(scID)) {
                rule.heldScIDs[scID] := false
            }
        }
    }

    static _EnableGuanYuHooks() {
        ctx := this._ctx
        seen := Map()
        for profile in ctx.guanYuProfiles {
            if seen.Has(profile.scID) {
                continue
            }
            seen[profile.scID] := true
            ctx.guanYuHotkeyIds.Push(profile.scID)
            HotIfWinActive("ahk_group DNF")
            Hotkey("~$" profile.scID, ObjBindMethod(ExActionRuntime, "GuanYuDownByScID", profile.scID), "On")
            Hotkey("~$" profile.scID " up", ObjBindMethod(ExActionRuntime, "GuanYuUpByScID", profile.scID), "On")
            HotIf()
        }
    }

    static _DisableGuanYuHooks() {
        ctx := this._ctx
        if !IsObject(ctx) {
            return
        }
        for profile in ctx.guanYuProfiles {
            try SetTimer(profile.pendingFn, 0)
            profile.pending := false
            profile.isHeld := false
        }
        for scID in ctx.guanYuHotkeyIds {
            try {
                HotIfWinActive("ahk_group DNF")
                try Hotkey("~$" scID, "Off")
                try Hotkey("~$" scID " up", "Off")
                HotIf()
            } catch {
                try HotIf()
            }
        }
        ctx.guanYuHotkeyIds := []
    }

    static GuanYuDownByScID(scID, *) {
        ctx := this._ctx
        if !IsObject(ctx) {
            return
        }
        loop ctx.guanYuProfiles.Length {
            if ctx.guanYuProfiles.Has(A_Index) && ctx.guanYuProfiles[A_Index].scID = scID {
                this.GuanYuDown(A_Index)
            }
        }
    }

    static GuanYuUpByScID(scID, *) {
        ctx := this._ctx
        if !IsObject(ctx) {
            return
        }
        loop ctx.guanYuProfiles.Length {
            if ctx.guanYuProfiles.Has(A_Index) && ctx.guanYuProfiles[A_Index].scID = scID {
                this.GuanYuUp(A_Index)
            }
        }
    }

    static GuanYuDown(profileIdx, *) {
        ctx := this._ctx
        if !IsObject(ctx) || profileIdx < 1 || profileIdx > ctx.guanYuProfiles.Length || !ctx.guanYuProfiles.Has(profileIdx) {
            return
        }
        profile := ctx.guanYuProfiles[profileIdx]
        if profile.isHeld {
            return
        }
        profile.isHeld := true
        profile.pending := true
        SetTimer(profile.pendingFn, 0)
        SetTimer(profile.pendingFn, -profile.leadDelayMs)
    }

    static GuanYuUp(profileIdx, *) {
        ctx := this._ctx
        if !IsObject(ctx) || profileIdx < 1 || profileIdx > ctx.guanYuProfiles.Length || !ctx.guanYuProfiles.Has(profileIdx) {
            return
        }
        profile := ctx.guanYuProfiles[profileIdx]
        profile.isHeld := false
        if profile.pending {
            try SetTimer(profile.pendingFn, 0)
            profile.pending := false
        }
    }

    static GuanYuSend(profileIdx, *) {
        ctx := this._ctx
        if !IsObject(ctx) || profileIdx < 1 || profileIdx > ctx.guanYuProfiles.Length || !ctx.guanYuProfiles.Has(profileIdx) {
            return
        }
        profile := ctx.guanYuProfiles[profileIdx]
        profile.pending := false
        if !WinActive("ahk_group DNF") {
            return
        }
        ExAction_RunSequence(profile)
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
            ExAction_ResetRuleForInactive(rule)
            return
        }

        anyHeld := ExAction_AnyHeld(rule.pressKeys)
        switch rule.policy {
        case "repeatWhileAnyHeld":
            if anyHeld {
                SendIP(rule.sendToken)
            }
        case "onceOnPollHoldEdge":
            if (anyHeld && !rule.heldLast) {
                SendIP(rule.sendToken)
            }
            rule.heldLast := anyHeld
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
        seen := Map()
        for profile in ctx.comboProfiles {
            if seen.Has(profile.scID) {
                continue
            }
            seen[profile.scID] := true
            ctx.comboHotkeyIds.Push(profile.scID)
            prefix := profile.blockOriginal ? "$" : "~$"
            HotIfWinActive("ahk_group DNF")
            Hotkey(prefix profile.scID, ObjBindMethod(ExActionRuntime, "ComboDownByScID", profile.scID), "On")
            Hotkey(prefix profile.scID " up", ObjBindMethod(ExActionRuntime, "ComboUpByScID", profile.scID), "On")
            HotIf()
        }
    }

    static _DisableComboHooks() {
        ctx := this._ctx
        if !IsObject(ctx) {
            return
        }
        this._ComboClearPendingTimer()
        for scID in ctx.comboHotkeyIds {
            try {
                HotIfWinActive("ahk_group DNF")
                try Hotkey("$" scID, "Off")
                try Hotkey("$" scID " up", "Off")
                try Hotkey("~$" scID, "Off")
                try Hotkey("~$" scID " up", "Off")
                HotIf()
            } catch {
                try HotIf()
            }
        }
        ctx.comboHotkeyIds := []
        ctx.runningComboIdx := 0
        ctx.comboAbortRequested := false
    }

    static ComboDownByScID(scID, *) {
        ctx := this._ctx
        if !IsObject(ctx) {
            return
        }
        loop ctx.comboProfiles.Length {
            if ctx.comboProfiles.Has(A_Index) && ctx.comboProfiles[A_Index].scID = scID {
                this.ComboDown(A_Index)
            }
        }
    }

    static ComboUpByScID(scID, *) {
        ctx := this._ctx
        if !IsObject(ctx) {
            return
        }
        loop ctx.comboProfiles.Length {
            if ctx.comboProfiles.Has(A_Index) && ctx.comboProfiles[A_Index].scID = scID {
                this.ComboUp(A_Index)
            }
        }
    }

    static ComboDown(profileIdx, *) {
        ctx := this._ctx
        if !IsObject(ctx) || profileIdx < 1 || profileIdx > ctx.comboProfiles.Length || !ctx.comboProfiles.Has(profileIdx) {
            return
        }
        profile := ctx.comboProfiles[profileIdx]
        if profile.isHeld {
            return
        }
        profile.isHeld := true
        if profile.loop {
            if (ctx.runningComboIdx = 0) {
                this._ComboStartFromDown(profileIdx)
            }
            return
        }
        this._ComboStartFromDown(profileIdx)
    }

    static ComboUp(profileIdx, *) {
        ctx := this._ctx
        if !IsObject(ctx) || profileIdx < 1 || profileIdx > ctx.comboProfiles.Length || !ctx.comboProfiles.Has(profileIdx) {
            return
        }
        profile := ctx.comboProfiles[profileIdx]
        profile.isHeld := false
        if (ctx.runningComboIdx = profileIdx && profile.breakOnRelease) {
            this._ComboAbortSequence()
        }
    }

    static _ComboStartFromDown(profileIdx) {
        ctx := this._ctx
        if !IsObject(ctx) || ctx.runningComboIdx != 0 {
            return
        }
        profile := ctx.comboProfiles[profileIdx]
        if !profile.isHeld || !WinActive("ahk_group DNF") {
            return
        }
        ctx.runningComboIdx := profileIdx
        ctx.comboAbortRequested := false
        if (profile.leadDelayMs > 0) {
            this._ComboSchedule(ObjBindMethod(ExActionRuntime, "_ComboSendSkillAt", 1), profile.leadDelayMs)
        } else {
            this._ComboSendSkillAt(1)
        }
    }

    static _ComboClearPendingTimer() {
        ctx := this._ctx
        if !IsObject(ctx) {
            return
        }
        if (ctx.comboPendingTimer != "") {
            try SetTimer(ctx.comboPendingTimer, 0)
            ctx.comboPendingTimer := ""
        }
    }

    static _ComboSchedule(fn, delayMs) {
        ctx := this._ctx
        this._ComboClearPendingTimer()
        ctx.comboPendingTimer := fn
        SetTimer(fn, -delayMs)
    }

    static _ComboShouldAbort() {
        ctx := this._ctx
        if !IsObject(ctx) || ctx.comboAbortRequested || !WinActive("ahk_group DNF") {
            return true
        }
        if (ctx.runningComboIdx = 0 || ctx.runningComboIdx > ctx.comboProfiles.Length || !ctx.comboProfiles.Has(ctx.runningComboIdx)) {
            return true
        }
        profile := ctx.comboProfiles[ctx.runningComboIdx]
        if (profile.breakOnRelease && !profile.isHeld) {
            return true
        }
        return false
    }

    static _ComboSendSkillAt(idx, *) {
        ctx := this._ctx
        if this._ComboShouldAbort() {
            this._ComboFinish()
            return
        }
        profile := ctx.comboProfiles[ctx.runningComboIdx]
        if (idx > profile.skills.Length || !profile.skills.Has(idx)) {
            this._ComboChainComplete()
            return
        }
        item := profile.skills[idx]
        if !IsObject(item) {
            this._ComboSendSkillAt(idx + 1)
            return
        }
        try SendIP(item.sendToken, ExAction_SequenceKeyHoldMs())
        delay := item.delay + 0
        if (delay <= 0) {
            this._ComboSendSkillAt(idx + 1)
            return
        }
        this._ComboSchedule(ObjBindMethod(ExActionRuntime, "_ComboSendSkillAt", idx + 1), delay)
    }

    static _ComboChainComplete(*) {
        ctx := this._ctx
        if this._ComboShouldAbort() {
            this._ComboFinish()
            return
        }
        profile := ctx.comboProfiles[ctx.runningComboIdx]
        if (profile.loop && profile.isHeld) {
            if (profile.mainIntervalMs > 0) {
                this._ComboSchedule(ObjBindMethod(ExActionRuntime, "_ComboSendSkillAt", 1), profile.mainIntervalMs)
            } else {
                this._ComboSendSkillAt(1)
            }
            return
        }
        this._ComboFinish()
    }

    static _ComboAbortSequence() {
        ctx := this._ctx
        if !IsObject(ctx) {
            return
        }
        ctx.comboAbortRequested := true
        this._ComboClearPendingTimer()
        this._ComboFinish()
    }

    static _ComboFinish() {
        ctx := this._ctx
        if !IsObject(ctx) {
            return
        }
        this._ComboClearPendingTimer()
        ctx.runningComboIdx := 0
        ctx.comboAbortRequested := false
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
                ExAction_ResetRuleForInactive(rule)
            }
            for profile in ctx.comboProfiles {
                profile.isHeld := false
            }
            for profile in ctx.guanYuProfiles {
                try SetTimer(profile.pendingFn, 0)
                profile.pending := false
                profile.isHeld := false
            }
            if (ctx.runningComboIdx != 0) {
                this._ComboAbortSequence()
            } else {
                this._ComboClearPendingTimer()
            }
            if IsObject(ctx.autoRun) {
                this._AutoRunStopActive(ctx.autoRun)
            }
        }
        ctx.wasActive := isActive
    }

    static OnExit(exitReason, exitCode) {
        this._StopRuleTimers()
        this._DisableEdgeHooks()
        this._DisableGuanYuHooks()
        this._DisableComboHooks()
        this._DisableAutoRunHooks()
        try RestoreSystemTimeLimit()
    }
}

ExActionRuntime_Run(presetName := "") {
    ExActionRuntime.Run(presetName)
}

ExAction_HasRunnable(presetName) {
    presetName := presetName = "" ? ResolvePresetName(LoadLastPreset()) : NormalizePresetName(presetName)
    return ExAction_BuildRules(presetName).Length > 0
        || ExAction_BuildGuanYuProfiles(presetName).Length > 0
        || ExAction_BuildComboProfiles(presetName).Length > 0
        || IsObject(ExAction_BuildAutoRun(presetName))
}

ExAction_BuildRules(presetName) {
    rules := []
    intervalMs := LoadAutoFireGlobalIntervalMs()
    if LoadPreset(presetName, "LvRenState", false) {
        ExAction_AddRepeatRule(rules, "LvRen", LvRenLoadKeys(presetName), LoadPreset(presetName, "LvRenShotKey", "Z"), intervalMs)
    }
    if LoadPreset(presetName, "ZhanFaState", false) {
        ExAction_AddRepeatRule(rules, "ZhanFa", ZhanFaLoadKeys(presetName), LoadPreset(presetName, "ZhanFaShotKey", "Space"), intervalMs)
        ExAction_AddPollEdgeRule(rules, "ZhanFaBig", ZhanFaLoadKeys(presetName), LoadPreset(presetName, "ZhanFaBigShotKey", ""), intervalMs)
    }
    if LoadPreset(presetName, "PetSkillState", false) {
        ExAction_AddEdgeRule(rules, "PetSkill", PetSkillLoadKeys(presetName), LoadPreset(presetName, "PetSkillShotKey", "Z"))
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

ExAction_BuildGuanYuProfiles(presetName) {
    if !LoadPreset(presetName, "GuanYuState", false) {
        return []
    }
    shotKey := LoadPreset(presetName, "GuanYuShotKey", "Space")
    sendToken := ExAction_SendToken(shotKey)
    if (sendToken = "") {
        return []
    }
    delayMs := ExAction_Clamp(LoadPreset(presetName, "GuanYuDelay", 300), 20, 500)
    skillKeys := GuanYuLoadKeys(presetName)
    skillKeys := ExAction_UniqueKeysByPressKey(skillKeys)
    profiles := []
    for skillKey in skillKeys {
        originKey := GetOriginKeyName(skillKey)
        scID := Key2SC(originKey)
        if (scID = "") {
            continue
        }
        profiles.Push({
            scID: scID,
            leadDelayMs: delayMs,
            isHeld: false,
            pending: false,
            skills: [{ sendToken: sendToken, delay: 0 }]
        })
        profiles[profiles.Length].pendingFn := ObjBindMethod(ExActionRuntime, "GuanYuSend", profiles.Length)
    }
    return profiles
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
        tickMs: ClampMsMin1(intervalMs),
        busy: false,
        pendingStartTick: 0,
        sentForHold: false,
        heldLast: false
    })
}

ExAction_AddEdgeRule(rules, name, triggerKeys, shotKey) {
    scIDs := ExAction_BuildScIDs(triggerKeys)
    sendToken := ExAction_SendToken(shotKey)
    if (scIDs.Length = 0 || sendToken = "") {
        return
    }
    rules.Push({
        name: name,
        policy: "onceOnPressEdge",
        scIDs: scIDs,
        sendToken: sendToken,
        busy: false,
        pendingStartTick: 0,
        sentForHold: false,
        heldLast: false,
        heldScIDs: Map()
    })
}

ExAction_AddPollEdgeRule(rules, name, triggerKeys, shotKey, intervalMs) {
    pressKeys := ExAction_BuildPressKeys(triggerKeys)
    sendToken := ExAction_SendToken(shotKey)
    if (pressKeys.Length = 0 || sendToken = "") {
        return
    }
    rules.Push({
        name: name,
        policy: "onceOnPollHoldEdge",
        pressKeys: pressKeys,
        sendToken: sendToken,
        tickMs: ClampMsMin1(intervalMs),
        busy: false,
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
        tickMs: ClampMsMin1(intervalMs),
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
    fastMs := ClampMsMin1(intervalMs)
    slowMs := ClampMsMin1(intervalMs * 3)
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
    mainIntervalMs := ExAction_Clamp(LoadPreset(presetName, "MainAutoFireInterval", 20), 1, 200)
    runtimeProfiles := []
    if LoadPreset(presetName, "ComboState", false) {
        profiles := ComboLoadProfilesFromPreset(presetName)
        loop profiles.Length {
            if !profiles.Has(A_Index) {
                continue
            }
            runtime := ExAction_BuildComboProfile(profiles[A_Index], mainIntervalMs)
            if IsObject(runtime) {
                runtimeProfiles.Push(runtime)
            }
        }
    }
    return runtimeProfiles
}

ExAction_BuildComboProfile(profile, mainIntervalMs) {
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
        breakOnRelease: profile.loop ? true : false,
        blockOriginal: (HasProp(profile, "blockOriginal") && profile.blockOriginal) ? true : false,
        leadDelayMs: 0,
        mainIntervalMs: mainIntervalMs,
        isHeld: false,
        skills: skills
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

ExAction_BuildScIDs(keys) {
    scIDs := []
    seen := Map()
    if !IsObject(keys) {
        return scIDs
    }
    for key in keys {
        key := Trim(String(key))
        if (key = "") {
            continue
        }
        scID := Key2SC(GetOriginKeyName(key))
        if (scID = "" || seen.Has(scID)) {
            continue
        }
        seen[scID] := true
        scIDs.Push(scID)
    }
    return scIDs
}

ExAction_RuleHasScID(rule, scID) {
    if !IsObject(rule) || !IsObject(rule.scIDs) {
        return false
    }
    for item in rule.scIDs {
        if (item = scID) {
            return true
        }
    }
    return false
}

ExAction_SendToken(key) {
    key := Trim(String(key))
    if (key = "") {
        return ""
    }
    return Key2NoVkSC(GetOriginKeyName(key))
}

ExAction_SequenceKeyHoldMs() {
    return 12
}

ExAction_RunSequence(profile) {
    if !IsObject(profile) || !IsObject(profile.skills) {
        return
    }
    for item in profile.skills {
        if !IsObject(item) {
            continue
        }
        try SendIP(item.sendToken, ExAction_SequenceKeyHoldMs())
        delay := item.delay + 0
        if (delay <= 0) {
            continue
        }
        beginTick := A_TickCount
        while (A_TickCount - beginTick < delay) {
            if !WinActive("ahk_group DNF") {
                return
            }
            Sleep(1)
        }
    }
}

ExAction_UniqueKeysByPressKey(keys) {
    seen := Map()
    out := []
    if !IsObject(keys) {
        return out
    }
    for key in keys {
        key := Trim(String(key))
        if (key = "") {
            continue
        }
        pressKey := Key2PressKey(GetOriginKeyName(key))
        if (pressKey = "" || seen.Has(pressKey)) {
            continue
        }
        seen[pressKey] := true
        out.Push(key)
    }
    return out
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

ExAction_ResetRuleForInactive(rule) {
    ExAction_ResetHoldRule(rule)
    rule.heldLast := false
    if (rule.policy = "xiuLuoBurstRepeat") {
        rule.lastXTick := 0
        rule.lastWaveTick := 0
    } else if (rule.policy = "onceOnPressEdge") {
        rule.heldScIDs := Map()
    }
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
