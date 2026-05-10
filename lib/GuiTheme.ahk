#Requires AutoHotkey v2.0

#Include <UiTheme>

global GuiTheme_Face := UiTheme.Face
global GuiTheme_Hint := UiTheme.Hint
global GuiTheme_KeyOff := UiTheme.KeyOff
global GuiTheme_KeyOn := UiTheme.KeyOn
global GuiTheme_KeyOv := UiTheme.KeyOv
global GuiTheme_KeyCellBg := UiTheme.KeyCellBg
global GuiTheme_SwitchTrackOn := UiTheme.SwitchTrackOn

; 使用 -VScroll 隐藏竖条时，靠 WM_MOUSEWHEEL + LB_SETTOPINDEX 滚动（见 GuiTheme_RegisterListBoxWheel）
global GuiTheme__LbWheelHwnds := Map()
global GuiTheme__HandCursorHwnds := Map()
global GuiTheme__HandCursorHandle := 0
global GuiTheme__FocusSinkByGuiHwnd := Map()
global GuiTheme__GuiByHwnd := Map()

GuiTheme_Apply(gui) {
    if !IsObject(gui) {
        return
    }
    try gui.BackColor := UiTheme.WindowBg
    gui.SetFont("s10 norm c" UiTheme.KeyOff, GuiTheme_Face)
    static cursorHooked := false
    if !cursorHooked {
        cursorHooked := true
        OnMessage(0x0020, GuiTheme__OnSetCursor)
    }
    GuiTheme_EnableBlankClickBlur(gui)
}

GuiTheme_EnableBlankClickBlur(gui) {
    global GuiTheme__FocusSinkByGuiHwnd, GuiTheme__GuiByHwnd
    if !IsObject(gui) {
        return
    }
    try guiHwnd := gui.Hwnd
    catch {
        return
    }
    if !guiHwnd {
        return
    }
    if !GuiTheme__FocusSinkByGuiHwnd.Has(guiHwnd) {
        sink := gui.Add("Edit", "x-100 y-100 w1 h1 -WantCtrlA -WantReturn")
        GuiTheme__FocusSinkByGuiHwnd[guiHwnd] := sink
    }
    GuiTheme__GuiByHwnd[guiHwnd] := gui
    static blurHooked := false
    if !blurHooked {
        blurHooked := true
        OnMessage(0x0201, GuiTheme__OnLButtonDownBlur)
    }
}

GuiTheme_FocusSink(gui) {
    global GuiTheme__FocusSinkByGuiHwnd
    if !IsObject(gui) {
        return
    }
    try guiHwnd := gui.Hwnd
    catch {
        return
    }
    if !GuiTheme__FocusSinkByGuiHwnd.Has(guiHwnd) {
        return
    }
    sink := GuiTheme__FocusSinkByGuiHwnd[guiHwnd]
    try sink.Focus()
}

GuiTheme__GetClassName(hwnd) {
    if !hwnd {
        return ""
    }
    buf := Buffer(256, 0)
    len := DllCall("user32\GetClassName", "ptr", hwnd, "ptr", buf, "int", 128, "int")
    if (len <= 0) {
        return ""
    }
    return StrGet(buf, len)
}

GuiTheme__IsInputClass(className) {
    return (className = "Edit"
        || className = "ListBox"
        || className = "ComboBox"
        || className = "msctls_hotkey32")
}

GuiTheme__OnLButtonDownBlur(wParam, lParam, msg, hwnd) {
    global GuiTheme__FocusSinkByGuiHwnd, GuiTheme__GuiByHwnd
    if !hwnd {
        return
    }
    rootHwnd := DllCall("user32\GetAncestor", "ptr", hwnd, "uint", 2, "ptr")
    if !rootHwnd || !GuiTheme__FocusSinkByGuiHwnd.Has(rootHwnd) || !GuiTheme__GuiByHwnd.Has(rootHwnd) {
        return
    }
    sink := GuiTheme__FocusSinkByGuiHwnd[rootHwnd]
    try sinkHwnd := sink.Hwnd
    catch {
        return
    }
    if (hwnd = sinkHwnd) {
        return
    }
    if (hwnd != rootHwnd) {
        className := GuiTheme__GetClassName(hwnd)
        if GuiTheme__IsInputClass(className) {
            return
        }
    }
    guiObj := GuiTheme__GuiByHwnd[rootHwnd]
    SetTimer((*) => GuiTheme_FocusSink(guiObj), -1)
}

; GDI+ 圆角按钮；primary 为真时使用主色（保存等强调按钮）。
GuiTheme_FlatBtn(gui, opts, text, handler, primary := false) {
    return FlatButtonGdip(gui, opts, text, handler, primary).ctrl
}

GuiTheme_FlatBtnSmall(gui, opts, text, handler) {
    return GuiTheme_FlatBtn(gui, opts, text, handler, false)
}

GuiTheme_FlatBtnCompact(gui, opts, text, handler) {
    return GuiTheme_FlatBtn(gui, opts, text, handler, false)
}

