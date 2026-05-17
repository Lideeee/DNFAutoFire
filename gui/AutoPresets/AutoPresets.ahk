#Requires AutoHotkey v2.0

global gAutoPresetsGui := Gui("-MinimizeBox -MaximizeBox")
global gAutoPresetsCtrls := Map()
global gAutoPresetsSelectedPreset := ""
global gAutoPresetsLayout := AutoPresetsLayout.Window()

UiApplyWindow(gAutoPresetsGui)
gAutoPresetsGui.OnEvent("Escape", AutoPresetsGuiEscape)
gAutoPresetsGui.OnEvent("Close", AutoPresetsGuiClose)

marginX := AutoPresetsLayout.MarginX()
windowW := AutoPresetsLayout.WindowWidth()
contentR := AutoPresetsLayout.ContentRight()
listW := AutoPresetsLayout.ListWidth()
rightX := AutoPresetsLayout.RightX()
rightW := AutoPresetsLayout.RightWidth()
pvW := AutoPresetsLayout.PreviewWidth()
pvH := AutoPresetsLayout.PreviewHeight()
pvY := AutoPresetsLayout.PreviewY()
calX := AutoPresetsLayout.CalX()
calPvW := AutoPresetsLayout.CalPreviewWidth()
calPvH := AutoPresetsLayout.CalPreviewHeight()
townW := AutoPresetsLayout.TownWidth()
rowActionY := AutoPresetsLayout.RowActionY()
apEnableY := AutoPresetsLayout.EnableY()
apHotkeyY := AutoPresetsLayout.HotkeyY()
middleLabelY := AutoPresetsLayout.MiddleLabelY()
calY := AutoPresetsLayout.CalY()
pickBtnY := AutoPresetsLayout.PickBtnY()
calBtnY := AutoPresetsLayout.CalBtnY()
townBtnY := AutoPresetsLayout.TownBtnY()
lowerY := AutoPresetsLayout.LowerY()
listY := AutoPresetsLayout.ListY()
listH := AutoPresetsLayout.ListHeight()
saveY := AutoPresetsLayout.SaveY()

UiSectionWithHelp(gAutoPresetsGui, gAutoPresetsLayout, marginX, 12, AutoPresetsText["SectionTitle"], AutoPresetsHelp, contentR)
gAutoPresetsGui.SetFont()
gAutoPresetsCtrls["AutoPresetsEnableVisible"] := gAutoPresetsGui.Add("CheckBox", UiLayoutRect(gAutoPresetsLayout, marginX, apEnableY, 310, 20, "vAutoPresetsEnableVisible"), AutoPresetsText["Enable"])
gAutoPresetsCtrls["AutoPresetsEnableVisible"].OnEvent("Click", AutoPresetsSyncEnableFromUi)
UiLabel(gAutoPresetsGui, UiLayoutRect(gAutoPresetsLayout, marginX, apHotkeyY, 140, 20), AutoPresetsText["ExtraHotkey"])
UiEdit(gAutoPresetsCtrls, gAutoPresetsGui, "AutoPresetHotkey", UiLayoutRect(gAutoPresetsLayout, 144, apHotkeyY - 1, 112, 22, "+ReadOnly -WantCtrlA -E0x200"))
UiPlainButton(gAutoPresetsGui, UiLayoutRect(gAutoPresetsLayout, 264, apHotkeyY - 2, 72, 24), AutoPresetsText["Capture"], AutoPresetsCaptureHotkey, "secondary")

UiLabel(gAutoPresetsGui, UiLayoutRect(gAutoPresetsLayout, marginX, middleLabelY, contentR - marginX, 18), AutoPresetsText["CalTownReference"])
gAutoPresetsCtrls["CalPreview"] := gAutoPresetsGui.Add("Picture", UiLayoutRect(gAutoPresetsLayout, calX, calY, calPvW, calPvH), "")
gAutoPresetsCtrls["TownPreview"] := gAutoPresetsGui.Add("Picture", UiLayoutRect(gAutoPresetsLayout, AutoPresetsLayout.CalTownX(), calY, townW, calPvH), "")
UiPlainButton(gAutoPresetsGui, UiLayoutRect(gAutoPresetsLayout, 76, pickBtnY, 192, 30), AutoPresetsText["PickRegion"], AutoPresetsOpenPickMenu, "secondary")
UiPlainButton(gAutoPresetsGui, UiLayoutRect(gAutoPresetsLayout, 76, calBtnY, 192, 28), AutoPresetsText["UpdateCalibrate"], AutoPresetsUpdateCalibrateIcon, "secondary")
UiPlainButton(gAutoPresetsGui, UiLayoutRect(gAutoPresetsLayout, 76, townBtnY, 192, 28), AutoPresetsText["UpdateTown"], AutoPresetsUpdateTownIcon, "secondary")

