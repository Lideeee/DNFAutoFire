#Requires AutoHotkey v2.0

; 自动识别配置：搜图匹配技能栏/血条/城镇参考图后切换预设

class AutoPresets {
    static RetryIntervalMs := 250
    static MaxRetryAttempts := 240
    static SkillImageVariation := 80
    static CalibrateImageVariation := 80
    static TownImageVariation := 20
    static _retryTimer := false
    static _startTimer := false
    static _registeredEsc := false
    static _registeredCustom := false
    static _lastCustomHotkey := ""
    static _sessionId := 0
    static _sequenceId := 0
}

; 是否开启「自动识别」（全局，config.ini [设置]）
AutoPresets_LoadEnabledGlobal() {
    raw := IniRead(ConfigIniPath(), "设置", "AutoPresetsEnabled", "__MISSING__")
    if (raw != "__MISSING__") {
        return AutoPresets_CoerceIniBool(raw)
    }
    mig := LoadPreset(LoadLastPreset(), "AutoPresetsState", false)
    SaveConfig("AutoPresetsEnabled", mig ? 1 : 0)
    return mig ? true : false
}

AutoPresets_CoerceIniBool(raw) {
    if (IsNumber(raw)) {
        return (raw + 0) != 0
    }
    s := StrLower(Trim(String(raw)))
    return (s = "1" || s = "true" || s = "yes" || s = "on")
}

AutoPresetsAssetDir() => A_ScriptDir "\assets\preset-recognition"

AutoPresetsSkillIconDir() => AutoPresetsAssetDir() "\skills"

AutoPresetsSkillIcon_SafeName(presetName) {
    return RegExReplace(StrReplace(presetName, "|", "_"), '[\\/:\*\?"<>\|]', "_")
}

AutoPresetsSkillIconPath(presetName) {
    return AutoPresetsSkillIconDir() "\" AutoPresetsSkillIcon_SafeName(presetName) ".png"
}

AutoPresetsSkillIcon_EnsureDir() {
    dir := AutoPresetsSkillIconDir()
    if !DirExist(dir) {
        DirCreate(dir)
    }
}

AutoPresets_OnPresetCloned(oldName, newName) {
    src := AutoPresetsSkillIconPath(oldName)
    if !FileExist(src) {
        return
    }
    AutoPresetsSkillIcon_EnsureDir()
    dest := AutoPresetsSkillIconPath(newName)
    try FileCopy(src, dest, true)
}

AutoPresets_OnPresetRenamed(oldName, newName) {
    AutoPresets_OnPresetCloned(oldName, newName)
    AutoPresets_OnPresetDeleted(oldName)
}

AutoPresets_OnPresetDeleted(presetName) {
    path := AutoPresetsSkillIconPath(presetName)
    if FileExist(path) {
        try FileDelete(path)
    }
}

AutoPresetsCalibrateIconDir() => AutoPresetsAssetDir() "\calibrate"

AutoPresetsCalibrateIconGlobalPath() {
    return AutoPresetsCalibrateIconDir() "\calibrate.png"
}

AutoPresetsTownIconDir() => AutoPresetsAssetDir() "\town"

AutoPresetsTownIconGlobalPath() {
    return AutoPresetsTownIconDir() "\town.png"
}