; 主界面与各 EX 子窗口统一：细边框、白底、-E0x200、-VScroll（隐藏滚动条）；滚轮由 GuiTheme_RegisterListBoxWheel 处理。
GuiTheme_MainCfgPresetListOpts(vName, x, y, w, h) {
    return "v" vName " x" x " y" y " w" w " h" h " -E0x200 +0x100 Border BackgroundFFFFFF -VScroll"
}

GuiTheme_RegisterListBoxWheel(ctrl) {
    global GuiTheme__LbWheelHwnds
    try hw := ctrl.Hwnd
    catch {
        return
    }
    GuiTheme__LbWheelHwnds[hw] := true
    static hooked := false
    if !hooked {
        hooked := true
        OnMessage(0x020A, GuiTheme__ListBoxOnMouseWheel)
    }
}

GuiTheme_RegisterHandCursor(ctrl) {
    global GuiTheme__HandCursorHwnds
    if !IsObject(ctrl) {
        return
    }
    try hw := ctrl.Hwnd
    catch {
        return
    }
    if !hw {
        return
    }
    rootHwnd := DllCall("user32\GetAncestor", "ptr", hw, "uint", 2, "ptr")
    GuiTheme__HandCursorHwnds[hw] := rootHwnd ? rootHwnd : hw
}

GuiTheme_AddListBox(gui, vName, x, y, w, h) {
    lb := gui.Add("ListBox", GuiTheme_MainCfgPresetListOpts(vName, x, y, w, h), [])
    GuiTheme_RegisterListBoxWheel(lb)
    return lb
}

