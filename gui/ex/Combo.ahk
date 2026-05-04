#Requires AutoHotkey v2.0

global gComboGui := Gui("+ToolWindow")
global gComboCtrls := Map()
global __ComboSkillItems := []
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

gComboGui.OnEvent("Escape", ComboGuiEscape)
gComboGui.OnEvent("Close", ComboGuiClose)
OnMessage(0x0201, ComboListOnLButtonDown)
OnMessage(0x0202, ComboListOnLButtonUp)
OnMessage(0x0200, ComboListOnMouseMove)

gComboCtrls["ComboSkillsListBox"] := gComboGui.Add("ListBox", "vComboSkillsListBox x8 y32 w140 h212")
gComboCtrls["ComboSkillsListBox"].OnEvent("DoubleClick", ComboEditSkill)
gComboCtrls["ComboTriggerKey"] := gComboGui.Add("Edit", "vComboTriggerKey x156 y124 w92 h20 +ReadOnly -WantCtrlA")
gComboCtrls["ComboLoopMode"] := gComboGui.Add("CheckBox", "vComboLoopMode x156 y172 h20", "循环触发")
gComboGui.Add("Button", "x156 y40 w92 h22", "添加技能").OnEvent("Click", ComboAddSkill)
gComboGui.Add("Button", "x156 y68 w92 h22", "删除技能").OnEvent("Click", ComboDeleteSkill)
gComboGui.Add("Button", "x156 y148 w92 h22", "设置触发键").OnEvent("Click", ComboSetTriggerKey)
gComboGui.Add("Button", "x156 y226 w92 h24", "保存").OnEvent("Click", ComboSave)
gComboGui.Add("Text", "x8 y8 w140 h20 +0x200", "连招顺序（双击可修改）")
gComboGui.Add("Text", "x156 y104 w92 h20 +0x200", "触发键")
gComboGui.Add("Button", "x230 y8 w18 h18", "?").OnEvent("Click", ComboHelp)

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
    gComboGui.Show("w256 h260")
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
    MsgBox("1、添加技能默认延迟 20ms`n2、双击列表项可修改技能键和延迟`n3、拖动列表可调整连招顺序`n4、设置触发键并保存（未设置触发键时连招不生效）`n`n循环开启：按住触发键会持续循环连招`n循环关闭：每次按下只执行一轮连招", "一键连招说明", "Iconi")
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
    key := GetPressKey()
    if (key = "") {
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

ComboSetTriggerKey(*) {
    ComboGetCtrl("ComboTriggerKey").Text := GetPressKey()
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
        delayRaw := parts.Length >= 2 ? parts[2] : 20
        items.Push({ key: key, delay: ComboNormalizeDelay(delayRaw) })
    }
    return items
}

ComboSave(*) {
    ComboSaveConfig()
    HideGuiCombo()
}

ComboSaveConfig() {
    global __ComboSkillItems
    triggerKey := ComboGetCtrl("ComboTriggerKey").Text
    SavePreset(GetNowSelectPreset(), "ComboTriggerKey", triggerKey)
    SavePreset(GetNowSelectPreset(), "ComboLoopMode", ComboGetCtrl("ComboLoopMode").Value)
    SavePreset(GetNowSelectPreset(), "ComboSkills", ComboSerializeSkills(__ComboSkillItems))
}

ComboLoadConfig() {
    global __ComboSkillItems
    __ComboSkillItems := ComboParseSkills(LoadPreset(GetNowSelectPreset(), "ComboSkills", ""))
    ComboRefreshList()
    ComboGetCtrl("ComboTriggerKey").Text := LoadPreset(GetNowSelectPreset(), "ComboTriggerKey", "")
    ComboGetCtrl("ComboLoopMode").Value := LoadPreset(GetNowSelectPreset(), "ComboLoopMode", false)
}

ComboShowEditDialog(item) {
    global gComboGui, gComboEditGui, gComboEditCtrls, gComboEditKey
    if !IsObject(item) {
        return
    }
    gComboEditKey := item.key
    if !IsObject(gComboEditGui) {
        gComboEditGui := Gui("+ToolWindow")
        gComboEditCtrls := Map()
        gComboEditGui.OnEvent("Escape", ComboEditCancel)
        gComboEditGui.OnEvent("Close", ComboEditCancel)
        gComboEditCtrls["ComboEditCurrentKey"] := gComboEditGui.Add("Edit", "x8 y28 w120 h22 +ReadOnly -WantCtrlA")
        gComboEditGui.Add("Button", "x8 y56 w120 h24", "修改按键").OnEvent("Click", ComboEditChangeKey)
        gComboEditGui.Add("Text", "x8 y8 w120 h20 +0x200", "当前技能键")
        gComboEditGui.Add("Text", "x140 y8 w100 h20 +0x200", "技能后延迟(ms)")
        gComboEditCtrls["ComboEditDelay"] := gComboEditGui.Add("Edit", "x140 y28 w100 h22 +Number")
        gComboEditGui.Add("Button", "x140 y56 w48 h24", "保存").OnEvent("Click", ComboEditSave)
        gComboEditGui.Add("Button", "x192 y56 w48 h24", "取消").OnEvent("Click", ComboEditCancel)
    }
    gComboEditCtrls["ComboEditCurrentKey"].Text := gComboEditKey
    gComboEditCtrls["ComboEditDelay"].Text := ComboNormalizeDelay(item.delay)
    if IsObject(gComboGui) {
        gComboEditGui.Opt("+Owner" gComboGui.Hwnd)
    }
    gComboEditGui.Title := "修改连招项"
    gComboEditGui.Show("w248 h90")
}

ComboEditChangeKey(*) {
    global gComboEditCtrls, gComboEditKey
    key := GetPressKey()
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
