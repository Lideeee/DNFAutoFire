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
            _AutoFireEnableKeys.Delete(needDeleteIndex)
        }
        MainSetKeyState(key, false)
        SetOriginalDirect(key)
    } else {
        _AutoFireEnableKeys.Push(key)
        MainSetKeyState(key, true)
        SetOriginalBlocking(key)
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

; 按用户要求：不屏蔽原键。保留函数是为了兼容现有调用点。
SetOriginalBlocking(key){
    return
}

; 不屏蔽原键时，无需恢复操作
SetOriginalDirect(key){
    return
}

; 设置托盘图标状态
SetTrayRunningIcon(state){
    ; v2 兼容：编译后从当前 exe 资源切换托盘图标索引
    try TraySetIcon(A_ScriptFullPath, state ? 3 : 4)
}

; 启动连发功能
StartAutoFire(){
    global _AutoFireEnableKeys
    global _AutoFireThreads
    global _AutoFireSingleProcessTimers
    global _AutoFireTimeUnlocked
    if (!IsSet(_AutoFireTimeUnlocked)) {
        _AutoFireTimeUnlocked := false
    }
    intervalMs := Round(LoadPreset(GetNowSelectPreset(), "MainAutoFireInterval", 20) + 0)
    if (intervalMs < 1) {
        intervalMs := 1
    } else if (intervalMs > 200) {
        intervalMs := 200
    }
    ; 提升定时器精度，降低高频连发的抖动/卡顿
    if (!_AutoFireTimeUnlocked) {
        try UnlockSystemTimeLimit()
        _AutoFireTimeUnlocked := true
    }
    _AutoFireThreads := []
    _AutoFireSingleProcessTimers := []
    try enableKeyCount := _AutoFireEnableKeys.Length
    catch {
        enableKeyCount := 0
    }
    loop enableKeyCount {
        if !_AutoFireEnableKeys.Has(A_Index) {
            continue
        }
        afKey := _AutoFireEnableKeys[A_Index]
        SetOriginalBlocking(afKey)
        originKey := GetOriginKeyName(afKey)
        fn := AutoFireSingleKeyTick.Bind(Key2PressKey(originKey), Key2NoVkSC(originKey))
        _AutoFireSingleProcessTimers.Push(fn)
        SetTimer(fn, intervalMs)
    }
    Sleep(10)
    StartEx()
    SetTrayRunningIcon(true)
    nowSelectPreset := GetNowSelectPreset()
    ShowTip("连发已启动 - " . nowSelectPreset)
}

StartEx(){
    global _AutoFireThreads
    if MainCheckboxOn("LvRen") {
        _AutoFireThreads.Push(SubProcessThread("ExLvRen"))
    }
    if MainCheckboxOn("GuanYu") {
        _AutoFireThreads.Push(SubProcessThread("ExGuanYu"))
    }
    if MainCheckboxOn("PetSkill") {
        _AutoFireThreads.Push(SubProcessThread("ExPetSkill"))
    }
    if MainCheckboxOn("ZhanFa") {
        _AutoFireThreads.Push(SubProcessThread("ExZhanFa"))
    }
    if MainCheckboxOn("JianZong") {
        skillKey := LoadPreset(GetNowSelectPreset(), "JianZongSkillKey")
        SetOriginalBlocking(skillKey)
        _AutoFireThreads.Push(SubProcessThread("ExJianZong"))
    }
    if MainCheckboxOn("AutoRun") {
        _AutoFireThreads.Push(SubProcessThread("ExAutoRun"))
    }
    if MainCheckboxOn("Combo") {
        _AutoFireThreads.Push(SubProcessThread("ExCombo"))
    }
}

; 停止连发功能
StopAutoFire(){
    global _AutoFireThreads
    global _AutoFireSingleProcessTimers
    global _AutoFireTimeUnlocked
    allKeys := GetAllKeys()
    try allKeyCount := allKeys.Length
    catch {
        allKeyCount := 0
    }
    loop allKeyCount {
        if !allKeys.Has(A_Index) {
            continue
        }
        SetOriginalDirect(allKeys[A_Index])
    }
    try timerCount := _AutoFireSingleProcessTimers.Length
    catch {
        timerCount := 0
    }
    loop timerCount {
        if !_AutoFireSingleProcessTimers.Has(A_Index) {
            continue
        }
        SetTimer(_AutoFireSingleProcessTimers[A_Index], 0)
    }
    _AutoFireSingleProcessTimers := []
    _AutoFireThreads := []
    SetTrayRunningIcon(false)
    ; 恢复系统计时精度（避免长期占用 1ms period）
    if (IsSet(_AutoFireTimeUnlocked) && _AutoFireTimeUnlocked) {
        try RestoreSystemTimeLimit()
        _AutoFireTimeUnlocked := false
    }
}

; 单进程多定时器：每个键独立 tick，避免多个键串行争用
AutoFireSingleKeyTick(pressKey, keyCode) {
    ; 仅在游戏窗口激活时发送，避免切出游戏后仍然连发
    if !WinActive("ahk_group DNF") {
        return
    }
    ; 定时器高频执行时可能重入；重入会破坏同键 Down/Up 配对并诱发卡键
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

; 切换预设
ChangePreset(presetName){
    StopAutoFire()
    presetKeys := LoadPresetKeys(presetName)
    SetAllKeysAutoFire(presetKeys)
    SetNowSelectPreset(presetName)
    SaveLastPreset(presetName)
    MainLoadEx()
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
    if(IsValueInArray(value, array)){
        needDeleteIndex := 0
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
                needDeleteIndex := A_Index
            }
        }
        if (needDeleteIndex > 0) {
            array.Delete(needDeleteIndex)
        }
    }
}

ShowTip(text){
    ToolTip(text)
    SetTimer(CloseTip, -3000)
    ; 只尝试激活标题匹配，避免把标题当成 ahk_class
    try WinActivate("地下城与勇士")
}

CloseTip(){
    ToolTip()
}

SetDNFWindowClass(){
    ; DNF 的窗口“类名”(Class)在不同地区/版本可能不同，但窗口标题与进程名更稳定。
    ; 旧版写法把标题当成 ahk_class，会导致 WinActive("ahk_group DNF") 永远不成立。
    ;
    ; 1) 标题匹配（不加 ahk_class/ahk_exe 前缀时，默认按标题匹配）
    GroupAdd("DNF", "地下城与勇士")
    GroupAdd("DNF", "Dungeon & Fighter")
    GroupAdd("DNF", "Dungeon Fighter Online")
    ; 次元对决（独立客户端）
    GroupAdd("DNF", "次元对决")
    ;
    ; 2) 进程匹配（尽量覆盖常见命名；如果你的进程名不同，后面我再按诊断结果补）
    GroupAdd("DNF", "ahk_exe dnf.exe")
    GroupAdd("DNF", "ahk_exe DNF.exe")
    GroupAdd("DNF", "ahk_exe DungeonFighter.exe")
    GroupAdd("DNF", "ahk_exe DFO.exe")
    GroupAdd("DNF", "ahk_exe DNF_SGM.exe")
}