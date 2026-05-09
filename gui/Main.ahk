#Requires AutoHotkey v2.0

#Include ./MainWindow.ahk

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
global gKeyIntervalMenu := Menu()
global gKeyIntervalMenuTarget := ""
global gMainMutedLinks := []
global __QuickSwitchHotkey := ""

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
    if (ctrlType = "ListBox") {
        try GuiTheme_RegisterListBoxWheel(ctrl)
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
    )
    return gray.Has(name)
}

; 主界面「其他功能」开关是否开启（隐藏 CheckBox 存状态，供 GUI 自绘与 INI 同步；业务层用 PresetExFeatures.IsOn）
MainCheckboxOn(name) {
    c := MainGetCtrl(name)
    if !IsObject(c) {
        return false
    }
    try {
        return Integer(c.Value) = 1
    } catch {
        return false
    }
}

MainAddExFeatureRow(name, colX, y, toggleW, linkW, linkText, linkHandler) {
    global gMainGui, gMainExSwitchUi
    swH := 20
    ui := ToggleGdip(gMainGui, colX, y + 1, toggleW, swH)
    gMainExSwitchUi[name] := ui
    ui.OnClick(MainExSwitchClick.Bind(name))
    lx := colX + toggleW + 8
    t := MainAdd("Text", "vMainExLink_" name " x" lx " y" y " w" linkW " h22 +0x200 +0x100", linkText)
    t.OnEvent("Click", linkHandler)
    MainMutedLinkRegister(t)
}

MainExSwitchClick(name, *) {
    cb := MainGetCtrl(name)
    if !IsObject(cb) {
        return
    }
    cb.Value := MainCheckboxOn(name) ? 0 : 1
    MainExSwitchPaint(name)
    MainSaveExToggle()
}

MainExSwitchPaint(name) {
    global gMainExSwitchUi
    if !gMainExSwitchUi.Has(name) {
        return
    }
    ui := gMainExSwitchUi[name]
    if !IsObject(MainGetCtrl(name)) {
        return
    }
    if HasMethod(ui, "Draw") {
        ui.Draw(MainCheckboxOn(name))
        return
    }
    GuiTheme_FlatSwitchPaint(ui, MainCheckboxOn(name))
}

MainExSwitchPaintAll(*) {
    global G_MAIN_EX_SWITCH_NAMES
    for name in G_MAIN_EX_SWITCH_NAMES {
        MainExSwitchPaint(name)
    }
}

MainMutedLinkRegister(ctrl) {
    global gMainMutedLinks
    if !IsObject(ctrl) {
        return
    }
    ctrl.SetFont("s10 norm c64748B", GuiTheme_Face)
    gMainMutedLinks.Push({ hwnd: ctrl.Hwnd, ctrl: ctrl, hover: false })
}

MainMutedLinkPoll(*) {
    global gMainMutedLinks
    if (gMainMutedLinks.Length = 0) {
        return
    }
    MouseGetPos(&_mx, &_my, &hwUnder)
    for it in gMainMutedLinks {
        isOver := (hwUnder = it.hwnd)
        if (isOver && !it.hover) {
            it.ctrl.SetFont("s10 underline c5B84D9", GuiTheme_Face)
            it.hover := true
        } else if (!isOver && it.hover) {
            it.ctrl.SetFont("s10 norm c64748B", GuiTheme_Face)
            it.hover := false
        }
    }
}

; 紧凑 98 键布局下的主窗口几何（顶区变窄变矮后底区与按钮随动）
global MAIN_GUI_W := 784
global MAIN_GUI_H := 504
global MAIN_GUI_H_RUNNING := 512
global MAIN_BTN_X := MAIN_GUI_W - 104
global MAIN_KEY_GB_W := 768
global MAIN_KEY_GB_H := 270
global MAIN_BOTTOM_Y := 8 + MAIN_KEY_GB_H + 12
global MAIN_OTHER_GB_W := MAIN_BTN_X - 8 - 326
global MAIN_CFG_SECTION_BOTTOM := MAIN_BOTTOM_Y + 200
global MAIN_CFG_LIST_TOP := MAIN_BOTTOM_Y + 26
global MAIN_CFG_LIST_H := MAIN_CFG_SECTION_BOTTOM - MAIN_CFG_LIST_TOP
global MAIN_CFG_LIST_BOTTOM := MAIN_CFG_SECTION_BOTTOM
global MAIN_PRESET_BTN_H := 36
global MAIN_PRESET_BTN_Y := MAIN_CFG_LIST_BOTTOM - MAIN_PRESET_BTN_H
global MAIN_CFG_FIELD_X := 174
global MAIN_CFG_FIELD_W := 124

MainWindow.EnsureBuilt()