GuiTheme_SetListBoxItems(ctrl, items := unset) {
    if !IsObject(ctrl) {
        return
    }
    ctrl.Delete()
    if !IsSet(items) || !IsObject(items) {
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

GuiTheme_SetListBoxItemsFromPipe(ctrl, listPipe) {
    items := []
    for item in StrSplit(listPipe, "|") {
        if (item != "") {
            items.Push(item)
        }
    }
    GuiTheme_SetListBoxItems(ctrl, items)
}

GuiTheme__ListBoxOnMouseWheel(wParam, lParam, msg, hwnd) {
    global GuiTheme__LbWheelHwnds
    MouseGetPos(, , , &ctrlHwnd, 2)
    if !GuiTheme__LbWheelHwnds.Has(ctrlHwnd) {
        return
    }
    wd := (wParam >> 16) & 0xFFFF
    if (wd > 0x7FFF) {
        wd -= 0x10000
    }
    cnt := SendMessage(0x018B, 0, 0,, ctrlHwnd)
    if (cnt <= 0 || cnt = 0xFFFFFFFF) {
        return
    }
    topIdx := SendMessage(0x018E, 0, 0,, ctrlHwnd)
    ih := SendMessage(0x01A1, 0, 0,, ctrlHwnd)
    if (ih <= 0) {
        ih := 16
    }
    rc := Buffer(16)
    if !DllCall("user32\GetClientRect", "ptr", ctrlHwnd, "ptr", rc) {
        return
    }
    chh := NumGet(rc, 12, "int") - NumGet(rc, 4, "int")
    if (chh <= 0) {
        chh := 100
    }
    vis := Max(1, Floor(chh / ih))
    maxTop := Max(0, cnt - vis)
    scrollLines := 3
    slBuf := Buffer(4, 0)
    if DllCall("user32\SystemParametersInfoW", "uint", 104, "uint", 0, "ptr", slBuf.Ptr, "uint", 0) {
        sl := NumGet(slBuf, 0, "uint")
        if (sl > 0 && sl < 0xFFFFFFFF) {
            scrollLines := sl
        }
    }
    scrollLines := Max(1, scrollLines)
    step := (wd > 0) ? -scrollLines : scrollLines
    newTop := Max(0, Min(topIdx + step, maxTop))
    SendMessage(0x0197, newTop, 0,, ctrlHwnd)
    return 0
}

GuiTheme__OnSetCursor(wParam, lParam, msg, hwnd) {
    global GuiTheme__HandCursorHwnds, GuiTheme__HandCursorHandle
    currentRoot := DllCall("user32\GetAncestor", "ptr", hwnd, "uint", 2, "ptr")
    if !currentRoot {
        currentRoot := hwnd
    }
    pt := Buffer(8, 0)
    if !DllCall("user32\GetCursorPos", "ptr", pt) {
        return
    }
    px := NumGet(pt, 0, "int")
    py := NumGet(pt, 4, "int")
    rc := Buffer(16, 0)
    for handHwnd, rootHwnd in GuiTheme__HandCursorHwnds {
        if (rootHwnd != currentRoot) {
            continue
        }
        if !DllCall("user32\GetWindowRect", "ptr", handHwnd, "ptr", rc) {
            continue
        }
        left := NumGet(rc, 0, "int")
        top := NumGet(rc, 4, "int")
        right := NumGet(rc, 8, "int")
        bottom := NumGet(rc, 12, "int")
        if (px >= left && px < right && py >= top && py < bottom) {
            if !GuiTheme__HandCursorHandle {
                GuiTheme__HandCursorHandle := DllCall("user32\LoadCursor", "ptr", 0, "ptr", 32649, "ptr")
            }
            if GuiTheme__HandCursorHandle {
                DllCall("user32\SetCursor", "ptr", GuiTheme__HandCursorHandle)
                return true
            }
        }
    }
}

; 主界面键盘格：背景与 SS 标志；locked 时 +Disabled（Esc / Win 等）
GuiTheme_MainKeyCellSuffix(locked := false) {
    suf := " Background" GuiTheme_KeyCellBg " -E0x200 +0x200 +0x100 +Center"
    if (locked) {
        suf .= " +Disabled"
    }
    return suf
}

; 主界面键帽字号（与 MainSetKeyState 一致）
GuiTheme_MainKeyLabelFontSize(keyName) {
    switch keyName {
        case "Backspace", "Backslash", "Enter", "LShift", "RShift", "LCtrl", "RCtrl", "LAlt", "RAlt", "Space", "NumLk", "NumEnter":
            return "s10"
        case "Caps", "Tab":
            return "s10"
        case "Up", "Down", "Left", "Right":
            return "s14"
        default:
            return "s12"
    }
}

GuiTheme_HRule(gui, x, y, w) {
    return gui.Add("Text", "x" x " y" y " w" w " h1 +0x200 Background" GuiTheme_KeyCellBg, "")
}

GuiTheme_FlatTextBtn(gui, opts, text, handler, primary := false) {
    return GuiTheme_FlatBtn(gui, opts, text, handler, primary)
}

; 经典双 Text 开关（子窗体仍可复用）；主界面扩展行优先用 ToggleGdip。
GuiTheme_FlatSwitch(gui, x, y, tw, th) {
    ks := th - 4
    track := gui.Add("Text", "x" x " y" y " w" tw " h" th " +0x200 Background" GuiTheme_KeyCellBg, "")
    knob := gui.Add("Text", Format("x{} y{} w{} h{} +0x200 BackgroundFFFFFF", x + 2, y + 2, ks, ks), "")
    return { track: track, knob: knob, x: x, y: y, tw: tw, th: th, ks: ks }
}

GuiTheme_FlatSwitchPaint(ui, on) {
    global GuiTheme_KeyCellBg, GuiTheme_SwitchTrackOn
    if !IsObject(ui) || !IsObject(ui.track) || !IsObject(ui.knob) {
        return
    }
    ui.track.Opt("+Background" (on ? GuiTheme_SwitchTrackOn : GuiTheme_KeyCellBg))
    kx := on ? (ui.x + ui.tw - ui.ks - 2) : (ui.x + 2)
    ui.knob.Move(kx, ui.y + 2, ui.ks, ui.ks)
}

GuiTheme_FlatChromeHwnd(hwnd) {
    if !hwnd {
        return
    }
    try DllCall("uxtheme\SetWindowTheme", "ptr", hwnd, "wstr", "", "wstr", "")
}

GuiTheme_ContentMaxRight(gui, includeHidden := true) {
    maxRight := 0
    if !IsObject(gui) {
        return maxRight
    }
    for ctrl in gui {
        if !IsObject(ctrl) {
            continue
        }
        if (!includeHidden) {
            try {
                if !ctrl.Visible {
                    continue
                }
            } catch {
            }
        }
        try ctrl.GetPos(&x, &y, &w, &h)
        catch {
            continue
        }
        right := x + w
        if (right > maxRight) {
            maxRight := right
        }
    }
    return maxRight
}

GuiTheme_ContentMaxBottom(gui, includeHidden := true) {
    maxBottom := 0
    if !IsObject(gui) {
        return maxBottom
    }
    for ctrl in gui {
        if !IsObject(ctrl) {
            continue
        }
        if (!includeHidden) {
            try {
                if !ctrl.Visible {
                    continue
                }
            } catch {
            }
        }
        try ctrl.GetPos(&x, &y, &w, &h)
        catch {
            continue
        }
        bottom := y + h
        if (bottom > maxBottom) {
            maxBottom := bottom
        }
    }
    return maxBottom
}

GuiTheme_ShowFit(gui, extraOpts := "", rightPad := 16, bottomPad := 16, minW := 0, minH := 0, includeHidden := true) {
    w := Max(minW, GuiTheme_ContentMaxRight(gui, includeHidden) + rightPad)
    h := Max(minH, GuiTheme_ContentMaxBottom(gui, includeHidden) + bottomPad)
    opts := Trim(extraOpts)
    if (opts != "") {
        opts .= " "
    }
    gui.Show(opts . "w" w . " h" h)
    SetTimer((*) => GuiTheme_FocusSink(gui), -1)
}

#Include GdipUiHelpers.ahk
#Include FlatButtonGdip.ahk
#Include ToggleGdip.ahk
