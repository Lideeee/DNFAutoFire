#Requires AutoHotkey v2.0

global gJianZongGui := Gui("+ToolWindow")
global gJianZongCtrls := Map()

gJianZongGui.OnEvent("Escape", JianZongGuiEscape)
gJianZongGui.OnEvent("Close", JianZongGuiClose)

gJianZongGui.Add("Text", "x8 y8 w80 h20 +0x200", "延迟时间(ms)")
gJianZongCtrls["JianZongDelay"] := gJianZongGui.Add("Edit", "vJianZongDelay x8 y32 w80 h20 +Number")
gJianZongGui.Add("Text", "x8 y56 w80 h20 +0x200", "帝国剑术键")
gJianZongCtrls["JianZongSkillKey"] := gJianZongGui.Add("Edit", "vJianZongSkillKey x8 y80 w80 h20 +ReadOnly")
gJianZongGui.Add("Button", "x8 y104 w80 h22", "设置按键").OnEvent("Click", JianZongSetSkillKey)
gJianZongGui.Add("Button", "x8 y128 w80 h26", "保存").OnEvent("Click", JianZongSave)
gJianZongGui.Add("Button", "x94 y8 w18 h18", "?").OnEvent("Click", JianZongHelp)

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
    gJianZongGui.Show("w120 h160")
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

JianZongSetSkillKey(*) {
    JianZongGetCtrl("JianZongSkillKey").Text := GetPressKey()
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
    JianZongGetCtrl("JianZongSkillKey").Text := LoadPreset(GetNowSelectPreset(), "JianZongSkillKey", "A")
    delay := Round(LoadPreset(GetNowSelectPreset(), "JianZongDelay", 200) + 0)
    if (delay < 20) {
        delay := 20
    } else if (delay > 3000) {
        delay := 3000
    }
    JianZongGetCtrl("JianZongDelay").Text := delay
}