gPresetContextMenu.Add("新建配置", MainCreatePreset)
gPresetContextMenu.Add("重命名配置", MainRenamePreset)
gPresetContextMenu.Add("克隆配置", MainClonePreset)
gPresetContextMenu.Add("删除配置", MainDeletePreset)
gPresetBlankContextMenu.Add("新建配置", MainCreatePreset)

gKeyIntervalMenu.Add("设置该键连发间隔…", MainKeyIntervalMenuEdit)
gKeyIntervalMenu.Add("恢复为全局默认", MainKeyIntervalMenuClear)

; 按控件真实位置对齐：「自动识别配置」底缘=列表底缘，左右与「当前配置名称」输入框一致
MainSyncPresetSkillLayout() {
    global gMainGui
    preset := MainGetCtrl("Preset")
    nameEdit := MainGetCtrl("PresetNameEdit")
    btn := MainGetCtrl("MainPresetSkill")
    if !IsObject(preset) || !IsObject(nameEdit) || !IsObject(btn) {
        return
    }
    try {
        if !IsObject(gMainGui) || !gMainGui.Hwnd {
            return
        }
    } catch {
        return
    }
    preset.GetPos(, &ply, , &plh)
    nameEdit.GetPos(&ex, &ey, &ew, &eh)
    bh := 36
    try {
        btn.GetPos(, , , &bhh)
        if (bhh > 0) {
            bh := bhh
        }
    } catch {
    }
    try {
        btn.Move(ex, ply + plh - bh, ew, bh)
    } catch {
    }
}

ShowGuiMain(*) {
    global gMainGui
    try PresetRecognition_CancelPending()
    gMainGui.Title := "DAF连发工具 - DNF AutoFire"
    gMainGui.Show("w" . MAIN_GUI_W . " h" . MAIN_GUI_H)
    MainLoadAllPreset()
    MainSyncPresetSkillLayout()
    QuickChangeHotKey_SyncFromConfig()
    SetTimer(MainMutedLinkPoll, 100)
}

HideGuiMain(*) {
    global gMainGui
    try PresetRecognition_CancelPending()
    SetTimer(MainMutedLinkPoll, 0)
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
    gMainGui.Show("w" . MAIN_GUI_W . " h" . MAIN_GUI_H_RUNNING)
    MainSyncPresetSkillLayout()
    MainExSwitchPaintAll()
    SetTimer(MainMutedLinkPoll, 100)
}

; 可右键设置独立连发间隔的键（与主界面可点键一致）
MainIsInteractiveKeyName(name) {
    if (name = "" || MainKeyUiGrayOnly(name)) {
        return false
    }
    return IsValueInArray(name, GetAllKeys())
}

MainSetKeyState(key, state, ovMap := 0) {
    if MainKeyUiGrayOnly(key) {
        return
    }
    ctrl := MainGetCtrl(key)
    if !IsObject(ctrl) {
        return
    }
    size := GuiTheme_MainKeyLabelFontSize(key)
    if !state {
        color := "c" GuiTheme_KeyOff
        weight := "Norm"
    } else {
        hasOv := false
        if IsObject(ovMap) {
            hasOv := ovMap.Has(key)
        } else {
            om := LoadPresetKeyIntervalOverrides(GetNowSelectPreset())
            hasOv := om.Has(key)
        }
        if hasOv {
            color := "c" GuiTheme_KeyOv
            weight := "Bold"
        } else {
            color := "c" GuiTheme_KeyOn
            weight := "Bold"
        }
    }
    ctrl.SetFont(size " " color " " weight, GuiTheme_Face)
}

AutoFireController.RegisterMainSetKeyState(MainSetKeyState)

MainRefreshAllKeyAppearances() {
    presetName := GetNowSelectPreset()
    if (presetName = "") {
        return
    }
    ov := LoadPresetKeyIntervalOverrides(presetName)
    allKeys := GetAllKeys()
    try n := allKeys.Length
    catch {
        n := 0
    }
    loop n {
        if !allKeys.Has(A_Index) {
            continue
        }
        k := allKeys[A_Index]
        if MainKeyUiGrayOnly(k) {
            continue
        }
        MainSetKeyState(k, IsKeyAutoFire(k), ov)
    }
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
    MainSyncPresetSkillLayout()
}

MainSetting(*) {
    ShowGuiSetting()
}

MainOpenSettingAbout(*) {
    ShowGuiSettingAbout()
}

