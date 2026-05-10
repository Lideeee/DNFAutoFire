#Requires AutoHotkey v2.0
#Include ./ExWindowHost.ahk

global COMBO_PROFILE_RS := Chr(30)
global COMBO_PROFILE_US := Chr(31)
global COMBO_PROFILE_MAX := 16

global gComboGui := Gui("+ToolWindow -Theme")
global gComboCtrls := Map()
global __ComboSkillItems := []
global __ComboProfiles := []
global __ComboProfileIndex := 1
global __ComboProfileLoading := false
global gComboEditGui := ""
global gComboEditCtrls := Map()
global gComboEditIndex := 0
global gComboEditKey := ""
global gComboDragStartIndex := 0
global gComboDragHoverIndex := 0
global gComboDragDown := false
global gComboDragPreviewing := false
global gComboDragPreviewList := []
global gComboDragCurrentFromIndex := 0

GuiTheme_Apply(gComboGui)

gComboGui.OnEvent("Escape", ComboGuiEscape)
gComboGui.OnEvent("Close", ComboGuiClose)
OnMessage(0x0201, ComboListOnLButtonDown)
OnMessage(0x0202, ComboListOnLButtonUp)
OnMessage(0x0200, ComboListOnMouseMove)

gComboCtrls["ComboProfilesListBox"] := GuiTheme_AddListBox(gComboGui, "ComboProfilesListBox", 16, 38, 196, 210)
gComboCtrls["ComboProfilesListBox"].OnEvent("Change", ComboProfileListChange)
gComboGui.Add("Text", "x16 y16 w196 h22 +0x200", ExText.ComboProfilesLabel())
GuiTheme_FlatBtn(gComboGui, "x16 y256 w94 h26", ExText.ComboAddProfile(), ComboAddProfile, false)
GuiTheme_FlatBtn(gComboGui, "x118 y256 w94 h26", ExText.ComboRemoveProfile(), ComboRemoveProfile, false)
gComboCtrls["ComboSkillsListBox"] := GuiTheme_AddListBox(gComboGui, "ComboSkillsListBox", 228, 38, 364, 210)
gComboCtrls["ComboSkillsListBox"].OnEvent("DoubleClick", ComboEditSkill)
gComboGui.Add("Text", "x228 y16 w344 h22 +0x200", ExText.ComboSequenceLabel())
GuiTheme_FlatBtnSmall(gComboGui, "x570 y16 w22 h22", GuiText.HelpButton(), ComboHelp)
GuiTheme_FlatBtn(gComboGui, "x228 y256 w112 h26", ExText.ComboAddSkill(), ComboAddSkill, false)
GuiTheme_FlatBtn(gComboGui, "x348 y256 w112 h26", ExText.ComboDeleteSkill(), ComboDeleteSkill, false)
gComboGui.Add("Text", "x228 y298 w44 h22 +0x200", ExText.ComboTriggerLabel())
gComboCtrls["ComboTriggerKey"] := gComboGui.Add("Edit", "vComboTriggerKey x276 y296 w232 h24 +ReadOnly -WantCtrlA -E0x200 Border")
RegisterEditPressKeyCapture(gComboCtrls["ComboTriggerKey"], GetKeycode.AfterCaptureEdit.Bind(gComboCtrls["ComboTriggerKey"]))
gComboCtrls["ComboLoopMode"] := gComboGui.Add("CheckBox", "vComboLoopMode x512 y298 h22", ExText.ComboLoopMode())
GuiTheme_FlatBtn(gComboGui, "x160 y360 w140 h32", ExText.ComboApplyProfile(), ComboApplyProfile, false)
GuiTheme_FlatBtn(gComboGui, "x316 y360 w140 h32", ExText.SaveButton(), ComboSaveAndClose, true)

ComboGetCtrl(name) {
    global gComboCtrls
    return gComboCtrls.Has(name) ? gComboCtrls[name] : ""
}

ShowGuiCombo(*) {
    gComboGui.Title := ExText.ComboTitle()
    ExWindowHost.ShowOwnedFit(gComboGui, gComboGui.Title)
    ComboLoadConfig()
}

HideGuiCombo() {
    ExWindowHost.HideOwned(gComboGui)
}

ComboGuiEscape(*) {
    HideGuiCombo()
}

ComboGuiClose(*) {
    HideGuiCombo()
}

ComboHelp(*) {
    MsgBox(ExText.ComboHelp(), ExText.ComboHelpTitle(), "Icon!")
}

ComboNormalizeDelay(raw) {
    delay := Round((Trim(raw) = "" ? 20 : raw) + 0)
    if (delay < 20) {
        delay := 20
    } else if (delay > 3000) {
        delay := 3000
    }
    return delay
}

