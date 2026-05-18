#Requires AutoHotkey v2.0

global gAutoPresetsRegionPickGui := false
global gAutoPresetsRegionPickHintText := false
global gAutoPresetsRegionPickKeyHook := false
global gAutoPresetsRegionPickNCHook := false
global gAutoPresetsRegionPickNCCalcHook := false
global gAutoPresetsRegionPickPaintHook := false
global gAutoPresetsRegionPickEraseHook := false
global gAutoPresetsRegionPickKind := "skill"

PresetRegionPickReadClientScreen(hwnd) {
    rc := Buffer(16, 0)
    if !DllCall("user32\GetClientRect", "ptr", hwnd, "ptr", rc) {
        return ""
    }
    cw := NumGet(rc, 8, "int") - NumGet(rc, 0, "int")
    ch := NumGet(rc, 12, "int") - NumGet(rc, 4, "int")
    pt := Buffer(8, 0)
    if !DllCall("user32\ClientToScreen", "ptr", hwnd, "ptr", pt) {
        return ""
    }
    return Map("x", NumGet(pt, 0, "int"), "y", NumGet(pt, 4, "int"), "w", cw, "h", ch)
}

PresetRegionPickPaintClient(hdc, hwnd) {
    rc := Buffer(16, 0)
    if !DllCall("user32\GetClientRect", "ptr", hwnd, "ptr", rc) {
        return
    }
    w := NumGet(rc, 8, "int") - NumGet(rc, 0, "int")
    h := NumGet(rc, 12, "int") - NumGet(rc, 4, "int")
    if (w < 1 || h < 1) {
        return
    }

    whiteBrush := DllCall("gdi32\CreateSolidBrush", "uint", 0x00FFFFFF, "ptr")
    if whiteBrush {
        try DllCall("user32\FillRect", "ptr", hdc, "ptr", rc, "ptr", whiteBrush)
        finally DllCall("gdi32\DeleteObject", "ptr", whiteBrush)
    }

    pen := DllCall("gdi32\CreatePen", "int", 0, "int", 2, "uint", 0x00B8B8B8, "ptr")
    if !pen {
        return
    }
    oldPen := DllCall("gdi32\SelectObject", "ptr", hdc, "ptr", pen, "ptr")
    try {
        step := 18
        x := -h
        while (x < w + h) {
            DllCall("gdi32\MoveToEx", "ptr", hdc, "int", x, "int", h, "ptr", 0)
            DllCall("gdi32\LineTo", "ptr", hdc, "int", x + h, "int", 0)
            x += step
        }
    } finally {
        DllCall("gdi32\SelectObject", "ptr", hdc, "ptr", oldPen, "ptr")
        DllCall("gdi32\DeleteObject", "ptr", pen)
    }
}

PresetRegionPickPaint(wParam, lParam, msg, hwnd) {
    global gAutoPresetsRegionPickGui
    if !IsObject(gAutoPresetsRegionPickGui) || (hwnd != gAutoPresetsRegionPickGui.Hwnd) {
        return
    }
    ps := Buffer(A_PtrSize = 8 ? 72 : 64, 0)
    hdc := DllCall("user32\BeginPaint", "ptr", hwnd, "ptr", ps, "ptr")
    if hdc {
        try PresetRegionPickPaintClient(hdc, hwnd)
        finally DllCall("user32\EndPaint", "ptr", hwnd, "ptr", ps)
    }
    return 0
}

PresetRegionPickEraseBkgnd(wParam, lParam, msg, hwnd) {
    global gAutoPresetsRegionPickGui
    if !IsObject(gAutoPresetsRegionPickGui) || (hwnd != gAutoPresetsRegionPickGui.Hwnd) {
        return
    }
    return 1
}

PresetRegionPickApplyDwmStyle(hwnd) {
    val := Buffer(4, 0)

    try {
        NumPut("uint", 1, val, 0)
        DllCall("dwmapi\DwmSetWindowAttribute", "ptr", hwnd, "uint", 38, "ptr", val, "uint", 4, "uint")
    }

    try {
        NumPut("uint", 1, val, 0)
        DllCall("dwmapi\DwmSetWindowAttribute", "ptr", hwnd, "uint", 33, "ptr", val, "uint", 4, "uint")
    }

    try {
        NumPut("uint", 1, val, 0)
        DllCall("dwmapi\DwmSetWindowAttribute", "ptr", hwnd, "uint", 2, "ptr", val, "uint", 4, "uint")
    }

    try {
        NumPut("uint", 0x00FFFFFF, val, 0)
        DllCall("dwmapi\DwmSetWindowAttribute", "ptr", hwnd, "uint", 34, "ptr", val, "uint", 4, "uint")
    }
}

PresetRegionPickNCCalcSize(wParam, lParam, msg, hwnd) {
    global gAutoPresetsRegionPickGui
    if !IsObject(gAutoPresetsRegionPickGui) || (hwnd != gAutoPresetsRegionPickGui.Hwnd) {
        return
    }
    if !wParam || !lParam {
        return
    }
    DllCall("kernel32\RtlCopyMemory", "ptr", lParam + 16, "ptr", lParam + 0, "uptr", 16)
    return 0x100
}

