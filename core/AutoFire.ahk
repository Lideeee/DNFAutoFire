; 全局主键连发间隔（毫秒），保存在 config.ini [设置]；供主界面与子进程复用
LoadAutoFireGlobalIntervalMs() {
    AutoFireGlobalInterval_EnsureMigrated()
    return ClampAutoFireIntervalMs(Round(LoadConfig("AutoFireIntervalMs", 20) + 0))
}

SaveAutoFireGlobalIntervalMs(intervalMs) {
    SaveConfig("AutoFireIntervalMs", ClampAutoFireIntervalMs(intervalMs))
}

AutoFireGlobalInterval_EnsureMigrated() {
    static done := false
    if (done) {
        return
    }
    done := true
    raw := IniRead(ConfigIniPath(), "设置", "AutoFireIntervalMs", "__MISSING__")
    if (raw != "__MISSING__") {
        return
    }
    presetName := ResolvePresetName(LoadLastPreset())
    SaveAutoFireGlobalIntervalMs(LoadPreset(presetName, "AutoFireIntervalMs", 20))
}

ClampAutoFireIntervalMs(intervalMs) {
    intervalMs := Round(intervalMs + 0)
    if (intervalMs < 1) {
        intervalMs := 1
    } else if (intervalMs > 200) {
        intervalMs := 200
    }
    return intervalMs
}

ResolveAutoFireIntervalMs(guiKeyName, presetName, defaultMs, perMap) {
    intervalMs := defaultMs
    if (IsObject(perMap) && perMap.Has(guiKeyName)) {
        intervalMs := perMap[guiKeyName]
    }
    return ClampAutoFireIntervalMs(intervalMs)
}

AutoFire_LoadRuntimeKeys(presetName) {
    keys := LoadPresetKeys(presetName)
    if !LoadPreset(presetName, "XiuLuoState", false) {
        return keys
    }
    triggerKey := Trim(String(LoadPreset(presetName, "XiuLuoTriggerKey", "")))
    if (triggerKey = "") {
        return keys
    }
    filteredKeys := []
    for key in keys {
        if (key != triggerKey) {
            filteredKeys.Push(key)
        }
    }
    return filteredKeys
}

; 单个专用子进程承载全部主键连发：保留子进程隔离，同时复刻 0.27 的单进程多定时器调度。
MainAutoFire(presetName := "") {
    ProcessSetPriority("High")
    RegisterGameWindowGroup()
    try InstallKeybdHook()
    try UnlockSystemTimeLimit()
    OnExit(MainAutoFire_OnExit)

    presetName := ResolvePresetName(presetName = "" ? LoadLastPreset() : presetName)
    keys := AutoFire_LoadRuntimeKeys(presetName)
    defaultMs := LoadAutoFireGlobalIntervalMs()
    perMap := AutoFireKeyIntervals_StringToMap(LoadPreset(presetName, "AutoFireKeyIntervals", ""))
    timers := []

    try keyCount := keys.Length
    catch {
        keyCount := 0
    }
    loop keyCount {
        if !keys.Has(A_Index) {
            continue
        }
        guiKeyName := keys[A_Index]
        key := GetOriginKeyName(guiKeyName)
        keyCode := Key2NoVkSC(key)
        pressKey := Key2PressKey(key)
        if (StrLen(pressKey) >= 4 && SubStr(pressKey, 1, 2) = "sc") {
            pressKey := Format("{:L}", pressKey)
        }
        intervalMs := ResolveAutoFireIntervalMs(guiKeyName, presetName, defaultMs, perMap)
        fn := AutoFireSingleKeyTick.Bind(pressKey, keyCode)
        timers.Push(fn)
        SetTimer(fn, intervalMs)
    }

    loop {
        Sleep(1000)
    }
}

MainAutoFire_OnExit(*) {
    try RestoreSystemTimeLimit()
}

AutoFireSingleKeyTick(pressKey, keyCode) {
    if !WinActive("ahk_group DNF") {
        return
    }
    static keyBusy := Map()
    if (keyBusy.Has(pressKey) && keyBusy[pressKey]) {
        return
    }
    keyBusy[pressKey] := true
    try if (GetKeyState(pressKey, "P")) {
        SendIP(keyCode)
    }
    finally keyBusy[pressKey] := false
}
