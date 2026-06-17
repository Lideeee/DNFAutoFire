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
global gComboProfileEditCtrls := Map()
global gComboProfileEditIndex := 0
global gComboLayout := ExLayout.Window()
global gComboEditLayout := ExLayout.Window()
global gComboProfileEditLayout := ExLayout.Window()

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
gComboCtrls["ComboProfilesListBox"].OnEvent("DoubleClick", ComboEditProfile)
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
UiPlainButton(gComboEditGui, UiLayoutRect(gComboEditLayout, 148, 68, 48, ExLayout.ControlHeight()), exText["ComboEditOk"], ComboEditSave, "primary")
UiPlainButton(gComboEditGui, UiLayoutRect(gComboEditLayout, 200, 68, 48, ExLayout.ControlHeight()), exText["ComboEditCancel"], ComboEditCancel)

gComboProfileEditGui := Gui("-MinimizeBox -MaximizeBox")
UiApplyWindow(gComboProfileEditGui)
gComboProfileEditGui.OnEvent("Escape", ComboProfileEditCancel)
gComboProfileEditGui.OnEvent("Close", ComboProfileEditCancel)
UiLabel(gComboProfileEditGui, UiLayoutRect(gComboProfileEditLayout, 16, 16, 120, 22, "+0x200"), exText["ComboProfileEditDelay"])
UiEdit(gComboProfileEditCtrls, gComboProfileEditGui, "ComboProfileEditDelay", UiLayoutRect(gComboProfileEditLayout, 16, 38, 120, 24, "+Number -E0x200"))
UiPlainButton(gComboProfileEditGui, UiLayoutRect(gComboProfileEditLayout, 148, 38, 48, ExLayout.ControlHeight()), exText["ComboEditOk"], ComboProfileEditSave, "primary")
UiPlainButton(gComboProfileEditGui, UiLayoutRect(gComboProfileEditLayout, 200, 38, 48, ExLayout.ControlHeight()), exText["ComboEditCancel"], ComboProfileEditCancel)

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
    canon := ComboCanonMainKey(key)
    if (canon = "") && key != "" {
        MsgBox(exText["ComboUnsupportedMainKey"], exText["ComboTitle"], "Icon!")
    }
    return canon
}

ComboCanonSkillPressKeyCaptured(key) {
    canon := ComboCanonMainKey(key)
    if (canon = "") && key != "" {
        MsgBox(exText["ComboUnsupportedKey"], exText["ComboTitle"], "Icon!")
    }
    return canon
}

ComboMakeDisplay(item) {
    return item.key " - " item.delay "ms"
}

ComboNormalizeProfileLeadDelay(profile) {
    if !IsObject(profile) || !HasProp(profile, "leadDelay") {
        return 0
    }
    return ComboNormalizeLeadDelay(profile.leadDelay)
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
        try btn.Text := exText["PressKeyPrompt"]
    }
    try {
        raw := GetPressKey(false)
    } finally {
        if IsObject(btn) {
            try btn.Text := exText["ComboAddSkill"]
        }
    }
    key := ComboCanonMainKey(raw)
    if (key = "") {
        if (raw != "") {
            MsgBox(exText["ComboUnsupportedKey"], exText["ComboTitle"], "Icon!")
        }
        return
    }
    __ComboSkillItems.Push({ key: key, delay: 20 })
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
        if (key = "") {
            continue
        }
        delay := HasProp(it, "delay") ? ComboNormalizeDelay(it.delay) : 20
        out.Push({ key: key, delay: delay })
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
    delay := ComboNormalizeProfileLeadDelay(p)
    suffix := delay > 0 ? " / " exText["ComboLeadDelay"] delay "ms" : ""
    return t " : " skills.Length exText["ComboSkillCountSuffix"] suffix
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
    p.leadDelay := ComboNormalizeProfileLeadDelay(p)
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
    if !HasProp(p, "leadDelay") {
        p.leadDelay := 0
    }
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
    __ComboProfiles.Push({ trigger: "", loop: false, blockOriginal: false, leadDelay: 0, skills: [] })
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
            leadDelay: ComboNormalizeProfileLeadDelay(p),
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
    SavePreset(presetName, "ComboProfiles", ComboSerializeProfiles(__ComboProfiles))
    SavePreset(presetName, "ComboTriggerKey", "")
    SavePreset(presetName, "ComboLoopMode", false)
    SavePreset(presetName, "ComboSkills", "")
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

ComboEditProfile(ctrl, *) {
    global __ComboProfiles, __ComboProfileIndex, gComboProfileEditIndex
    idx := ctrl.Value
    if (idx < 1 || idx > __ComboProfiles.Length || !__ComboProfiles.Has(idx)) {
        return
    }
    ComboFlushEditorToProfileAt(__ComboProfileIndex)
    gComboProfileEditIndex := idx
    ComboShowProfileEditDialog(__ComboProfiles[idx])
}

ComboShowProfileEditDialog(profile) {
    global gComboGui, gComboProfileEditGui, gComboProfileEditCtrls, gComboProfileEditLayout
    if !IsObject(profile) {
        return
    }
    gComboProfileEditCtrls["ComboProfileEditDelay"].Text := ComboNormalizeProfileLeadDelay(profile)
    if IsObject(gComboGui) {
        gComboProfileEditGui.Opt("+Owner" gComboGui.Hwnd)
    }
    gComboProfileEditGui.Title := exText["ComboProfileEditTitle"]
    gComboProfileEditGui.Show("w" gComboProfileEditLayout.Width() " h" gComboProfileEditLayout.Height())
}

ComboProfileEditSave(*) {
    global __ComboProfiles, __ComboProfileIndex, gComboProfileEditCtrls, gComboProfileEditIndex
    if (gComboProfileEditIndex < 1 || gComboProfileEditIndex > __ComboProfiles.Length || !__ComboProfiles.Has(gComboProfileEditIndex)) {
        ComboProfileEditCancel()
        return
    }
    __ComboProfiles[gComboProfileEditIndex].leadDelay := ComboNormalizeLeadDelay(gComboProfileEditCtrls["ComboProfileEditDelay"].Text)
    __ComboProfileIndex := gComboProfileEditIndex
    ComboRefreshProfileList()
    ComboLoadProfileToEditor(__ComboProfileIndex)
    ComboProfileEditCancel()
}

ComboProfileEditCancel(*) {
    global gComboProfileEditGui, gComboProfileEditIndex
    gComboProfileEditIndex := 0
    gComboProfileEditGui.Hide()
}

ComboShowEditDialog(item) {
    global gComboGui, gComboEditGui, gComboEditCtrls, gComboEditKey, gComboEditLayout
    if !IsObject(item) {
        return
    }
    gComboEditKey := item.key
    gComboEditCtrls["ComboEditCurrentKey"].Text := gComboEditKey
    gComboEditCtrls["ComboEditDelay"].Text := ComboNormalizeDelay(item.delay)
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
    key := UiPressKeyEdit_Value(gComboEditCtrls["ComboEditCurrentKey"])
    if (key != "") {
        gComboEditKey := key
    } else if (gComboEditKey = "") {
        gComboEditKey := __ComboSkillItems[gComboEditIndex].key
    }
    __ComboSkillItems[gComboEditIndex] := { key: gComboEditKey, delay: delay }
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
        items.Push({ key: item.key, delay: item.delay })
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