PresetRegionPickSetOuterFromClientScreen(hwnd, sx, sy, cw, ch) {
    DllCall("user32\SetWindowPos", "ptr", hwnd, "ptr", 0, "int", sx, "int", sy, "int", cw, "int", ch, "uint", 0x0044)
}

PresetRegionPickLayoutHint(guiObj, minMax := 0, width := 0, height := 0) {
    global gAutoPresetsRegionPickHintText
    if !IsObject(guiObj) || !IsObject(gAutoPresetsRegionPickHintText) {
        return
    }
    if (width < 1 || height < 1) {
        return
    }
    gAutoPresetsRegionPickHintText.Move(0, 0, width, height)
}

PresetRegionPickCommitIfOpen() {
    global gAutoPresetsRegionPickGui
    if !IsObject(gAutoPresetsRegionPickGui) || !WinExist("ahk_id " gAutoPresetsRegionPickGui.Hwnd) {
        return
    }
    PresetRegionPickOk()
}

PresetRegionPickCancelIfOpen() {
    global gAutoPresetsRegionPickGui
    if IsObject(gAutoPresetsRegionPickGui) && WinExist("ahk_id " gAutoPresetsRegionPickGui.Hwnd) {
        PresetRegionPickCancel()
    }
}

PresetRegionPickInstallHooks() {
    global gAutoPresetsRegionPickKeyHook, gAutoPresetsRegionPickNCHook, gAutoPresetsRegionPickNCCalcHook
    global gAutoPresetsRegionPickPaintHook, gAutoPresetsRegionPickEraseHook
    if !gAutoPresetsRegionPickKeyHook {
        OnMessage(0x0100, PresetRegionPickKey)
        gAutoPresetsRegionPickKeyHook := true
    }
    if !gAutoPresetsRegionPickNCHook {
        OnMessage(0x0084, PresetRegionPickNCHitTest)
        gAutoPresetsRegionPickNCHook := true
    }
    if !gAutoPresetsRegionPickNCCalcHook {
        OnMessage(0x0083, PresetRegionPickNCCalcSize)
        gAutoPresetsRegionPickNCCalcHook := true
    }
    if !gAutoPresetsRegionPickPaintHook {
        OnMessage(0x000F, PresetRegionPickPaint)
        gAutoPresetsRegionPickPaintHook := true
    }
    if !gAutoPresetsRegionPickEraseHook {
        OnMessage(0x0014, PresetRegionPickEraseBkgnd)
        gAutoPresetsRegionPickEraseHook := true
    }
}

PresetRegionPickUninstallHooks() {
    global gAutoPresetsRegionPickKeyHook, gAutoPresetsRegionPickNCHook, gAutoPresetsRegionPickNCCalcHook
    global gAutoPresetsRegionPickPaintHook, gAutoPresetsRegionPickEraseHook
    if gAutoPresetsRegionPickKeyHook {
        OnMessage(0x0100, PresetRegionPickKey, 0)
        gAutoPresetsRegionPickKeyHook := false
    }
    if gAutoPresetsRegionPickNCHook {
        OnMessage(0x0084, PresetRegionPickNCHitTest, 0)
        gAutoPresetsRegionPickNCHook := false
    }
    if gAutoPresetsRegionPickNCCalcHook {
        OnMessage(0x0083, PresetRegionPickNCCalcSize, 0)
        gAutoPresetsRegionPickNCCalcHook := false
    }
    if gAutoPresetsRegionPickPaintHook {
        OnMessage(0x000F, PresetRegionPickPaint, 0)
        gAutoPresetsRegionPickPaintHook := false
    }
    if gAutoPresetsRegionPickEraseHook {
        OnMessage(0x0014, PresetRegionPickEraseBkgnd, 0)
        gAutoPresetsRegionPickEraseHook := false
    }
}

