; 切换按键连发状态
ChangeKeyAutoFireState(key){
    global _AutoFireEnableKeys
    if(IsKeyAutoFire(key)){
        needDeleteIndex := 0
        try keyCount := _AutoFireEnableKeys.Length
        catch {
            keyCount := 0
        }
        loop keyCount
        {
            if !_AutoFireEnableKeys.Has(A_Index) {
                continue
            }
            if(_AutoFireEnableKeys[A_Index] == key){
                needDeleteIndex := A_Index
            }
        }
        if (needDeleteIndex > 0) {
            _AutoFireEnableKeys.RemoveAt(needDeleteIndex)
        }
        MainSetKeyState(key, false)
    } else {
        _AutoFireEnableKeys.Push(key)
        MainSetKeyState(key, true)
    }
}

; 判断按键是否启用了连发
IsKeyAutoFire(key){
    global _AutoFireEnableKeys
    try keyCount := _AutoFireEnableKeys.Length
    catch {
        keyCount := 0
    }
    loop keyCount
    {
        if !_AutoFireEnableKeys.Has(A_Index) {
            continue
        }
        if(_AutoFireEnableKeys[A_Index] == key){
            return true
        }
    }
    return false
}

; 把Gui上的key名转换为真实的键值
GetOriginKeyName(key){
    switch key {
    Case "Sub":
        keyName := "-"
    Case "Add":
        keyName := "="
    Case "Tilde":
        keyName := "``"
    Case "LeftBracket":
        keyName := "["
    Case "RightBracket":
        keyName := "]"
    Case "Backslash":
        keyName := "\"
    Case "Semicolon":
        keyName := ";"
    Case "Caps":
        keyName := "CapsLock"
    Case "QuotationMark":
        keyName := "'"
    Case "Comma":
        keyName := ","
    Case "Period":
        keyName := "."
    Case "Slash":
        keyName := "/"
    Case "PrtSc":
        keyName := "PrintScreen"
    Case "ScrLk":
        keyName := "ScrollLock"
    Case "Ins":
        keyName := "Insert"
    Case "Del":
        keyName := "Delete"
    Case "Num1":
        keyName := "Numpad1"
    Case "Num2":
        keyName := "Numpad2"
    Case "Num3":
        keyName := "Numpad3"
    Case "Num4":
        keyName := "Numpad4"
    Case "Num5":
        keyName := "Numpad5"
    Case "Num6":
        keyName := "Numpad6"
    Case "Num7":
        keyName := "Numpad7"
    Case "Num8":
        keyName := "Numpad8"
    Case "Num9":
        keyName := "Numpad9"
    Case "Num0":
        keyName := "Numpad0"
    Case "NumPeriod":
        keyName := "NumpadDot"
    Case "NumLk":
        keyName := "NumLock"
    Case "NumEnter":
        keyName := "NumpadEnter"
    Case "NumAdd":
        keyName := "NumpadAdd"
    Case "NumSub":
        keyName := "NumpadSub"
    Case "NumStar":
        keyName := "NumpadMult"
    Case "NumSlash":
        keyName := "NumpadDiv"
    Default:
        keyName := key
    }
    return keyName
}