ComboMakeDisplay(item) {
    return item.key " - " item.delay "ms"
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
    raw := GetPressKey()
    key := GetKeycode.CanonMainKey(raw)
    if (key = "") {
        if (raw != "") {
            MsgBox(ExText.ComboInvalidSkillKey(),, "Icon!")
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

ComboSerializeSkills(items) {
    data := ""
    loop items.Length {
        if !items.Has(A_Index) {
            continue
        }
        item := items[A_Index]
        if !IsObject(item) {
            continue
        }
        data .= item.key "," item.delay "|"
    }
    if (StrLen(data) > 0) {
        data := SubStr(data, 1, StrLen(data) - 1)
    }
    return data
}

ComboParseSkills(raw) {
    items := []
    for unit in StrSplit(raw, "|") {
        unit := Trim(unit)
        if (unit = "") {
            continue
        }
        parts := StrSplit(unit, ",")
        if (parts.Length < 1) {
            continue
        }
        key := Trim(parts[1])
        if (key = "") {
            continue
        }
        key := GetKeycode.CanonMainKey(key)
        if (key = "") {
            continue
        }
        delayRaw := parts.Length >= 2 ? parts[2] : 20
        items.Push({ key: key, delay: ComboNormalizeDelay(delayRaw) })
    }
    return items
}

ComboProfileSummary(p) {
    if !IsObject(p) {
        return ""
    }
    t := Trim(p.trigger)
    if (t = "") {
        t := ExText.ComboProfileUnsetTrigger()
    }
    skills := IsObject(p.skills) ? p.skills : []
    return ExText.ComboProfileSummary(t, skills.Length)
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
        out.Push({ key: it.key, delay: it.delay })
    }
    return out
}

ComboSerializeProfiles(profiles) {
    global COMBO_PROFILE_RS, COMBO_PROFILE_US
    out := ""
    if !IsObject(profiles) {
        return out
    }
    rs := COMBO_PROFILE_RS
    us := COMBO_PROFILE_US
    loop profiles.Length {
        if !profiles.Has(A_Index) {
            continue
        }
        p := profiles[A_Index]
        if !IsObject(p) {
            continue
        }
        trig := p.trigger
        loopOn := p.loop ? "1" : "0"
        skills := IsObject(p.skills) ? p.skills : []
        skillsStr := ComboSerializeSkills(skills)
        rec := trig us loopOn us skillsStr
        if (out != "") {
            out .= rs
        }
        out .= rec
    }
    return out
}

ComboParseProfiles(raw) {
    global COMBO_PROFILE_RS, COMBO_PROFILE_US
    out := []
    raw := Trim(raw)
    if (raw = "") {
        return out
    }
    rs := COMBO_PROFILE_RS
    us := COMBO_PROFILE_US
    for rec in StrSplit(raw, rs) {
        rec := Trim(rec)
        if (rec = "") {
            continue
        }
        parts := StrSplit(rec, us,, 3)
        if (parts.Length < 2) {
            continue
        }
        trigger := GetKeycode.CanonMainKey(Trim(parts[1]))
        loopOn := (parts.Length >= 2 && Trim(parts[2]) = "1")
        skillsRaw := parts.Length >= 3 ? parts[3] : ""
        out.Push({ trigger: trigger, loop: loopOn, skills: ComboParseSkills(skillsRaw) })
    }
    return out
}

ComboLoadProfilesFromPreset(presetName) {
    raw := Trim(LoadPresetSafe(presetName, "ComboProfiles"))
    if (raw != "") {
        return ComboParseProfiles(raw)
    }
    trigger := GetKeycode.CanonMainKey(LoadPresetSafe(presetName, "ComboTriggerKey"))
    skills := ComboParseSkills(LoadPresetSafe(presetName, "ComboSkills"))
    loopOn := LoadPreset(presetName, "ComboLoopMode", false)
    return [{ trigger: trigger, loop: loopOn, skills: skills }]
}

ComboFlushEditorToProfileAt(idx) {
    global __ComboProfiles, __ComboSkillItems
    if (idx < 1 || idx > __ComboProfiles.Length || !__ComboProfiles.Has(idx)) {
        return
    }
    p := __ComboProfiles[idx]
    p.trigger := ComboGetCtrl("ComboTriggerKey").Text
    p.loop := ComboGetCtrl("ComboLoopMode").Value
    p.skills := ComboCloneSkillItems(__ComboSkillItems)
}

ComboLoadProfileToEditor(idx) {
    global __ComboProfiles, __ComboSkillItems
    if (idx < 1 || idx > __ComboProfiles.Length || !__ComboProfiles.Has(idx)) {
        return
    }
    p := __ComboProfiles[idx]
    __ComboSkillItems := ComboCloneSkillItems(p.skills)
    ComboRefreshList()
    ComboGetCtrl("ComboTriggerKey").Text := p.trigger
    ComboGetCtrl("ComboLoopMode").Value := p.loop
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

ComboProfileListChange(ctrl, *) {
    global __ComboProfiles, __ComboProfileIndex, __ComboProfileLoading
    if __ComboProfileLoading {
        return
    }
    newIdx := ctrl.Value
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
    global __ComboProfiles, __ComboProfileIndex, COMBO_PROFILE_MAX
    ComboFlushEditorToProfileAt(__ComboProfileIndex)
    if (__ComboProfiles.Length >= COMBO_PROFILE_MAX) {
        MsgBox(ExText.ComboProfileMax(COMBO_PROFILE_MAX),, "Icon!")
        return
    }
    __ComboProfiles.Push({ trigger: "", loop: false, skills: [] })
    __ComboProfileIndex := __ComboProfiles.Length
    ComboRefreshProfileList()
    ComboLoadProfileToEditor(__ComboProfileIndex)
}

ComboRemoveProfile(*) {
    global __ComboProfiles, __ComboProfileIndex
    if (__ComboProfiles.Length <= 1) {
        MsgBox(ExText.ComboKeepOneProfile(),, "Icon!")
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
    seen := Map()
    loop __ComboProfiles.Length {
        if !__ComboProfiles.Has(A_Index) {
            continue
        }
        t := Trim(__ComboProfiles[A_Index].trigger)
        if (t = "") {
            continue
        }
        c := GetKeycode.CanonMainKey(t)
        if (c = "") {
            continue
        }
        id := GetKeycode.ToRouterId(c)
        if (id = "") {
            continue
        }
        if seen.Has(id) {
            MsgBox(ExText.ComboDuplicateTrigger(t), ExText.ComboTitle(), "Icon!")
            return false
        }
        seen[id] := true
    }
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
    if (__ComboProfiles.Length = 0) {
        __ComboProfiles.Push({ trigger: "", loop: false, skills: [] })
    }
    __ComboProfileIndex := 1
    ComboRefreshProfileList()
    ComboLoadProfileToEditor(__ComboProfileIndex)
}

ComboShowEditDialog(item) {
    global gComboGui, gComboEditGui, gComboEditCtrls, gComboEditKey
    if !IsObject(item) {
        return
    }
    gComboEditKey := item.key
    if !IsObject(gComboEditGui) {
        gComboEditGui := Gui("+ToolWindow -Theme")
        gComboEditCtrls := Map()
        GuiTheme_Apply(gComboEditGui)
        gComboEditGui.OnEvent("Escape", ComboEditCancel)
        gComboEditGui.OnEvent("Close", ComboEditCancel)
        gComboEditCtrls["ComboEditCurrentKey"] := gComboEditGui.Add("Edit", "x16 y38 w120 h24 +ReadOnly -WantCtrlA -E0x200 Border")
        GuiTheme_FlatBtn(gComboEditGui, "x16 y68 w120 h28", ExText.ComboEditChangeKey(), ComboEditChangeKey, false)
        gComboEditGui.Add("Text", "x16 y16 w120 h22 +0x200", ExText.ComboCurrentKeyLabel())
        gComboEditGui.Add("Text", "x148 y16 w100 h22 +0x200", ExText.ComboDelayLabel())
        gComboEditCtrls["ComboEditDelay"] := gComboEditGui.Add("Edit", "x148 y38 w100 h24 +Number -E0x200 Border")
        GuiTheme_FlatBtn(gComboEditGui, "x148 y68 w48 h28", ExText.SaveButton(), ComboEditSave, true)
        GuiTheme_FlatBtn(gComboEditGui, "x200 y68 w48 h28", ExText.CancelButton(), ComboEditCancel, false)
    }
    gComboEditCtrls["ComboEditCurrentKey"].Text := gComboEditKey
    gComboEditCtrls["ComboEditDelay"].Text := ComboNormalizeDelay(item.delay)
    if IsObject(gComboGui) {
        gComboEditGui.Opt("+Owner" gComboGui.Hwnd)
    }
    gComboEditGui.Title := ExText.ComboEditTitle()
    GuiTheme_ShowFit(gComboEditGui)
}

ComboEditChangeKey(*) {
    global gComboEditCtrls, gComboEditKey
    raw := GetPressKey()
    key := GetKeycode.CanonMainKey(raw)
    if (key = "") {
        if (raw != "") {
            MsgBox(ExText.ComboInvalidSkillKey(),, "Icon!")
        }
        return
    }
    gComboEditKey := key
    gComboEditCtrls["ComboEditCurrentKey"].Text := key
}

ComboEditSave(*) {
    global __ComboSkillItems, gComboEditCtrls, gComboEditIndex, gComboEditKey
    if (gComboEditIndex < 1 || gComboEditIndex > __ComboSkillItems.Length || !__ComboSkillItems.Has(gComboEditIndex)) {
        ComboEditCancel()
        return
    }
    delay := ComboNormalizeDelay(gComboEditCtrls["ComboEditDelay"].Text)
    if (gComboEditKey = "") {
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
    if IsObject(gComboEditGui) {
        gComboEditGui.Hide()
    }
}

ComboMoveArrayItemInPlace(arr, fromIndex, toIndex) {
    if !IsObject(arr) {
        return 0
    }
    if (fromIndex <= 0 || toIndex <= 0 || fromIndex > arr.Length || toIndex > arr.Length) {
        return 0
    }
    if (fromIndex = toIndex) {
        return fromIndex
    }
    moving := arr[fromIndex]
    arr.RemoveAt(fromIndex)
    if (toIndex < 1) {
        toIndex := 1
    } else if (toIndex > arr.Length + 1) {
        toIndex := arr.Length + 1
    }
    arr.InsertAt(toIndex, moving)
    return toIndex
}

ComboListIndexFromClientPoint(ctrl, x, y) {
    if !IsObject(ctrl) {
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

ComboListOnLButtonDown(wParam, lParam, msg, hwnd) {
    global gComboDragStartIndex, gComboDragHoverIndex, gComboDragDown, gComboDragPreviewing
    global gComboDragPreviewList, gComboDragCurrentFromIndex, __ComboSkillItems
    ctrl := ComboGetCtrl("ComboSkillsListBox")
    if !IsObject(ctrl) || hwnd != ctrl.Hwnd {
        return
    }
    x := lParam & 0xFFFF
    y := (lParam >> 16) & 0xFFFF
    gComboDragStartIndex := ComboListIndexFromClientPoint(ctrl, x, y)
    gComboDragHoverIndex := gComboDragStartIndex
    gComboDragDown := (gComboDragStartIndex > 0)
    gComboDragPreviewing := false
    gComboDragPreviewList := []
    gComboDragCurrentFromIndex := gComboDragStartIndex
    if gComboDragDown {
        loop __ComboSkillItems.Length {
            if !__ComboSkillItems.Has(A_Index) {
                continue
            }
            item := __ComboSkillItems[A_Index]
            gComboDragPreviewList.Push({ key: item.key, delay: item.delay })
        }
    }
}

ComboListOnMouseMove(wParam, lParam, msg, hwnd) {
    global gComboDragStartIndex, gComboDragHoverIndex, gComboDragDown, gComboDragPreviewing
    global gComboDragPreviewList, gComboDragCurrentFromIndex
    if !gComboDragDown {
        return
    }
    ctrl := ComboGetCtrl("ComboSkillsListBox")
    if !IsObject(ctrl) || hwnd != ctrl.Hwnd {
        return
    }
    if (gComboDragStartIndex <= 0 || !IsObject(gComboDragPreviewList) || gComboDragPreviewList.Length = 0) {
        return
    }
    x := lParam & 0xFFFF
    y := (lParam >> 16) & 0xFFFF
    hoverIndex := ComboListIndexFromClientPoint(ctrl, x, y)
    if (hoverIndex <= 0) {
        return
    }
    fromIndex := gComboDragCurrentFromIndex
    if (hoverIndex = fromIndex || hoverIndex = gComboDragHoverIndex) {
        return
    }
    if (hoverIndex > gComboDragPreviewList.Length) {
        return
    }
    gComboDragHoverIndex := hoverIndex
    newIndex := ComboMoveArrayItemInPlace(gComboDragPreviewList, fromIndex, hoverIndex)
    if (newIndex <= 0) {
        return
    }
    gComboDragCurrentFromIndex := newIndex
    gComboDragPreviewing := true
    ComboSetListBoxFromItems(ctrl, gComboDragPreviewList)
    try ctrl.Choose(newIndex)
}

ComboListOnLButtonUp(wParam, lParam, msg, hwnd) {
    global gComboDragStartIndex, gComboDragHoverIndex, gComboDragDown, gComboDragPreviewing
    global gComboDragPreviewList, gComboDragCurrentFromIndex, __ComboSkillItems
    ctrl := ComboGetCtrl("ComboSkillsListBox")
    if !IsObject(ctrl) || hwnd != ctrl.Hwnd {
        return
    }
    previewing := gComboDragPreviewing
    previewList := gComboDragPreviewList
    currentIndex := gComboDragCurrentFromIndex
    gComboDragStartIndex := 0
    gComboDragHoverIndex := 0
    gComboDragDown := false
    gComboDragPreviewing := false
    gComboDragPreviewList := []
    gComboDragCurrentFromIndex := 0
    if !previewing {
        return
    }
    __ComboSkillItems := previewList
    ComboRefreshList()
    if (currentIndex > 0 && currentIndex <= __ComboSkillItems.Length) {
        try ctrl.Choose(currentIndex)
    }
}
