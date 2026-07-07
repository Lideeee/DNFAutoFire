#Requires AutoHotkey v2.0

; 自动识别配置：搜图匹配城镇与技能栏参考图后切换预设

class AutoPresets {
    static StartDelayMs := 500
    static RetryIntervalMs := 500
    static MaxRetryAttempts := 60
    static SkillImageVariation := 80
    static TownImageVariation := 20
    static RegionCornerRadius := 12
    static RegionMaskRgb := "White"
    static SearchExpandRatio := 0.05
    static SearchExpandMinX := 6
    static SearchExpandMinY := 4
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
    return AutoPresets_CoerceIniBool(LoadConfig("AutoPresetsEnabled", false))
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

AutoPresets_GetGameClientRect() {
    title := FindDNFGameWindowTitle()
    if (title = "") {
        return ""
    }
    try {
        WinGetClientPos(&cx, &cy, &cw, &ch, title)
    } catch {
        return ""
    }
    if (cw < 1 || ch < 1) {
        return ""
    }
    return Map("x", cx, "y", cy, "w", cw, "h", ch, "title", title)
}

AutoPresetsResolutionKey(client := "") {
    if !IsObject(client) {
        client := AutoPresets_GetGameClientRect()
    }
    if !IsObject(client) {
        return ""
    }
    return client["w"] "x" client["h"]
}

AutoPresetsSkillPresetDir(presetName) {
    return AutoPresetsSkillIconDir() "\" AutoPresetsSkillIcon_SafeName(presetName)
}

AutoPresetsSkillIconPathForId(presetName, skillId) {
    return AutoPresetsSkillPresetDir(presetName) "\" skillId ".png"
}

AutoPresetsSkillIcon_EnsureDir() {
    dir := AutoPresetsSkillIconDir()
    if !DirExist(dir) {
        DirCreate(dir)
    }
}

AutoPresetsSkillIcons_ParseStored(raw) {
    out := Map()
    raw := Trim(raw)
    if (raw = "") {
        return out
    }
    for part in StrSplit(raw, "|") {
        part := Trim(part)
        if (part = "") {
            continue
        }
        eq := InStr(part, "=")
        if !eq {
            continue
        }
        id := Trim(SubStr(part, 1, eq - 1))
        name := Trim(SubStr(part, eq + 1))
        if (id != "" && name != "") {
            out[id] := name
        }
    }
    return out
}

AutoPresetsSkillIcons_FormatStored(items) {
    parts := []
    for item in items {
        parts.Push(item["id"] "=" item["name"])
    }
    if (parts.Length = 0) {
        return ""
    }
    out := parts[1]
    loop parts.Length - 1 {
        out .= "|" parts[A_Index + 1]
    }
    return out
}

AutoPresetsSkillIcons_SortItems(items) {
    if (items.Length < 2) {
        return items
    }
    order := []
    byId := Map()
    for item in items {
        order.Push(item["id"])
        byId[item["id"]] := item
    }
    loop order.Length - 1 {
        loop order.Length - A_Index {
            i := A_Index
            ai := 0
            bi := 0
            try ai := Integer(order[i])
            catch {
                ai := 0
            }
            try bi := Integer(order[i + 1])
            catch {
                bi := 0
            }
            if (ai > bi) {
                tmp := order[i]
                order[i] := order[i + 1]
                order[i + 1] := tmp
            }
        }
    }
    sorted := []
    for id in order {
        sorted.Push(byId[id])
    }
    return sorted
}

AutoPresetsSkillIcons_Load(presetName) {
    name := Trim(presetName)
    if (name = "") {
        return []
    }
    nameMap := AutoPresetsSkillIcons_ParseStored(LoadPreset(name, "AutoPresetSkillIcons", ""))
    items := []
    dir := AutoPresetsSkillPresetDir(name)
    if !DirExist(dir) {
        return items
    }
    Loop Files dir "\*.png" {
        id := RegExReplace(A_LoopFileName, "\.png$", "", , 1)
        if (id = "") {
            continue
        }
        path := A_LoopFileFullPath
        displayName := nameMap.Has(id) ? nameMap[id] : ("角色" id)
        items.Push(Map("id", id, "name", displayName, "path", path))
    }
    return AutoPresetsSkillIcons_SortItems(items)
}

AutoPresetsSkillIcons_Save(presetName, items) {
    name := Trim(presetName)
    if (name = "") {
        return
    }
    SavePreset(name, "AutoPresetSkillIcons", AutoPresetsSkillIcons_FormatStored(items))
}

AutoPresetsSkillIcons_NextId(presetName) {
    maxId := 0
    for item in AutoPresetsSkillIcons_Load(presetName) {
        try n := Integer(item["id"])
        catch {
            n := 0
        }
        if (n > maxId) {
            maxId := n
        }
    }
    return String(maxId + 1)
}

AutoPresetsSkillIcons_NextDefaultName(presetName) {
    maxN := 0
    for item in AutoPresetsSkillIcons_Load(presetName) {
        try n := Integer(item["id"])
        catch {
            n := 0
        }
        if (n > maxN) {
            maxN := n
        }
        if RegExMatch(item["name"], "^角色(\d+)$", &m) {
            nn := m[1] + 0
            if (nn > maxN) {
                maxN := nn
            }
        }
    }
    return "角色" (maxN + 1)
}

AutoPresetsSkillIcon_Add(presetName) {
    name := Trim(presetName)
    if (name = "") {
        throw Error("当前没有选中的配置。")
    }
    AutoPresetsSkillIcon_EnsureDir()
    dir := AutoPresetsSkillPresetDir(name)
    if !DirExist(dir) {
        DirCreate(dir)
    }
    skillId := AutoPresetsSkillIcons_NextId(name)
    displayName := AutoPresetsSkillIcons_NextDefaultName(name)
    path := AutoPresetsSkillIconPathForId(name, skillId)
    r := AutoPresets_ResolveRegion(ParseAutoPresetRegion())
    AutoPresetsCaptureRegionToPng(path, r["x"], r["y"], r["w"], r["h"])
    AutoPresetsSkillIcons_Save(name, AutoPresetsSkillIcons_Load(name))
    return Map("id", skillId, "name", displayName, "path", path)
}

AutoPresetsSkillIcon_Delete(presetName, skillId) {
    name := Trim(presetName)
    skillId := Trim(skillId)
    if (name = "" || skillId = "") {
        return
    }
    path := AutoPresetsSkillIconPathForId(name, skillId)
    if FileExist(path) {
        try FileDelete(path)
    }
    kept := []
    for item in AutoPresetsSkillIcons_Load(name) {
        if (item["id"] != skillId) {
            kept.Push(item)
        }
    }
    AutoPresetsSkillIcons_Save(name, kept)
}

AutoPresetsSkillIcon_Rename(presetName, skillId, newName) {
    name := Trim(presetName)
    skillId := Trim(skillId)
    newName := Trim(newName)
    if (name = "" || skillId = "" || newName = "") {
        return false
    }
    items := AutoPresetsSkillIcons_Load(name)
    found := false
    for item in items {
        if (item["id"] = skillId) {
            item["name"] := newName
            found := true
            break
        }
    }
    if !found {
        return false
    }
    AutoPresetsSkillIcons_Save(name, items)
    return true
}

AutoPresetsSkillIcons_CopyDir(srcPreset, destPreset) {
    srcDir := AutoPresetsSkillPresetDir(srcPreset)
    destDir := AutoPresetsSkillPresetDir(destPreset)
    if DirExist(destDir) {
        try DirDelete(destDir, true)
    }
    if DirExist(srcDir) {
        AutoPresetsSkillIcon_EnsureDir()
        try DirCopy(srcDir, destDir, true)
    }
}

AutoPresets_OnPresetCloned(oldName, newName) {
    AutoPresetsSkillIcons_CopyDir(oldName, newName)
    SavePreset(newName, "AutoPresetSkillIcons", LoadPreset(oldName, "AutoPresetSkillIcons", ""))
}

AutoPresets_OnPresetRenamed(oldName, newName) {
    AutoPresets_OnPresetCloned(oldName, newName)
    AutoPresets_OnPresetDeleted(oldName)
}

AutoPresets_OnPresetDeleted(presetName) {
    dir := AutoPresetsSkillPresetDir(presetName)
    if DirExist(dir) {
        try DirDelete(dir, true)
    }
}

AutoPresetsTownIconDir() => AutoPresetsAssetDir() "\town"

AutoPresetsTownIconCurrentPath() {
    resKey := AutoPresetsResolutionKey()
    if (resKey = "") {
        throw Error("未找到 DNF 游戏窗口，无法按分辨率保存城镇识别图。")
    }
    return AutoPresetsTownIconDir() "\" resKey ".png"
}

AutoPresetsTownIconPaths() {
    paths := []
    dir := AutoPresetsTownIconDir()
    if !DirExist(dir) {
        return paths
    }
    Loop Files dir "\*.png" {
        if !RegExMatch(A_LoopFileName, "^\d+x\d+\.png$") {
            continue
        }
        paths.Push(A_LoopFileFullPath)
    }
    return paths
}

AutoPresetsTownIconPreviewPath() {
    try {
        p := AutoPresetsTownIconCurrentPath()
        if FileExist(p) {
            return p
        }
    } catch {
    }
    for p in AutoPresetsTownIconPaths() {
        return p
    }
    return ""
}

AutoPresets_DefaultRegion() {
    w := 200
    h := 90
    client := AutoPresets_GetGameClientRect()
    if IsObject(client) {
        return Map("x", client["x"] + (client["w"] - w) // 2, "y", client["y"] + (client["h"] - h) // 2, "w", w, "h", h)
    }
    return Map("x", (A_ScreenWidth - w) // 2, "y", (A_ScreenHeight - h) // 2, "w", w, "h", h)
}

AutoPresets_ResolveRegion(region, expandForSearch := false) {
    if !IsObject(region) || !region.Has("mode") || region["mode"] != "clientRatio" {
        return AutoPresets_DefaultRegion()
    }
    client := AutoPresets_GetGameClientRect()
    if !IsObject(client) {
        return AutoPresets_DefaultRegion()
    }
    x := client["x"] + Round(region["rx"] * client["w"])
    y := client["y"] + Round(region["ry"] * client["h"])
    w := Max(1, Round(region["rw"] * client["w"]))
    h := Max(1, Round(region["rh"] * client["h"]))
    out := Map("x", x, "y", y, "w", w, "h", h, "client", client)
    return expandForSearch ? AutoPresets_ExpandSearchRegion(out, client) : out
}

AutoPresets_ExpandSearchRegion(region, client := "") {
    if !IsObject(region) || !region.Has("w") {
        return region
    }
    mx := Max(AutoPresets.SearchExpandMinX, Round(region["w"] * AutoPresets.SearchExpandRatio))
    my := Max(AutoPresets.SearchExpandMinY, Round(region["h"] * AutoPresets.SearchExpandRatio))
    x := region["x"] - mx
    y := region["y"] - my
    w := region["w"] + mx * 2
    h := region["h"] + my * 2
    if IsObject(client) {
        left := client["x"]
        top := client["y"]
        right := client["x"] + client["w"]
        bottom := client["y"] + client["h"]
        x2 := Min(right, x + w)
        y2 := Min(bottom, y + h)
        x := Max(left, x)
        y := Max(top, y)
        w := Max(1, x2 - x)
        h := Max(1, y2 - y)
    } else {
        x2 := Min(A_ScreenWidth, x + w)
        y2 := Min(A_ScreenHeight, y + h)
        x := Max(0, x)
        y := Max(0, y)
        w := Max(1, x2 - x)
        h := Max(1, y2 - y)
    }
    out := Map("x", x, "y", y, "w", w, "h", h)
    if IsObject(client) {
        out["client"] := client
    }
    return out
}

ParseAutoPresetRegionByKey(configKey) {
    raw := Trim(LoadConfig(configKey, " "))
    out := Map()
    if (raw = "" || raw = " ") {
        return out
    }
    parts := StrSplit(raw, "|")
    if (parts.Length < 7 || parts[1] != "clientRatio") {
        return out
    }
    try {
        baseW := Integer(parts[2])
        baseH := Integer(parts[3])
        rx := parts[4] + 0
        ry := parts[5] + 0
        rw := parts[6] + 0
        rh := parts[7] + 0
    } catch {
        return out
    }
    if (baseW < 1 || baseH < 1 || rw <= 0 || rh <= 0) {
        return out
    }
    out["mode"] := "clientRatio"
    out["baseW"] := baseW
    out["baseH"] := baseH
    out["rx"] := rx
    out["ry"] := ry
    out["rw"] := rw
    out["rh"] := rh
    out["w"] := Max(1, Round(rw * baseW))
    out["h"] := Max(1, Round(rh * baseH))
    return out
}

SaveAutoPresetRegionByKey(configKey, x, y, w, h) {
    client := AutoPresets_GetGameClientRect()
    if !IsObject(client) {
        throw Error("未找到 DNF 游戏窗口，无法保存客户区相对识别区域。")
    }
    rx := (x - client["x"]) / client["w"]
    ry := (y - client["y"]) / client["h"]
    rw := w / client["w"]
    rh := h / client["h"]
    SaveConfig(configKey, "clientRatio|" client["w"] "|" client["h"] "|"
        Round(rx, 6) "|" Round(ry, 6) "|" Round(rw, 6) "|" Round(rh, 6))
}

ParseAutoPresetTownRegion() {
    return ParseAutoPresetRegionByKey("AutoPresetTownRegion")
}

SaveAutoPresetTownRegion(x, y, w, h) {
    SaveAutoPresetRegionByKey("AutoPresetTownRegion", x, y, w, h)
}

AutoPresets_HasAnyTownPng() {
    return AutoPresetsTownIconPaths().Length > 0
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

AutoPresets_RegionCornerRadius(w, h) {
    return Max(0, Min(AutoPresets.RegionCornerRadius, w // 2, h // 2))
}

AutoPresets_ImageSearchPrefix(variation) {
    return "*" variation " *Trans" AutoPresets.RegionMaskRgb " "
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
            _AutoPresetsGdipSaveHbitmapPng(hbm, path, AutoPresets_RegionCornerRadius(w, h))
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

_AutoPresetsGdipSaveHbitmapPng(hbm, path, radius := 0) {
    _AutoPresetsGdipStartup()
    pBitmap := 0
    if DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", "ptr", hbm, "int", 0, "ptr*", &pBitmap := 0) != 0 || !pBitmap {
        throw Error("GdipCreateBitmapFromHBITMAP failed")
    }
    try {
        if (radius > 0) {
            rounded := _AutoPresetsGdipCreateRoundedBitmap(pBitmap, radius)
            try _AutoPresetsGdipSaveGpBitmapToPng(rounded, path)
            finally DllCall("gdiplus\GdipDisposeImage", "ptr", rounded)
        } else {
            _AutoPresetsGdipSaveGpBitmapToPng(pBitmap, path)
        }
    } finally {
        DllCall("gdiplus\GdipDisposeImage", "ptr", pBitmap)
    }
}

_AutoPresetsGdipCreateRoundedBitmap(pSrc, radius) {
    sw := 0
    sh := 0
    DllCall("gdiplus\GdipGetImageWidth", "ptr", pSrc, "uint*", &sw := 0)
    DllCall("gdiplus\GdipGetImageHeight", "ptr", pSrc, "uint*", &sh := 0)
    if (sw < 1 || sh < 1) {
        throw Error("GdipGetImageSize failed")
    }
    stride := sw * 4
    pDst := 0
    if DllCall("gdiplus\GdipCreateBitmapFromScan0", "int", sw, "int", sh, "int", stride, "int", GdipUiHelpers.PixelFormat32bppARGB, "ptr", 0, "ptr*", &pDst := 0) != 0 || !pDst {
        throw Error("GdipCreateBitmapFromScan0 failed")
    }
    gr := 0
    pPath := 0
    try {
        if DllCall("gdiplus\GdipGetImageGraphicsContext", "ptr", pDst, "ptr*", &gr := 0) != 0 || !gr {
            throw Error("GdipGetImageGraphicsContext failed")
        }
        DllCall("gdiplus\GdipSetSmoothingMode", "ptr", gr, "int", 3)
        DllCall("gdiplus\GdipSetPixelOffsetMode", "ptr", gr, "int", 3)
        DllCall("gdiplus\GdipGraphicsClear", "ptr", gr, "uint", 0xFFFFFFFF)
        if DllCall("gdiplus\GdipCreatePath", "int", 0, "ptr*", &pPath := 0) != 0 || !pPath {
            throw Error("GdipCreatePath failed")
        }
        GdipUiHelpers.AddPathRoundedRect(pPath, 0, 0, sw, sh, radius)
        if DllCall("gdiplus\GdipSetClipPath", "ptr", gr, "ptr", pPath, "int", 0) != 0 {
            throw Error("GdipSetClipPath failed")
        }
        if DllCall("gdiplus\GdipDrawImageRectI", "ptr", gr, "ptr", pSrc, "int", 0, "int", 0, "int", sw, "int", sh) != 0 {
            throw Error("GdipDrawImageRectI failed")
        }
        return pDst
    } catch Error as e {
        if pDst {
            DllCall("gdiplus\GdipDisposeImage", "ptr", pDst)
        }
        throw e
    } finally {
        if pPath {
            DllCall("gdiplus\GdipDeletePath", "ptr", pPath)
        }
        if gr {
            DllCall("gdiplus\GdipDeleteGraphics", "ptr", gr)
        }
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

AutoPresetsTownIcon_UpdateCurrent() {
    r := AutoPresets_ResolveRegion(ParseAutoPresetTownRegion())
    path := AutoPresetsTownIconCurrentPath()
    AutoPresetsCaptureRegionToPng(path, r["x"], r["y"], r["w"], r["h"])
    return path
}

AutoPresetsTownIconMatches() {
    r := AutoPresets_ResolveRegion(ParseAutoPresetTownRegion(), true)
    paths := AutoPresetsTownIconPaths()
    if (paths.Length = 0) {
        return false
    }
    x1 := r["x"]
    y1 := r["y"]
    x2 := x1 + r["w"] - 1
    y2 := y1 + r["h"] - 1
    variation := AutoPresets.TownImageVariation
    optPrefix := AutoPresets_ImageSearchPrefix(variation)
    prevPixel := CoordMode("Pixel", "Screen")
    try {
        for path in paths {
            needle := optPrefix . path
            try {
                if ImageSearch(&_icx, &_icy, x1, y1, x2, y2, needle) {
                    return true
                }
            } catch TargetError {
            }
        }
        return false
    } finally {
        CoordMode("Pixel", prevPixel)
    }
}

AutoPresetsSkillIcon_UpdateForPreset(presetName, skillId := "") {
    name := Trim(presetName)
    if (name = "") {
        throw Error("当前没有选中的配置。")
    }
    skillId := Trim(skillId)
    if (skillId = "") {
        return AutoPresetsSkillIcon_Add(name)
    }
    path := AutoPresetsSkillIconPathForId(name, skillId)
    r := AutoPresets_ResolveRegion(ParseAutoPresetRegion())
    AutoPresetsCaptureRegionToPng(path, r["x"], r["y"], r["w"], r["h"])
    return path
}

AutoPresetsFindPresetBySkillIcon() {
    r := AutoPresets_ResolveRegion(ParseAutoPresetRegion(), true)
    x1 := r["x"]
    y1 := r["y"]
    x2 := x1 + r["w"] - 1
    y2 := y1 + r["h"] - 1
    variation := AutoPresets.SkillImageVariation
    optPrefix := AutoPresets_ImageSearchPrefix(variation)
    prevPixel := CoordMode("Pixel", "Screen")
    try {
        for presetName in LoadAllPreset() {
            for item in AutoPresetsSkillIcons_Load(presetName) {
                path := item["path"]
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
    SetTimer(fn, -AutoPresets.StartDelayMs)
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

AutoPresets_ScheduleNextAttempt(sessionId, sequenceId, attemptIdx) {
    AutoPresets_ClearRetryTimer()
    if (attemptIdx >= AutoPresets.MaxRetryAttempts) {
        return
    }
    if !AutoPresets_IsCurrentSequence(sessionId, sequenceId) {
        return
    }
    fn := AutoPresets_RunAttempt.Bind(sessionId, sequenceId, attemptIdx + 1)
    AutoPresets._retryTimer := fn
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
        AutoPresets_ScheduleNextAttempt(sessionId, sequenceId, attemptIdx)
        return
    }
    if AutoPresets_HasAnyTownPng() && AutoPresetsTownIconMatches() {
        AutoPresets_ClearRetryTimer()
        return
    }

    found := AutoPresetsFindPresetBySkillIcon()
    current := GetNowSelectPreset()
    if (found != "" && found != current) {
        AutoPresets_ApplySwitchOnMain(found)
    }
    AutoPresets_ScheduleNextAttempt(sessionId, sequenceId, attemptIdx)
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