; 设置托盘图标状态
SetTrayRunningIcon(state){
    ; 编译后从 exe 资源切换；源码运行时直接读取 lib\ui\icons 目录下的图标文件。
    if (A_IsCompiled) {
        try TraySetIcon(A_ScriptFullPath, state ? 3 : 4)
        return
    }
    try TraySetIcon(A_ScriptDir "\lib\ui\icons\" (state ? "icon_green.ico" : "icon_red.ico"))
}

; 启动连发功能
StartAutoFire(){
    global _AutoFireEnableKeys
    global _AutoFireThreads
    AutoFireThreads_StopAll()
    _AutoFireThreads := []
    nowSelectPreset := ResolvePresetName()
    runtimeKeys := AutoFire_LoadRuntimeKeys(nowSelectPreset)
    try enableKeyCount := runtimeKeys.Length
    catch {
        enableKeyCount := 0
    }
    if (enableKeyCount > 0) {
        _AutoFireThreads.Push(SubProcessThread("MainAutoFire", nowSelectPreset))
    }
    StartEx(nowSelectPreset)
    if (_AutoFireThreads.Length = 0) {
        try AutoPresets_OnSessionStopped()
        SetTrayRunningIcon(false)
        return false
    }
    try AutoPresets_OnSessionStarted()
    SetTrayRunningIcon(true)
    ShowTip("连发已启动")
    return true
}

EnterRunningMode(presetName := "") {
    targetPreset := ResolvePresetName(presetName)
    SaveCurrentPresetState()
    LoadMainPresetState(targetPreset)
    HideGuiMain()
    if !StartAutoFire() {
        SwitchToStoppedState()
        gMainGui.Show("w" MainLayout.GuiWidth() " h" MainLayout.GuiHeight())
        SetTimer(MainMutedLinkPoll, 100)
    }
}

StartEx(presetName := ""){
    global _AutoFireThreads
    presetName := ResolvePresetName(presetName)
    exNames := ["LvRen", "GuanYu", "PetSkill", "ZhanFa", "JianZong", "XiuLuo", "AutoRun", "Combo"]
    for exName in exNames {
        if MainCheckboxOn(exName) {
            _AutoFireThreads.Push(SubProcessThread("ExActionRuntime", presetName))
            return
        }
    }
}

; 停止连发功能
StopAutoFire(){
    global _AutoFireThreads
    try AutoPresets_OnSessionStopped()
    AutoFireThreads_StopAll()
    _AutoFireThreads := []
    SetTrayRunningIcon(false)
}

AutoFireThreads_StopAll() {
    global _AutoFireThreads
    try threadCount := _AutoFireThreads.Length
    catch {
        threadCount := 0
    }
    loop threadCount {
        if !_AutoFireThreads.Has(A_Index) {
            continue
        }
        try _AutoFireThreads[A_Index].Stop()
    }
}

; 设置所有关闭连发
SetAllKeysDisable(){
    global _AutoFireEnableKeys
    allKeys := GetAllKeys()
    try allKeyCount := allKeys.Length
    catch {
        allKeyCount := 0
    }
    loop allKeyCount {
        if !allKeys.Has(A_Index) {
            continue
        }
        MainSetKeyState(allKeys[A_Index], false)
    }
    _AutoFireEnableKeys := []
}

; 设置所有按键开启连发
SetAllKeysAutoFire(keys){
    global _AutoFireEnableKeys
    SetAllKeysDisable()
    if !IsObject(keys) {
        return
    }
    try keyCount := keys.Length
    catch {
        keyCount := 0
    }
    loop keyCount {
        if !keys.Has(A_Index) {
            continue
        }
        kName := keys[A_Index]
        MainSetKeyState(kName, true)
        _AutoFireEnableKeys.Push(kName)
    }
}

SaveMainPresetState(presetName) {
    global _AutoFireEnableKeys, _AutoFireKeyIntervals
    presetName := NormalizePresetName(presetName)
    if (presetName = "") {
        return false
    }
    SavePresetKeys(presetName, _AutoFireEnableKeys)
    SavePreset(presetName, "LvRenState", MainGetCtrl("LvRen").Value)
    SavePreset(presetName, "GuanYuState", MainGetCtrl("GuanYu").Value)
    SavePreset(presetName, "PetSkillState", MainGetCtrl("PetSkill").Value)
    SavePreset(presetName, "ZhanFaState", MainGetCtrl("ZhanFa").Value)
    SavePreset(presetName, "JianZongState", MainGetCtrl("JianZong").Value)
    SavePreset(presetName, "XiuLuoState", MainGetCtrl("XiuLuo").Value)
    SavePreset(presetName, "AutoRunState", MainGetCtrl("AutoRun").Value)
    SavePreset(presetName, "ComboState", MainGetCtrl("Combo").Value)
    SaveConfig("AutoPresetsEnabled", MainGetCtrl("AutoPresets").Value ? 1 : 0)
    try {
        SaveAutoFireGlobalIntervalMs(MainGetCtrl("AutoFireIntervalMs").Text)
    } catch {
        SaveAutoFireGlobalIntervalMs(20)
    }
    SavePreset(presetName, "AutoFireKeyIntervals", AutoFireKeyIntervals_MapToString(_AutoFireKeyIntervals))
    return true
}

; 设置当前选择预设名
SetNowSelectPreset(presetName){
    global _NowSelectPreset
    _NowSelectPreset := presetName
}

; 获取当前选择预设名
GetNowSelectPreset(){
    global _NowSelectPreset
    return _NowSelectPreset
}

ResolvePresetName(presetName := "") {
    presetName := NormalizePresetName(presetName = "" ? GetNowSelectPreset() : presetName)
    if (PresetExists(presetName)) {
        return presetName
    }
    fallbackPreset := GetFirstPresetName()
    if (fallbackPreset = "") {
        fallbackPreset := DEFAULT_PRESET_NAME
    }
    return fallbackPreset
}

; 从预设节加载单键连发间隔表到内存（与主界面右键设置共用）
AutoFireKeyIntervals_LoadForPreset(presetName) {
    global _AutoFireKeyIntervals
    presetName := NormalizePresetName(presetName)
    if (presetName = "") {
        _AutoFireKeyIntervals := Map()
        return
    }
    _AutoFireKeyIntervals := AutoFireKeyIntervals_StringToMap(LoadPreset(presetName, "AutoFireKeyIntervals", ""))
}

LoadMainPresetState(presetName) {
    presetName := ResolvePresetName(presetName)
    presetKeys := LoadPresetKeys(presetName)
    SetAllKeysAutoFire(presetKeys)
    SetNowSelectPreset(presetName)
    SaveLastPreset(presetName)
    MainLoadEx()
    MainRefreshPresetUi()
    return presetName
}

SaveCurrentPresetState() {
    return SaveMainPresetState(ResolvePresetName())
}

; 切换预设
ChangePreset(presetName){
    currentPreset := ResolvePresetName()
    targetPreset := ResolvePresetName(presetName)
    if (currentPreset != "") {
        SaveMainPresetState(currentPreset)
    }
    LoadMainPresetState(targetPreset)
}

; 判断数组中是否存在某值
IsValueInArray(value, array){
    if !IsObject(array) {
        return false
    }
    try itemCount := array.Length
    catch {
        itemCount := 0
    }
    loop itemCount
    {
        if !array.Has(A_Index) {
            continue
        }
        if(array[A_Index] == value){
            return true
        }
    }
    return false
}

; 删除数组中的某值
DeleteValueInArray(value, array){
    if !IsObject(array) {
        return
    }
    try itemCount := array.Length
    catch {
        itemCount := 0
    }
    loop itemCount
    {
        if !array.Has(A_Index) {
            continue
        }
        if(array[A_Index] == value){
            array.RemoveAt(A_Index)
            return
        }
    }
}

GAME_WINDOW_TITLES := [
    "地下城与勇士：创新世纪",
    "次元对决"
]

FindDNFGameWindowTitle() {
    global GAME_WINDOW_TITLES
    for t in GAME_WINDOW_TITLES {
        try {
            if WinExist(t)
                return t
        }
    }
    return ""
}

; 提示前切回游戏：按精确客户端标题依次尝试，避免 WinActivate("ahk_group DNF") 命中组内非客户区 HWND（有声但键像未进游戏）。
ActivateDNFBeforeTip() {
    t := FindDNFGameWindowTitle()
    if t {
        try WinActivate(t)
    }
}

ShowTip(text) {
    try SetTimer(ShowTipDisplay, 0)
    try SetTimer(CloseTip, 0)
    global __ShowTipPendingText := text
    SetTimer(ShowTipDisplay, -50)
}

ShowTipDisplay() {
    global __ShowTipPendingText
    text := __ShowTipPendingText
    try ActivateDNFBeforeTip()
    marginX := 16
    marginY := 16
    tipH := 24
    tipW := ShowTipEstimateWidth(text)
    title := FindDNFGameWindowTitle()
    if title {
        try {
            WinGetClientPos(&cx, &cy, &cw, &ch, title)
            tipX := cx + cw - tipW - marginX
            tipY := cy + ch - tipH - marginY
            if (tipX < cx)
                tipX := cx + marginX
            if (tipY < cy)
                tipY := cy + marginY
            ToolTip(text, tipX, tipY)
        } catch {
            ToolTip(text)
        }
    } else {
        ToolTip(text)
    }
    SetTimer(CloseTip, -1000)
}

ShowTipEstimateWidth(text) {
    w := 20
    Loop Parse text {
        w += (Ord(A_LoopField) > 127) ? 15 : 8
    }
    return Max(w, 64)
}

CloseTip(){
    ToolTip()
}

RegisterGameWindowGroup(){
    global GAME_WINDOW_TITLES
    ; DNF 的窗口“类名”(Class)在不同地区/版本可能不同，这里只按精确窗口标题纳入前台判定。
    ; 旧版写法把标题当成 ahk_class，会导致 WinActive("ahk_group DNF") 永远不成立。
    for t in GAME_WINDOW_TITLES {
        GroupAdd("DNF", t)
    }
}
