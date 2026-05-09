#Requires AutoHotkey v2.0

; 设计 token（与旧全局 GuiTheme_* 对齐，便于 GDI+ 与经典 Text 控件共用）。
class UiTheme {
    static Face := "Microsoft YaHei UI"
    static Hint := "64748B"
    static KeyOff := "334155"
    static KeyOn := "DC2626"
    static KeyOv := "2563EB"
    static KeyCellBg := "E2E8F0"
    static SwitchTrackOn := "93C5FD"
    static WindowBg := "F8FAFC"
    static BtnText := "334155"
    static BtnPrimaryBg := "3B82F6"
    static BtnPrimaryText := "FFFFFF"
    static RadiusSm := 6
    static RadiusMd := 8
    static RadiusLg := 10
    static MutedLink := "64748B"
    static MutedLinkHover := "5B84D9"
}
