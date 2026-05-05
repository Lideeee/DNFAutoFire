#Requires AutoHotkey v2.0

global gPresetAutoGui := Gui("-MinimizeBox -MaximizeBox -Theme", "自动识别设置")
global gPresetAutoCtrls := Map()
global gPresetAutoPvW := 224
global gPresetAutoPvH := 126
global gRegionPickGui := false
global gRegionPickKeyHook := false
global gRegionPickNCHook := false
global gRegionPickKind := "skill"

gPresetAutoGui.OnEvent("Escape", PresetAutoGuiEscape)
gPresetAutoGui.OnEvent("Close", PresetAutoGuiClose)

; 与自动识别配置界面相同：宽 240、预览 224×126；识别热键在预览图上方
gPresetAutoGui.Add("Text", "x8 y8 w224 h14 +0x200", "识别热键 (冒险团玩法信息)")
gPresetAutoCtrls["AutoPresetHotkey"] := gPresetAutoGui.Add("Edit", "vAutoPresetHotkey x8 y24 w132 h22 +ReadOnly -WantCtrlA")
gPresetAutoGui.Add("Button", "x148 y22 w84 h26", "设置识别热键").OnEvent("Click", PresetAutoSetHotkeyFromPress)
gPresetAutoCtrls["CalPreview"] := gPresetAutoGui.Add("Picture", "x8 y52 w224 h126 +Border", "")
gPresetAutoCtrls["CalHint"] := gPresetAutoGui.Add("Text", "x8 y182 w224 h44", "")
gPresetAutoGui.Add("Button", "x8 y230 w224 h26", "框选血条区域").OnEvent("Click", (*) => PresetRegionPickOpen("calibrate"))
gPresetAutoGui.Add("Button", "x8 y260 w108 h26", "截取图像").OnEvent("Click", PresetAutoUpdateCalibrateIcon)
gPresetAutoGui.Add("Button", "x124 y260 w108 h26", "清除图像").OnEvent("Click", PresetAutoDoDeleteCalibrateIcon)
gPresetAutoGui.Add("Button", "x8 y290 w224 h28", "保存").OnEvent("Click", PresetAutoSaveClose)

PresetAutoGetCtrl(name) {
    global gPresetAutoCtrls
    return gPresetAutoCtrls.Has(name) ? gPresetAutoCtrls[name] : ""
}

PresetAutoLockCalPreviewFrame(pic) {
    global gPresetAutoPvW, gPresetAutoPvH
    if IsObject(pic) {
        pic.Move(8, 52, gPresetAutoPvW, gPresetAutoPvH)
    }
}

ShowGuiPresetAutoSwitch(*) {
    global gMainGui, gSettingGui, gPresetAutoGui
    owner := 0
    if IsObject(gSettingGui) && WinExist("ahk_id " gSettingGui.Hwnd) {
        gPresetAutoGui.Opt("+Owner" gSettingGui.Hwnd)
    } else if IsObject(gMainGui) {
        gPresetAutoGui.Opt("+Owner" gMainGui.Hwnd)
    }
    gPresetAutoGui.Title := "自动识别设置"
    PresetAutoGetCtrl("AutoPresetHotkey").Text := Trim(LoadConfig("AutoPresetHotkey", ""))
    PresetAutoRefreshCalibratePreview()
    gPresetAutoGui.Show("w240 h326")
}

HideGuiPresetAutoSwitch() {
    global gPresetAutoGui
    PresetRegionPickCancelIfOpen()
    gPresetAutoGui.Hide()
}

PresetAutoGuiEscape(*) {
    HideGuiPresetAutoSwitch()
}

PresetAutoGuiClose(*) {
    HideGuiPresetAutoSwitch()
}

; 框选窗口打开时点「保存」等同按 Enter：写入当前技能区域或校准区域
PresetAutoSaveClose(*) {
    PresetRegionPickCommitIfOpen()
    HideGuiPresetAutoSwitch()
}

PresetAutoSetHotkeyFromPress(*) {
    hk := Trim(GetPressKey())
    PresetAutoGetCtrl("AutoPresetHotkey").Text := hk
    SaveConfig("AutoPresetHotkey", hk)
    PresetRecognition_UpdateHotkeys()
}

PresetAutoDoDeleteCalibrateIcon(*) {
    path := PresetCalibrateIconGlobalPath()
    if !FileExist(path) {
        return
    }
    try FileDelete(path)
    PresetAutoRefreshCalibratePreview()
}

