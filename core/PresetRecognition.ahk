#Requires AutoHotkey v2.0

PresetSkillIconDir() => A_ScriptDir "\preset_skill_icons"

PresetSkillIcon_SafeName(presetName) {
    return RegExReplace(StrReplace(presetName, "|", "_"), '[\\/:\*\?"<>\|]', "_")
}

PresetSkillIconPath(presetName) {
    return PresetSkillIconDir() "\" PresetSkillIcon_SafeName(presetName) ".png"
}

PresetSkillIcon_EnsureDir() {
    dir := PresetSkillIconDir()
    if !DirExist(dir) {
        DirCreate(dir)
    }
}

PresetSkillIcon_CopyForPreset(oldName, newName) {
    src := PresetSkillIconPath(oldName)
    if !FileExist(src) {
        return
    }
    PresetSkillIcon_EnsureDir()
    dest := PresetSkillIconPath(newName)
    try FileCopy(src, dest, true)
}

PresetSkillIcon_DeleteForPreset(presetName) {
    p := PresetSkillIconPath(presetName)
    if FileExist(p) {
        try FileDelete(p)
    }
}

; ---------- 校准区域（先于技能图匹配；全局一张参考图 calibrate.png）----------

PresetCalibrateIconDir() => A_ScriptDir "\preset_calibrate_icons"

PresetCalibrateIconGlobalPath() {
    return PresetCalibrateIconDir() "\calibrate.png"
}

ParseAutoPresetCalibrateRegion() {
    raw := Trim(LoadConfig("AutoPresetCalibrateRegion", ""))
    out := Map()
    if (raw = "") {
        return out
    }
    parts := StrSplit(raw, "|")
    if (parts.Length < 4) {
        return out
    }
    try {
        x := Integer(parts[1])
        y := Integer(parts[2])
        w := Integer(parts[3])
        h := Integer(parts[4])
    } catch {
        return out
    }
    if (w < 1 || h < 1) {
        return out
    }
    out["x"] := x
    out["y"] := y
    out["w"] := w
    out["h"] := h
    return out
}

SaveAutoPresetCalibrateRegion(x, y, w, h) {
    SaveConfig("AutoPresetCalibrateRegion", x "|" y "|" w "|" h)
}

PresetRecognition_HasAnyCalibratePng() {
    return FileExist(PresetCalibrateIconGlobalPath())
}

PresetRecognition_UseCalibratePass() {
    return ParseAutoPresetCalibrateRegion().Has("w") && PresetRecognition_HasAnyCalibratePng()
}

PresetRecognition_FirstPresetName() {
    pl := LoadAllPreset()
    return pl.Length >= 1 ? pl[1] : ""
}

PresetRecognition_GameActive() {
    return WinActive("ahk_group DNF")
}

; 返回 Map: x,y,w,h 或空 Map（无效）
ParseAutoPresetRegion() {
    raw := Trim(LoadConfig("AutoPresetRegion", ""))
    out := Map()
    if (raw = "") {
        return out
    }
    parts := StrSplit(raw, "|")
    if (parts.Length < 4) {
        return out
    }
    try {
        x := Integer(parts[1])
        y := Integer(parts[2])
        w := Integer(parts[3])
        h := Integer(parts[4])
    } catch {
        return out
    }
    if (w < 1 || h < 1) {
        return out
    }
    out["x"] := x
    out["y"] := y
    out["w"] := w
    out["h"] := h
    return out
}

SaveAutoPresetRegion(x, y, w, h) {
    SaveConfig("AutoPresetRegion", x "|" y "|" w "|" h)
}

LoadAutoPresetImageVariation() {
    v := Round(LoadConfig("AutoPresetImageVariation", 80) + 0)
    if (v < 0) {
        v := 0
    } else if (v > 255) {
        v := 255
    }
    return v
}

