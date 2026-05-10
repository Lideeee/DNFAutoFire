#Requires AutoHotkey v2.0

; 连发启停、预设切换、主连发热键注册；主界面按键状态通过 RegisterMainKeyStateRenderer 注入，避免 core 依赖 GUI

class AutoFireService {
    static _onMainKeyStateRender := 0

    static RegisterMainKeyStateRenderer(callback) {
        this._onMainKeyStateRender := callback
    }

    static RenderMainKeyState(keyName, isEnabled, overrideMap := unset) {
        renderer := this._onMainKeyStateRender
        if !renderer {
            return
        }
        try {
            if IsSet(overrideMap) {
                renderer.Call(keyName, isEnabled, overrideMap)
            } else {
                renderer.Call(keyName, isEnabled, 0)
            }
        }
    }

    static ToggleAutoFireKey(keyName) {
        enabledKeys := SessionState.AutoFireEnableKeys
        overrideMap := PresetManager.LoadKeyIntervalOverrides(SessionState.GetCurrentPreset())
        if SessionState.IsKeyAutoFire(keyName) {
            for index, existingKey in enabledKeys {
                if (existingKey = keyName) {
                    enabledKeys.RemoveAt(index)
                    break
                }
            }
            this.RenderMainKeyState(keyName, false, overrideMap)
            AutoFireController.RestoreOriginalKeyMode(keyName)
        } else {
            enabledKeys.Push(keyName)
            this.RenderMainKeyState(keyName, true, overrideMap)
            AutoFireController.UseBlockingOriginalKeyMode(keyName)
        }
    }

    static StartSession() {
        presetName := SessionState.GetCurrentPreset()
        mainIntervalMs := PresetManager.NormalizeInterval(LoadPreset(presetName, "MainAutoFireInterval", PresetManager.DefaultAutoFireInterval))
        keyIntervalOverrides := PresetManager.LoadKeyIntervalOverrides(presetName)
        MainAutoFireHotkeys_Stop()
        FeatureModuleRegistry.StopAllModules()
        KeyRouter.ClearAll()
        for keyName in SessionState.AutoFireEnableKeys {
            AutoFireController.UseBlockingOriginalKeyMode(keyName)
        }
        MainAutoFireHotkeys_Start(mainIntervalMs, keyIntervalOverrides)
        Sleep(10)
        this.StartFeatureModules()
        AutoFireController.UpdateTrayRunningIcon(true)
        SetTimer(AppTip.Bind("连发已启动 - " . SessionState.GetCurrentPreset()), -100)
        try PresetRecognition_UpdateHotkeys()
    }

    static StartFeatureModules() {
        FeatureModuleRegistry.StartEnabledModules(SessionState.GetCurrentPreset())
    }

    static StopSession() {
        allKeys := GetAllKeys()
        for keyName in allKeys {
            AutoFireController.RestoreOriginalKeyMode(keyName)
        }
        MainAutoFireHotkeys_Stop()
        FeatureModuleRegistry.StopAllModules()
        KeyRouter.ClearAll()
        AutoFireController.UpdateTrayRunningIcon(false)
        try PresetRecognition_CancelPending()
        try PresetRecognition_UpdateHotkeys()
    }

    static ClearAllAutoFireKeys() {
        allKeys := GetAllKeys()
        for keyName in allKeys {
            this.RenderMainKeyState(keyName, false)
        }
        SessionState.AutoFireEnableKeys := []
    }

    static ApplyAutoFireKeys(keys, presetName := unset) {
        this.ClearAllAutoFireKeys()
        if !IsObject(keys) {
            return
        }
        if !IsSet(presetName) {
            presetName := SessionState.GetCurrentPreset()
        }
        overrideMap := PresetManager.LoadKeyIntervalOverrides(presetName)
        for keyName in keys {
            if !IsValueInArray(keyName, GetAllKeys()) {
                continue
            }
            this.RenderMainKeyState(keyName, true, overrideMap)
            SessionState.AutoFireEnableKeys.Push(keyName)
        }
    }

    static SwitchPreset(presetName) {
        this.StopSession()
        presetKeys := LoadPresetKeys(presetName)
        PresetManager.Select(presetName, true)
        this.ApplyAutoFireKeys(presetKeys, presetName)
        MainLoadEx()
    }

    static IsSessionRunning() {
        mainRegisteredCount := SessionState.AutoFireMainHotkeyRegs.Length
        return mainRegisteredCount > 0 || FeatureModuleRegistry.AnyModuleRunning()
    }

    static SwitchPresetKeepingRunState(presetName) {
        presetName := Trim(presetName)
        if (presetName = "" || presetName = SessionState.GetCurrentPreset()) {
            return
        }
        wasRunning := this.IsSessionRunning()
        this.SwitchPreset(presetName)
        if wasRunning {
            this.StartSession()
        }
    }
}

class AutoFireController {
    static _originalKeyBlockers := Map()

    static RegisterMainSetKeyState(callback) {
        AutoFireService.RegisterMainKeyStateRenderer(callback)
    }

    static Start() {
        AutoFireService.StartSession()
    }

    static StartEx() {
        AutoFireService.StartFeatureModules()
    }

    static Stop() {
        AutoFireService.StopSession()
    }

    static ChangeKeyAutoFireState(keyName) {
        AutoFireService.ToggleAutoFireKey(keyName)
    }

    static SetAllKeysDisable() {
        AutoFireService.ClearAllAutoFireKeys()
    }

