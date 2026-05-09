#Requires AutoHotkey v2.0

; 连发启停、预设切换、主连发热键注册；主界面键帽状态通过 RegisterMainSetKeyState 注入，避免 core 依赖 GUI

class AutoFireController {
    static _onMainSetKeyState := 0

    static RegisterMainSetKeyState(callback) {
        this._onMainSetKeyState := callback
    }

    static _VisualKey(key, on, ov := unset) {
        fn := this._onMainSetKeyState
        if !fn {
            return
        }
        try {
            if IsSet(ov) {
                fn.Call(key, on, ov)
            } else {
                fn.Call(key, on, 0)
            }
        }
    }

    static ChangeKeyAutoFireState(key) {
        keys := SessionState.AutoFireEnableKeys
        ov := LoadPresetKeyIntervalOverrides(SessionState.GetCurrentPreset())
        if SessionState.IsKeyAutoFire(key) {
            for i, k in keys {
                if (k == key) {
                    keys.RemoveAt(i)
                    break
                }
            }
            this._VisualKey(key, false, ov)
            SetOriginalDirect(key)
        } else {
            keys.Push(key)
            this._VisualKey(key, true, ov)
            SetOriginalBlocking(key)
        }
    }

    static Start() {
        presetName := SessionState.GetCurrentPreset()
        intervalMs := Round(LoadPreset(presetName, "MainAutoFireInterval", 20) + 0)
        if (intervalMs < 1) {
            intervalMs := 1
        } else if (intervalMs > 200) {
            intervalMs := 200
        }
        keyIvOv := LoadPresetKeyIntervalOverrides(presetName)
        AutoFireMainUnregisterHotkeys()
        ZhanFaUnregisterHotkeys()
        LvRenUnregisterHotkeys()
        GuanYuUnregisterHotkeys()
        PetSkillUnregisterHotkeys()
        JianZongUnregisterHotkeys()
        ComboUnregisterHotkeys()
        ExAutoRun.UnregisterHotkeys()
        KeyRouter.ClearAll()
        for afKey in SessionState.AutoFireEnableKeys {
            SetOriginalBlocking(afKey)
        }
        AutoFireMainRegisterHotkeys(intervalMs, keyIvOv)
        Sleep(10)
        this.StartEx()
        SetTrayRunningIcon(true)
        SetTimer(AppTip.Bind("连发已启动 - " . SessionState.GetCurrentPreset()), -100)
        try PresetRecognition_UpdateHotkeys()
    }

    static StartEx() {
        if PresetExFeatures.IsOn("LvRen") {
            LvRenRegisterHotkeys()
        }
        if PresetExFeatures.IsOn("GuanYu") {
            GuanYuRegisterHotkeys()
        }
        if PresetExFeatures.IsOn("PetSkill") {
            PetSkillRegisterHotkeys()
        }
        if PresetExFeatures.IsOn("JianZong") {
            skillKey := LoadPreset(SessionState.GetCurrentPreset(), "JianZongSkillKey")
            SetOriginalBlocking(skillKey)
            JianZongRegisterHotkeys()
        }
        if PresetExFeatures.IsOn("AutoRun") {
            ExAutoRun.RegisterHotkeys()
        }
        if PresetExFeatures.IsOn("Combo") {
            ComboRegisterHotkeys()
        }
        if PresetExFeatures.IsOn("ZhanFa") {
            ZhanFaRegisterHotkeys()
        }
    }

    static Stop() {
        allKeys := GetAllKeys()
        for k in allKeys {
            SetOriginalDirect(k)
        }
        AutoFireMainUnregisterHotkeys()
        ZhanFaUnregisterHotkeys()
        LvRenUnregisterHotkeys()
        GuanYuUnregisterHotkeys()
        PetSkillUnregisterHotkeys()
        JianZongUnregisterHotkeys()
        ComboUnregisterHotkeys()
        ExAutoRun.UnregisterHotkeys()
        KeyRouter.ClearAll()
        SetTrayRunningIcon(false)
        try PresetRecognition_CancelPending()
        try PresetRecognition_UpdateHotkeys()
    }

    static SetAllKeysDisable() {
        allKeys := GetAllKeys()
        for k in allKeys {
            this._VisualKey(k, false)
        }
        SessionState.AutoFireEnableKeys := []
    }

    static SetAllKeysAutoFire(keys) {
        this.SetAllKeysDisable()
        if !IsObject(keys) {
            return
        }
        ov := LoadPresetKeyIntervalOverrides(SessionState.GetCurrentPreset())
        for kName in keys {
            if !IsValueInArray(kName, GetAllKeys()) {
                continue
            }
            this._VisualKey(kName, true, ov)
            SessionState.AutoFireEnableKeys.Push(kName)
        }
    }

    static ChangePreset(presetName) {
        this.Stop()
        presetKeys := LoadPresetKeys(presetName)
        this.SetAllKeysAutoFire(presetKeys)
        SessionState.SetCurrentPreset(presetName)
        SaveLastPreset(presetName)
        MainLoadEx()
    }

    static IsRunning() {
        mr := SessionState.AutoFireMainHotkeyRegs.Length
        return mr > 0 || ExAutoRun._registered
    }

    static ChangePresetAndResumeAutoFire(presetName) {
        presetName := Trim(presetName)
        if (presetName = "") {
            return
        }
        if (presetName = SessionState.GetCurrentPreset()) {
            return
        }
        was := this.IsRunning()
        this.ChangePreset(presetName)
        if was {
            this.Start()
        }
    }
}