; 将屏幕矩形保存为 PNG（GDI BitBlt + GDI+）
PresetCaptureRegionToPng(path, x, y, w, h) {
    pdir := RegExReplace(path, "\\[^\\]+$", "")
    if (pdir != "" && pdir != path && !DirExist(pdir)) {
        DirCreate(pdir)
    }
    hdc := DllCall("user32\GetDC", "ptr", 0, "ptr")
    if !hdc {
        throw Error("GetDC failed")
    }
    try {
        hdcMem := DllCall("gdi32\CreateCompatibleDC", "ptr", hdc, "ptr")
        hbm := DllCall("gdi32\CreateCompatibleBitmap", "ptr", hdc, "int", w, "int", h, "ptr")
        if !hbm || !hdcMem {
            throw Error("CreateCompatibleBitmap/DC failed")
        }
        try {
            obm := DllCall("gdi32\SelectObject", "ptr", hdcMem, "ptr", hbm, "ptr")
            if !DllCall("gdi32\BitBlt", "ptr", hdcMem, "int", 0, "int", 0, "int", w, "int", h,
                "ptr", hdc, "int", x, "int", y, "uint", 0x00CC0020) {
                throw Error("BitBlt failed")
            }
            DllCall("gdi32\SelectObject", "ptr", hdcMem, "ptr", obm, "ptr")
            _PresetGdipSaveHbitmapPng(hbm, path)
        } finally {
            DllCall("gdi32\DeleteObject", "ptr", hbm)
            DllCall("gdi32\DeleteDC", "ptr", hdcMem)
        }
    } finally {
        DllCall("user32\ReleaseDC", "ptr", 0, "ptr", hdc)
    }
}

global __gdipToken := 0

_PresetGdipStartup() {
    global __gdipToken
    if __gdipToken {
        return __gdipToken
    }
    DllCall("ole32\OleInitialize", "ptr", 0)
    si := Buffer(A_PtrSize = 8 ? 24 : 16, 0)
    NumPut("uint", 1, si, 0) ; GdiplusVersion
    if (A_PtrSize = 8) {
        NumPut("ptr", 0, si, 8) ; DebugEventCallback
        NumPut("int", 0, si, 16) ; SuppressBackgroundThread
        NumPut("int", 0, si, 20) ; SuppressExternalCodecs
    } else {
        NumPut("ptr", 0, si, 4)
        NumPut("int", 0, si, 8)
        NumPut("int", 0, si, 12)
    }
    if DllCall("gdiplus\GdiplusStartup", "ptr*", &pToken := 0, "ptr", si, "ptr", 0) != 0 {
        throw Error("GdiplusStartup failed")
    }
    __gdipToken := pToken
    return pToken
}

_PresetGdipSaveHbitmapPng(hbm, path) {
    _PresetGdipStartup()
    pBitmap := 0
    if DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", "ptr", hbm, "int", 0, "ptr*", &pBitmap := 0) != 0 || !pBitmap {
        throw Error("GdipCreateBitmapFromHBITMAP failed")
    }
    try {
        clsid := Buffer(16, 0)
        if DllCall("ole32\CLSIDFromString", "wstr", "{557CF406-1A04-11D3-9A73-0000F81EF32E}", "ptr", clsid) != 0 {
            throw Error("CLSIDFromString failed")
        }
        wpath := Buffer(2 * StrLen(path) + 2, 0)
        StrPut(path, wpath, "UTF-16")
        if DllCall("gdiplus\GdipSaveImageToFile", "ptr", pBitmap, "ptr", wpath.Ptr, "ptr", clsid, "ptr", 0) != 0 {
            throw Error("GdipSaveImageToFile failed")
        }
    } finally {
        DllCall("gdiplus\GdipDisposeImage", "ptr", pBitmap)
    }
}

_PresetGdipSaveGpBitmapToPng(pBitmap, path) {
    _PresetGdipStartup()
    clsid := Buffer(16, 0)
    if DllCall("ole32\CLSIDFromString", "wstr", "{557CF406-1A04-11D3-9A73-0000F81EF32E}", "ptr", clsid) != 0 {
        throw Error("CLSIDFromString failed")
    }
    wpath := Buffer(2 * StrLen(path) + 2, 0)
    StrPut(path, wpath, "UTF-16")
    if DllCall("gdiplus\GdipSaveImageToFile", "ptr", pBitmap, "ptr", wpath.Ptr, "ptr", clsid, "ptr", 0) != 0 {
        throw Error("GdipSaveImageToFile failed")
    }
}