PresetRegionPickOpen(kind := "skill") {
    global gAutoPresetsRegionPickGui, gAutoPresetsRegionPickHintText, gAutoPresetsRegionPickKind
    if IsObject(gAutoPresetsRegionPickGui) && WinExist("ahk_id " gAutoPresetsRegionPickGui.Hwnd) {
        PresetRegionPickOk()
    }
    gAutoPresetsRegionPickKind := kind
    if IsObject(gAutoPresetsRegionPickGui) {
        try gAutoPresetsRegionPickGui.Destroy()
        gAutoPresetsRegionPickGui := false
    }
    gAutoPresetsRegionPickGui := Gui("+AlwaysOnTop +Resize +ToolWindow +MinSize8x8 -Caption -Border -DPIScale +E0x80000", "")
    gAutoPresetsRegionPickGui.MarginX := 0
    gAutoPresetsRegionPickGui.MarginY := 0
    gAutoPresetsRegionPickGui.BackColor := "FFFFFF"
    UiInstallBlankClickBlur(gAutoPresetsRegionPickGui)
    gAutoPresetsRegionPickGui.OnEvent("Close", PresetRegionPickCancel)
    gAutoPresetsRegionPickGui.OnEvent("Size", PresetRegionPickLayoutHint)
    UiSetDefaultFont(gAutoPresetsRegionPickGui, "s10 " UiTheme["TextColor"])
    gAutoPresetsRegionPickHintText := gAutoPresetsRegionPickGui.Add("Text", "x0 y0 w200 h90 BackgroundTrans +Center 0x200", AutoPresetsText["RegionPickHint"])
    gAutoPresetsRegionPickGui.Show("Hide w200 h90")
    PresetRegionPickLayoutHint(gAutoPresetsRegionPickGui, 0, 200, 90)
    hwnd := gAutoPresetsRegionPickGui.Hwnd
    if (kind = "town") {
        r := ParseAutoPresetTownRegion()
    } else {
        r := ParseAutoPresetRegion()
    }
    if r.Has("w") {
        PresetRegionPickSetOuterFromClientScreen(hwnd, r["x"], r["y"], r["w"], r["h"])
    } else {
        cw := 200
        ch := 90
        sx := (A_ScreenWidth - cw) // 2
        sy := (A_ScreenHeight - ch) // 2
        PresetRegionPickSetOuterFromClientScreen(hwnd, sx, sy, cw, ch)
    }
    PresetRegionPickApplyDwmStyle(hwnd)
    WinSetTransparent(185, "ahk_id " hwnd)
    PresetRegionPickInstallHooks()
    DllCall("user32\SetWindowPos", "ptr", hwnd, "ptr", 0, "int", 0, "int", 0, "int", 0, "int", 0, "uint", 0x0027)
}

PresetRegionPickNCHitTest(wParam, lParam, msg, hwnd) {
    global gAutoPresetsRegionPickGui
    if !IsObject(gAutoPresetsRegionPickGui) || (hwnd != gAutoPresetsRegionPickGui.Hwnd) {
        return
    }
    x := lParam & 0xFFFF
    if (x >= 0x8000) {
        x := x - 0x10000
    }
    y := (lParam >> 16) & 0xFFFF
    if (y >= 0x8000) {
        y := y - 0x10000
    }
    DllCall("user32\GetWindowRect", "ptr", hwnd, "ptr", rc := Buffer(16))
    wl := NumGet(rc, 0, "int")
    wt := NumGet(rc, 4, "int")
    wr := NumGet(rc, 8, "int")
    wb := NumGet(rc, 12, "int")
    b := 12
    onLeft := (x < wl + b)
    onRight := (x >= wr - b)
    onTop := (y < wt + b)
    onBottom := (y >= wb - b)
    if (onTop && onLeft) {
        return 13
    }
    if (onTop && onRight) {
        return 14
    }
    if (onBottom && onLeft) {
        return 16
    }
    if (onBottom && onRight) {
        return 17
    }
    if (onTop) {
        return 12
    }
    if (onBottom) {
        return 15
    }
    if (onLeft) {
        return 10
    }
    if (onRight) {
        return 11
    }
    return 2
}

PresetRegionPickKey(wParam, lParam, msg, hwnd) {
    global gAutoPresetsRegionPickGui
    if !IsObject(gAutoPresetsRegionPickGui) {
        return
    }
    rootHwnd := DllCall("user32\GetAncestor", "ptr", hwnd, "uint", 2, "ptr")
    if (rootHwnd != gAutoPresetsRegionPickGui.Hwnd) {
        return
    }
    if !WinActive("ahk_id " rootHwnd) {
        return
    }
    vk := wParam & 0xFF
    if (vk = 0x0D) {
        PresetRegionPickOk()
    } else if (vk = 0x1B) {
        PresetRegionPickCancel()
    }
}

PresetRegionPickOk(*) {
    global gAutoPresetsRegionPickGui, gAutoPresetsRegionPickKind
    if !IsObject(gAutoPresetsRegionPickGui) {
        return
    }
    cr := PresetRegionPickReadClientScreen(gAutoPresetsRegionPickGui.Hwnd)
    if (cr = "") {
        return
    }
    x := cr["x"]
    y := cr["y"]
    w := cr["w"]
    h := cr["h"]
    kind := gAutoPresetsRegionPickKind
    if (kind = "town") {
        SaveAutoPresetTownRegion(x, y, w, h)
    } else {
        SaveAutoPresetRegion(x, y, w, h)
    }
    try AutoPresetsAfterRegionPick(kind)
    PresetRegionPickClose()
}

PresetRegionPickCancel(*) {
    PresetRegionPickClose()
}

PresetRegionPickClose() {
    global gAutoPresetsRegionPickGui, gAutoPresetsRegionPickHintText
    PresetRegionPickUninstallHooks()
    if IsObject(gAutoPresetsRegionPickGui) {
        try gAutoPresetsRegionPickGui.Destroy()
    }
    gAutoPresetsRegionPickGui := false
    gAutoPresetsRegionPickHintText := false
}
