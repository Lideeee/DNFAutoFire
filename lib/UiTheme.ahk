#Requires AutoHotkey v2.0

; 设计 token（与旧全局 GuiTheme_* 对齐，便于 GDI+ 与经典 Text 控件共用）。
class UiTheme {
    static Face := "Microsoft YaHei UI"
    static KeyFace := "Segoe UI"
    static Hint := "64748B"
    static KeyOff := "334155"
    static KeyOn := "355FA3"
    static KeyOv := "355FA3"
    static KeyCellBg := "E2E8F0"
    static KeyCapOffBg := "F8FAFC"
    static KeyCapOffBorder := "CBD5E1"
    static KeyCapOffHover := "F1F5F9"
    static KeyCapOnBg := "EAF2FF"
    static KeyCapOnBorder := "B7CCEE"
    static KeyCapOnAccent := "355FA3"
    static KeyCapOvBg := "EAF2FF"
    static KeyCapOvBorder := "B7CCEE"
    static KeyCapOvAccent := "355FA3"
    static KeyCapLockedBg := "E5E7EB"
    static KeyCapLockedBorder := "CBD5E1"
    static KeyCapLockedText := "94A3B8"
    static KeyCapHintOn := "355FA3"
    static KeyCapHintOv := "355FA3"
    static KeyCapHintLocked := "94A3B8"
    static SwitchTrackOn := "93C5FD"
    static WindowBg := "F8FAFC"
    static BtnText := "334155"
    static BtnPrimaryBg := "3B82F6"
    static BtnPrimaryText := "FFFFFF"
    static RadiusSm := 0
    static RadiusMd := 0
    static RadiusLg := 0
    static MutedLink := "64748B"
    static MutedLinkHover := "5B84D9"
}
