#Requires AutoHotkey v2.0

global gJianZongGui := Gui("+ToolWindow -Theme")
global gJianZongCtrls := Map()

GuiTheme_Apply(gJianZongGui)

gJianZongGui.OnEvent("Escape", JianZongGuiEscape)
gJianZongGui.OnEvent("Close", JianZongGuiClose)

; 标签同宽；两枚 Edit 同左 x126、同宽 w72（毫秒与单键均够用）
gJianZongGui.Add("Text", "x14 y48 w110 h24 +0x200", "延迟时间(ms)")
gJianZongCtrls["JianZongDelay"] := gJianZongGui.Add("Edit", "vJianZongDelay x126 y48 w72 h24 +Number -E0x200 Border")
gJianZongGui.Add("Text", "x14 y80 w110 h24 +0x200", "帝国剑术键")
gJianZongCtrls["JianZongSkillKey"] := gJianZongGui.Add("Edit", "vJianZongSkillKey x126 y80 w72 h24 +ReadOnly -WantCtrlA -E0x200 Border")
RegisterEditPressKeyCapture(gJianZongCtrls["JianZongSkillKey"], GetKeycode.AfterCaptureEdit.Bind(gJianZongCtrls["JianZongSkillKey"]))
GuiTheme_HRule(gJianZongGui, 14, 118, 302)
GuiTheme_FlatBtn(gJianZongGui, "x89 y128 w152 h34", "保存", JianZongSave, true)
GuiTheme_FlatBtnSmall(gJianZongGui, "x290 y10 w26 h26", "?", JianZongHelp)

JianZongGetCtrl(name) {
    global gJianZongCtrls
    return gJianZongCtrls.Has(name) ? gJianZongCtrls[name] : ""
}

ShowGuiJianZong(*) {
    global gMainGui, gJianZongGui
    if IsObject(gMainGui) {
        gJianZongGui.Opt("+Owner" gMainGui.Hwnd)
    }
    gJianZongGui.Title := "太宗帝剑延迟"
    gJianZongGui.Show("w330 h188")
    JianZongLoadConfig()
    DisableGuiMain()
}

HideGuiJianZong() {
    gJianZongGui.Hide()
    EnableGuiMain()
}

JianZongGuiEscape(*) {
    HideGuiJianZong()
}

JianZongGuiClose(*) {
    HideGuiJianZong()
}

JianZongHelp(*) {
    MsgBox("1、设置游戏中帝国剑术的技能按键`n2、设置帝国剑术第一刀后的延迟时间，单位毫秒键`n3、保存配置，启动连发并使用`n`nPS：该按键不能打开连发，否则功能失效", "如何使用太宗帝剑延迟", "Iconi")
}

JianZongSave(*) {
    JianZongSaveConfig()
    HideGuiJianZong()
}

JianZongSaveConfig() {
    delay := Round((Trim(JianZongGetCtrl("JianZongDelay").Text) = "" ? 200 : JianZongGetCtrl("JianZongDelay").Text) + 0)
    if (delay < 20) {
        delay := 20
    } else if (delay > 3000) {
        delay := 3000
    }
    JianZongGetCtrl("JianZongDelay").Text := delay
    SavePreset(GetNowSelectPreset(), "JianZongSkillKey", JianZongGetCtrl("JianZongSkillKey").Text)
    SavePreset(GetNowSelectPreset(), "JianZongDelay", delay)
}

JianZongLoadConfig() {
    sk := GetKeycode.CanonMainKey(Trim(LoadPreset(GetNowSelectPreset(), "JianZongSkillKey", "A")))
    JianZongGetCtrl("JianZongSkillKey").Text := sk != "" ? sk : "A"
    delay := Round(LoadPreset(GetNowSelectPreset(), "JianZongDelay", 200) + 0)
    if (delay < 20) {
        delay := 20
    } else if (delay > 3000) {
        delay := 3000
    }
    JianZongGetCtrl("JianZongDelay").Text := delay
}
