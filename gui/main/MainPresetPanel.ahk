#Requires AutoHotkey v2.0

class MainPresetPanel {
    static CloneSuffix() {
        return "-copy"
    }

    static KeyIntervalNotSet() {
        return MainWindowText.KeyIntervalNotSet()
    }

    static ClonePreset() {
        oldName := MainGetCtrl("Preset").Text
        if (oldName = "") {
            MsgBox(MainWindowText.PresetInvalid(),, "Icon!")
            return
        }
        defaultName := oldName this.CloneSuffix()
        newName := this.AskPresetName(MainWindowText.ClonePresetPrompt(), MainWindowText.ClonePresetTitle(), defaultName)
        if (newName = "") {
            return
        }
        if this.PresetExists(newName) {
            MsgBox(MainWindowText.PresetNameExists(),, "Icon!")
            return
        }
        if !PresetManager.CloneAs(oldName, newName) {
            MsgBox(MainWindowText.PresetNameExists(),, "Icon!")
            return
        }
        PresetSkillIcon_CopyForPreset(oldName, newName)
        this.ReloadPresetList()
    }

    static DeletePreset() {
        presetName := MainGetCtrl("Preset").Text
        if (presetName = "") {
            MsgBox(MainWindowText.PresetInvalid(),, "Icon!")
            return
        }
        if (LoadAllPreset().Length <= 1) {
            MsgBox(MainWindowText.PresetKeepOne(),, "Icon!")
            return
        }
        ret := MsgBox(MainWindowText.PresetDeleteConfirm(presetName), MainWindowText.PresetDeleteTitle(), "YesNo Icon!")
        if (ret != "Yes") {
            return
        }
        PresetSkillIcon_DeleteForPreset(presetName)
        PresetManager.Delete(presetName)
        this.ReloadPresetList()
    }

    static SetListBox(ctrl, listPipe) {
        GuiTheme_SetListBoxItemsFromPipe(ctrl, listPipe)
    }

    static SetListBoxFromArray(ctrl, items) {
        GuiTheme_SetListBoxItems(ctrl, items)
    }

    static PresetCountFromPipe(pipe) {
        n := 0
        for x in StrSplit(pipe, "|") {
            if (x != "") {
                n++
            }
        }
        return n
    }

    static SafeChooseListItem(ctrl, index, presetListPipe) {
        n := this.PresetCountFromPipe(presetListPipe)
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

    static ReloadPresetList() {
        AutoFireController.Stop()
        presetCtrl := MainGetCtrl("Preset")
        presetNameCtrl := MainGetCtrl("PresetNameEdit")
        presetList := PresetManager.ListPipe()
        nowSelectPreset := GetNowSelectPreset()
        this.SetListBox(presetCtrl, presetList)
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
            if this.SafeChooseListItem(presetCtrl, idx, presetList) {
                AutoFireController.ChangePreset(nowSelectPreset)
                presetNameCtrl.Text := nowSelectPreset
            }
        } else if this.SafeChooseListItem(presetCtrl, 1, presetList) {
            presetName := presetCtrl.Text
            AutoFireController.ChangePreset(presetName)
            presetNameCtrl.Text := presetName
        }
        try AutoPresetSettingsSyncPresetList()
    }

    static OnPresetSelectionChange(*) {
        global gPresetSuppressChange, gPresetDragPreviewing
        if (gPresetSuppressChange || gPresetDragPreviewing) {
            return
        }
        presetName := MainGetCtrl("Preset").Text
        if (presetName = "") {
            return
        }
        MainGetCtrl("PresetNameEdit").Text := presetName
        AutoFireController.ChangePreset(presetName)
    }