    static SetAllKeysAutoFire(keys) {
        AutoFireService.ApplyAutoFireKeys(keys)
    }

    static ChangePreset(presetName) {
        AutoFireService.SwitchPreset(presetName)
    }

    static IsRunning() {
        return AutoFireService.IsSessionRunning()
    }

    static ChangePresetAndResumeAutoFire(presetName) {
        AutoFireService.SwitchPresetKeepingRunState(presetName)
    }

    static UseBlockingOriginalKeyMode(keyName) {
        routerId := GetKeycode.ToRouterId(keyName)
        if (routerId = "" || this._originalKeyBlockers.Has(routerId)) {
            return
        }
        blockFn := (*) => 0
        try {
            HotIfWinActive("ahk_group DNF")
            Hotkey("$*" routerId, blockFn, "On")
            Hotkey("$*" routerId " up", blockFn, "On")
            HotIf()
            this._originalKeyBlockers[routerId] := blockFn
        } catch {
            try HotIf()
        }
    }

    static RestoreOriginalKeyMode(keyName) {
        routerId := GetKeycode.ToRouterId(keyName)
        if (routerId = "") {
            return
        }
        try {
            HotIfWinActive("ahk_group DNF")
            try Hotkey("$*" routerId, "Off")
            try Hotkey("$*" routerId " up", "Off")
            HotIf()
        } catch {
            try HotIf()
        }
        if this._originalKeyBlockers.Has(routerId) {
            this._originalKeyBlockers.Delete(routerId)
        }
    }

    static UpdateTrayRunningIcon(isRunning) {
        try TraySetIcon(A_ScriptFullPath, isRunning ? 3 : 4)
    }

    static IsKeyAutoFire(keyName) {
        return SessionState.IsKeyAutoFire(keyName)
    }
}

MainAutoFireHotkeys_OnKeyDown(tickFn, intervalMs, *) {
    SetTimer(tickFn, intervalMs)
}

MainAutoFireHotkeys_OnKeyUp(tickFn, *) {
    SetTimer(tickFn, 0)
}

MainAutoFireHotkeys_Stop() {
    registrations := SessionState.AutoFireMainHotkeyRegs
    if !registrations.Length {
        return
    }
    for registration in registrations {
        SetTimer(registration.tickFn, 0)
        if registration.HasOwnProp("downFn") {
            KeyRouter.UnsubscribeDown(registration.id, registration.downFn)
        }
        if registration.HasOwnProp("upFn") {
            KeyRouter.UnsubscribeUp(registration.id, registration.upFn)
        }
    }
    SessionState.AutoFireMainHotkeyRegs := []
}

MainAutoFireHotkeys_Start(defaultIntervalMs, keyIntervalOverrides := unset) {
    MainAutoFireHotkeys_Stop()
    if !IsSet(keyIntervalOverrides) || !IsObject(keyIntervalOverrides) {
        keyIntervalOverrides := Map()
    }
    autoFireKeys := SessionState.AutoFireEnableKeys
    if (autoFireKeys.Length = 0) {
        return
    }
    for autoFireKey in autoFireKeys {
        effectiveIntervalMs := defaultIntervalMs
        if keyIntervalOverrides.Has(autoFireKey) {
            effectiveIntervalMs := PresetManager.NormalizeInterval(keyIntervalOverrides[autoFireKey], defaultIntervalMs)
        }
        if !GetKeycode.IsMainKey(autoFireKey) {
            continue
        }
        probeKey := GetKeycode.ToProbeKey(autoFireKey)
        sendToken := GetKeycode.ToSendToken(autoFireKey)
        routerId := GetKeycode.ToRouterId(autoFireKey)
        if (routerId = "" || sendToken = "" || probeKey = "") {
            continue
        }
        tickFn := MainAutoFireHotkeys_Tick.Bind(probeKey, sendToken)
        downFn := MainAutoFireHotkeys_OnKeyDown.Bind(tickFn, effectiveIntervalMs)
        upFn := MainAutoFireHotkeys_OnKeyUp.Bind(tickFn)
        if !KeyRouter.SubscribeDown(routerId, downFn) {
            continue
        }
        if !KeyRouter.SubscribeUp(routerId, upFn) {
            KeyRouter.UnsubscribeDown(routerId, downFn)
            continue
        }
        SessionState.AutoFireMainHotkeyRegs.Push({
            id: routerId,
            tickFn: tickFn,
            downFn: downFn,
            upFn: upFn
        })
    }
}

MainAutoFireHotkeys_Tick(probeKey, sendToken) {
    if !GameContext.IsActiveNow() {
        return
    }
    if (probeKey = "Tab" && (GetKeyState("LAlt", "P") || GetKeyState("RAlt", "P"))) {
        return
    }
    static keyBusyMap := Map()
    if (keyBusyMap.Has(probeKey) && keyBusyMap[probeKey]) {
        return
    }
    keyBusyMap[probeKey] := true
    try {
        SendIP(sendToken)
    } finally {
        keyBusyMap[probeKey] := false
    }
}

IsValueInArray(value, array) {
    if !IsObject(array) {
        return false
    }
    for item in array {
        if (item = value) {
            return true
        }
    }
    return false
}

DeleteValueInArray(value, array) {
    if !IsObject(array) {
        return
    }
    for index, item in array {
        if (item = value) {
            array.RemoveAt(index)
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
