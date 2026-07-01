#Requires AutoHotkey v2.0

global gComboGui := Gui("-MinimizeBox -MaximizeBox")
global gComboCtrls := Map()
global __ComboSkillItems := []
global __ComboProfiles := []
global __ComboProfileIndex := 1
global __ComboProfileLoading := false
global gComboProfileDragCurrentProfile := ""
global gComboEditCtrls := Map()
global gComboEditIndex := 0
global gComboEditKey := ""
global gComboLayout := ExLayout.Window()
global gComboEditLayout := ExLayout.Window()

UiApplyWindow(gComboGui)
gComboGui.OnEvent("Escape", ComboGuiEscape)
gComboGui.OnEvent("Close", ComboGuiClose)

contentRight := 592
profileColX := ExLayout.MarginLeft()
profileColW := 196
colGap := 16
skillColX := profileColX + profileColW + colGap
skillColW := contentRight - skillColX
bottomBtnRects := UiExSplitButtonRects(gComboLayout, ExLayout.MarginLeft(), 396, contentRight - ExLayout.MarginLeft(), 8, ExLayout.SaveButtonHeight())

UiExPageTitle(gComboGui, exText["ComboTitleLine"], contentRight, gComboLayout, ComboHelp)

UiLabel(gComboGui, UiLayoutRect(gComboLayout, profileColX, 52, profileColW, 22, "+0x200"), exText["ComboProfileList"])
UiListBox(gComboCtrls, gComboGui, "ComboProfilesListBox", UiLayoutRect(gComboLayout, profileColX, 74, profileColW, 210), ComboProfileListChange)
UiListBoxDragSort_Attach(gComboCtrls["ComboProfilesListBox"], ComboProfileDragGetItems, ComboProfileDragRender, ComboProfileDragCommit, ComboProfileDragClick)
profileBtnRects := UiExSplitButtonRects(gComboLayout, profileColX, 292, profileColW, 8)
UiPlainButton(gComboGui, profileBtnRects[1], exText["ComboAddProfile"], ComboAddProfile)
UiPlainButton(gComboGui, profileBtnRects[2], exText["ComboRemoveProfile"], ComboRemoveProfile)
profileFileBtnRects := UiExSplitButtonRects(gComboLayout, profileColX, 322, profileColW, 8)
UiPlainButton(gComboGui, profileFileBtnRects[1], exText["ComboImportProfiles"], ComboImportProfiles)
UiPlainButton(gComboGui, profileFileBtnRects[2], exText["ComboExportProfiles"], ComboExportProfiles)

UiLabel(gComboGui, UiLayoutRect(gComboLayout, skillColX, 52, skillColW, 22, "+0x200"), exText["ComboSkillList"])
UiListBox(gComboCtrls, gComboGui, "ComboSkillsListBox", UiLayoutRect(gComboLayout, skillColX, 74, skillColW, 210))
gComboCtrls["ComboSkillsListBox"].OnEvent("DoubleClick", ComboEditSkill)
UiListBoxDragSort_Attach(gComboCtrls["ComboSkillsListBox"], ComboDragGetItems, ComboDragRender, ComboDragCommit)
skillActionRects := UiExSplitButtonRects(gComboLayout, skillColX, 292, skillColW, 8)
gComboCtrls["ComboAddSkillButton"] := UiPlainButton(gComboGui, skillActionRects[1], exText["ComboAddSkill"], ComboAddSkill)
UiPlainButton(gComboGui, skillActionRects[2], exText["ComboDeleteSkill"], ComboDeleteSkill)

UiLabel(gComboGui, UiLayoutRect(gComboLayout, skillColX, 334, 44, 22, "+0x200"), exText["ComboTriggerKey"])
UiPressKeyEdit(gComboCtrls, gComboGui, "ComboTriggerKey", UiLayoutRect(gComboLayout, 276, 332, 232, 24), ComboCanonMainPressKeyCaptured)
gComboCtrls["ComboLoopMode"] := gComboGui.Add("CheckBox", UiLayoutRect(gComboLayout, 516, 334, 58, 22, "vComboLoopMode"), exText["ComboLoopMode"])
gComboCtrls["ComboBlockOriginal"] := gComboGui.Add("CheckBox", UiLayoutRect(gComboLayout, 276, 362, 116, 22, "vComboBlockOriginal"), exText["ComboBlockOriginal"])

