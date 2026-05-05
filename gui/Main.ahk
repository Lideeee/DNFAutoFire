#Requires AutoHotkey v2.0

global gMainGui := Gui("-MinimizeBox -MaximizeBox -Theme +OwnDialogs")
global gMainCtrls := Map()
global gPresetContextMenu := Menu()
global gPresetBlankContextMenu := Menu()
global gPresetDragStartIndex := 0
global gPresetDragHoverIndex := 0
global gPresetDragDown := false
global gPresetDragPreviewing := false
global gPresetSuppressChange := false
global gPresetDragPreviewList := []
global gPresetDragCurrentFromIndex := 0
global gPresetDragItemName := ""

gMainGui.OnEvent("Escape", MainGuiEscape)
gMainGui.OnEvent("Close", MainGuiClose)
gMainGui.OnEvent("ContextMenu", MainGuiContextMenu)
OnMessage(0x0201, MainPresetListOnLButtonDown)
OnMessage(0x0202, MainPresetListOnLButtonUp)
OnMessage(0x0200, MainPresetListOnMouseMove)

MainAdd(ctrlType, options, text := "") {
    global gMainGui, gMainCtrls
    ; v2：ListBox / DropDownList / ComboBox 初始项须为字符串数组，不能用 ""（会报 Expected an Array）
    if (ctrlType = "ListBox" || ctrlType = "DropDownList" || ctrlType = "ComboBox") && (text = "") {
        ctrl := gMainGui.Add(ctrlType, options, [])
    } else if (ctrlType = "Hotkey" && text = "") {
        ctrl := gMainGui.Add(ctrlType, options)
    } else {
        ctrl := gMainGui.Add(ctrlType, options, text)
    }
    if (ctrl.Name != "") {
        gMainCtrls[ctrl.Name] := ctrl
    }
    return ctrl
}

MainGetCtrl(name) {
    global gMainCtrls
    return gMainCtrls.Has(name) ? gMainCtrls[name] : ""
}

; 不参与连发开关、固定灰色（与 Win 键一致，+Disabled）
MainKeyUiGrayOnly(name) {
    static gray := Map(
        "Esc", true,
        "Tab", true,
        "Caps", true,
        "LShift", true,
        "RShift", true,
        "LCtrl", true,
        "RCtrl", true,
        "LAlt", true,
        "RAlt", true,
    )
    return gray.Has(name)
}

; 主界面「其他功能」复选框是否勾选（供 core/Scripts.ahk 等使用，避免 v1 式未赋值全局变量触发 #Warn）
MainCheckboxOn(name) {
    c := MainGetCtrl(name)
    return IsObject(c) && c.Value
}

