#Requires AutoHotkey v2.0

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
        defaultIntervalMs := PresetManager.NormalizeInterval(LoadPreset(presetName, "MainAutoFireInterval", PresetManager.DefaultAutoFireInterval))
        pressDurationMs := PresetManager.NormalizePressDuration(LoadPreset(presetName, "MainAutoFirePressDuration", PresetManager.DefaultAutoFirePressDuration))
        keyIntervalOverrides := PresetManager.LoadKeyIntervalOverrides(presetName)
        SendIP_ReleaseMany(CollectSyntheticReleaseTokens(presetName))
        MultipleThread.StopAllThreads()
        for keyName in SessionState.AutoFireEnableKeys {
            AutoFireController.UseBlockingOriginalKeyMode(keyName)
            effectiveIntervalMs := defaultIntervalMs
            if keyIntervalOverrides.Has(keyName) {
                effectiveIntervalMs := PresetManager.NormalizeInterval(keyIntervalOverrides[keyName], defaultIntervalMs)
            }
            MultipleThread.StartMainKeyThread(keyName, effectiveIntervalMs, pressDurationMs)
        }
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
        SendIP_ReleaseMany(CollectSyntheticReleaseTokens(SessionState.GetCurrentPreset()))
        allKeys := GetAllKeys()
        for keyName in allKeys {
            AutoFireController.RestoreOriginalKeyMode(keyName)
        }
        MultipleThread.StopAllThreads()
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

    static SwitchPreset(presetName, resumeIfRunning := false) {
        presetName := Trim(presetName)
        if (presetName = "") {
            return
        }
        wasRunning := this.IsSessionRunning()
        this.StopSession()
        presetKeys := LoadPresetKeys(presetName)
        PresetManager.Select(presetName, true)
        this.ApplyAutoFireKeys(presetKeys, presetName)
        MainLoadEx()
        if (resumeIfRunning && wasRunning) {
            this.StartSession()
        }
    }

    static IsSessionRunning() {
        return MultipleThread.AnyThreadRunning()
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

    static IsRunning() {
        return AutoFireService.IsSessionRunning()
    }

    static ChangePreset(presetName, resumeIfRunning := false) {
        AutoFireService.SwitchPreset(presetName, resumeIfRunning)
    }

    static UseBlockingOriginalKeyMode(keyName) {
        ; Keep the -0 main auto-fire behavior: do not block the original key.
        ; The child process reads the physical key state directly and sends repeats.
        return
    }

    static RestoreOriginalKeyMode(keyName) {
        return
    }

    static UpdateTrayRunningIcon(isRunning) {
        try TraySetIcon(A_ScriptFullPath, isRunning ? 3 : 4)
    }

    static IsKeyAutoFire(keyName) {
        return SessionState.IsKeyAutoFire(keyName)
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