UiButton(gComboCtrls, gComboGui, "ComboApply", bottomBtnRects[1], exText["ComboApply"], ComboApplyProfile, "secondary")
UiButton(gComboCtrls, gComboGui, "ComboSaveClose", bottomBtnRects[2], exText["ComboSaveClose"], ComboSaveAndClose, "primary")

gComboEditGui := Gui("-MinimizeBox -MaximizeBox")
UiApplyWindow(gComboEditGui)
gComboEditGui.OnEvent("Escape", ComboEditCancel)
gComboEditGui.OnEvent("Close", ComboEditCancel)
UiLabel(gComboEditGui, UiLayoutRect(gComboEditLayout, 16, 16, 120, 22, "+0x200"), exText["ComboEditSkillKey"])
UiPressKeyEdit(gComboEditCtrls, gComboEditGui, "ComboEditCurrentKey", UiLayoutRect(gComboEditLayout, 16, 38, 120, 24), ComboCanonSkillPressKeyCaptured)
UiLabel(gComboEditGui, UiLayoutRect(gComboEditLayout, 148, 16, 100, 22, "+0x200"), exText["ComboEditDelay"])
UiEdit(gComboEditCtrls, gComboEditGui, "ComboEditDelay", UiLayoutRect(gComboEditLayout, 148, 38, 100, 24, "+Number -E0x200"))
UiLabel(gComboEditGui, UiLayoutRect(gComboEditLayout, 260, 16, 100, 22, "+0x200"), exText["ComboEditHold"])
UiEdit(gComboEditCtrls, gComboEditGui, "ComboEditHold", UiLayoutRect(gComboEditLayout, 260, 38, 100, 24, "+Number -E0x200"))
UiPlainButton(gComboEditGui, UiLayoutRect(gComboEditLayout, 148, 68, 48, ExLayout.ControlHeight()), exText["ComboEditOk"], ComboEditSave, "primary")
UiPlainButton(gComboEditGui, UiLayoutRect(gComboEditLayout, 200, 68, 48, ExLayout.ControlHeight()), exText["ComboEditCancel"], ComboEditCancel)

ComboGetCtrl(name) {
    global gComboCtrls
    return gComboCtrls.Has(name) ? gComboCtrls[name] : ""
}

ShowGuiCombo(*) {
    global gMainGui, gComboGui, gComboLayout
    if IsObject(gMainGui) {
        gComboGui.Opt("+Owner" gMainGui.Hwnd)
    }
    gComboGui.Title := exText["ComboTitle"]
    gComboGui.Show("w" gComboLayout.Width() " h" gComboLayout.Height())
    ComboLoadConfig()
    DisableGuiMain()
}

HideGuiCombo() {
    global gComboGui
    gComboGui.Hide()
    EnableGuiMain()
}

ComboGuiEscape(*) {
    if !ComboSaveConfig() {
        return
    }
    HideGuiCombo()
}

ComboGuiClose(*) {
    ComboGuiEscape()
}

ComboHelp(*) {
    UiHelpMsgBox(exText["ComboHelp"], exText["ComboHelpTitle"])
}

ComboCanonMainPressKeyCaptured(key) {
    return ComboCanonMainKey(key)
}

ComboCanonSkillPressKeyCaptured(key) {
    return ComboCanonMainKey(key)
}

ComboMakeDisplay(item) {
    rawKey := HasProp(item, "key") ? Trim(String(item.key)) : ""
    displayKey := ComboIsEmptySkillKey(rawKey) ? exText["ComboEmptySkillDisplay"] : rawKey
    text := displayKey " - 间隔 " item.delay "ms"
    hold := HasProp(item, "hold") ? ComboNormalizeHold(item.hold) : ComboSkillHoldDefault()
    if (hold != ComboSkillHoldDefault()) {
        text .= " / 按下 " hold "ms"
    }
    return text
}