gMainGui.Add("GroupBox", "x8 y8 w926 h276", "按键设置 - [ 红色为启用连发 蓝色为关闭连发 ]")
gMainGui.SetFont("s12 cBlue")
for item in [
    ["Esc","x16 y30 w36 h36"],["F1","x90 y30 w36 h36"],["F2","x130 y30 w36 h36"],["F3","x170 y30 w36 h36"],["F4","x210 y30 w36 h36"],["F5","x270 y30 w36 h36"],["F6","x310 y30 w36 h36"],["F7","x350 y30 w36 h36"],["F8","x390 y30 w36 h36"],["F9","x450 y30 w36 h36"],["F10","x490 y30 w36 h36"],["F11","x530 y30 w36 h36"],["F12","x570 y30 w36 h36"],
    ["Tilde","x16 y80 w36 h36","``"],["1","x56 y80 w36 h36"],["2","x96 y80 w36 h36"],["3","x136 y80 w36 h36"],["4","x176 y80 w36 h36"],["5","x216 y80 w36 h36"],["6","x256 y80 w36 h36"],["7","x296 y80 w36 h36"],["8","x336 y80 w36 h36"],["9","x376 y80 w36 h36"],["0","x416 y80 w36 h36"],["Sub","x456 y80 w36 h36","-"],["Add","x496 y80 w36 h36","+"],["Backspace","x536 y80 w70 h36","←"],
    ["Tab","x16 y120 w54 h36"],["Q","x74 y120 w36 h36"],["W","x114 y120 w36 h36"],["E","x154 y120 w36 h36"],["R","x194 y120 w36 h36"],["T","x234 y120 w36 h36"],["Y","x274 y120 w36 h36"],["U","x314 y120 w36 h36"],["I","x354 y120 w36 h36"],["O","x394 y120 w36 h36"],["P","x434 y120 w36 h36"],["LeftBracket","x474 y120 w36 h36","["],["RightBracket","x514 y120 w36 h36","]"],["Backslash","x554 y120 w52 h36","\"],
    ["Caps","x16 y160 w64 h36"],["A","x84 y160 w36 h36"],["S","x124 y160 w36 h36"],["D","x164 y160 w36 h36"],["F","x204 y160 w36 h36"],["G","x244 y160 w36 h36"],["H","x284 y160 w36 h36"],["J","x324 y160 w36 h36"],["K","x364 y160 w36 h36"],["L","x404 y160 w36 h36"],["Semicolon","x444 y160 w36 h36",";"],["QuotationMark","x484 y160 w36 h36","'"],["Enter","x524 y160 w82 h36"],
    ["LShift","x16 y200 w86 h36","Shift"],["Z","x106 y200 w36 h36"],["X","x146 y200 w36 h36"],["C","x186 y200 w36 h36"],["V","x226 y200 w36 h36"],["B","x266 y200 w36 h36"],["N","x306 y200 w36 h36"],["M","x346 y200 w36 h36"],["Comma","x386 y200 w36 h36",","],["Period","x426 y200 w36 h36","."],["Slash","x466 y200 w36 h36","/"],["RShift","x506 y200 w100 h36","Shift"],
    ["LCtrl","x16 y240 w48 h36","Ctrl"],["LAlt","x120 y240 w48 h36","Alt"],["Space","x172 y240 w226 h36"],["RAlt","x402 y240 w48 h36","Alt"],["RCtrl","x558 y240 w48 h36","Ctrl"],
    ["Up","x670 y200 w36 h36","↑"],["Left","x630 y240 w36 h36","←"],["Down","x670 y240 w36 h36","↓"],["Right","x710 y240 w36 h36","→"],
    ["Num0","x770 y240 w76 h36"],["NumPeriod","x850 y240 w36 h36","."],["NumSlash","x810 y80 w36 h36","/"],["NumStar","x850 y80 w36 h36","*"],["NumSub","x890 y80 w36 h36","-"],["NumAdd","x890 y120 w36 h76","+"],
    ["Ins","x630 y70 w36 h36"],["Home","x670 y70 w36 h36"],["PgUp","x710 y70 w36 h36"],["Del","x630 y110 w36 h36"],["End","x670 y110 w36 h36"],["PgDn","x710 y110 w36 h36"],
    ["Num1","x770 y200 w36 h36"],["Num2","x810 y200 w36 h36"],["Num3","x850 y200 w36 h36"],["Num4","x770 y160 w36 h36"],["Num5","x810 y160 w36 h36"],["Num6","x850 y160 w36 h36"],["Num7","x770 y120 w36 h36"],["Num8","x810 y120 w36 h36"],["Num9","x850 y120 w36 h36"],
    ["PrtSc","x630 y30 w36 h36"],["ScrLk","x670 y30 w36 h36"],["Pause","x710 y30 w36 h36"],["NumEnter","x890 y200 w36 h76","`n`n`nNum`nEnter"],["NumLk","x770 y80 w36 h36"]
] {
    name := item[1], pos := item[2], label := item.Length >= 3 ? item[3] : name
    fontSize := (name = "PrtSc" || name = "ScrLk" || name = "Pause" || name = "NumEnter" || name = "NumLk") ? "s7" : ((name ~= "^(Ins|Home|PgUp|Del|End|PgDn|Num[1-9])$") ? "s9" : "s12")
    if MainKeyUiGrayOnly(name) {
        gMainGui.SetFont(fontSize)
        ctrl := MainAdd("Text", "v" name " " pos " +0x200 +0x400000 +Center +Disabled", label)
    } else {
        gMainGui.SetFont(fontSize " cBlue")
        ctrl := MainAdd("Text", "v" name " " pos " +0x200 +0x400000 +Center", label)
        ctrl.OnEvent("Click", MainKeyClick)
    }
}
gMainGui.SetFont()

gMainGui.Add("Text", "x68 y240 w48 h36 +0x200 +0x400000 +Center +Disabled", "Win")
gMainGui.Add("Text", "x454 y240 w48 h36 +0x200 +0x400000 +Center +Disabled", "Fn")
gMainGui.Add("Text", "x506 y240 w48 h36 +0x200 +0x400000 +Center +Disabled", "App")

gMainGui.SetFont("s9")
MainAdd("Text", "vMainVersionText x770 y30 w112 h42", "版本信息：`nv" __Version "`n原作者：某亚瑟")
MainAdd("Button", "vMainClear x890 y30 w36 h36 +0x200 +Center", "清空").OnEvent("Click", MainClear)
gMainGui.SetFont()

gMainGui.Add("GroupBox", "x8 y300 w340 h200", "配置设置 - [ 单击切换配置，右键配置列表管理 ]")
MainAdd("ListBox", "vPreset x16 y320 w150 h180")
MainGetCtrl("Preset").OnEvent("Change", MainChangeListPreset)
gMainGui.Add("Text", "x174 y320 w150 h24 +0x200", "当前配置名称：")
MainAdd("Edit", "vPresetNameEdit x174 y344 w150 h22 +ReadOnly")

gMainGui.Add("Text", "x174 y370 w150 h24 +0x200", "连发间隔(ms)")
ctrlInterval := MainAdd("Edit", "vMainAutoFireInterval x174 y394 w150 h20 +Number")
ctrlInterval.OnEvent("Change", MainSaveAutoFireInterval)
ctrlInterval.OnEvent("LoseFocus", MainCommitAutoFireInterval)

gMainGui.Add("Text", "x174 y420 w150 h24 +0x200", "快速切换热键")
MainAdd("Hotkey", "vQuickChangeHotKey x174 y444 w150 h20").OnEvent("Change", MainSaveQuickChangeHotKey)

MainAdd("Button", "vMainSetting x838 y305 w96 h60", "软件设置").OnEvent("Click", MainSetting)
MainAdd("Button", "vMainCheckUpdate x838 y372 w96 h60", "检查更新").OnEvent("Click", MainCheckUpdate)
MainAdd("Button", "vMainStart x838 y440 w96 h60", "启动连发").OnEvent("Click", MainStart)

; 右缘与按钮左缘间距 8px，与左侧 GroupBox 到窗口左缘间距一致（按钮 x838）
gMainGui.Add("GroupBox", "x356 y300 w474 h200", "其他功能")
MainAdd("CheckBox", "vLvRen x364 y320 h20 w16").OnEvent("Click", MainSaveExToggle)
MainAdd("Link", "vMainLvRen x382 y323 h20", "<a>旅人自动流星</a>").OnEvent("Click", MainLvRen)
MainAdd("CheckBox", "vGuanYu x364 y340 h20 w16").OnEvent("Click", MainSaveExToggle)
MainAdd("Link", "vMainGuanYu x382 y343 h20", "<a>关羽自动猛攻</a>").OnEvent("Click", MainGuanYu)
MainAdd("CheckBox", "vJianZong x364 y360 h20 w16").OnEvent("Click", MainSaveExToggle)
MainAdd("Link", "vMainJianZong x382 y363 h20", "<a>太宗帝剑延迟</a>").OnEvent("Click", MainJianZong)
MainAdd("CheckBox", "vZhanFa x364 y380 h20 w16").OnEvent("Click", MainSaveExToggle)
MainAdd("Link", "vMainZhanFa x382 y383 h20", "<a>战法自动炫纹</a>").OnEvent("Click", MainZhanFa)
MainAdd("CheckBox", "vPetSkill x364 y400 h20 w16").OnEvent("Click", MainSaveExToggle)
MainAdd("Link", "vMainPetSkill x382 y403 h20", "<a>自动宠物技能</a>").OnEvent("Click", MainPetSkill)
MainAdd("CheckBox", "vAutoRun x364 y420 h20 w16").OnEvent("Click", MainSaveExToggle)
MainAdd("Link", "vMainAutoRun x382 y423 h20", "<a>自动奔跑</a>").OnEvent("Click", MainAutoRun)
MainAdd("CheckBox", "vCombo x364 y440 h20 w16").OnEvent("Click", MainSaveExToggle)
MainAdd("Link", "vMainCombo x382 y443 h20", "<a>一键连招</a>").OnEvent("Click", MainCombo)
MainAdd("Link", "vMainPresetSkill x364 y480 w400 h18", "<a>自动识别配置（需在软件设置中开启自动识别）</a>").OnEvent("Click", MainPresetSkill)

gPresetContextMenu.Add("新建配置", MainCreatePreset)
gPresetContextMenu.Add("重命名配置", MainRenamePreset)
gPresetContextMenu.Add("克隆配置", MainClonePreset)
gPresetContextMenu.Add("删除配置", MainDeletePreset)
gPresetBlankContextMenu.Add("新建配置", MainCreatePreset)

ShowGuiMain(*) {
    global gMainGui
    try PresetRecognition_CancelPending()
    gMainGui.Title := "DAF连发工具 - DNF AutoFire"
    gMainGui.Show("w940 h510")
    MainLoadAllPreset()
    MainLoatQuickChangeHotKey()
}

HideGuiMain(*) {
    global gMainGui
    try PresetRecognition_CancelPending()
    gMainGui.Hide()
}

MainGuiEscape(*) {
    HideGuiMain()
}

MainGuiClose(*) {
    HideGuiMain()
}

DisableGuiMain() {
    global gMainGui
    gMainGui.Opt("+Disabled")
}

EnableGuiMain() {
    global gMainGui
    gMainGui.Opt("-Disabled")
    gMainGui.Title := "DAF连发工具 - DNF AutoFire - v" __Version "（原作者：某亚瑟）"
    gMainGui.Show("w940 h518")
}

MainSetKeyState(key, state) {
    if MainKeyUiGrayOnly(key) {
        return
    }
    ctrl := MainGetCtrl(key)
    if !IsObject(ctrl) {
        return
    }
    color := state ? "cRed" : "cBlue"
    weight := state ? "Bold" : "Norm"
    size := "s12"
    if (key = "PrtSc" || key = "ScrLk" || key = "Pause" || key = "NumEnter" || key = "NumLk") {
        size := "s7"
    } else if (key ~= "^(Ins|Home|PgUp|Del|End|PgDn|Num[1-9])$") {
        size := "s9"
    }
    ctrl.SetFont(size " " color " " weight)
}

MainKeyClick(ctrl, *) {
    ChangeKeyAutoFireState(ctrl.Name)
    MainSaveCurrentPreset()
}

MainStart(*) {
    HideGuiMain()
    StartAutoFire()
    try PresetRecognition_StartSequence()
}

MainClear(*) {
    SetAllKeysDisable()
    MainSaveCurrentPreset()
}

MainClonePreset(*) {
    oldName := MainGetCtrl("Preset").Text
    if (oldName = "") {
        MsgBox("请选择有效的配置",, "Icon!")
        return
    }
    defaultName := oldName "-克隆"
    newName := MainAskPresetName("请输入克隆后的配置名称", "克隆配置", defaultName)
    if (newName = "") {
        return
    }
    if MainPresetExists(newName) {
        MsgBox("配置名称已存在",, "Icon!")
        return
    }
    config := IniRead(ConfigIniPath(), "预设:" oldName)
    IniWrite(config, ConfigIniPath(), "预设:" newName)
    PresetSkillIcon_CopyForPreset(oldName, newName)
    presetList := LoadAllPreset()
    if !IsValueInArray(newName, presetList) {
        presetList.Push(newName)
    }
    SavePresetOrder(presetList)
    SetNowSelectPreset(newName)
    MainLoadAllPreset()
}

MainDeletePreset(*) {
    presetName := MainGetCtrl("Preset").Text
    if (presetName = "") {
        MsgBox("请选择有效的配置",, "Icon!")
        return
    }
    if (LoadAllPreset().Length <= 1) {
        MsgBox("至少保留一个配置",, "Icon!")
        return
    }
    ret := MsgBox("确定删除配置：" presetName "？", "删除配置", "YesNo Icon!")
    if (ret != "Yes") {
        return
    }
    PresetSkillIcon_DeleteForPreset(presetName)
    DeletePreset(presetName)
    presetList := LoadAllPreset()
    DeleteValueInArray(presetName, presetList)
    SavePresetOrder(presetList)
    if (presetList.Length > 0) {
        SetNowSelectPreset(presetList[1])
    }
    MainLoadAllPreset()
}

MainSetListBox(ctrl, listPipe) {
    ctrl.Delete()
    for item in StrSplit(listPipe, "|") {
        if (item != "") {
            ctrl.Add([item])
        }
    }
}

MainSetListBoxFromArray(ctrl, items) {
    ctrl.Delete()
    if !IsObject(items) {
        return
    }
    loop items.Length {
        if !items.Has(A_Index) {
            continue
        }
        item := items[A_Index]
        if (item != "") {
            ctrl.Add([item])
        }
    }
}

; 与 pipe 字符串一致计数；部分环境下 ListBox.GetCount() 不可靠，勿单独依赖
MainPresetCountFromPipe(pipe) {
    n := 0
    for x in StrSplit(pipe, "|") {
        if (x != "") {
            n++
        }
    }
    return n
}

MainPresetListSafeChoose(ctrl, index, presetListPipe) {
    n := MainPresetCountFromPipe(presetListPipe)
    if (n < 1 || index < 1 || index > n) {
        return false
    }
    try {
        ctrl.Choose(index)
        return true
    } catch {
        return false
    }
}

MainLoadAllPreset() {
    StopAutoFire()
    presetCtrl := MainGetCtrl("Preset")
    presetNameCtrl := MainGetCtrl("PresetNameEdit")
    presetList := LoadAllPresetString()
    nowSelectPreset := GetNowSelectPreset()
    MainSetListBox(presetCtrl, presetList)
    presetNameCtrl.Text := nowSelectPreset

    idx := 0
    presetItems := StrSplit(presetList, "|")
    loop presetItems.Length {
        if !presetItems.Has(A_Index) {
            continue
        }
        if (presetItems[A_Index] = nowSelectPreset) {
            idx := A_Index
            break
        }
    }

    if (idx > 0) {
        if MainPresetListSafeChoose(presetCtrl, idx, presetList) {
            ChangePreset(nowSelectPreset)
            presetNameCtrl.Text := nowSelectPreset
        }
    } else if MainPresetListSafeChoose(presetCtrl, 1, presetList) {
        presetName := presetCtrl.Text
        ChangePreset(presetName)
        presetNameCtrl.Text := presetName
    }
}

MainSetting(*) {
    ShowGuiSetting()
}

MainOpenSettingAbout(*) {
    ShowGuiSettingAbout()
}

MainCheckUpdate(*) {
    postUrl := "https://github.com/Lideeee/DNFAutoFire"
    try Run(postUrl)
    catch {
        MsgBox("打开链接失败，请手动访问：`n" postUrl,, "Icon!")
    }
}

MainSaveEx() {
    presetName := GetNowSelectPreset()
    if (presetName = "") {
        return
    }
    SavePreset(presetName, "LvRenState", MainGetCtrl("LvRen").Value)
    SavePreset(presetName, "GuanYuState", MainGetCtrl("GuanYu").Value)
    SavePreset(presetName, "PetSkillState", MainGetCtrl("PetSkill").Value)
    SavePreset(presetName, "ZhanFaState", MainGetCtrl("ZhanFa").Value)
    SavePreset(presetName, "JianZongState", MainGetCtrl("JianZong").Value)
    SavePreset(presetName, "AutoRunState", MainGetCtrl("AutoRun").Value)
    SavePreset(presetName, "ComboState", MainGetCtrl("Combo").Value)
    SavePreset(presetName, "MainAutoFireInterval", MainNormalizeAutoFireInterval())
}

MainLoadEx() {
    MainGetCtrl("LvRen").Value := LoadPreset(GetNowSelectPreset(), "LvRenState", false)
    MainGetCtrl("GuanYu").Value := LoadPreset(GetNowSelectPreset(), "GuanYuState", false)
    MainGetCtrl("PetSkill").Value := LoadPreset(GetNowSelectPreset(), "PetSkillState", false)
    MainGetCtrl("ZhanFa").Value := LoadPreset(GetNowSelectPreset(), "ZhanFaState", false)
    MainGetCtrl("JianZong").Value := LoadPreset(GetNowSelectPreset(), "JianZongState", false)
    MainGetCtrl("AutoRun").Value := LoadPreset(GetNowSelectPreset(), "AutoRunState", false)
    MainGetCtrl("Combo").Value := LoadPreset(GetNowSelectPreset(), "ComboState", false)
    MainGetCtrl("MainAutoFireInterval").Text := LoadPreset(GetNowSelectPreset(), "MainAutoFireInterval", 20)
    MainNormalizeAutoFireInterval()
}

MainNormalizeAutoFireInterval() {
    ctrl := MainGetCtrl("MainAutoFireInterval")
    raw := Trim(ctrl.Text)
    n := Round((raw = "" ? 20 : raw) + 0)
    if (n < 1) {
        n := 1
    } else if (n > 200) {
        n := 200
    }
    ctrl.Text := n
    return n
}

MainSaveAutoFireInterval(*) {
    presetName := GetNowSelectPreset()
    if (presetName = "") {
        return
    }
    ctrl := MainGetCtrl("MainAutoFireInterval")
    raw := Trim(ctrl.Text)
    if (raw = "") {
        return
    }
    n := Round(raw + 0)
    if (n < 1) {
        n := 1
    } else if (n > 200) {
        n := 200
    }
    SavePreset(presetName, "MainAutoFireInterval", n)
}

MainCommitAutoFireInterval(*) {
    presetName := GetNowSelectPreset()
    if (presetName = "") {
        return
    }
    SavePreset(presetName, "MainAutoFireInterval", MainNormalizeAutoFireInterval())
}

MainLvRen(*) {
    ShowGuiLvRen()
}

MainGuanYu(*) {
    ShowGuiGuanYu()
}

MainPetSkill(*) {
    ShowGuiPetSkill()
}

MainZhanFa(*) {
    ShowGuiZhanFa()
}

MainJianZong(*) {
    ShowGuiJianZong()
}

MainAutoRun(*) {
    ShowGuiAutoRun()
}

MainCombo(*) {
    ShowGuiCombo()
}

MainChangeListPreset(*) {
    global gPresetSuppressChange, gPresetDragPreviewing
    if (gPresetSuppressChange || gPresetDragPreviewing) {
        return
    }
    presetName := MainGetCtrl("Preset").Text
    if (presetName = "") {
        return
    }
    MainGetCtrl("PresetNameEdit").Text := presetName
    ChangePreset(presetName)
}

MainSaveExToggle(*) {
    MainSaveEx()
}

MainSaveCurrentPreset() {
    global _AutoFireEnableKeys
    presetName := GetNowSelectPreset()
    if (presetName = "") {
        return
    }
    SavePresetKeys(presetName, _AutoFireEnableKeys)
    MainSaveEx()
}

MainGuiContextMenu(guiObj, ctrlObj, item, isRightClick, x, y) {
    global gPresetContextMenu, gPresetBlankContextMenu
    if !IsObject(ctrlObj) || ctrlObj.Name != "Preset" {
        return
    }
    idx := MainPresetListIndexFromCursor(ctrlObj)
    if (idx > 0) {
        ctrlObj.Choose(idx)
    }
    if (x != "" && y != "") {
        if (idx > 0) {
            gPresetContextMenu.Show(x, y)
        } else {
            gPresetBlankContextMenu.Show(x, y)
        }
    } else {
        if (idx > 0) {
            gPresetContextMenu.Show()
        } else {
            gPresetBlankContextMenu.Show()
        }
    }
}

MainCreatePreset(*) {
    name := MainAskPresetName("请输入新配置名称", "新建配置")
    if (name = "") {
        return
    }
    if MainPresetExists(name) {
        MsgBox("配置名称已存在",, "Icon!")
        return
    }
    MainInitPreset(name)
    presetList := LoadAllPreset()
    if !IsValueInArray(name, presetList) {
        presetList.Push(name)
    }
    SavePresetOrder(presetList)
    SetNowSelectPreset(name)
    MainLoadAllPreset()
}

MainRenamePreset(*) {
    oldName := MainGetCtrl("Preset").Text
    if (oldName = "") {
        MsgBox("请选择有效的配置",, "Icon!")
        return
    }
    newName := MainAskPresetName("请输入新的配置名称", "重命名配置", oldName)
    if (newName = "" || newName = oldName) {
        return
    }
    if MainPresetExists(newName) {
        MsgBox("配置名称已存在",, "Icon!")
        return
    }
    config := IniRead(ConfigIniPath(), "预设:" oldName)
    IniWrite(config, ConfigIniPath(), "预设:" newName)
    DeletePreset(oldName)
    presetList := LoadAllPreset()
    loop presetList.Length {
        if !presetList.Has(A_Index) {
            continue
        }
        if (presetList[A_Index] = oldName) {
            presetList[A_Index] := newName
            break
        }
    }
    SavePresetOrder(presetList)
    SetNowSelectPreset(newName)
    MainLoadAllPreset()
}

MainAskPresetName(prompt, title, default := "") {
    ib := InputBox(prompt, title, "w280 h140", default)
    if (ib.Result != "OK") {
        return ""
    }
    name := Trim(ib.Value)
    if (name = "") {
        MsgBox("配置名称不能为空",, "Icon!")
        return ""
    }
    if InStr(name, "|") {
        MsgBox("配置名称不能包含 | 字符",, "Icon!")
        return ""
    }
    return name
}

MainPresetExists(name) {
    return IsValueInArray(name, LoadAllPreset())
}

MainInitPreset(name) {
    SavePreset(name, "keys", "")
    SavePreset(name, "LvRenState", false)
    SavePreset(name, "GuanYuState", false)
    SavePreset(name, "PetSkillState", false)
    SavePreset(name, "ZhanFaState", false)
    SavePreset(name, "JianZongState", false)
    SavePreset(name, "AutoRunState", false)
    SavePreset(name, "ComboState", false)
    SavePreset(name, "MainAutoFireInterval", 20)
    SavePreset(name, "ComboTriggerKey", "")
    SavePreset(name, "ComboLoopMode", false)
    SavePreset(name, "ComboSkills", "")
}

MainSaveQuickChangeHotKey(*) {
    global __QuickSwitchHotkey
    quickChangeHotKey := MainGetCtrl("QuickChangeHotKey").Value
    quickChangeHotKeyConfig := LoadConfig("QuickChangeHotKey")
    if (quickChangeHotKeyConfig = "") {
        quickChangeHotKeyConfig := "!``"
    }
    try Hotkey("~$" quickChangeHotKeyConfig, "Off")
    SaveConfig("QuickChangeHotKey", quickChangeHotKey)
    __QuickSwitchHotkey := "~$" quickChangeHotKey
    Hotkey(__QuickSwitchHotkey, ShowGuiQuickSwitch, "On")
}

MainLoatQuickChangeHotKey() {
    global __QuickSwitchHotkey
    quickChangeHotKey := LoadConfig("QuickChangeHotKey")
    if (quickChangeHotKey = "") {
        quickChangeHotKey := "!``"
    }
    __QuickSwitchHotkey := "~$" quickChangeHotKey
    Hotkey(__QuickSwitchHotkey, ShowGuiQuickSwitch, "On")
    MainGetCtrl("QuickChangeHotKey").Value := quickChangeHotKey
}

MainPresetListIndexFromClientPoint(ctrl, x, y) {
    if !IsObject(ctrl) {
        return 0
    }
    if (x = "" || y = "") {
        return 0
    }
    lp := (y << 16) | (x & 0xFFFF)
    ret := DllCall("SendMessage", "ptr", ctrl.Hwnd, "uint", 0x01A9, "ptr", 0, "ptr", lp, "ptr")
    outside := (ret >> 16) & 0xFFFF
    idx0 := ret & 0xFFFF
    if (outside != 0 || idx0 = 0xFFFF) {
        return 0
    }
    return idx0 + 1
}

MainPresetListIndexFromScreenPoint(ctrl, sx, sy) {
    if !IsObject(ctrl) {
        return 0
    }
    if (sx = "" || sy = "") {
        return 0
    }
    pt := Buffer(8, 0)
    NumPut("int", sx, pt, 0)
    NumPut("int", sy, pt, 4)
    DllCall("ScreenToClient", "ptr", ctrl.Hwnd, "ptr", pt)
    cx := NumGet(pt, 0, "int")
    cy := NumGet(pt, 4, "int")
    return MainPresetListIndexFromClientPoint(ctrl, cx, cy)
}

MainPresetListIndexFromCursor(ctrl) {
    if !IsObject(ctrl) {
        return 0
    }
    pt := Buffer(8, 0)
    if !DllCall("GetCursorPos", "ptr", pt) {
        return 0
    }
    sx := NumGet(pt, 0, "int")
    sy := NumGet(pt, 4, "int")
    return MainPresetListIndexFromScreenPoint(ctrl, sx, sy)
}

MainMovePresetOrder(fromIndex, toIndex) {
    if (fromIndex <= 0 || toIndex <= 0 || fromIndex = toIndex) {
        return
    }
    presetList := LoadAllPreset()
    newIndex := MainMoveArrayItemInPlace(presetList, fromIndex, toIndex)
    if (newIndex <= 0) {
        return
    }
    movingName := presetList[newIndex]
    SavePresetOrder(presetList)
    SetNowSelectPreset(movingName)
    MainLoadAllPreset()
}

MainMoveArrayItemInPlace(arr, fromIndex, toIndex) {
    if !IsObject(arr) {
        return 0
    }
    if (fromIndex <= 0 || toIndex <= 0 || fromIndex > arr.Length || toIndex > arr.Length) {
        return 0
    }
    if (fromIndex = toIndex) {
        return fromIndex
    }
    movingName := arr[fromIndex]
    arr.RemoveAt(fromIndex)
    ; 预览/拖放语义：鼠标指到哪一项就放到哪一项（不做下移减一修正）
    if (toIndex < 1) {
        toIndex := 1
    } else if (toIndex > arr.Length + 1) {
        toIndex := arr.Length + 1
    }
    arr.InsertAt(toIndex, movingName)
    return toIndex
}

MainPresetListOnLButtonDown(wParam, lParam, msg, hwnd) {
    global gPresetDragStartIndex, gPresetDragHoverIndex, gPresetDragDown, gPresetDragPreviewing
    global gPresetDragPreviewList, gPresetDragCurrentFromIndex, gPresetDragItemName
    presetCtrl := MainGetCtrl("Preset")
    if !IsObject(presetCtrl) || hwnd != presetCtrl.Hwnd {
        return
    }
    x := lParam & 0xFFFF
    y := (lParam >> 16) & 0xFFFF
    gPresetDragStartIndex := MainPresetListIndexFromClientPoint(presetCtrl, x, y)
    gPresetDragHoverIndex := gPresetDragStartIndex
    gPresetDragDown := (gPresetDragStartIndex > 0)
    gPresetDragPreviewing := false
    gPresetDragPreviewList := []
    gPresetDragCurrentFromIndex := gPresetDragStartIndex
    gPresetDragItemName := ""
    if gPresetDragDown {
        gPresetDragPreviewList := LoadAllPreset()
        if (gPresetDragStartIndex <= gPresetDragPreviewList.Length) {
            gPresetDragItemName := gPresetDragPreviewList[gPresetDragStartIndex]
        }
    }
}

MainPresetListOnLButtonUp(wParam, lParam, msg, hwnd) {
    global gPresetDragStartIndex, gPresetDragHoverIndex, gPresetDragDown, gPresetDragPreviewing
    global gPresetDragPreviewList, gPresetDragCurrentFromIndex, gPresetDragItemName, gPresetSuppressChange
    presetCtrl := MainGetCtrl("Preset")
    if !IsObject(presetCtrl) || hwnd != presetCtrl.Hwnd {
        return
    }
    previewing := gPresetDragPreviewing
    movedName := gPresetDragItemName
    previewList := gPresetDragPreviewList
    gPresetDragStartIndex := 0
    gPresetDragHoverIndex := 0
    gPresetDragDown := false
    gPresetDragPreviewing := false
    gPresetDragPreviewList := []
    gPresetDragCurrentFromIndex := 0
    gPresetDragItemName := ""
    if !previewing {
        return
    }
    SavePresetOrder(previewList)
    if (movedName != "") {
        SetNowSelectPreset(movedName)
    }
    gPresetSuppressChange := true
    MainLoadAllPreset()
    gPresetSuppressChange := false
}

MainPresetListOnMouseMove(wParam, lParam, msg, hwnd) {
    global gPresetDragStartIndex, gPresetDragHoverIndex, gPresetDragDown, gPresetDragPreviewing, gPresetSuppressChange
    global gPresetDragPreviewList, gPresetDragCurrentFromIndex
    if !gPresetDragDown {
        return
    }
    presetCtrl := MainGetCtrl("Preset")
    if !IsObject(presetCtrl) || hwnd != presetCtrl.Hwnd {
        return
    }
    if (gPresetDragStartIndex <= 0) {
        return
    }
    x := lParam & 0xFFFF
    y := (lParam >> 16) & 0xFFFF
    hoverIndex := MainPresetListIndexFromClientPoint(presetCtrl, x, y)
    if (hoverIndex <= 0) {
        return
    }
    if !IsObject(gPresetDragPreviewList) || gPresetDragPreviewList.Length = 0 {
        return
    }
    fromIndex := gPresetDragCurrentFromIndex
    if (fromIndex <= 0 || fromIndex > gPresetDragPreviewList.Length) {
        return
    }
    if (hoverIndex > gPresetDragPreviewList.Length || hoverIndex = fromIndex) {
        return
    }
    gPresetDragPreviewing := true
    gPresetDragHoverIndex := hoverIndex
    newIndex := MainMoveArrayItemInPlace(gPresetDragPreviewList, fromIndex, hoverIndex)
    if (newIndex <= 0) {
        return
    }
    gPresetDragCurrentFromIndex := newIndex
    ; 拖拽过程中预览“换序后的完整结果”，松开后再真正保存
    gPresetSuppressChange := true
    MainSetListBoxFromArray(presetCtrl, gPresetDragPreviewList)
    try presetCtrl.Choose(newIndex)
    gPresetSuppressChange := false
}