; 技能预览：适应框内显示（保持宽高比，不足处黑边），写入临时 PNG 供 Picture 加载
PresetSkillIcon_FitPreviewTempPath() {
    return A_Temp "\DAF_skill_fit_preview.png"
}

PresetSkillIcon_RenderFitPreviewToFile(srcPath, boxW, boxH, destPath) {
    if !FileExist(srcPath) || boxW < 1 || boxH < 1 {
        return false
    }
    _PresetGdipStartup()
    pSrc := 0
    if DllCall("gdiplus\GdipCreateBitmapFromFile", "wstr", srcPath, "ptr*", &pSrc := 0) != 0 || !pSrc {
        return false
    }
    sw := 0
    sh := 0
    DllCall("gdiplus\GdipGetImageWidth", "ptr", pSrc, "uint*", &sw := 0)
    DllCall("gdiplus\GdipGetImageHeight", "ptr", pSrc, "uint*", &sh := 0)
    if (sw < 1 || sh < 1) {
        DllCall("gdiplus\GdipDisposeImage", "ptr", pSrc)
        return false
    }
    ; 必须是 0x26200A（32bpp ARGB）；误写 0x26200A0 会导致创建失败并退回未缩放原图
    fmtArgb := 0x26200A
    stride := boxW * 4
    buf := Buffer(stride * boxH, 0)
    pDst := 0
    if DllCall("gdiplus\GdipCreateBitmapFromScan0", "int", boxW, "int", boxH, "int", stride, "uint", fmtArgb, "ptr", buf.Ptr, "ptr*", &pDst := 0) != 0 || !pDst {
        DllCall("gdiplus\GdipDisposeImage", "ptr", pSrc)
        return false
    }
    gr := 0
    if DllCall("gdiplus\GdipGetImageGraphicsContext", "ptr", pDst, "ptr*", &gr := 0) != 0 || !gr {
        DllCall("gdiplus\GdipDisposeImage", "ptr", pDst)
        DllCall("gdiplus\GdipDisposeImage", "ptr", pSrc)
        return false
    }
    drawOk := false
    try {
        stClear := DllCall("gdiplus\GdipGraphicsClear", "ptr", gr, "uint", 0xFFFFFFFF)
        stMode := DllCall("gdiplus\GdipSetInterpolationMode", "ptr", gr, "int", 7)
        if (stClear = 0 && stMode = 0) {
            scale := Min(boxW / sw, boxH / sh)
            newW := Max(1, Round(sw * scale))
            newH := Max(1, Round(sh * scale))
            dstX := (boxW - newW) // 2
            dstY := (boxH - newH) // 2
            drawOk := (DllCall("gdiplus\GdipDrawImageRectI", "ptr", gr, "ptr", pSrc, "int", dstX, "int", dstY, "int", newW, "int", newH) = 0)
        }
    } finally {
        DllCall("gdiplus\GdipDeleteGraphics", "ptr", gr)
    }
    if !drawOk {
        DllCall("gdiplus\GdipDisposeImage", "ptr", pDst)
        DllCall("gdiplus\GdipDisposeImage", "ptr", pSrc)
        return false
    }
    try {
        _PresetGdipSaveGpBitmapToPng(pDst, destPath)
    } finally {
        DllCall("gdiplus\GdipDisposeImage", "ptr", pDst)
        DllCall("gdiplus\GdipDisposeImage", "ptr", pSrc)
    }
    return true
}

; 更新全局校准参考图（截取校准区域）
PresetCalibrateIcon_UpdateCurrent() {
    r := ParseAutoPresetCalibrateRegion()
    if !r.Has("w") {
        throw Error("请先在自动识别设置里设置校准识别区域")
    }
    path := PresetCalibrateIconGlobalPath()
    PresetCaptureRegionToPng(path, r["x"], r["y"], r["w"], r["h"])
    return path
}

