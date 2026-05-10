#Requires AutoHotkey v2.0

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
    global gRegionPickGui
    if !IsObject(gRegionPickGui) || (hwnd != gRegionPickGui.Hwnd) {
        return
    }
    if !wParam || !lParam {
        return
    }
    DllCall("kernel32\RtlCopyMemory", "ptr", lParam + 16, "ptr", lParam + 0, "uptr", 16)
    return 0x100
}

PresetRegionPickSetOuterFromClientScreen(hwnd, sx, sy, cw, ch) {
    style := DllCall("user32\GetWindowLong", "ptr", hwnd, "int", -16, "uint")
    ex := DllCall("user32\GetWindowLong", "ptr", hwnd, "int", -20, "uint")
    rc := Buffer(16, 0)
    NumPut("int", 0, rc, 0)
    NumPut("int", 0, rc, 4)
    NumPut("int", cw, rc, 8)
    NumPut("int", ch, rc, 12)
    adjusted := false
    try {
        dpi := DllCall("user32\GetDpiForWindow", "ptr", hwnd, "uint")
        if (dpi) {
            adjusted := DllCall("user32\AdjustWindowRectExForDpi", "ptr", rc, "uint", style, "int", 0, "uint", ex, "uint", dpi, "int")
        }
    } catch {
        adjusted := false
    }
    if !adjusted {
        NumPut("int", 0, rc, 0)
        NumPut("int", 0, rc, 4)
        NumPut("int", cw, rc, 8)
        NumPut("int", ch, rc, 12)
        DllCall("user32\AdjustWindowRectEx", "ptr", rc, "uint", style, "int", 0, "uint", ex)
    }
    l := NumGet(rc, 0, "int")
    t := NumGet(rc, 4, "int")
    rr := NumGet(rc, 8, "int")
    b := NumGet(rc, 12, "int")
    ow := rr - l
    oh := b - t
    ox := sx + l
    oy := sy + t
    DllCall("user32\SetWindowPos", "ptr", hwnd, "ptr", 0, "int", ox, "int", oy, "int", ow, "int", oh, "uint", 0x0044)
}

PresetRegionPickCommitSkillRegionIfOpen() {
    global gRegionPickGui, gRegionPickKind
    if !IsObject(gRegionPickGui) || !WinExist("ahk_id " gRegionPickGui.Hwnd) {
        return
    }
    if (gRegionPickKind != "skill") {
        return
    }
    PresetRegionPickOk()
}

PresetRegionPickCommitIfOpen() {
    global gRegionPickGui
    if !IsObject(gRegionPickGui) || !WinExist("ahk_id " gRegionPickGui.Hwnd) {
        return
    }
    PresetRegionPickOk()
}

PresetRegionPickCommitCalibrateRegionIfOpen() {
    global gRegionPickGui, gRegionPickKind
    if !IsObject(gRegionPickGui) || !WinExist("ahk_id " gRegionPickGui.Hwnd) {
        return
    }
    if (gRegionPickKind != "calibrate") {
        return
    }
    PresetRegionPickOk()
}

PresetRegionPickCancelIfOpen() {
    global gRegionPickGui
    if IsObject(gRegionPickGui) && WinExist("ahk_id " gRegionPickGui.Hwnd) {
        PresetRegionPickCancel()
    }
}

PresetRegionPickOpen(kind := "skill") {
    global gRegionPickGui, gRegionPickKeyHook, gRegionPickNCHook, gRegionPickNCCalcHook, gRegionPickKind
    gRegionPickKind := kind
    if IsObject(gRegionPickGui) {
        try gRegionPickGui.Destroy()
        gRegionPickGui := false
    }
    gRegionPickGui := Gui("+AlwaysOnTop +Resize +ToolWindow +MinSize8x8 -Caption -Border -DPIScale +E0x80000", "")
    gRegionPickGui.MarginX := 0
    gRegionPickGui.MarginY := 0
    gRegionPickGui.BackColor := "FFFFFF"
    gRegionPickGui.OnEvent("Close", PresetRegionPickCancel)
    gRegionPickGui.Show("Hide w200 h90")
    hwnd := gRegionPickGui.Hwnd
    r := (kind = "calibrate") ? ParseAutoPresetCalibrateRegion() : ParseAutoPresetRegion()
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
    if !gRegionPickKeyHook {
        OnMessage(0x0100, PresetRegionPickKey)
        gRegionPickKeyHook := true
    }
    if !gRegionPickNCHook {
        OnMessage(0x0084, PresetRegionPickNCHitTest)
        gRegionPickNCHook := true
    }
    if !gRegionPickNCCalcHook {
        OnMessage(0x0083, PresetRegionPickNCCalcSize)
        gRegionPickNCCalcHook := true
    }
    DllCall("user32\SetWindowPos", "ptr", hwnd, "ptr", 0, "int", 0, "int", 0, "int", 0, "int", 0, "uint", 0x0027)
}

PresetRegionPickNCHitTest(wParam, lParam, msg, hwnd) {
    global gRegionPickGui
    if !IsObject(gRegionPickGui) || (hwnd != gRegionPickGui.Hwnd) {
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
    global gRegionPickGui
    if !IsObject(gRegionPickGui) {
        return
    }
    rootHwnd := DllCall("user32\GetAncestor", "ptr", hwnd, "uint", 2, "ptr")
    if (rootHwnd != gRegionPickGui.Hwnd) {
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
    global gRegionPickGui, gRegionPickKind
    if !IsObject(gRegionPickGui) {
        return
    }
    cr := PresetRegionPickReadClientScreen(gRegionPickGui.Hwnd)
    if (cr = "") {
        return
    }
    x := cr["x"]
    y := cr["y"]
    w := cr["w"]
    h := cr["h"]
    kind := gRegionPickKind
    if (kind = "calibrate") {
        SaveAutoPresetCalibrateRegion(x, y, w, h)
        PresetAutoRefreshCalibratePreviewIfVisible()
    } else {
        SaveAutoPresetRegion(x, y, w, h)
    }
    PresetRegionPickClose()
}

PresetRegionPickCancel(*) {
    PresetRegionPickClose()
}

PresetRegionPickClose() {
    global gRegionPickGui
    if IsObject(gRegionPickGui) {
        try gRegionPickGui.Destroy()
    }
    gRegionPickGui := false
}