MainCheckUpdate(*) {
    postUrl := "https://bbs.colg.cn/forum.php?mod=viewthread&tid=9593722"
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
    p := GetNowSelectPreset()
    MainGetCtrl("LvRen").Value := LoadPresetBool01(p, "LvRenState", false)
    MainGetCtrl("GuanYu").Value := LoadPresetBool01(p, "GuanYuState", false)
    MainGetCtrl("PetSkill").Value := LoadPresetBool01(p, "PetSkillState", false)
    MainGetCtrl("ZhanFa").Value := LoadPresetBool01(p, "ZhanFaState", false)
    MainGetCtrl("JianZong").Value := LoadPresetBool01(p, "JianZongState", false)
    MainGetCtrl("AutoRun").Value := LoadPresetBool01(p, "AutoRunState", false)
    MainGetCtrl("Combo").Value := LoadPresetBool01(p, "ComboState", false)
    MainGetCtrl("MainAutoFireInterval").Text := LoadPreset(GetNowSelectPreset(), "MainAutoFireInterval", 20)
    MainNormalizeAutoFireInterval()
    MainRefreshAllKeyAppearances()
    MainExSwitchPaintAll()
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

MainPruneObsoleteKeyIntervals(presetName) {
    m := LoadPresetKeyIntervalOverrides(presetName)
    vk := GetAllKeys()
    del := []
    for k, v in m {
        if !IsValueInArray(k, vk) {
            del.Push(k)
        }
    }
    for k in del {
        m.Delete(k)
    }
    if del.Length {
        SavePresetKeyIntervalOverrides(presetName, m)
    }
}

MainSaveCurrentPreset() {
    presetName := GetNowSelectPreset()
    if (presetName = "") {
        return
    }
    MainPruneObsoleteKeyIntervals(presetName)
    SavePresetKeys(presetName, SessionState.AutoFireEnableKeys)
    MainSaveEx()
}

MainGuiContextMenu(guiObj, ctrlObj, item, isRightClick, x, y) {
    global gPresetContextMenu, gPresetBlankContextMenu, gKeyIntervalMenu, gKeyIntervalMenuTarget
    if !IsObject(ctrlObj) {
        return
    }
    nm := ctrlObj.Name
    if MainIsInteractiveKeyName(nm) {
        gKeyIntervalMenuTarget := nm
        if (x != "" && y != "") {
            gKeyIntervalMenu.Show(x, y)
        } else {
            gKeyIntervalMenu.Show()
        }
        return
    }
    if (nm != "Preset") {
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

MainKeyIntervalMenuEdit(*) {
    global gKeyIntervalMenuTarget
    key := gKeyIntervalMenuTarget
    presetName := GetNowSelectPreset()
    if (presetName = "" || key = "") {
        return
    }
    m := LoadPresetKeyIntervalOverrides(presetName)
    defaultTxt := m.Has(key) ? String(m[key]) : ""
    ib := InputBox(
        "为该键设置连发间隔 (ms)，范围 1–200。`n留空表示使用全局间隔（并清除该键的独立设置）。",
        "按键连发间隔", "w360", defaultTxt)
    if (ib.Result != "OK") {
        return
    }
    val := Trim(ib.Value)
    if (val = "") {
        if m.Has(key) {
            m.Delete(key)
        }
        SavePresetKeyIntervalOverrides(presetName, m)
    } else {
        n := Round(val + 0)
        if (n < 1) {
            n := 1
        } else if (n > 200) {
            n := 200
        }
        m[key] := n
        SavePresetKeyIntervalOverrides(presetName, m)
    }
    MainRefreshAllKeyAppearances()
}

MainKeyIntervalMenuClear(*) {
    global gKeyIntervalMenuTarget
    key := gKeyIntervalMenuTarget
    presetName := GetNowSelectPreset()
    if (presetName = "" || key = "") {
        return
    }
    m := LoadPresetKeyIntervalOverrides(presetName)
    if !m.Has(key) {
        MsgBox("该键未设置独立间隔。",, "Iconi")
        return
    }
    m.Delete(key)
    SavePresetKeyIntervalOverrides(presetName, m)
    MainRefreshAllKeyAppearances()
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
    SavePreset(name, "ComboProfiles", "")
    SavePreset(name, "MainAutoFireKeyIntervals", "")
}

QuickChangeHotKey_RegisterOnly(keyWithoutTildeDollar) {
    global __QuickSwitchHotkey
    if (keyWithoutTildeDollar = "") {
        keyWithoutTildeDollar := "!``"
    }
    newHk := "~$" keyWithoutTildeDollar
    try {
        if (__QuickSwitchHotkey != "") {
            Hotkey(__QuickSwitchHotkey, "Off")
        }
    } catch {
    }
    __QuickSwitchHotkey := newHk
    Hotkey(__QuickSwitchHotkey, ShowGuiQuickSwitch, "On")
}

QuickChangeHotKey_PersistAndRegister(newKey) {
    SaveConfig("QuickChangeHotKey", newKey)
    reg := (newKey = "") ? "!``" : newKey
    QuickChangeHotKey_RegisterOnly(reg)
}

QuickChangeHotKey_SyncFromConfig() {
    v := LoadConfig("QuickChangeHotKey")
    reg := (v = "") ? "!``" : v
    QuickChangeHotKey_RegisterOnly(reg)
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