ComboRefreshList() {
    global __ComboSkillItems
    ctrl := ComboGetCtrl("ComboSkillsListBox")
    ctrl.Delete()
    count := 0
    loop __ComboSkillItems.Length {
        if !__ComboSkillItems.Has(A_Index) {
            continue
        }
        item := __ComboSkillItems[A_Index]
        if !IsObject(item) {
            continue
        }
        ctrl.Add([ComboMakeDisplay(item)])
        count++
    }
    if (count > 0) {
        ctrl.Choose(count)
    }
}

ComboAddSkill(*) {
    global __ComboSkillItems
    btn := ComboGetCtrl("ComboAddSkillButton")
    if IsObject(btn) {
        try btn.Text := exText["ComboAddSkillEscTip"]
    }
    try {
        raw := GetPressKey(false)
    } finally {
        if IsObject(btn) {
            try btn.Text := exText["ComboAddSkill"]
        }
    }
    if (raw = "Escape") {
        __ComboSkillItems.Push({ key: ComboEmptySkillKey(), delay: 20, hold: ComboSkillHoldDefault() })
        ComboRefreshList()
        return
    }
    key := ComboCanonMainKey(raw)
    if (key = "") {
        return
    }
    __ComboSkillItems.Push({ key: key, delay: 20, hold: ComboSkillHoldDefault() })
    ComboRefreshList()
}

ComboDeleteSkill(*) {
    global __ComboSkillItems
    ctrl := ComboGetCtrl("ComboSkillsListBox")
    if (ctrl.Text = "") {
        return
    }
    idx := ctrl.Value
    if (idx >= 1 && idx <= __ComboSkillItems.Length) {
        __ComboSkillItems.RemoveAt(idx)
        ComboRefreshList()
    }
}

ComboEditSkill(ctrl, *) {
    global __ComboSkillItems, gComboEditIndex
    idx := ctrl.Value
    if (idx < 1 || idx > __ComboSkillItems.Length || !__ComboSkillItems.Has(idx)) {
        return
    }
    gComboEditIndex := idx
    ComboShowEditDialog(__ComboSkillItems[idx])
}

ComboCloneSkillItems(items) {
    out := []
    if !IsObject(items) {
        return out
    }
    loop items.Length {
        if !items.Has(A_Index) {
            continue
        }
        it := items[A_Index]
        if !IsObject(it) {
            continue
        }
        key := HasProp(it, "key") ? ComboNormalizeStoredKey(it.key) : ""
        delay := HasProp(it, "delay") ? ComboNormalizeDelay(it.delay) : 20
        hold := HasProp(it, "hold") ? ComboNormalizeHold(it.hold) : ComboSkillHoldDefault()
        out.Push({ key: key, delay: delay, hold: hold })
    }
    return out
}

ComboProfileSummary(p) {
    if !IsObject(p) {
        return ""
    }
    t := Trim(String(p.trigger))
    if (t = "") {
        t := exText["ComboUnsetTrigger"]
    }
    skills := IsObject(p.skills) ? p.skills : []
    return t " : " skills.Length exText["ComboSkillCountSuffix"]
}

ComboFlushEditorToProfileAt(idx) {
    global __ComboProfiles, __ComboSkillItems
    if (idx < 1 || idx > __ComboProfiles.Length || !__ComboProfiles.Has(idx)) {
        return
    }
    p := __ComboProfiles[idx]
    p.trigger := ComboCanonMainKey(UiPressKeyEdit_Value(ComboGetCtrl("ComboTriggerKey")))
    p.loop := ComboGetCtrl("ComboLoopMode").Value
    p.blockOriginal := ComboGetCtrl("ComboBlockOriginal").Value
    p.skills := ComboCloneSkillItems(__ComboSkillItems)
}

ComboLoadProfileToEditor(idx) {
    global __ComboProfiles, __ComboSkillItems
    if (idx < 1 || idx > __ComboProfiles.Length || !__ComboProfiles.Has(idx)) {
        ComboClearEditor()
        return
    }
    p := __ComboProfiles[idx]
    __ComboSkillItems := ComboCloneSkillItems(p.skills)
    ComboRefreshList()
    ComboGetCtrl("ComboTriggerKey").Text := p.trigger
    ComboGetCtrl("ComboLoopMode").Value := p.loop
    ComboGetCtrl("ComboBlockOriginal").Value := HasProp(p, "blockOriginal") ? p.blockOriginal : false
}