UiLabel(gAutoPresetsGui, UiLayoutRect(gAutoPresetsLayout, marginX, lowerY, listW, 20), AutoPresetsText["PresetList"])
UiListBox(gAutoPresetsCtrls, gAutoPresetsGui, "AutoPresetPresetList", UiLayoutRect(gAutoPresetsLayout, marginX, listY, listW, listH), AutoPresetsOnPresetListChange)
UiLabel(gAutoPresetsGui, UiLayoutRect(gAutoPresetsLayout, rightX, lowerY, rightW, 20), AutoPresetsText["SkillReference"])
UiEdit(gAutoPresetsCtrls, gAutoPresetsGui, "AutoPresetSelectedName", UiLayoutRect(gAutoPresetsLayout, rightX, lowerY + 1, 1, 1, "+ReadOnly Hidden -E0x200"))
gAutoPresetsCtrls["SkillPreview"] := gAutoPresetsGui.Add("Picture", UiLayoutRect(gAutoPresetsLayout, rightX, pvY, pvW, pvH), "")
UiPlainButton(gAutoPresetsGui, UiLayoutRect(gAutoPresetsLayout, rightX, rowActionY, (pvW - 8) // 2, 28), AutoPresetsText["CaptureReference"], AutoPresetsUpdateSkillIcon, "secondary")
UiPlainButton(gAutoPresetsGui, UiLayoutRect(gAutoPresetsLayout, rightX + (pvW + 8) // 2, rowActionY, (pvW - 8) // 2, 28), AutoPresetsText["DeleteReference"], AutoPresetsDeleteSkillIcon, "secondary")
UiPlainButton(gAutoPresetsGui, UiExSaveButtonRect(gAutoPresetsLayout, saveY, contentR, 30), AutoPresetsText["Save"], AutoPresetsGuiSave, "primary")

AutoPresetsGetCtrl(name) {
    global gAutoPresetsCtrls
    return gAutoPresetsCtrls.Has(name) ? gAutoPresetsCtrls[name] : ""
}

AutoPresetsLockSkillPreview(pic) {
    if IsObject(pic) {
        pic.Move(AutoPresetsLayout.RightX(), AutoPresetsLayout.PreviewY(), AutoPresetsLayout.PreviewWidth(), AutoPresetsLayout.PreviewHeight())
    }
}

AutoPresetsLockCalPreview(pic) {
    if IsObject(pic) {
        pic.Move(AutoPresetsLayout.CalX(), AutoPresetsLayout.CalY(), AutoPresetsLayout.CalPreviewWidth(), AutoPresetsLayout.CalPreviewHeight())
    }
}

AutoPresetsLockTownPreview(pic) {
    if IsObject(pic) {
        pic.Move(AutoPresetsLayout.CalTownX(), AutoPresetsLayout.CalY(), AutoPresetsLayout.TownWidth(), AutoPresetsLayout.CalPreviewHeight())
    }
}

AutoPresetsResolveSelectedPreset() {
    global gAutoPresetsSelectedPreset
    presetList := LoadAllPreset()
    for n in presetList {
        if (n = gAutoPresetsSelectedPreset) {
            return gAutoPresetsSelectedPreset
        }
    }
    cur := GetNowSelectPreset()
    for n in presetList {
        if (n = cur) {
            return cur
        }
    }
    return presetList.Length >= 1 ? presetList[1] : ""
}

AutoPresetsSyncPresetList() {
    global gAutoPresetsSelectedPreset
    listCtrl := AutoPresetsGetCtrl("AutoPresetPresetList")
    nameCtrl := AutoPresetsGetCtrl("AutoPresetSelectedName")
    if !IsObject(listCtrl) {
        return
    }
    pipe := LoadAllPresetString()
    MainSetListBox(listCtrl, pipe)
    gAutoPresetsSelectedPreset := AutoPresetsResolveSelectedPreset()
    if (gAutoPresetsSelectedPreset != "") {
        idx := 0
        for i, txt in StrSplit(pipe, "|") {
            if (txt = gAutoPresetsSelectedPreset) {
                idx := i
                break
            }
        }
        if (idx > 0) {
            MainPresetListSafeChoose(listCtrl, idx, pipe)
        }
    }
    if IsObject(nameCtrl) {
        nameCtrl.Text := gAutoPresetsSelectedPreset
    }
}

AutoPresetsOnPresetListChange(*) {
    global gAutoPresetsSelectedPreset
    listCtrl := AutoPresetsGetCtrl("AutoPresetPresetList")
    nameCtrl := AutoPresetsGetCtrl("AutoPresetSelectedName")
    if !IsObject(listCtrl) {
        return
    }
    presetName := Trim(listCtrl.Text)
    if (presetName = "") {
        return
    }
    gAutoPresetsSelectedPreset := presetName
    if IsObject(nameCtrl) {
        nameCtrl.Text := presetName
    }
    AutoPresetsRefreshEnableCheckbox()
    AutoPresetsRefreshSkillPreview()
}

AutoPresetsRefreshEnableCheckbox() {
    v := AutoPresets_LoadEnabledGlobal() ? 1 : 0
    c := AutoPresetsGetCtrl("AutoPresetsEnableVisible")
    if IsObject(c) {
        c.Value := v
    }
}

AutoPresetsRefreshSkillPreview() {
    pic := AutoPresetsGetCtrl("SkillPreview")
    if !IsObject(pic) {
        return
    }
    path := AutoPresetsSkillIconPath(AutoPresetsResolveSelectedPreset())
    pic.Value := ""
    AutoPresetsLockSkillPreview(pic)
    if FileExist(path) {
        tmp := AutoPresetsSkillIcon_FitPreviewTempPath()
        if AutoPresetsSkillIcon_RenderFitPreviewToFile(path, AutoPresetsLayout.PreviewWidth(), AutoPresetsLayout.PreviewHeight(), tmp) && FileExist(tmp) {
            pic.Value := tmp
        } else {
            pic.Value := path
        }
        AutoPresetsLockSkillPreview(pic)
    }
}

AutoPresetsRefreshCalTownPreviews() {
    picC := AutoPresetsGetCtrl("CalPreview")
    picT := AutoPresetsGetCtrl("TownPreview")
    if IsObject(picC) {
        picC.Value := ""
        AutoPresetsLockCalPreview(picC)
        p := AutoPresetsCalibrateIconGlobalPath()
        if FileExist(p) {
            tmp := A_Temp "\DAF_cal_fit_preview.png"
            if AutoPresetsSkillIcon_RenderFitPreviewToFile(p, AutoPresetsLayout.CalPreviewWidth(), AutoPresetsLayout.CalPreviewHeight(), tmp) && FileExist(tmp) {
                picC.Value := tmp
            } else {
                picC.Value := p
            }
            AutoPresetsLockCalPreview(picC)
        }
    }
    if IsObject(picT) {
        picT.Value := ""
        AutoPresetsLockTownPreview(picT)
        p2 := AutoPresetsTownIconGlobalPath()
        if FileExist(p2) {
            tmp2 := A_Temp "\DAF_town_fit_preview.png"
            if AutoPresetsSkillIcon_RenderFitPreviewToFile(p2, AutoPresetsLayout.TownWidth(), AutoPresetsLayout.CalPreviewHeight(), tmp2) && FileExist(tmp2) {
                picT.Value := tmp2
            } else {
                picT.Value := p2
            }
            AutoPresetsLockTownPreview(picT)
        }
    }
}

AutoPresetsAfterRegionPick(kind) {
    global gAutoPresetsGui
    if IsObject(gAutoPresetsGui) && WinExist("ahk_id " gAutoPresetsGui.Hwnd) {
        AutoPresetsRefreshCalTownPreviews()
        if (kind = "skill") {
            AutoPresetsRefreshSkillPreview()
        }
    }
}

AutoPresetsLoadToGui() {
    global gAutoPresetsSelectedPreset
    gAutoPresetsSelectedPreset := GetNowSelectPreset()
    AutoPresetsSyncPresetList()
    hk := Trim(LoadConfig("AutoPresetHotkey", " "))
    if (hk = " ") {
        hk := ""
    }
    AutoPresetsGetCtrl("AutoPresetHotkey").Text := hk
    AutoPresetsRefreshEnableCheckbox()
    AutoPresetsRefreshSkillPreview()
    AutoPresetsRefreshCalTownPreviews()
}

AutoPresetsSyncEnableFromUi(*) {
    v := AutoPresetsGetCtrl("AutoPresetsEnableVisible").Value ? 1 : 0
    SaveConfig("AutoPresetsEnabled", v)
    m := MainGetCtrl("AutoPresets")
    if IsObject(m) {
        m.Value := v
    }
    if AutoPresets_IsSessionRunning() {
        AutoPresets_RegisterSessionHotkeys()
    }
}

ShowGuiAutoPresets(*) {
    global gMainGui, gAutoPresetsGui, gAutoPresetsLayout
    if IsObject(gMainGui) {
        gAutoPresetsGui.Opt("+Owner" gMainGui.Hwnd)
    }
    gAutoPresetsGui.Title := AutoPresetsText["SectionTitle"]
    AutoPresetsLoadToGui()
    gAutoPresetsGui.Show("w" gAutoPresetsLayout.Width(windowW) " h" gAutoPresetsLayout.Height())
    DisableGuiMain()
}

HideGuiAutoPresets() {
    global gAutoPresetsGui
    PresetRegionPickCommitIfOpen()
    gAutoPresetsGui.Hide()
    EnableGuiMain()
}

AutoPresetsGuiEscape(*) {
    AutoPresetsGuiSave()
}

AutoPresetsGuiClose(*) {
    AutoPresetsGuiSave()
}

AutoPresetsGuiSave(*) {
    PresetRegionPickCommitIfOpen()
    hk := Trim(AutoPresetsGetCtrl("AutoPresetHotkey").Text)
    SaveConfig("AutoPresetHotkey", hk)
    v := AutoPresetsGetCtrl("AutoPresetsEnableVisible").Value ? 1 : 0
    SaveConfig("AutoPresetsEnabled", v)
    m := MainGetCtrl("AutoPresets")
    if IsObject(m) {
        m.Value := v
    }
    HideGuiAutoPresets()
    if AutoPresets_IsSessionRunning() {
        AutoPresets_RegisterSessionHotkeys()
    }
}

AutoPresetsHelp(*) {
    UiHelpMsgBox(AutoPresetsText["Help"], AutoPresetsText["HelpTitle"])
}

AutoPresetsCaptureHotkey(*) {
    AutoPresetsGetCtrl("AutoPresetHotkey").Text := GetPressKey()
}

AutoPresetsUpdateSkillIcon(*) {
    PresetRegionPickCommitIfOpen()
    try {
        AutoPresetsSkillIcon_UpdateForPreset(AutoPresetsResolveSelectedPreset())
        AutoPresetsRefreshSkillPreview()
    } catch Error as e {
        MsgBox(e.Message,, "Icon!")
    }
}

AutoPresetsDeleteSkillIcon(*) {
    name := AutoPresetsResolveSelectedPreset()
    if (name = "") {
        return
    }
    AutoPresets_OnPresetDeleted(name)
    AutoPresetsRefreshSkillPreview()
}

AutoPresetsUpdateCalibrateIcon(*) {
    PresetRegionPickCommitIfOpen()
    try {
        AutoPresetsCalibrateIcon_UpdateCurrent()
        AutoPresetsRefreshCalTownPreviews()
    } catch Error as e {
        MsgBox(e.Message,, "Icon!")
    }
}

AutoPresetsUpdateTownIcon(*) {
    PresetRegionPickCommitIfOpen()
    try {
        AutoPresetsTownIcon_UpdateCurrent()
        AutoPresetsRefreshCalTownPreviews()
    } catch Error as e {
        MsgBox(e.Message,, "Icon!")
    }
}

AutoPresetsOpenPickMenu(*) {
    m := Menu()
    m.Add(AutoPresetsText["SkillRegion"], (*) => PresetRegionPickOpen("skill"))
    m.Add(AutoPresetsText["CalibrateRegion"], (*) => PresetRegionPickOpen("calibrate"))
    m.Add(AutoPresetsText["TownRegion"], (*) => PresetRegionPickOpen("town"))
    m.Show()
}

#Include ./AutoPresetsRegionPick.ahk
