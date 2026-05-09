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

GuiTheme_Apply(gui) {
    if !IsObject(gui) {
        return
    }
    try gui.BackColor := UiTheme.WindowBg
    gui.SetFont("s10 norm c" UiTheme.KeyOff, GuiTheme_Face)
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
    return "v" vName " x" x " y" y " w" w " h" h " -E0x200 Border BackgroundFFFFFF -VScroll"
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

GuiTheme_AddMainStyleListBox(gui, vName, x, y, w, h) {
    lb := gui.Add("ListBox", GuiTheme_MainCfgPresetListOpts(vName, x, y, w, h), [])
    GuiTheme_RegisterListBoxWheel(lb)
    return lb
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
    return (keyName = "NumLk" || keyName = "NumEnter") ? "s9" : "s12"
}

GuiTheme_HRule(gui, x, y, w) {
    return gui.Add("Text", "x" x " y" y " w" w " h1 +0x200 Background" GuiTheme_KeyCellBg, "")
}

GuiTheme_FlatTextBtn(gui, opts, text, handler) {
    return GuiTheme_FlatBtn(gui, opts, text, handler, false)
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

#Include GdipUiHelpers.ahk
#Include FlatButtonGdip.ahk
#Include ToggleGdip.ahk