; 按用户要求：不屏蔽原键。保留函数是为了兼容现有调用点。
SetOriginalBlocking(key) {
}

SetOriginalDirect(key) {
}

SetTrayRunningIcon(state) {
    try TraySetIcon(A_ScriptFullPath, state ? 3 : 4)
}

StartAutoFire() {
    AutoFireController.Start()
}

StopAutoFire() {
    AutoFireController.Stop()
}

StartEx() {
    AutoFireController.StartEx()
}

ChangeKeyAutoFireState(key) {
    AutoFireController.ChangeKeyAutoFireState(key)
}

IsKeyAutoFire(key) {
    return SessionState.IsKeyAutoFire(key)
}

SetAllKeysDisable() {
    AutoFireController.SetAllKeysDisable()
}

SetAllKeysAutoFire(keys) {
    AutoFireController.SetAllKeysAutoFire(keys)
}

ChangePreset(presetName) {
    AutoFireController.ChangePreset(presetName)
}

AutoFireIsRunning() {
    return AutoFireController.IsRunning()
}

ChangePresetAndResumeAutoFire(presetName) {
    AutoFireController.ChangePresetAndResumeAutoFire(presetName)
}

AutoFireMainOnDown(tickFn, intervalMs, *) {
    SetTimer(tickFn, intervalMs)
}

AutoFireMainOnUp(tickFn, *) {
    SetTimer(tickFn, 0)
}

AutoFireMainUnregisterHotkeys() {
    regs := SessionState.AutoFireMainHotkeyRegs
    if !regs.Length {
        return
    }
    for reg in regs {
        SetTimer(reg.tickFn, 0)
        if reg.HasOwnProp("downFn") {
            KeyRouter.UnsubscribeDown(reg.id, reg.downFn)
        }
        if reg.HasOwnProp("upFn") {
            KeyRouter.UnsubscribeUp(reg.id, reg.upFn)
        }
    }
    SessionState.AutoFireMainHotkeyRegs := []
}

AutoFireMainRegisterHotkeys(defaultIntervalMs, keyIvOv := unset) {
    AutoFireMainUnregisterHotkeys()
    if !IsSet(keyIvOv) || !IsObject(keyIvOv) {
        keyIvOv := Map()
    }
    afKeys := SessionState.AutoFireEnableKeys
    if (afKeys.Length = 0) {
        return
    }
    for afKey in afKeys {
        effectiveMs := defaultIntervalMs
        if keyIvOv.Has(afKey) {
            effectiveMs := Round(keyIvOv[afKey] + 0)
            if (effectiveMs < 1) {
                effectiveMs := 1
            } else if (effectiveMs > 200) {
                effectiveMs := 200
            }
        }
        if !GetKeycode.IsMainKey(afKey) {
            continue
        }
        pressKey := GetKeycode.ToProbeKey(afKey)
        keyCode := GetKeycode.ToSendToken(afKey)
        id := GetKeycode.ToRouterId(afKey)
        if (id = "" || keyCode = "" || pressKey = "") {
            continue
        }
                tickFn := AutoFireEventTick.Bind(pressKey, keyCode)
        downFn := AutoFireMainOnDown.Bind(tickFn, effectiveMs)
        upFn := AutoFireMainOnUp.Bind(tickFn)
        if !KeyRouter.SubscribeDown(id, downFn) {
            continue
        }
        if !KeyRouter.SubscribeUp(id, upFn) {
            KeyRouter.UnsubscribeDown(id, downFn)
            continue
        }
        SessionState.AutoFireMainHotkeyRegs.Push({
            id: id,
            tickFn: tickFn,
            downFn: downFn,
            upFn: upFn,
        })
    }
}

AutoFireEventTick(pressKey, keyCode) {
    if !GameContext.IsActiveNow() {
        return
    }
    if (pressKey = "Tab" && (GetKeyState("LAlt", "P") || GetKeyState("RAlt", "P"))) {
        return
    }
    static keyBusy := Map()
    if (keyBusy.Has(pressKey) && keyBusy[pressKey]) {
        return
    }
    keyBusy[pressKey] := true
    try {
        SendIP(keyCode)
    } finally {
        keyBusy[pressKey] := false
    }
}

IsValueInArray(value, array) {
    if !IsObject(array) {
        return false
    }
    for v in array {
        if (v == value) {
            return true
        }
    }
    return false
}

DeleteValueInArray(value, array) {
    if !IsObject(array) {
        return
    }
    for i, v in array {
        if (v == value) {
            array.RemoveAt(i)
            return
        }
    }
}

ShowTipPlaceNearDnfBottomRight(text) {
    GameContext.RefreshNow()
    hwnd := GameContext.DnfHwnd
    if !hwnd {
        ToolTip(text)
        return
    }
    try WinGetClientPos(&cx, &cy, &cw, &ch, "ahk_id " hwnd)
    catch {
        ToolTip(text)
        return
    }
    pad := 14
    estW := Min(560, Max(140, Ceil(StrLen(text) * 10)))
    estH := 40
    tipX := cx + cw - estW - pad
    tipY := cy + ch - estH - pad
    if (tipX < cx + 8) {
        tipX := cx + 8
    }
    if (tipY < cy + 8) {
        tipY := cy + 8
    }
    ToolTip(text, tipX, tipY)
}

AppTip(text) {
    ShowTipPlaceNearDnfBottomRight(text)
    SetTimer(CloseTip, -1000)
    try WinActivate("地下城与勇士")
}

CloseTip() {
    ToolTip()
}