; 在校准区域内匹配全局 calibrate.png，成功表示可进行技能图识别
CalibrateIconMatches() {
    r := ParseAutoPresetCalibrateRegion()
    if !r.Has("w") {
        return false
    }
    path := PresetCalibrateIconGlobalPath()
    if !FileExist(path) {
        return false
    }
    x1 := r["x"]
    y1 := r["y"]
    x2 := x1 + r["w"] - 1
    y2 := y1 + r["h"] - 1
    var := LoadAutoPresetImageVariation()
    optPrefix := "*" var " "
    needle := optPrefix . path
    prevPixel := CoordMode("Pixel", "Screen")
    try {
        try {
            if ImageSearch(&_icx, &_icy, x1, y1, x2, y2, needle) {
                return true
            }
        } catch TargetError {
        }
        return false
    } finally {
        CoordMode "Pixel", prevPixel
    }
}

; 更新当前预设参考图（截图识别区域）
PresetSkillIcon_UpdateCurrent() {
    r := ParseAutoPresetRegion()
    if !r.Has("w") {
        throw Error("请先在软件设置中配置识别区域")
    }
    name := GetNowSelectPreset()
    if (name = "") {
        throw Error("无当前配置")
    }
    path := PresetSkillIconPath(name)
    PresetCaptureRegionToPng(path, r["x"], r["y"], r["w"], r["h"])
    return path
}

FindPresetBySkillIcon() {
    r := ParseAutoPresetRegion()
    if !r.Has("w") {
        return ""
    }
    x1 := r["x"]
    y1 := r["y"]
    x2 := x1 + r["w"] - 1
    y2 := y1 + r["h"] - 1
    var := LoadAutoPresetImageVariation()
    ; 选项与路径同一字符串；勿在路径两侧再加引号字符，否则会触发 ValueError「参数无效」
    optPrefix := "*" var " "
    ; 保存的区域为屏幕坐标，ImageSearch 默认相对活动窗口客户区，必须改为 Screen
    prevPixel := CoordMode("Pixel", "Screen")
    try {
        for presetName in LoadAllPreset() {
            path := PresetSkillIconPath(presetName)
            if !FileExist(path) {
                continue
            }
            needle := optPrefix . path
            try {
                if ImageSearch(&_isx, &_isy, x1, y1, x2, y2, needle) {
                    return presetName
                }
            } catch TargetError {
                ; 未找到，继续
            }
        }
        return ""
    } finally {
        CoordMode "Pixel", prevPixel
    }
}

; ---------- 识别热键与重试序列 ----------

PresetRecognition_MaxRetryAttempts := 120

global __prRetryTimer := false
global __prStartDelayTimer := false
global __prRegisteredEsc := false
global __prRegisteredCustom := false
global __prLastCustomHotkey := ""

PresetRecognition_ClearRetryTimer() {
    global __prRetryTimer
    if __prRetryTimer {
        try SetTimer(__prRetryTimer, 0)
        __prRetryTimer := false
    }
}

PresetRecognition_ClearStartDelayTimer() {
    global __prStartDelayTimer
    if __prStartDelayTimer {
        try SetTimer(__prStartDelayTimer, 0)
        __prStartDelayTimer := false
    }
}

PresetRecognition_CancelPending() {
    PresetRecognition_ClearRetryTimer()
    PresetRecognition_ClearStartDelayTimer()
}

PresetRecognition_Trigger(*) {
    PresetRecognition_StartSequence()
}

; 热键触发后等待 1 秒再开始搜图，避免与游戏内菜单/遮罩同帧
PresetRecognition_StartSequence() {
    if !PresetRecognition_IsEnabled() {
        return
    }
    if !PresetRecognition_GameActive() {
        return
    }
    PresetRecognition_CancelPending()
    fn := PresetRecognition_AfterStartDelay
    global __prStartDelayTimer := fn
    SetTimer(fn, -1000)
}

PresetRecognition_AfterStartDelay(*) {
    global __prStartDelayTimer
    __prStartDelayTimer := false
    if !PresetRecognition_IsEnabled() {
        return
    }
    if !PresetRecognition_GameActive() {
        return
    }
    PresetRecognition_RunAttempt(1)
}

PresetRecognition_IsEnabled() {
    return Trim(LoadConfig("SettingAutoPresetSwitch", "0")) = "1"
}