AutoPresets_DefaultRegion() {
    w := 200
    h := 90
    return Map("x", (A_ScreenWidth - w) // 2, "y", (A_ScreenHeight - h) // 2, "w", w, "h", h)
}

AutoPresets_ResolveRegion(region) {
    return region.Has("w") ? region : AutoPresets_DefaultRegion()
}

ParseAutoPresetRegionByKey(configKey) {
    raw := Trim(LoadConfig(configKey, " "))
    out := Map()
    if (raw = "" || raw = " ") {
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

SaveAutoPresetRegionByKey(configKey, x, y, w, h) {
    SaveConfig(configKey, x "|" y "|" w "|" h)
}

ParseAutoPresetCalibrateRegion() {
    return ParseAutoPresetRegionByKey("AutoPresetCalibrateRegion")
}

SaveAutoPresetCalibrateRegion(x, y, w, h) {
    SaveAutoPresetRegionByKey("AutoPresetCalibrateRegion", x, y, w, h)
}

ParseAutoPresetTownRegion() {
    return ParseAutoPresetRegionByKey("AutoPresetTownRegion")
}

SaveAutoPresetTownRegion(x, y, w, h) {
    SaveAutoPresetRegionByKey("AutoPresetTownRegion", x, y, w, h)
}

AutoPresets_HasAnyCalibratePng() {
    return FileExist(AutoPresetsCalibrateIconGlobalPath())
}

AutoPresets_HasAnyTownPng() {
    return FileExist(AutoPresetsTownIconGlobalPath())
}

AutoPresets_FirstPresetName() {
    presetList := LoadAllPreset()
    return presetList.Length >= 1 ? presetList[1] : ""
}

AutoPresets_GameActive() {
    return WinActive("ahk_group DNF") != 0
}

AutoPresets_IsSessionRunning() {
    global _AutoFireThreads
    try n := _AutoFireThreads.Length
    catch {
        n := 0
    }
    return n > 0
}

ParseAutoPresetRegion() {
    return ParseAutoPresetRegionByKey("AutoPresetRegion")
}

SaveAutoPresetRegion(x, y, w, h) {
    SaveAutoPresetRegionByKey("AutoPresetRegion", x, y, w, h)
}

AutoPresetsCaptureRegionToPng(path, x, y, w, h) {
    parentDir := RegExReplace(path, "\\[^\\]+$", "")
    if (parentDir != "" && parentDir != path && !DirExist(parentDir)) {
        DirCreate(parentDir)
    }
    hdc := DllCall("user32\GetDC", "ptr", 0, "ptr")
    if !hdc {
        throw Error("GetDC failed")
    }
    hdcMem := 0
    hbm := 0
    obm := 0
    selected := false
    try {
        hdcMem := DllCall("gdi32\CreateCompatibleDC", "ptr", hdc, "ptr")
        if !hdcMem {
            throw Error("CreateCompatibleDC failed")
        }
        hbm := DllCall("gdi32\CreateCompatibleBitmap", "ptr", hdc, "int", w, "int", h, "ptr")
        if !hbm {
            throw Error("CreateCompatibleBitmap failed")
        }
        obm := DllCall("gdi32\SelectObject", "ptr", hdcMem, "ptr", hbm, "ptr")
        if !obm {
            throw Error("SelectObject failed")
        }
        selected := true
        try {
            if !DllCall("gdi32\BitBlt", "ptr", hdcMem, "int", 0, "int", 0, "int", w, "int", h,
                "ptr", hdc, "int", x, "int", y, "uint", 0x00CC0020) {
                throw Error("BitBlt failed")
            }
            _AutoPresetsGdipSaveHbitmapPng(hbm, path)
        } finally {
            if selected {
                try DllCall("gdi32\SelectObject", "ptr", hdcMem, "ptr", obm, "ptr")
                selected := false
            }
        }
    } finally {
        if hbm {
            DllCall("gdi32\DeleteObject", "ptr", hbm)
        }
        if hdcMem {
            DllCall("gdi32\DeleteDC", "ptr", hdcMem)
        }
        DllCall("user32\ReleaseDC", "ptr", 0, "ptr", hdc)
    }
}

_AutoPresetsGdipStartup() {
    return GdiPlusSession.EnsureStarted()
}

_AutoPresetsGdipSaveHbitmapPng(hbm, path) {
    _AutoPresetsGdipStartup()
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

_AutoPresetsGdipSaveGpBitmapToPng(pBitmap, path) {
    _AutoPresetsGdipStartup()
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

AutoPresetsSkillIcon_FitPreviewTempPath() {
    return A_Temp "\DAF_skill_fit_preview.png"
}

AutoPresetsSkillIcon_RenderFitPreviewToFile(srcPath, boxW, boxH, destPath) {
    if !FileExist(srcPath) || boxW < 1 || boxH < 1 {
        return false
    }
    _AutoPresetsGdipStartup()
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
        _AutoPresetsGdipSaveGpBitmapToPng(pDst, destPath)
    } finally {
        DllCall("gdiplus\GdipDisposeImage", "ptr", pDst)
        DllCall("gdiplus\GdipDisposeImage", "ptr", pSrc)
    }
    return true
}

AutoPresetsCalibrateIcon_UpdateCurrent() {
    r := AutoPresets_ResolveRegion(ParseAutoPresetCalibrateRegion())
    path := AutoPresetsCalibrateIconGlobalPath()
    AutoPresetsCaptureRegionToPng(path, r["x"], r["y"], r["w"], r["h"])
    return path
}

AutoPresetsTownIcon_UpdateCurrent() {
    r := AutoPresets_ResolveRegion(ParseAutoPresetTownRegion())
    path := AutoPresetsTownIconGlobalPath()
    AutoPresetsCaptureRegionToPng(path, r["x"], r["y"], r["w"], r["h"])
    return path
}

AutoPresetsCalibrateIconMatches() {
    r := AutoPresets_ResolveRegion(ParseAutoPresetCalibrateRegion())
    path := AutoPresetsCalibrateIconGlobalPath()
    if !FileExist(path) {
        return false
    }
    x1 := r["x"]
    y1 := r["y"]
    x2 := x1 + r["w"] - 1
    y2 := y1 + r["h"] - 1
    variation := AutoPresets.CalibrateImageVariation
    optPrefix := "*" variation " "
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
        CoordMode("Pixel", prevPixel)
    }
}

AutoPresetsTownIconMatches() {
    r := AutoPresets_ResolveRegion(ParseAutoPresetTownRegion())
    path := AutoPresetsTownIconGlobalPath()
    if !FileExist(path) {
        return false
    }
    x1 := r["x"]
    y1 := r["y"]
    x2 := x1 + r["w"] - 1
    y2 := y1 + r["h"] - 1
    variation := AutoPresets.TownImageVariation
    optPrefix := "*" variation " "
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
        CoordMode("Pixel", prevPixel)
    }
}

AutoPresetsSkillIcon_UpdateForPreset(presetName) {
    r := AutoPresets_ResolveRegion(ParseAutoPresetRegion())
    name := Trim(presetName)
    if (name = "") {
        throw Error("当前没有选中的配置。")
    }
    path := AutoPresetsSkillIconPath(name)
    AutoPresetsCaptureRegionToPng(path, r["x"], r["y"], r["w"], r["h"])
    return path
}

AutoPresetsFindPresetBySkillIcon() {
    r := AutoPresets_ResolveRegion(ParseAutoPresetRegion())
    x1 := r["x"]
    y1 := r["y"]
    x2 := x1 + r["w"] - 1
    y2 := y1 + r["h"] - 1
    variation := AutoPresets.SkillImageVariation
    optPrefix := "*" variation " "
    prevPixel := CoordMode("Pixel", "Screen")
    try {
        for presetName in LoadAllPreset() {
            path := AutoPresetsSkillIconPath(presetName)
            if !FileExist(path) {
                continue
            }
            needle := optPrefix . path
            try {
                if ImageSearch(&_isx, &_isy, x1, y1, x2, y2, needle) {
                    return presetName
                }
            } catch TargetError {
            }
        }
        return ""
    } finally {
        CoordMode("Pixel", prevPixel)
    }
}

AutoPresets_ClearRetryTimer() {
    if AutoPresets._retryTimer {
        try SetTimer(AutoPresets._retryTimer, 0)
        AutoPresets._retryTimer := false
    }
}

AutoPresets_ClearStartTimer() {
    if AutoPresets._startTimer {
        try SetTimer(AutoPresets._startTimer, 0)
        AutoPresets._startTimer := false
    }
}

AutoPresets_CancelPending() {
    AutoPresets_ClearRetryTimer()
    AutoPresets_ClearStartTimer()
}

AutoPresets_CurrentSessionId() {
    return AutoPresets._sessionId
}

AutoPresets_StartNewSequence() {
    AutoPresets._sequenceId += 1
    return AutoPresets._sequenceId
}

AutoPresets_IsCurrentSequence(sessionId, sequenceId) {
    return sessionId = AutoPresets._sessionId && sequenceId = AutoPresets._sequenceId
}

AutoPresets_Trigger(*) {
    AutoPresets_Request(true)
}

AutoPresets_Request(requireActive := false) {
    if !AutoPresets_IsFeatureEnabledForRunningPreset() {
        return
    }
    if !AutoPresets_IsSessionRunning() {
        return
    }
    if (requireActive && !AutoPresets_GameActive()) {
        return
    }
    AutoPresets_CancelPending()
    sessionId := AutoPresets_CurrentSessionId()
    sequenceId := AutoPresets_StartNewSequence()
    fn := AutoPresets_Begin.Bind(sessionId, sequenceId, 1)
    AutoPresets._startTimer := fn
    SetTimer(fn, -AutoPresets.RetryIntervalMs)
}

AutoPresets_IsFeatureEnabledForRunningPreset() {
    return AutoPresets_LoadEnabledGlobal()
}

AutoPresets_HotIfShouldFire(*) {
    if !AutoPresets_LoadEnabledGlobal() {
        return false
    }
    if !AutoPresets_IsSessionRunning() {
        return false
    }
    return WinActive("ahk_group DNF") != 0
}

AutoPresets_Begin(sessionId, sequenceId, attemptIdx, *) {
    if !AutoPresets_IsCurrentSequence(sessionId, sequenceId) {
        return
    }
    AutoPresets._startTimer := false
    if !AutoPresets_IsFeatureEnabledForRunningPreset() {
        return
    }
    if !AutoPresets_IsSessionRunning() {
        return
    }
    if AutoPresets_GameActive() {
        AutoPresets_RunAttempt(sessionId, sequenceId, attemptIdx)
        return
    }
    if (attemptIdx >= AutoPresets.MaxRetryAttempts) {
        return
    }
    fn := AutoPresets_Begin.Bind(sessionId, sequenceId, attemptIdx + 1)
    AutoPresets._startTimer := fn
    SetTimer(fn, -AutoPresets.RetryIntervalMs)
}

AutoPresets_RunAttempt(sessionId, sequenceId, attemptIdx) {
    if !AutoPresets_IsCurrentSequence(sessionId, sequenceId) {
        return
    }
    if !AutoPresets_IsFeatureEnabledForRunningPreset() {
        AutoPresets_ClearRetryTimer()
        return
    }
    if !AutoPresets_IsSessionRunning() {
        AutoPresets_ClearRetryTimer()
        return
    }
    if !AutoPresets_GameActive() {
        if (attemptIdx >= AutoPresets.MaxRetryAttempts) {
            AutoPresets_ClearRetryTimer()
            return
        }
        fn := AutoPresets_RunAttempt.Bind(sessionId, sequenceId, attemptIdx + 1)
        AutoPresets._retryTimer := fn
        SetTimer(fn, -AutoPresets.RetryIntervalMs)
        return
    }
    if !AutoPresets_HasAnyCalibratePng() || !AutoPresetsCalibrateIconMatches() {
        if (attemptIdx >= AutoPresets.MaxRetryAttempts) {
            AutoPresets_ClearRetryTimer()
            return
        }
        fn := AutoPresets_RunAttempt.Bind(sessionId, sequenceId, attemptIdx + 1)
        AutoPresets._retryTimer := fn
        SetTimer(fn, -AutoPresets.RetryIntervalMs)
        return
    }

    if !AutoPresets_HasAnyTownPng() || !AutoPresetsTownIconMatches() {
        AutoPresets_ClearRetryTimer()
        return
    }

    found := AutoPresetsFindPresetBySkillIcon()
    current := GetNowSelectPreset()
    AutoPresets_ClearRetryTimer()
    if (found != "" && found != current) {
        AutoPresets_ApplySwitchOnMain(found)
        return
    }
    if (found != "" && found = current) {
        return
    }
    firstN := AutoPresets_FirstPresetName()
    if (firstN != "" && firstN != current) {
        AutoPresets_ApplySwitchOnMain(firstN)
    }
}

AutoPresets_ApplySwitchOnMain(presetName) {
    presetName := NormalizePresetName(presetName)
    if (presetName = "" || !PresetExists(presetName)) {
        return
    }
    cur := GetNowSelectPreset()
    if (cur = presetName) {
        return
    }
    StopAutoFire()
    EnterRunningMode(presetName)
    ShowTip("已切换到配置: " presetName)
}

AutoPresets_IsEscHotkeyStr(hk) {
    t := StrLower(Trim(hk))
    return (t = "esc" || t = "escape")
}

AutoPresets_DisableSessionHotkeys() {
    AutoPresets_CancelPending()
    HotIf(AutoPresets_HotIfShouldFire)
    if AutoPresets._registeredEsc {
        try Hotkey("~Esc", "Off")
        AutoPresets._registeredEsc := false
    }
    if AutoPresets._registeredCustom && AutoPresets._lastCustomHotkey != "" {
        try Hotkey("~$" AutoPresets._lastCustomHotkey, "Off")
        AutoPresets._registeredCustom := false
        AutoPresets._lastCustomHotkey := ""
    }
    HotIf()
}

AutoPresets_RegisterSessionHotkeys() {
    AutoPresets_DisableSessionHotkeys()
    if !AutoPresets_LoadEnabledGlobal() {
        return
    }
    if !AutoPresets_IsSessionRunning() {
        return
    }
    hk := Trim(LoadConfig("AutoPresetHotkey", " "))
    if (hk = " ") {
        hk := ""
    }
    HotIf(AutoPresets_HotIfShouldFire)
    try {
        Hotkey("~Esc", AutoPresets_Trigger, "On")
        AutoPresets._registeredEsc := true
    }
    if (hk != "" && !AutoPresets_IsEscHotkeyStr(hk)) {
        try {
            Hotkey("~$" hk, AutoPresets_Trigger, "On")
            AutoPresets._lastCustomHotkey := hk
            AutoPresets._registeredCustom := true
        }
    }
    HotIf()
}

AutoPresets_OnSessionStarted() {
    AutoPresets._sessionId += 1
    AutoPresets._sequenceId += 1
    AutoPresets_CancelPending()
    AutoPresets_RegisterSessionHotkeys()
    if !AutoPresets_LoadEnabledGlobal() {
        return
    }
    AutoPresets_Request()
}

AutoPresets_OnSessionStopped() {
    AutoPresets._sessionId += 1
    AutoPresets._sequenceId += 1
    AutoPresets_DisableSessionHotkeys()
    AutoPresets_CancelPending()
}