ComboClearEditor() {
    global __ComboSkillItems
    __ComboSkillItems := []
    ComboRefreshList()
    ComboGetCtrl("ComboTriggerKey").Text := ""
    ComboGetCtrl("ComboLoopMode").Value := false
    ComboGetCtrl("ComboBlockOriginal").Value := false
}

ComboRefreshProfileList() {
    global __ComboProfiles, __ComboProfileIndex, __ComboProfileLoading
    __ComboProfileLoading := true
    try {
        ctrl := ComboGetCtrl("ComboProfilesListBox")
        ctrl.Delete()
        loop __ComboProfiles.Length {
            if !__ComboProfiles.Has(A_Index) {
                continue
            }
            ctrl.Add([ComboProfileSummary(__ComboProfiles[A_Index])])
        }
        if (__ComboProfileIndex >= 1 && __ComboProfileIndex <= __ComboProfiles.Length) {
            ctrl.Choose(__ComboProfileIndex)
        } else if (__ComboProfiles.Length > 0) {
            ctrl.Choose(1)
        }
    } finally {
        __ComboProfileLoading := false
    }
}

ComboSetProfileListBoxFromItems(ctrl, items, selectedIndex) {
    ctrl.Delete()
    if IsObject(items) {
        loop items.Length {
            if !items.Has(A_Index) {
                continue
            }
            ctrl.Add([ComboProfileSummary(items[A_Index])])
        }
    }
    if (selectedIndex > 0) {
        try ctrl.Choose(selectedIndex)
    }
}

ComboProfileDragGetItems(*) {
    global __ComboProfiles, __ComboProfileIndex, gComboProfileDragCurrentProfile
    ComboFlushEditorToProfileAt(__ComboProfileIndex)
    gComboProfileDragCurrentProfile := ""
    if (__ComboProfileIndex >= 1 && __ComboProfileIndex <= __ComboProfiles.Length) {
        gComboProfileDragCurrentProfile := __ComboProfiles[__ComboProfileIndex]
    }
    return UiListBoxDragSort_CopyArray(__ComboProfiles)
}

ComboProfileDragRender(ctrl, items, selectedIndex) {
    global __ComboProfileLoading
    __ComboProfileLoading := true
    try {
        ComboSetProfileListBoxFromItems(ctrl, items, selectedIndex)
    } finally {
        __ComboProfileLoading := false
    }
}

ComboProfileDragCommit(items, selectedIndex) {
    global __ComboProfiles, __ComboProfileIndex, gComboProfileDragCurrentProfile
    __ComboProfiles := items
    newCurrentIndex := 0
    if IsObject(gComboProfileDragCurrentProfile) {
        loop __ComboProfiles.Length {
            if __ComboProfiles.Has(A_Index) && (__ComboProfiles[A_Index] == gComboProfileDragCurrentProfile) {
                newCurrentIndex := A_Index
                break
            }
        }
    }
    __ComboProfileIndex := newCurrentIndex > 0 ? newCurrentIndex : selectedIndex
    ComboRefreshProfileList()
    ComboLoadProfileToEditor(__ComboProfileIndex)
    gComboProfileDragCurrentProfile := ""
}

ComboProfileDragClick(ctrl) {
    ComboProfileChangeToIndex(ctrl.Value)
}

ComboProfileListChange(ctrl, *) {
    global __ComboProfiles, __ComboProfileIndex, __ComboProfileLoading
    if __ComboProfileLoading || UiListBoxDragSort_IsActive(ctrl) {
        return
    }
    ComboProfileChangeToIndex(ctrl.Value)
}

ComboProfileChangeToIndex(newIdx) {
    global __ComboProfiles, __ComboProfileIndex
    if (newIdx < 1 || newIdx > __ComboProfiles.Length) {
        return
    }
    oldIdx := __ComboProfileIndex
    if (oldIdx >= 1 && oldIdx <= __ComboProfiles.Length && oldIdx != newIdx) {
        ComboFlushEditorToProfileAt(oldIdx)
    }
    __ComboProfileIndex := newIdx
    ComboLoadProfileToEditor(newIdx)
    ComboRefreshProfileList()
}

