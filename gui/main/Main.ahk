#Requires AutoHotkey v2.0

global gMainGui := Gui("-MaximizeBox +OwnDialogs")
global gMainCtrls := Map()
global gMainKeyCaps := Map()
global _IsPresetUiSyncing := false
global gPresetContextMenu := Menu()
global gPresetBlankContextMenu := Menu()
global gMainKeyIntervalMenuTargetKey := ""
global gMainExSwitchUi := Map()
global gMainMutedLinks := []

UiApplyWindow(gMainGui)
gMainGui.OnEvent("Escape", MainGuiEscape)
gMainGui.OnEvent("Close", MainGuiClose)
gMainGui.OnEvent("ContextMenu", MainGuiContextMenu)

MainAdd(ctrlType, options, text := "") {
    global gMainGui, gMainCtrls
    return UiAdd(gMainCtrls, gMainGui, ctrlType, options, text)
}

MainGetCtrl(name) {
    global gMainCtrls
    return gMainCtrls.Has(name) ? gMainCtrls[name] : ""
}

; 主界面「其他功能」开关是否打开（逻辑状态在隐藏 CheckBox 上，与 DNFAutoFire 主界面 GDI+ 开关一致）
MainExFeatureIsEnabled(name) {
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

MainCheckboxOn(name) => MainExFeatureIsEnabled(name)

MainAddExFeatureRow(name, colX, y, toggleW, linkW, linkText, linkHandler) {
    global gMainGui, gMainExSwitchUi
    switchH := 20
    ui := ToggleGdip(gMainGui, colX, y + 1, toggleW, switchH)
    gMainExSwitchUi[name] := ui
    ui.OnClick(MainExSwitchClick.Bind(name))
    linkX := colX + toggleW + 8
    textCtrl := MainAdd("Text", "vMainExLink_" name " x" linkX " y" y " w" linkW " h22 +0x200 +0x100", linkText)
    textCtrl.OnEvent("Click", linkHandler)
    MainMutedLinkRegister(textCtrl)
}

MainExSwitchClick(name, *) {
    cb := MainGetCtrl(name)
    if !IsObject(cb) {
        return
    }
    cb.Value := MainExFeatureIsEnabled(name) ? 0 : 1
    MainExSwitchPaint(name)
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
    ui.Draw(MainExFeatureIsEnabled(name))
}

MainExSwitchPaintAll(*) {
    for name in gMainExSwitchUi {
        MainExSwitchPaint(name)
    }
}

MainMutedLinkRegister(ctrl) {
    global gMainMutedLinks, UiTheme
    if !IsObject(ctrl) {
        return
    }
    ctrl.SetFont("s10 norm " UiTheme["MutedColor"], UiTheme["FontName"])
    gMainMutedLinks.Push({ hwnd: ctrl.Hwnd, ctrl: ctrl, hover: false })
}

MainMutedLinkPoll(*) {
    global gMainMutedLinks, UiTheme
    if (gMainMutedLinks.Length = 0) {
        return
    }
    snapshot := UiHoverSnapshot()
    hwUnder := snapshot["hwnd"]
    for item in gMainMutedLinks {
        isOver := (hwUnder = item.hwnd)
        if (isOver && !item.hover) {
            item.ctrl.SetFont("s10 underline " UiTheme["MutedLinkHover"], UiTheme["FontName"])
            item.hover := true
        } else if (!isOver && item.hover) {
            item.ctrl.SetFont("s10 norm " UiTheme["MutedColor"], UiTheme["FontName"])
            item.hover := false
        }
    }
}

MainKeyUiGrayOnly(name) => name = "Esc"

MainBuildKeyboardPanel() {
    global gMainGui, gMainCtrls, __Version, UiTheme

    for item in MainKeyLayoutData.GetRows() {
        name := item[1], pos := item[2], label := item.Length >= 3 ? item[3] : name
        MainCreateKeyCap(gMainGui, name, pos, label, MainKeyUiGrayOnly(name), MainKeyClick)
    }

    MainCreateKeyCap(gMainGui, "Win", MainKeyLayoutData.WinRect(), "Win", true)

    versionX := MainKeyLayoutData.TopRowVersionX()
    versionY := MainKeyLayoutData.TopRowVersionY()
    versionW := MainKeyLayoutData.VersionWidth()
    versionH := MainKeyLayoutData.TopRowVersionHeight()
    lineH := 12
    lineGap := 2
    textBlockH := lineH * 2 + lineGap
    line1Y := versionY + Floor((versionH - textBlockH) / 2)
    line2Y := line1Y + lineH + lineGap
    UiSetDefaultFont(gMainGui, "s8 " UiTheme["MutedColor"])
    gMainGui.Add("Text", UiRect(versionX, line1Y, versionW, lineH, "+Center +0x200"), MainText["VersionPrefix"] __Version)
    gMainGui.Add("Text", UiRect(versionX, line2Y, versionW, lineH, "+Center +0x200"), MainText["OriginalAuthor"])

    UiButton(gMainCtrls, gMainGui, "MainClear", UiRect(
        MainKeyLayoutData.TopRowClearX(),
        MainKeyLayoutData.TopRowY(),
        MainKeyLayoutData.KeyWidth(1),
        MainKeyLayoutData.Height(),
        "+0x200 +Center"
    ), MainText["ClearKeys"], MainClear, "danger")
}

MainBuildPresetPanel() {
    global gMainGui, gMainCtrls
    panelX := MainLayout.StandardMargin(), panelY := MainLayout.BottomY()
    panelW := MainLayout.ButtonColumnX() - panelX - MainLayout.StandardMargin()
    titleW := MainLayout.GuiWidth() - panelX - MainLayout.StandardMargin()
    listH := MainLayout.ConfigListHeight()
    fx := MainLayout.ConfigFieldX()
    fw := MainLayout.ConfigFieldWidth()
    feh := MainLayout.ConfigFieldEditHeight()

    UiSection(gMainGui, UiRect(panelX, panelY + 6, titleW, 20), MainText["PresetSection"])
    presetCtrl := UiListBox(gMainCtrls, gMainGui, "Preset", UiRect(MainLayout.ConfigListX(), MainLayout.ConfigListTop(), MainLayout.ConfigListWidth(), listH), MainChangePresetByList)
    UiListBoxDragSort_Attach(presetCtrl, MainPresetDragGetItems, MainPresetDragRender, MainPresetDragCommit, MainPresetDragClick)
    UiLabel(gMainGui, UiRect(fx, MainLayout.ConfigFieldLabelY(1), fw, MainLayout.ConfigFieldLabelHeight()), MainText["CurrentPreset"])
    UiEdit(gMainCtrls, gMainGui, "CurrentPresetLabel", UiRect(fx, MainLayout.ConfigFieldEditY(1), fw, feh, "+ReadOnly -WantCtrlA -E0x200 Border"))

    UiLabel(gMainGui, UiRect(fx, MainLayout.ConfigFieldLabelY(2), fw, MainLayout.ConfigFieldLabelHeight()), MainText["AutoFireInterval"])
    UiEdit(gMainCtrls, gMainGui, "AutoFireIntervalMs", UiRect(fx, MainLayout.ConfigFieldEditY(2), fw, feh, "+Number +Limit3 -E0x200 Border"))

    UiLabel(gMainGui, UiRect(fx, MainLayout.ConfigFieldLabelY(3), fw, MainLayout.ConfigFieldLabelHeight()), MainText["QuickSwitchHotkey"])
    UiHotkey(gMainCtrls, gMainGui, "QuickChangeHotKey", UiRect(fx, MainLayout.ConfigFieldEditY(3), fw, 22, "-E0x200 Border"), MainSaveQuickChangeHotKey)
}

MainBuildActionButtons() {
    global gMainGui, gMainCtrls
    x := MainLayout.ButtonColumnX(), w := MainLayout.ActionButtonWidth(), h := MainLayout.ActionButtonHeight()
    for item in [
        ["MainSetting", MainText["Setting"], MainSetting, MainLayout.ActionButtonYTop(), "secondary"],
        ["MainOpenAutoPresets", MainText["AutoPresets"], ShowGuiAutoPresets, MainLayout.ActionButtonYMiddle(), "secondary"],
        ["MainStart", MainText["Start"], MainStart, MainLayout.ActionButtonYBottom(), "primary"]
    ] {
        UiButton(gMainCtrls, gMainGui, item[1], UiRect(x, item[4], w, h), item[2], item[3], item[5])
    }
}

MainBuildFeaturePanel() {
    global gMainGui, gMainCtrls
    panelX := MainLayout.ExLeftColumnX(), panelY := MainLayout.BottomY()
    panelW := MainLayout.ButtonColumnX() - panelX - 8
    titleW := MainLayout.GuiWidth() - panelX - MainLayout.StandardMargin()
    panelH := MainLayout.GuiHeight() - panelY - 8
    tw := MainLayout.ExToggleWidth()
    rowH := MainLayout.ExRowHeight()
    y0 := MainLayout.ExRowTop()

    for name in ["LvRen", "GuanYu", "JianZong", "ZhanFa", "PetSkill", "XiuLuo", "AutoRun", "Combo", "AutoPresets"] {
        MainAdd("CheckBox", "v" name " Hidden x-2000 y-2000 w1 h1 -TabStop")
    }

    UiSection(gMainGui, UiRect(panelX, panelY + 6, titleW, panelH), MainText["FeatureSection"])
    leftRows := [
        ["LvRen", MainText["LvRen"], MainLvRen, MainLayout.ExLeftColumnX(), MainLayout.ExLeftLinkWidth()],
        ["GuanYu", MainText["GuanYu"], MainGuanYu, MainLayout.ExLeftColumnX(), MainLayout.ExLeftLinkWidth()],
        ["ZhanFa", MainText["ZhanFa"], MainZhanFa, MainLayout.ExLeftColumnX(), MainLayout.ExLeftLinkWidth()],
        ["XiuLuo", MainText["XiuLuo"], MainXiuLuo, MainLayout.ExLeftColumnX(), MainLayout.ExLeftLinkWidth()]
    ]
    rightRows := [
        ["JianZong", MainText["JianZong"], MainJianZong, MainLayout.ExRightColumnX(), MainLayout.ExRightLinkWidth()],
        ["PetSkill", MainText["PetSkill"], MainPetSkill, MainLayout.ExRightColumnX(), MainLayout.ExRightLinkWidth()],
        ["AutoRun", MainText["AutoRun"], MainAutoRun, MainLayout.ExRightColumnX(), MainLayout.ExRightLinkWidth()],
        ["Combo", MainText["Combo"], MainCombo, MainLayout.ExRightColumnX(), MainLayout.ExRightLinkWidth()]
    ]
    for i, item in leftRows {
        rowY := y0 + (i - 1) * rowH
        cx := item[4], lw := item[5]
        MainAddExFeatureRow(item[1], cx, rowY, tw, lw, item[2], item[3])
    }
    for i, item in rightRows {
        rowY := y0 + (i - 1) * rowH
        cx := item[4], lw := item[5]
        MainAddExFeatureRow(item[1], cx, rowY, tw, lw, item[2], item[3])
    }
    MainExSwitchPaintAll()
}

keyPanelH := MainLayout.KeyPanelHeight()
UiSection(gMainGui, UiRect(MainLayout.StandardMargin(), 14, MainLayout.GuiWidth() - MainLayout.StandardMargin() * 2, keyPanelH), MainText["KeySection"])
MainBuildKeyboardPanel()
UiSetDefaultFont(gMainGui)

MainBuildPresetPanel()
MainBuildActionButtons()
MainBuildFeaturePanel()

gPresetContextMenu.Add(MainText["NewPreset"], MainNewPreset)
gPresetContextMenu.Add(MainText["RenamePreset"], MainRenamePreset)
gPresetContextMenu.Add(MainText["ClonePreset"], MainClonePreset)
gPresetContextMenu.Add(MainText["DeletePreset"], MainDeletePreset)
gPresetBlankContextMenu.Add(MainText["NewPreset"], MainNewPreset)

SwitchToStoppedState(*) {
    StopAutoFire()
    gMainGui.Title := MainText["AppTitle"]
    MainLoadAllPreset()
    MainLoadAutoFireGlobalInterval()
    LoadMainPresetState(ResolvePresetName(LoadLastPreset()))
    MainLoatQuickChangeHotKey()
}

HideGuiMain(*) {
    global gMainGui
    SetTimer(MainMutedLinkPoll, 0)
    gMainGui.Hide()
}

MainGuiEscape(*) {
    return MainGuiClose()
}

MainGuiClose(*) {
    global _CloseToTray
    SaveCurrentPresetState()
    if (_CloseToTray) {
        HideGuiMain()
        return true
    }
    ExitApp()
}

DisableGuiMain() {
    global gMainGui
    gMainGui.Opt("+Disabled")
}

EnableGuiMain() {
    global gMainGui
    gMainGui.Opt("-Disabled")
    gMainGui.Title := MainText["AppTitleWithVersion"] __Version
    gMainGui.Show("w" MainLayout.GuiWidth() " h" MainLayout.GuiHeight())
    MainExSwitchPaintAll()
    SetTimer(MainMutedLinkPoll, 100)
}

MainSetKeyState(key, state) {
    keyCap := MainGetKeyCap(key)
    if !IsObject(keyCap) {
        return
    }
    if MainKeyUiGrayOnly(key) {
        keyCap.SetVisualState("locked", false)
        return
    }
    keyCap.SetVisualState(state ? "on" : "off", false)
}

MainKeyClick(ctrl, *) {
    ChangeKeyAutoFireState(ctrl.Name)
}

MainStart(*) {
    EnterRunningMode()
}

MainClear(*) {
    SetAllKeysDisable()
}

MainPromptPresetName(title, prompt, defaultValue := "") {
    ret := InputBox(prompt, title, "w280 h130", defaultValue)
    if (ret.Result != "OK") {
        return ""
    }
    rawValue := Trim(ret.Value)
    if InStr(rawValue, "|") {
        MsgBox(MainText["PresetNameInvalidChar"],, "Icon!")
        return ""
    }
    presetName := NormalizePresetName(rawValue)
    if (presetName = "") {
        MsgBox(MainText["PresetNameRequired"],, "Icon!")
        return ""
    }
    return presetName
}

MainPromptUniquePresetName(title, prompt, defaultValue := "") {
    presetName := MainPromptPresetName(title, prompt, defaultValue)
    if (presetName = "") {
        return ""
    }
    if (PresetExists(presetName)) {
        MsgBox(MainText["PresetNameExists"],, "Icon!")
        return ""
    }
    return presetName
}

MainClonePreset(*) {
    sourceName := ResolvePresetName()
    presetName := MainPromptUniquePresetName(MainText["ClonePreset"], MainText["ClonePresetPrompt"], sourceName MainText["ClonePresetSuffix"])
    if (presetName = "") {
        return
    }
    SaveCurrentPresetState()
    ClonePreset(sourceName, presetName)
    AutoPresets_OnPresetCloned(sourceName, presetName)
    MainLoadAllPreset()
    LoadMainPresetState(presetName)
}

MainNewPreset(*) {
    presetName := MainPromptUniquePresetName(MainText["NewPreset"], MainText["NewPresetPrompt"], MainText["NewPresetDefault"])
    if (presetName = "") {
        return
    }
    SaveCurrentPresetState()
    CreateBlankPreset(presetName)
    MainLoadAllPreset()
    LoadMainPresetState(presetName)
}

MainRenamePreset(*) {
    presetName := MainGetCtrl("Preset").Text
    newPresetName := MainPromptPresetName(MainText["RenamePresetTitle"], MainText["RenamePresetPrompt"], presetName)
    if (newPresetName = "") {
        return
    }
    if (newPresetName = presetName) {
        return
    }
    if (PresetExists(newPresetName)) {
        MsgBox(MainText["PresetNameExists"],, "Icon!")
        return
    }
    SaveCurrentPresetState()
    RenamePreset(presetName, newPresetName)
    AutoPresets_OnPresetRenamed(presetName, newPresetName)
    if (GetNowSelectPreset() = presetName) {
        SetNowSelectPreset(newPresetName)
        SaveLastPreset(newPresetName)
    }
    MainLoadAllPreset()
    LoadMainPresetState(newPresetName)
}

MainDeletePreset(*) {
    presetName := ResolvePresetName()
    if (presetName = "") {
        MsgBox(MainText["SelectValidPreset"],, "Icon!")
        return
    }
    if (LoadAllPreset().Length <= 1) {
        MsgBox(MainText["KeepOnePreset"],, "Icon!")
        return
    }
    ret := MsgBox(MainText["DeletePresetConfirmPrefix"] presetName MainText["DeletePresetConfirmSuffix"], MainText["DeletePreset"], "YesNo Icon!")
    if (ret != "Yes") {
        return
    }
    DeletePreset(presetName)
    AutoPresets_OnPresetDeleted(presetName)
    MainLoadAllPreset()
    LoadMainPresetState(ResolvePresetName())
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
        name := items[A_Index]
        if (name != "") {
            ctrl.Add([name])
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
    global _IsPresetUiSyncing
    presetCtrl := MainGetCtrl("Preset")
    presetList := LoadAllPresetString()
    nowSelectPreset := ResolvePresetName()
    _IsPresetUiSyncing := true
    MainSetListBox(presetCtrl, presetList)

    idx := 0
    for i, txt in StrSplit(presetList, "|") {
        if (txt = nowSelectPreset) {
            idx := i
            break
        }
    }

    if (idx > 0) {
        MainPresetListSafeChoose(presetCtrl, idx, presetList)
    } else if MainPresetListSafeChoose(presetCtrl, 1, presetList) {
        nowSelectPreset := presetCtrl.Text
    }
    _IsPresetUiSyncing := false
    MainSetCurrentPresetLabel(nowSelectPreset)
}

MainSetting(*) {
    ShowGuiSetting()
}

MainLoadAutoFireGlobalInterval() {
    MainGetCtrl("AutoFireIntervalMs").Text := String(LoadAutoFireGlobalIntervalMs())
}

MainLoadEx() {
    AutoFireKeyIntervals_LoadForPreset(GetNowSelectPreset())
    MainGetCtrl("LvRen").Value := LoadPreset(GetNowSelectPreset(), "LvRenState", false)
    MainGetCtrl("GuanYu").Value := LoadPreset(GetNowSelectPreset(), "GuanYuState", false)
    MainGetCtrl("PetSkill").Value := LoadPreset(GetNowSelectPreset(), "PetSkillState", false)
    MainGetCtrl("ZhanFa").Value := LoadPreset(GetNowSelectPreset(), "ZhanFaState", false)
    MainGetCtrl("JianZong").Value := LoadPreset(GetNowSelectPreset(), "JianZongState", false)
    MainGetCtrl("XiuLuo").Value := LoadPreset(GetNowSelectPreset(), "XiuLuoState", false)
    MainGetCtrl("AutoRun").Value := LoadPreset(GetNowSelectPreset(), "AutoRunState", false)
    MainGetCtrl("Combo").Value := LoadPreset(GetNowSelectPreset(), "ComboState", false)
    MainGetCtrl("AutoPresets").Value := AutoPresets_LoadEnabledGlobal() ? 1 : 0
    MainSyncKeyIntervalBars()
    MainExSwitchPaintAll()
}

MainSetCurrentPresetLabel(presetName) {
    MainGetCtrl("CurrentPresetLabel").Value := presetName
}

MainRefreshPresetUi() {
    MainLoadAllPreset()
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

MainXiuLuo(*) {
    ShowGuiXiuLuo()
}

MainAutoRun(*) {
    ShowGuiAutoRun()
}

MainCombo(*) {
    ShowGuiCombo()
}

MainChangePresetByList(*) {
    global _IsPresetUiSyncing
    if (_IsPresetUiSyncing || UiListBoxDragSort_IsActive(MainGetCtrl("Preset"))) {
        return
    }
    presetName := MainGetCtrl("Preset").Text
    if (presetName = "") {
        return
    }
    ChangePreset(presetName)
}

MainPresetDragGetItems(*) {
    return LoadAllPreset()
}

MainPresetDragRender(ctrl, items, selectedIndex) {
    global _IsPresetUiSyncing
    _IsPresetUiSyncing := true
    try {
        MainSetListBoxFromArray(ctrl, items)
        try ctrl.Choose(selectedIndex)
    } finally {
        _IsPresetUiSyncing := false
    }
}

MainPresetDragCommit(items, selectedIndex) {
    SavePresetOrder(items)
    MainLoadAllPreset()
}

MainPresetDragClick(ctrl) {
    presetName := ctrl.Text
    if (presetName != "") {
        ChangePreset(presetName)
    }
}

MainGuiContextMenu(guiObj, ctrlObj, item, isRightClick, x, y) {
    global gPresetContextMenu, gPresetBlankContextMenu
    kc := MainKeyCapFromControl(ctrlObj)
    if IsObject(kc) && !kc.locked {
        MainShowKeyIntervalContextMenu(kc, x, y)
        return
    }
    if !IsObject(ctrlObj) || ctrlObj.Name != "Preset" {
        return
    }
    idx := MainPresetListIndexFromCursor(ctrlObj)
    if (idx > 0) {
        try ctrlObj.Choose(idx)
    }
    if (x != "" && y != "") {
        if (idx > 0) {
            gPresetContextMenu.Show(x, y)
        } else {
            gPresetBlankContextMenu.Show(x, y)
        }
    } else if (idx > 0) {
        gPresetContextMenu.Show()
    } else {
        gPresetBlankContextMenu.Show()
    }
}

MainPresetListIndexFromScreenPoint(ctrl, sx, sy) {
    if !IsObject(ctrl) || sx = "" || sy = "" {
        return 0
    }
    pt := Buffer(8, 0)
    NumPut("int", sx, pt, 0)
    NumPut("int", sy, pt, 4)
    if !DllCall("ScreenToClient", "ptr", ctrl.Hwnd, "ptr", pt) {
        return 0
    }
    cx := NumGet(pt, 0, "int")
    cy := NumGet(pt, 4, "int")
    return UiListBoxDragSort_IndexFromClientPoint(ctrl, cx, cy)
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

MainKeyCapFromControl(ctrlObj) {
    global gMainKeyCaps
    if !IsObject(ctrlObj) {
        return ""
    }
    try hw := ctrlObj.Hwnd
    catch {
        return ""
    }
    if !hw {
        return ""
    }
    for _, kc in gMainKeyCaps {
        if !IsObject(kc) {
            continue
        }
        try {
            if (kc.ctrl.Hwnd = hw) {
                return kc
            }
        } catch {
        }
        try {
            if IsObject(kc.labelCtrl) && (kc.labelCtrl.Hwnd = hw) {
                return kc
            }
        } catch {
        }
        try {
            if IsObject(kc.auxLabelCtrl) && (kc.auxLabelCtrl.Hwnd = hw) {
                return kc
            }
        } catch {
        }
    }
    return ""
}

MainSyncKeyIntervalBars() {
    global gMainKeyCaps, _AutoFireKeyIntervals, _AutoFireKeyDelays
    if !IsObject(gMainKeyCaps) {
        return
    }
    for kn, kc in gMainKeyCaps {
        if !IsObject(kc) {
            continue
        }
        has := (IsObject(_AutoFireKeyIntervals) && _AutoFireKeyIntervals.Has(kn)) || (IsObject(_AutoFireKeyDelays) && _AutoFireKeyDelays.Has(kn))
        kc.SetIntervalBarHint(!!has)
    }
}

MainShowKeyIntervalContextMenu(kc, x, y) {
    global gMainKeyIntervalMenuTargetKey, gKeyIntervalMenu
    gMainKeyIntervalMenuTargetKey := kc.name
    if (x != "" && y != "") {
        gKeyIntervalMenu.Show(x, y)
    } else {
        gKeyIntervalMenu.Show()
    }
}

MainKeyIntervalMenu_Edit(*) {
    global gMainKeyIntervalMenuTargetKey, _AutoFireKeyIntervals, _AutoFireKeyDelays
    kn := gMainKeyIntervalMenuTargetKey
    if (kn = "") {
        return
    }
    if !IsObject(_AutoFireKeyIntervals) {
        _AutoFireKeyIntervals := Map()
    }
    if !IsObject(_AutoFireKeyDelays) {
        _AutoFireKeyDelays := Map()
    }
    defGlobal := 20
    try {
        defGlobal := Round(MainGetCtrl("AutoFireIntervalMs").Text + 0)
    } catch {
        defGlobal := 20
    }
    if (defGlobal < 1) {
        defGlobal := 1
    }
    intervalText := _AutoFireKeyIntervals.Has(kn) ? String(_AutoFireKeyIntervals[kn]) : String(defGlobal)
    delayText := _AutoFireKeyDelays.Has(kn) ? String(_AutoFireKeyDelays[kn]) : "8"
    ret := MainShowKeyParamsDialog(kn, intervalText, delayText)
    if !IsObject(ret) {
        return
    }
    intervalText := Trim(ret.intervalMs)
    delayText := Trim(ret.delayMs)
    if (intervalText = "" || delayText = "" || !IsInteger(intervalText) || !IsInteger(delayText)) {
        MsgBox(MainText["KeyParamsFormatRequired"],, "Icon!")
        return
    }
    intervalMs := Integer(intervalText)
    delayMs := Integer(delayText)
    if (intervalMs < 1) {
        MsgBox(MainText["IntegerMsPositive"],, "Icon!")
        return
    }
    if (delayMs < 0) {
        MsgBox(MainText["IntegerMsNonNegative"],, "Icon!")
        return
    }
    _AutoFireKeyIntervals[kn] := intervalMs
    _AutoFireKeyDelays[kn] := delayMs
    if IsObject(MainGetKeyCap(kn)) {
        MainGetKeyCap(kn).SetIntervalBarHint(true)
    }
    SaveCurrentPresetState()
}

MainShowKeyParamsDialog(kn, intervalText, delayText) {
    dlg := Gui("+Owner" gMainGui.Hwnd " -MinimizeBox -MaximizeBox", MainText["KeyParamsTitlePrefix"] kn)
    ctrls := Map()
    UiApplyWindow(dlg)
    labelW := 60
    fieldW := 80
    fieldX := ExLayout.MarginLeft() + labelW + 8
    contentRight := fieldX + fieldW
    UiLabel(dlg, UiRect(ExLayout.MarginLeft(), 16, labelW, 26), MainText["KeyParamsIntervalLabel"])
    intervalEdit := UiEdit(ctrls, dlg, "KeyParamsInterval", UiRect(fieldX, 16, fieldW, ExLayout.ControlHeight(), "+Number -E0x200 Border"))
    UiLabel(dlg, UiRect(ExLayout.MarginLeft(), 48, labelW, 26), MainText["KeyParamsDelayLabel"])
    delayEdit := UiEdit(ctrls, dlg, "KeyParamsDelay", UiRect(fieldX, 48, fieldW, ExLayout.ControlHeight(), "+Number -E0x200 Border"))
    intervalEdit.Text := intervalText
    delayEdit.Text := delayText
    btnRects := UiExSplitButtonRects("", ExLayout.MarginLeft(), 88, contentRight - ExLayout.MarginLeft(), 8, ExLayout.SaveButtonHeight())
    okBtn := UiPlainButton(dlg, btnRects[1], MainText["Ok"], "", "primary")
    cancelBtn := UiPlainButton(dlg, btnRects[2], MainText["Cancel"], "", "secondary")
    result := false
    okBtn.OnEvent("Click", (*) => (result := { intervalMs: intervalEdit.Text, delayMs: delayEdit.Text }, dlg.Destroy()))
    cancelBtn.OnEvent("Click", (*) => dlg.Destroy())
    dlg.OnEvent("Close", (*) => dlg.Destroy())
    dlg.OnEvent("Escape", (*) => dlg.Destroy())
    hwnd := dlg.Hwnd
    dlg.Show("w" (contentRight + ExLayout.MarginRight()) " h132")
    WinWaitClose("ahk_id " hwnd)
    return result
}

MainKeyIntervalMenu_UseDefault(*) {
    global gMainKeyIntervalMenuTargetKey, _AutoFireKeyIntervals, _AutoFireKeyDelays
    kn := gMainKeyIntervalMenuTargetKey
    if (kn = "") {
        return
    }
    hasInterval := IsObject(_AutoFireKeyIntervals) && _AutoFireKeyIntervals.Has(kn)
    hasDelay := IsObject(_AutoFireKeyDelays) && _AutoFireKeyDelays.Has(kn)
    if (!hasInterval && !hasDelay) {
        MsgBox(MainText["KeyParamsAlreadyDefault"],, "Iconi")
        return
    }
    if (hasInterval) {
        _AutoFireKeyIntervals.Delete(kn)
    }
    if (hasDelay) {
        _AutoFireKeyDelays.Delete(kn)
    }
    if IsObject(MainGetKeyCap(kn)) {
        MainGetKeyCap(kn).SetIntervalBarHint(false)
    }
    SaveCurrentPresetState()
}
global gKeyIntervalMenu := Menu()
gKeyIntervalMenu.Add(MainText["SetKeyParams"], MainKeyIntervalMenu_Edit)
gKeyIntervalMenu.Add(MainText["UseDefaultParams"], MainKeyIntervalMenu_UseDefault)
