#Requires AutoHotkey v2.0

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

gComboCtrls["ComboProfilesListBox"] := GuiTheme_AddMainStyleListBox(gComboGui, "ComboProfilesListBox", 12, 34, 196, 210)
gComboCtrls["ComboProfilesListBox"].OnEvent("Change", ComboProfileListChange)
gComboGui.Add("Text", "x12 y12 w196 h22 +0x200", "连招方案")
GuiTheme_FlatBtn(gComboGui, "x12 y252 w94 h26", "新建", ComboAddProfile, false)
GuiTheme_FlatBtn(gComboGui, "x114 y252 w94 h26", "删除", ComboRemoveProfile, false)
gComboCtrls["ComboSkillsListBox"] := GuiTheme_AddMainStyleListBox(gComboGui, "ComboSkillsListBox", 224, 34, 364, 210)
gComboCtrls["ComboSkillsListBox"].OnEvent("DoubleClick", ComboEditSkill)
gComboGui.Add("Text", "x224 y12 w344 h22 +0x200", "连招顺序（双击可修改）")
GuiTheme_FlatBtnSmall(gComboGui, "x574 y10 w22 h22", "?", ComboHelp)
GuiTheme_FlatBtn(gComboGui, "x224 y252 w112 h26", "添加技能", ComboAddSkill, false)
GuiTheme_FlatBtn(gComboGui, "x344 y252 w112 h26", "删除技能", ComboDeleteSkill, false)
gComboGui.Add("Text", "x224 y294 w44 h22 +0x200", "触发键")
gComboCtrls["ComboTriggerKey"] := gComboGui.Add("Edit", "vComboTriggerKey x272 y292 w232 h24 +ReadOnly -WantCtrlA -E0x200 Border")
RegisterEditPressKeyCapture(gComboCtrls["ComboTriggerKey"], GetKeycode.AfterCaptureEdit.Bind(gComboCtrls["ComboTriggerKey"]))
gComboCtrls["ComboLoopMode"] := gComboGui.Add("CheckBox", "vComboLoopMode x512 y294 h22", "循环触发")
GuiTheme_FlatBtn(gComboGui, "x160 y348 w140 h32", "应用方案", ComboApplyProfile, false)
GuiTheme_FlatBtn(gComboGui, "x316 y348 w140 h32", "保存", ComboSaveAndClose, true)

ComboGetCtrl(name) {
    global gComboCtrls
    return gComboCtrls.Has(name) ? gComboCtrls[name] : ""
}

ShowGuiCombo(*) {
    global gMainGui, gComboGui
    if IsObject(gMainGui) {
        gComboGui.Opt("+Owner" gMainGui.Hwnd)
    }
    gComboGui.Title := "一键连招设置"
    gComboGui.Show("w608 h408")
    ComboLoadConfig()
    DisableGuiMain()
}

HideGuiCombo() {
    gComboGui.Hide()
    EnableGuiMain()
}

ComboGuiEscape(*) {
    HideGuiCombo()
}

ComboGuiClose(*) {
    HideGuiCombo()
}

ComboHelp(*) {
    MsgBox("1、添加技能默认延迟 20ms`n2、双击列表项可修改技能键和延迟`n3、拖动列表可调整连招顺序`n4、多套方案须使用不同触发键`n5、「应用方案」写入当前预设但不关窗口；「保存并关闭」写入后关闭`n6、未设置触发键或没有技能时该套不生效`n`n循环开启：按住触发键会持续循环连招`n循环关闭：每次按下只执行一轮连招", "一键连招说明", "Iconi")
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
            MsgBox("仅支持主连发键盘上的键。",, "Icon!")
        }
        return
    }
    delay := 20
    __ComboSkillItems.Push({ key: key, delay: delay })
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
        t := "(未设触发)"
    }
    skills := IsObject(p.skills) ? p.skills : []
    n := skills.Length
    return t " · " n " 个技能"
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
        MsgBox("最多 " COMBO_PROFILE_MAX " 套连招方案",, "Icon!")
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
        MsgBox("至少保留一套方案",, "Icon!")
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
            MsgBox("多套方案的触发键不能相同（冲突键：" t "）",, "Icon!")
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
        gComboEditCtrls["ComboEditCurrentKey"] := gComboEditGui.Add("Edit", "x12 y32 w120 h24 +ReadOnly -WantCtrlA -E0x200 Border")
        GuiTheme_FlatBtn(gComboEditGui, "x12 y62 w120 h28", "修改按键", ComboEditChangeKey, false)
        gComboEditGui.Add("Text", "x12 y10 w120 h22 +0x200", "当前技能键")
        gComboEditGui.Add("Text", "x144 y10 w100 h22 +0x200", "技能后延迟(ms)")
        gComboEditCtrls["ComboEditDelay"] := gComboEditGui.Add("Edit", "x144 y32 w100 h24 +Number -E0x200 Border")
        GuiTheme_FlatBtn(gComboEditGui, "x144 y62 w48 h28", "保存", ComboEditSave, true)
        GuiTheme_FlatBtn(gComboEditGui, "x196 y62 w48 h28", "取消", ComboEditCancel, false)
    }
    gComboEditCtrls["ComboEditCurrentKey"].Text := gComboEditKey
    gComboEditCtrls["ComboEditDelay"].Text := ComboNormalizeDelay(item.delay)
    if IsObject(gComboGui) {
        gComboEditGui.Opt("+Owner" gComboGui.Hwnd)
    }
    gComboEditGui.Title := "修改连招项"
    gComboEditGui.Show("w256 h104")
}

ComboEditChangeKey(*) {
    global gComboEditCtrls, gComboEditKey
    raw := GetPressKey()
    key := GetKeycode.CanonMainKey(raw)
    if (key = "") {
        if (raw != "") {
            MsgBox("仅支持主连发键盘上的键。",, "Icon!")
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