ComboAddProfile(*) {
    global __ComboProfiles, __ComboProfileIndex
    ComboFlushEditorToProfileAt(__ComboProfileIndex)
    __ComboProfiles.Push({ trigger: "", loop: false, blockOriginal: false, skills: [] })
    __ComboProfileIndex := __ComboProfiles.Length
    ComboRefreshProfileList()
    ComboLoadProfileToEditor(__ComboProfileIndex)
}

ComboRemoveProfile(*) {
    global __ComboProfiles, __ComboProfileIndex
    if (__ComboProfileIndex < 1 || __ComboProfileIndex > __ComboProfiles.Length || !__ComboProfiles.Has(__ComboProfileIndex)) {
        return
    }
    ComboFlushEditorToProfileAt(__ComboProfileIndex)
    __ComboProfiles.RemoveAt(__ComboProfileIndex)
    if (__ComboProfileIndex > __ComboProfiles.Length) {
        __ComboProfileIndex := __ComboProfiles.Length
    }
    ComboRefreshProfileList()
    ComboLoadProfileToEditor(__ComboProfileIndex)
}

ComboImportProfiles(*) {
    global __ComboProfiles, __ComboProfileIndex
    ComboFlushEditorToProfileAt(__ComboProfileIndex)
    filePath := FileSelect(1, A_ScriptDir, exText["ComboImportTitle"], "INI (*.ini)")
    if (filePath = "") {
        return
    }
    try {
        imported := ComboReadExportFile(filePath)
    } catch Error as e {
        ComboShowImportError(e)
        return
    }
    startIndex := __ComboProfiles.Length + 1
    added := 0
    loop imported.Length {
        if !imported.Has(A_Index) {
            continue
        }
        p := imported[A_Index]
        if !IsObject(p) {
            continue
        }
        __ComboProfiles.Push({
            trigger: p.trigger,
            loop: p.loop ? true : false,
            blockOriginal: (HasProp(p, "blockOriginal") && p.blockOriginal) ? true : false,
            skills: ComboCloneSkillItems(p.skills)
        })
        added++
    }
    if (added = 0) {
        MsgBox(exText["ComboImportNoValidProfiles"], exText["ComboTitle"], "Icon!")
        return
    }
    __ComboProfileIndex := startIndex
    ComboRefreshProfileList()
    ComboLoadProfileToEditor(__ComboProfileIndex)
    MsgBox(exText["ComboImportSuccessPrefix"] added exText["ComboImportSuccessSuffix"], exText["ComboTitle"], "Iconi")
}

ComboExportProfiles(*) {
    global __ComboProfiles, __ComboProfileIndex
    ComboFlushEditorToProfileAt(__ComboProfileIndex)
    defaultPath := A_ScriptDir "\combo-profiles.ini"
    filePath := FileSelect("S16", defaultPath, exText["ComboExportTitle"], "INI (*.ini)")
    if (filePath = "") {
        return
    }
    if !RegExMatch(filePath, "i)\.ini$") {
        filePath .= ".ini"
    }
    try {
        ComboWriteExportFile(filePath, __ComboProfiles)
    } catch {
        MsgBox(exText["ComboExportFailed"], exText["ComboTitle"], "Icon!")
        return
    }
    MsgBox(exText["ComboExportSuccess"], exText["ComboTitle"], "Iconi")
}

ComboShowImportError(e) {
    code := IsObject(e) ? e.Message : ""
    if (code = "MISSING_SECTION") {
        text := exText["ComboImportMissingSection"]
    } else if (code = "EMPTY_PROFILES") {
        text := exText["ComboImportNoValidProfiles"]
    } else if (code = "MISSING_FILE") {
        text := exText["ComboImportMissingFile"]
    } else {
        text := exText["ComboImportFailed"]
    }
    MsgBox(text, exText["ComboTitle"], "Icon!")
}

ComboApplyProfile(*) {
    if !ComboSaveConfig() {
        return
    }
    ComboRefreshProfileList()
}

ComboSaveAndClose(*) {
    if !ComboSaveConfig() {
        return
    }
    ComboRefreshProfileList()
    HideGuiCombo()
}