; 启用校准时：先匹配全局校准图，仅在校准成功后才匹配技能图；校准失败才按 1 秒重试
PresetRecognition_RunAttempt(attemptIdx) {
    if !PresetRecognition_IsEnabled() {
        PresetRecognition_ClearRetryTimer()
        return
    }
    if !PresetRecognition_GameActive() {
        PresetRecognition_ClearRetryTimer()
        return
    }
    r := ParseAutoPresetRegion()
    if !r.Has("w") {
        PresetRecognition_ClearRetryTimer()
        ShowTip("请先配置识别区域（自动识别配置 → 框选技能图标）", 1000)
        return
    }

    if PresetRecognition_UseCalibratePass() {
        if !CalibrateIconMatches() {
            if (attemptIdx >= PresetRecognition_MaxRetryAttempts) {
                PresetRecognition_ClearRetryTimer()
                ShowTip("校准图未匹配", 1000)
                return
            }
            fn := PresetRecognition_RunAttempt.Bind(attemptIdx + 1)
            global __prRetryTimer := fn
            SetTimer(fn, -1000)
            return
        }
        skillFound := FindPresetBySkillIcon()
        current := GetNowSelectPreset()
        PresetRecognition_ClearRetryTimer()
        if (skillFound != "" && skillFound != current) {
            ChangePresetAndResumeAutoFire(skillFound)
            ShowTip("已切换配置: " skillFound, 1000)
        } else if (skillFound = "") {
            firstN := PresetRecognition_FirstPresetName()
            if (firstN != "" && firstN != current) {
                ChangePresetAndResumeAutoFire(firstN)
            }
            ShowTip("已切换配置: " GetNowSelectPreset(), 1000)
        }
        return
    }

    PresetRecognition_SkillOnlyAttempt(attemptIdx)
}

; 仅按技能图标匹配，失败时每 1s 重试
PresetRecognition_SkillOnlyAttempt(attemptIdx) {
    if !PresetRecognition_IsEnabled() {
        PresetRecognition_ClearRetryTimer()
        return
    }
    if !PresetRecognition_GameActive() {
        PresetRecognition_ClearRetryTimer()
        return
    }
    found := FindPresetBySkillIcon()
    current := GetNowSelectPreset()
    if (found != "" && found != current) {
        ChangePresetAndResumeAutoFire(found)
        PresetRecognition_ClearRetryTimer()
        ShowTip("已切换配置: " found, 1000)
        return
    }
    if (found != "" && found = current) {
        PresetRecognition_ClearRetryTimer()
        return
    }
    if (attemptIdx >= PresetRecognition_MaxRetryAttempts) {
        PresetRecognition_ClearRetryTimer()
        ShowTip("已切换配置: " GetNowSelectPreset(), 1000)
        return
    }
    fn := PresetRecognition_RunAttempt.Bind(attemptIdx + 1)
    global __prRetryTimer := fn
    SetTimer(fn, -1000)
}

PresetRecognition_IsEscHotkeyStr(hk) {
    t := StrLower(Trim(hk))
    return (t = "esc" || t = "escape")
}

PresetRecognition_DisableAllHotkeys() {
    global __prRegisteredEsc, __prRegisteredCustom, __prLastCustomHotkey
    PresetRecognition_CancelPending()
    if __prRegisteredEsc {
        try Hotkey("~Esc", "Off")
        __prRegisteredEsc := false
    }
    if __prRegisteredCustom && __prLastCustomHotkey != "" {
        try Hotkey("~$" __prLastCustomHotkey, "Off")
        __prRegisteredCustom := false
        __prLastCustomHotkey := ""
    }
}

PresetRecognition_UpdateHotkeys() {
    global __prRegisteredEsc, __prRegisteredCustom, __prLastCustomHotkey
    PresetRecognition_DisableAllHotkeys()
    if !PresetRecognition_IsEnabled() {
        return
    }
    hk := Trim(LoadConfig("AutoPresetHotkey", ""))
    __prRegisteredEsc := true
    Hotkey("~Esc", PresetRecognition_Trigger, "On")
    if (hk != "" && !PresetRecognition_IsEscHotkeyStr(hk)) {
        __prLastCustomHotkey := hk
        __prRegisteredCustom := true
        Hotkey("~$" hk, PresetRecognition_Trigger, "On")
    }
}
