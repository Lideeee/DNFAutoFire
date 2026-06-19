; 全局主键连发间隔（毫秒），保存在 config.ini [设置]；供主界面与子进程复用
LoadAutoFireGlobalIntervalMs() {
    return ClampMsMin1(Round(LoadConfig("AutoFireIntervalMs", 20) + 0))
}

SaveAutoFireGlobalIntervalMs(intervalMs) {
    SaveConfig("AutoFireIntervalMs", ClampMsMin1(intervalMs))
}

ClampMsMin1(ms) {
    ms := Round(ms + 0)
    if (ms < 1) {
        ms := 1
    }
    return ms
}

ResolveKeyMs(guiKeyName, defaultMs, perMap, minMs := 0) {
    ms := defaultMs
    if (IsObject(perMap) && perMap.Has(guiKeyName)) {
        ms := perMap[guiKeyName]
    }
    ms := Round(ms + 0)
    if (ms < minMs) {
        ms := minMs
    }
    return ms
}

AutoFire_LoadRuntimeKeys(presetName) {
    keys := LoadPresetKeys(presetName)
    avoidPressKeys := AutoFire_LoadAvoidPressKeys(presetName)
    if (avoidPressKeys.Count = 0) {
        return keys
    }
    filteredKeys := []
    for key in keys {
        pressKey := AutoFire_KeyToPressKey(key)
        if (pressKey = "" || !avoidPressKeys.Has(pressKey)) {
            filteredKeys.Push(key)
        }
    }
    return filteredKeys
}

AutoFire_LoadAvoidPressKeys(presetName) {
    avoidPressKeys := Map()
    if LoadPreset(presetName, "XiuLuoState", false) {
        AutoFire_AddAvoidPressKey(avoidPressKeys, LoadPreset(presetName, "XiuLuoTriggerKey", ""))
    }
    return avoidPressKeys
}

AutoFire_AddAvoidPressKey(avoidPressKeys, key) {
    pressKey := AutoFire_KeyToPressKey(key)
    if (pressKey != "") {
        avoidPressKeys[pressKey] := true
    }
}

AutoFire_KeyToPressKey(key) {
    key := Trim(String(key))
    if (key = "") {
        return ""
    }
    pressKey := Key2PressKey(GetOriginKeyName(key))
    if (StrLen(pressKey) >= 4 && SubStr(pressKey, 1, 2) = "sc") {
        pressKey := Format("{:L}", pressKey)
    }
    return pressKey
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
    perMap := StrToMsMap(LoadPreset(presetName, "AutoFireKeyIntervals", ""))
    delayMap := StrToMsMap(LoadPreset(presetName, "AutoFireKeyDelays", ""))
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
        pressKey := AutoFire_KeyToPressKey(guiKeyName)
        intervalMs := ResolveKeyMs(guiKeyName, defaultMs, perMap, 1)
        keyDelayMs := ResolveKeyMs(guiKeyName, 8, delayMap)
        fn := AutoFireSingleKeyTick.Bind(pressKey, keyCode, keyDelayMs)
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

AutoFireSingleKeyTick(pressKey, keyCode, keyDelayMs) {
    if !WinActive("ahk_group DNF") {
        return
    }
    static keyBusy := Map()
    if (keyBusy.Has(pressKey) && keyBusy[pressKey]) {
        return
    }
    keyBusy[pressKey] := true
    try if (GetKeyState(pressKey, "P")) {
        SendIP(keyCode, keyDelayMs)
    }
    finally keyBusy[pressKey] := false
}