ComboSaveConfig() {
    global __ComboProfiles, __ComboProfileIndex
    presetName := GetNowSelectPreset()
    ComboFlushEditorToProfileAt(__ComboProfileIndex)
    ComboSaveProfilesToPreset(presetName, __ComboProfiles)
    return true
}

ComboLoadConfig() {
    global __ComboProfiles, __ComboProfileIndex
    presetName := GetNowSelectPreset()
    __ComboProfiles := ComboLoadProfilesFromPreset(presetName)
    __ComboProfileIndex := __ComboProfiles.Length > 0 ? 1 : 0
    ComboRefreshProfileList()
    ComboLoadProfileToEditor(__ComboProfileIndex)
}

ComboShowEditDialog(item) {
    global gComboGui, gComboEditGui, gComboEditCtrls, gComboEditKey, gComboEditLayout
    if !IsObject(item) {
        return
    }
    gComboEditKey := item.key
    displayKey := ComboIsEmptySkillKey(item.key) ? "" : item.key
    gComboEditCtrls["ComboEditCurrentKey"].Text := displayKey
    gComboEditCtrls["ComboEditDelay"].Text := ComboNormalizeDelay(item.delay)
    gComboEditCtrls["ComboEditHold"].Text := HasProp(item, "hold") ? ComboNormalizeHold(item.hold) : ComboSkillHoldDefault()
    if IsObject(gComboGui) {
        gComboEditGui.Opt("+Owner" gComboGui.Hwnd)
    }
    gComboEditGui.Title := exText["ComboEditTitle"]
    gComboEditGui.Show("w" gComboEditLayout.Width() " h" gComboEditLayout.Height())
}

ComboEditSave(*) {
    global __ComboSkillItems, gComboEditCtrls, gComboEditIndex, gComboEditKey
    if (gComboEditIndex < 1 || gComboEditIndex > __ComboSkillItems.Length || !__ComboSkillItems.Has(gComboEditIndex)) {
        ComboEditCancel()
        return
    }
    delay := ComboNormalizeDelay(gComboEditCtrls["ComboEditDelay"].Text)
    hold := ComboNormalizeHold(gComboEditCtrls["ComboEditHold"].Text)
    key := UiPressKeyEdit_Value(gComboEditCtrls["ComboEditCurrentKey"])
    if (key != "") {
        gComboEditKey := key
    } else {
        ; 输入框被 ESC 清空时，落到空技能占位符，保留延迟占位语义
        gComboEditKey := ComboEmptySkillKey()
    }
    __ComboSkillItems[gComboEditIndex] := { key: gComboEditKey, delay: delay, hold: hold }
    ComboRefreshList()
    try ComboGetCtrl("ComboSkillsListBox").Choose(gComboEditIndex)
    ComboEditCancel()
}

ComboEditCancel(*) {
    global gComboEditGui, gComboEditIndex, gComboEditKey
    gComboEditIndex := 0
    gComboEditKey := ""
    gComboEditGui.Hide()
}

ComboSetListBoxFromItems(ctrl, items) {
    ctrl.Delete()
    if !IsObject(items) {
        return
    }
    loop items.Length {
        if !items.Has(A_Index) {
            continue
        }
        item := items[A_Index]
        if !IsObject(item) {
            continue
        }
        ctrl.Add([ComboMakeDisplay(item)])
    }
}

ComboDragGetItems(*) {
    global __ComboSkillItems
    items := []
    loop __ComboSkillItems.Length {
        if !__ComboSkillItems.Has(A_Index) {
            continue
        }
        item := __ComboSkillItems[A_Index]
        items.Push({ key: item.key, delay: item.delay, hold: HasProp(item, "hold") ? item.hold : ComboSkillHoldDefault() })
    }
    return items
}

ComboDragRender(ctrl, items, selectedIndex) {
    ComboSetListBoxFromItems(ctrl, items)
    try ctrl.Choose(selectedIndex)
}

ComboDragCommit(items, selectedIndex) {
    global __ComboSkillItems
    __ComboSkillItems := items
    ComboRefreshList()
    if (selectedIndex > 0 && selectedIndex <= __ComboSkillItems.Length) {
        try ComboGetCtrl("ComboSkillsListBox").Choose(selectedIndex)
    }
}