PresetAutoRefreshCalibratePreview() {
    global gPresetAutoPvW, gPresetAutoPvH
    pic := PresetAutoGetCtrl("CalPreview")
    if !IsObject(pic) {
        return
    }
    hint := PresetAutoGetCtrl("CalHint")
    cpath := PresetCalibrateIconGlobalPath()
    pic.Value := ""
    PresetAutoLockCalPreviewFrame(pic)
    tip := "框选后按 Enter 确认，Esc 取消。圆形血条不要截取到血条外的背景。"
    if IsObject(hint) {
        hint.Text := tip
    }
    if FileExist(cpath) {
        tmp := A_Temp "\DAF_cal_fit_preview.png"
        if PresetSkillIcon_RenderFitPreviewToFile(cpath, gPresetAutoPvW, gPresetAutoPvH, tmp) && FileExist(tmp) {
            pic.Value := tmp
        } else {
            pic.Value := cpath
        }
        PresetAutoLockCalPreviewFrame(pic)
    }
}

PresetAutoRefreshCalibratePreviewIfVisible() {
    global gPresetAutoGui
    if IsObject(gPresetAutoGui) && WinExist("ahk_id " gPresetAutoGui.Hwnd) {
        PresetAutoRefreshCalibratePreview()
    }
}

PresetAutoUpdateCalibrateIcon(*) {
    PresetRegionPickCommitCalibrateRegionIfOpen()
    try {
        PresetCalibrateIcon_UpdateCurrent()
        PresetAutoRefreshCalibratePreview()
    } catch Error as e {
        MsgBox(e.Message,, "Icon!")
    }
}

; ---------- 识别区域框选（无边框：客户区即截取区域，避免比可视框多出一圈）----------
; 拖拽：WM_NCHITTEST 中心为 HTCAPTION；边缘为缩放热点

; 框选仍在且为技能区域时：把当前灰框写入全局技能区域并关闭（等同按 Enter），供「截取图像」等调用
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

; 任意类型的框选窗口打开时提交（技能 / 校准），关闭框选窗口
PresetRegionPickCommitIfOpen() {
    global gRegionPickGui
    if !IsObject(gRegionPickGui) || !WinExist("ahk_id " gRegionPickGui.Hwnd) {
        return
    }
    PresetRegionPickOk()
}

; 框选仍为校准时提交（等同 Enter），供「截取图像」与保存前提交共用
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

; 关闭配置子窗口时若框选未确认，丢弃灰框（等同 Esc）
PresetRegionPickCancelIfOpen() {
    global gRegionPickGui
    if IsObject(gRegionPickGui) && WinExist("ahk_id " gRegionPickGui.Hwnd) {
        PresetRegionPickCancel()
    }
}

PresetRegionPickOpen(kind := "skill") {
    global gRegionPickGui, gRegionPickKeyHook, gRegionPickNCHook, gRegionPickKind
    gRegionPickKind := kind
    if IsObject(gRegionPickGui) {
        try gRegionPickGui.Destroy()
        gRegionPickGui := false
    }
    gRegionPickGui := Gui("+AlwaysOnTop +Resize +ToolWindow +MinSize8x8 -Caption -DPIScale", "RegionPick")
    gRegionPickGui.MarginX := 0
    gRegionPickGui.MarginY := 0
    gRegionPickGui.BackColor := "505050"
    gRegionPickGui.OnEvent("Close", PresetRegionPickCancel)
    r := (kind = "calibrate") ? ParseAutoPresetCalibrateRegion() : ParseAutoPresetRegion()
    if r.Has("w") {
        gRegionPickGui.Show("x" r["x"] " y" r["y"] " w" r["w"] " h" r["h"])
    } else {
        gRegionPickGui.Show("w200 h90")
        WinGetPos(&gx, &gy, &gw, &gh, "ahk_id " gRegionPickGui.Hwnd)
        gRegionPickGui.Move((A_ScreenWidth - gw) // 2, (A_ScreenHeight - gh) // 2)
    }
    if !gRegionPickKeyHook {
        OnMessage(0x0100, PresetRegionPickKey)
        gRegionPickKeyHook := true
    }
    if !gRegionPickNCHook {
        OnMessage(0x0084, PresetRegionPickNCHitTest)
        gRegionPickNCHook := true
    }
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
    ; WM_KEYDOWN 的 hwnd 常为获得焦点的子控件，不是 Gui 本身
    rootHwnd := DllCall("user32\GetAncestor", "ptr", hwnd, "uint", 2, "ptr") ; GA_ROOT = 2
    if (rootHwnd != gRegionPickGui.Hwnd) {
        return
    }
    if !WinActive("ahk_id " rootHwnd) {
        return
    }
    vk := wParam & 0xFF
    if (vk = 0x0D) { ; Enter
        PresetRegionPickOk()
    } else if (vk = 0x1B) { ; Esc
        PresetRegionPickCancel()
    }
}

PresetRegionPickOk(*) {
    global gRegionPickGui, gRegionPickKind
    if !IsObject(gRegionPickGui) {
        return
    }
    WinGetClientPos(&x, &y, &w, &h, "ahk_id " gRegionPickGui.Hwnd)
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