    static OnContextMenu(guiObj, ctrlObj, item, isRightClick, x, y) {
        global gPresetContextMenu, gPresetBlankContextMenu, gKeyIntervalMenu, gKeyIntervalMenuTarget
        if !IsObject(ctrlObj) {
            return
        }
        name := ctrlObj.Name
        if MainIsInteractiveKeyName(name) {
            gKeyIntervalMenuTarget := name
            if (x != "" && y != "") {
                gKeyIntervalMenu.Show(x, y)
            } else {
                gKeyIntervalMenu.Show()
            }
            return
        }
        if (name != "Preset") {
            return
        }
        idx := this.ListIndexFromCursor(ctrlObj)
        if (idx > 0) {
            ctrlObj.Choose(idx)
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

    static EditKeyInterval(*) {
        global gKeyIntervalMenuTarget
        key := gKeyIntervalMenuTarget
        presetName := GetNowSelectPreset()
        if (presetName = "" || key = "") {
            return
        }
        m := PresetManager.LoadKeyIntervalOverrides(presetName)
        defaultTxt := m.Has(key) ? String(m[key]) : ""
        ib := InputBox(
            MainWindowText.KeyIntervalPrompt(),
            MainWindowText.KeyIntervalTitle(), "w360", defaultTxt)
        if (ib.Result != "OK") {
            return
        }
        val := Trim(ib.Value)
        if (val = "") {
            if m.Has(key) {
                m.Delete(key)
            }
            PresetManager.SaveKeyIntervalOverrides(presetName, m)
        } else {
            m[key] := PresetManager.NormalizeInterval(val)
            PresetManager.SaveKeyIntervalOverrides(presetName, m)
        }
        MainRefreshAllKeyAppearances()
    }

    static ClearKeyInterval(*) {
        global gKeyIntervalMenuTarget
        key := gKeyIntervalMenuTarget
        presetName := GetNowSelectPreset()
        if (presetName = "" || key = "") {
            return
        }
        m := PresetManager.LoadKeyIntervalOverrides(presetName)
        if !m.Has(key) {
            MsgBox(this.KeyIntervalNotSet(),, "Icon!")
            return
        }
        m.Delete(key)
        PresetManager.SaveKeyIntervalOverrides(presetName, m)
        MainRefreshAllKeyAppearances()
    }

    static CreatePreset(*) {
        name := this.AskPresetName(MainWindowText.CreatePresetPrompt(), MainWindowText.CreatePresetTitle())
        if (name = "") {
            return
        }
        if this.PresetExists(name) {
            MsgBox(MainWindowText.PresetNameExists(),, "Icon!")
            return
        }
        if !PresetManager.Create(name) {
            MsgBox(MainWindowText.PresetNameExists(),, "Icon!")
            return
        }
        this.ReloadPresetList()
    }

    static RenamePreset(*) {
        oldName := MainGetCtrl("Preset").Text
        if (oldName = "") {
            MsgBox(MainWindowText.PresetInvalid(),, "Icon!")
            return
        }
        newName := this.AskPresetName(MainWindowText.RenamePresetPrompt(), MainWindowText.RenamePresetTitle(), oldName)
        if (newName = "" || newName = oldName) {
            return
        }
        if this.PresetExists(newName) {
            MsgBox(MainWindowText.PresetNameExists(),, "Icon!")
            return
        }
        if !PresetManager.Rename(oldName, newName) {
            MsgBox(MainWindowText.PresetNameExists(),, "Icon!")
            return
        }
        this.ReloadPresetList()
    }

    static AskPresetName(prompt, title, default := "") {
        ib := InputBox(prompt, title, "w280 h140", default)
        if (ib.Result != "OK") {
            return ""
        }
        name := Trim(ib.Value)
        if (name = "") {
            MsgBox(MainWindowText.PresetNameEmpty(),, "Icon!")
            return ""
        }
        if InStr(name, "|") {
            MsgBox(MainWindowText.PresetNameInvalidChar(),, "Icon!")
            return ""
        }
        return name
    }

    static PresetExists(name) {
        return PresetManager.Exists(name)
    }

    static InitPreset(name) {
        PresetManager.Initialize(name)
    }

    static ListIndexFromClientPoint(ctrl, x, y) {
        if !IsObject(ctrl) || x = "" || y = "" {
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

    static ListIndexFromScreenPoint(ctrl, sx, sy) {
        if !IsObject(ctrl) || sx = "" || sy = "" {
            return 0
        }
        pt := Buffer(8, 0)
        NumPut("int", sx, pt, 0)
        NumPut("int", sy, pt, 4)
        DllCall("ScreenToClient", "ptr", ctrl.Hwnd, "ptr", pt)
        cx := NumGet(pt, 0, "int")
        cy := NumGet(pt, 4, "int")
        return this.ListIndexFromClientPoint(ctrl, cx, cy)
    }

    static ListIndexFromCursor(ctrl) {
        if !IsObject(ctrl) {
            return 0
        }
        pt := Buffer(8, 0)
        if !DllCall("GetCursorPos", "ptr", pt) {
            return 0
        }
        sx := NumGet(pt, 0, "int")
        sy := NumGet(pt, 4, "int")
        return this.ListIndexFromScreenPoint(ctrl, sx, sy)
    }

    static MovePresetOrder(fromIndex, toIndex) {
        if (fromIndex <= 0 || toIndex <= 0 || fromIndex = toIndex) {
            return
        }
        presetList := LoadAllPreset()
        newIndex := this.MoveArrayItemInPlace(presetList, fromIndex, toIndex)
        if (newIndex <= 0) {
            return
        }
        movingName := presetList[newIndex]
        SavePresetOrder(presetList)
        SetNowSelectPreset(movingName)
        this.ReloadPresetList()
    }

    static MoveArrayItemInPlace(arr, fromIndex, toIndex) {
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
        if (toIndex < 1) {
            toIndex := 1
        } else if (toIndex > arr.Length + 1) {
            toIndex := arr.Length + 1
        }
        arr.InsertAt(toIndex, movingName)
        return toIndex
    }

    static OnListLButtonDown(wParam, lParam, msg, hwnd) {
        global gPresetDragStartIndex, gPresetDragHoverIndex, gPresetDragDown, gPresetDragPreviewing
        global gPresetDragPreviewList, gPresetDragCurrentFromIndex, gPresetDragItemName
        presetCtrl := MainGetCtrl("Preset")
        if !IsObject(presetCtrl) || hwnd != presetCtrl.Hwnd {
            return
        }
        x := lParam & 0xFFFF
        y := (lParam >> 16) & 0xFFFF
        gPresetDragStartIndex := this.ListIndexFromClientPoint(presetCtrl, x, y)
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

    static OnListLButtonUp(wParam, lParam, msg, hwnd) {
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
        this.ReloadPresetList()
        gPresetSuppressChange := false
    }

    static OnListMouseMove(wParam, lParam, msg, hwnd) {
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
        hoverIndex := this.ListIndexFromClientPoint(presetCtrl, x, y)
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
        newIndex := this.MoveArrayItemInPlace(gPresetDragPreviewList, fromIndex, hoverIndex)
        if (newIndex <= 0) {
            return
        }
        gPresetDragCurrentFromIndex := newIndex
        gPresetSuppressChange := true
        this.SetListBoxFromArray(presetCtrl, gPresetDragPreviewList)
        try presetCtrl.Choose(newIndex)
        gPresetSuppressChange := false
    }
}

MainClonePreset(*) => MainPresetPanel.ClonePreset()
MainDeletePreset(*) => MainPresetPanel.DeletePreset()
MainSetListBox(ctrl, listPipe) => MainPresetPanel.SetListBox(ctrl, listPipe)
MainSetListBoxFromArray(ctrl, items) => MainPresetPanel.SetListBoxFromArray(ctrl, items)
MainPresetCountFromPipe(pipe) => MainPresetPanel.PresetCountFromPipe(pipe)
MainPresetListSafeChoose(ctrl, index, presetListPipe) => MainPresetPanel.SafeChooseListItem(ctrl, index, presetListPipe)
MainLoadAllPreset() => MainPresetPanel.ReloadPresetList()
MainChangeListPreset(*) => MainPresetPanel.OnPresetSelectionChange()
MainGuiContextMenu(guiObj, ctrlObj, item, isRightClick, x, y) => MainPresetPanel.OnContextMenu(guiObj, ctrlObj, item, isRightClick, x, y)
MainKeyIntervalMenuEdit(*) => MainPresetPanel.EditKeyInterval()
MainKeyIntervalMenuClear(*) => MainPresetPanel.ClearKeyInterval()
MainCreatePreset(*) => MainPresetPanel.CreatePreset()
MainRenamePreset(*) => MainPresetPanel.RenamePreset()
MainAskPresetName(prompt, title, default := "") => MainPresetPanel.AskPresetName(prompt, title, default)
MainPresetExists(name) => MainPresetPanel.PresetExists(name)
MainInitPreset(name) => MainPresetPanel.InitPreset(name)
MainPresetListIndexFromClientPoint(ctrl, x, y) => MainPresetPanel.ListIndexFromClientPoint(ctrl, x, y)
MainPresetListIndexFromScreenPoint(ctrl, sx, sy) => MainPresetPanel.ListIndexFromScreenPoint(ctrl, sx, sy)
MainPresetListIndexFromCursor(ctrl) => MainPresetPanel.ListIndexFromCursor(ctrl)
MainMovePresetOrder(fromIndex, toIndex) => MainPresetPanel.MovePresetOrder(fromIndex, toIndex)
MainMoveArrayItemInPlace(arr, fromIndex, toIndex) => MainPresetPanel.MoveArrayItemInPlace(arr, fromIndex, toIndex)
MainPresetListOnLButtonDown(wParam, lParam, msg, hwnd) => MainPresetPanel.OnListLButtonDown(wParam, lParam, msg, hwnd)
MainPresetListOnLButtonUp(wParam, lParam, msg, hwnd) => MainPresetPanel.OnListLButtonUp(wParam, lParam, msg, hwnd)
MainPresetListOnMouseMove(wParam, lParam, msg, hwnd) => MainPresetPanel.OnListMouseMove(wParam, lParam, msg, hwnd)
