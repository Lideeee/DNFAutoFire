#Requires AutoHotkey v2.0

global UiTheme := Map(
    "FontName", "Microsoft YaHei UI",
    "KeyFace", "Segoe UI",
    "FontSize", "s9",
    "TextColor", "c202124",
    "MutedColor", "c64748B",
    "SectionColor", "c374151",
    "PrimaryColor", "c2563EB",
    "DangerColor", "cB42318",
    "KeyOff", "334155",
    "KeyOn", "2F5B9C",
    "KeyOv", "355FA3",
    "KeyOffColor", "c334155",
    "KeyOnColor", "c2F5B9C",
    "KeyDisabledColor", "c94A3B8",
    "KeyCellBg", "E2E8F0",
    "KeyCapOffBg", "F8FAFC",
    "KeyCapOffBorder", "CBD5E1",
    "KeyCapOnBg", "E3EEFF",
    "KeyCapOnBorder", "A7C2EE",
    "KeyCapOvBg", "EAF2FF",
    "KeyCapOvBorder", "B7CCEE",
    "KeyCapLockedBg", "E5E7EB",
    "KeyCapLockedBorder", "CBD5E1",
    "KeyCapLockedText", "94A3B8",
    "KeyCapHintOn", "2F5B9C",
    "KeyCapHintOv", "355FA3",
    "KeyCapHintLocked", "94A3B8",
    "SwitchTrackOff", "D5D9E0",
    "SwitchTrackOffHover", "CDD3DB",
    "SwitchTrackOffPressed", "C3CAD4",
    "SwitchTrackOn", "4F7FD1",
    "SwitchTrackOnHover", "5B89D8",
    "SwitchTrackOnPressed", "456FBB",
    "SwitchThumb", "FFFFFF",
    "SwitchThumbPressed", "F4F6F8",
    "SwitchBorder", "CBD5E1",
    "SwitchBorderOn", "5B82C8",
    "ButtonBg", "FAFAFB",
    "ButtonBgHover", "F3F6FA",
    "ButtonBgPressed", "ECEFF4",
    "ButtonBorder", "C9D1DB",
    "ButtonBorderHover", "B8C3D1",
    "ButtonBorderPressed", "AEB9C7",
    "ButtonPrimaryBg", "4F7FD1",
    "ButtonPrimaryBgHover", "5A88D7",
    "ButtonPrimaryBgPressed", "456FBB",
    "ButtonPrimaryBorder", "4B78C5",
    "ButtonPrimaryBorderHover", "5C88D2",
    "ButtonPrimaryBorderPressed", "4067AF",
    "ButtonDangerBg", "FBFBFC",
    "ButtonDangerBgHover", "F8F3F3",
    "ButtonDangerBgPressed", "F3EBEB",
    "ButtonDangerBorder", "D8DDE5",
    "ButtonDangerBorderHover", "C9D2DC",
    "ButtonDangerBorderPressed", "BEC8D3",
    "ButtonText", "1F2937",
    "ButtonPrimaryText", "FFFFFF",
    "ButtonDangerText", "B42318",
    "MutedLinkHover", "c5B84D9",
    "WindowBg", "F8FAFC"
)

global UiTheme__HoverState := Map("tick", 0, "hwnd", 0, "windowHwnd", 0, "controlHwnd", 0, "rootHwnd", 0, "leftButtonDown", false)
global UiBlankClickBlur__Entries := []
global UiBlankClickBlur__OnMessageInstalled := false

UiApplyWindow(gui) {
    global UiTheme
    gui.BackColor := UiTheme["WindowBg"]
    gui.SetFont(UiTheme["FontSize"] " c" UiTheme["KeyOff"], UiTheme["FontName"])
    UiInstallBlankClickBlur(gui)
}

UiSetDefaultFont(gui, options := "") {
    global UiTheme
    fontOptions := options = "" ? UiTheme["FontSize"] " " UiTheme["TextColor"] : options
    gui.SetFont(fontOptions, UiTheme["FontName"])
}

UiSetKeyFont(gui, size, enabled := false) {
    global UiTheme
    color := enabled ? UiTheme["KeyOnColor"] : UiTheme["KeyOffColor"]
    weight := enabled ? "Bold" : "Norm"
    gui.SetFont(size " " color " " weight, UiTheme["FontName"])
}

UiSetButtonFont(gui, kind := "secondary") {
    global UiTheme
    if (kind = "primary") {
        gui.SetFont("s10 Bold " UiTheme["PrimaryColor"], UiTheme["FontName"])
    } else if (kind = "danger") {
        gui.SetFont("s9 " UiTheme["DangerColor"], UiTheme["FontName"])
    } else {
        gui.SetFont("s9 " UiTheme["TextColor"], UiTheme["FontName"])
    }
}

; 主界面键帽字号（与参考项目 DNFAutoFire 一致）
UiMainKeyLabelFontSize(keyName) {
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

UiHoverSnapshot(force := false) {
    global UiTheme__HoverState
    tickNow := A_TickCount
    if !force && UiTheme__HoverState["tick"] = tickNow {
        return UiTheme__HoverState
    }
    winHwnd := 0
    ctrlHwnd := 0
    MouseGetPos(&_mx, &_my, &winHwnd, &ctrlHwnd, 2)
    hwUnder := ctrlHwnd ? ctrlHwnd : winHwnd
    rootHwnd := 0
    if winHwnd {
        rootHwnd := DllCall("user32\GetAncestor", "ptr", winHwnd, "uint", 2, "ptr")
        if !rootHwnd {
            rootHwnd := winHwnd
        }
    }
    UiTheme__HoverState["tick"] := tickNow
    UiTheme__HoverState["hwnd"] := hwUnder
    UiTheme__HoverState["windowHwnd"] := winHwnd
    UiTheme__HoverState["controlHwnd"] := ctrlHwnd
    UiTheme__HoverState["rootHwnd"] := rootHwnd
    UiTheme__HoverState["leftButtonDown"] := !!GetKeyState("LButton", "P")
    return UiTheme__HoverState
}

UiInstallBlankClickBlur(gui, onBlur := "") {
    global UiBlankClickBlur__Entries, UiBlankClickBlur__OnMessageInstalled
    if !IsObject(gui) {
        return ""
    }
    for entry in UiBlankClickBlur__Entries {
        if (entry["guiHwnd"] = gui.Hwnd) {
            return entry["sink"]
        }
    }
    sinkName := "__UiBlankFocusSink" gui.Hwnd
    sink := gui.Add("Button", "v" sinkName " x-2000 y-2000 w1 h1")
    try sink.Opt("-TabStop")
    entry := Map("guiHwnd", gui.Hwnd, "sink", sink, "onBlur", onBlur)
    UiBlankClickBlur__Entries.Push(entry)
    if !UiBlankClickBlur__OnMessageInstalled {
        OnMessage(0x0201, UiBlankClickBlur_OnLButtonDown)
        UiBlankClickBlur__OnMessageInstalled := true
    }
    return sink
}

UiBlankClickBlur_OnLButtonDown(wParam, lParam, msg, hwnd) {
    global UiBlankClickBlur__Entries
    if !hwnd {
        return
    }
    for entry in UiBlankClickBlur__Entries {
        if (entry["guiHwnd"] != hwnd) {
            continue
        }
        sink := entry["sink"]
        if !IsObject(sink) {
            return
        }
        try sink.Focus()
        callback := entry["onBlur"]
        if IsObject(callback) {
            try callback.Call()
        }
        return
    }
}
