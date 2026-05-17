#Requires AutoHotkey v2.0

global gAutoRunGui := Gui("-MinimizeBox -MaximizeBox")
global gAutoRunCtrls := Map()
global gAutoRunLayout := ExLayout.Window()

UiApplyWindow(gAutoRunGui)
gAutoRunGui.OnEvent("Escape", AutoRunGuiEscape)
gAutoRunGui.OnEvent("Close", AutoRunGuiClose)

contentRight := 264
fieldX := 96
fieldW := contentRight - fieldX
smallFieldW := 88
clearBtnW := 44
pauseBtnGap := 8
pauseSetBtnW := fieldW - clearBtnW - pauseBtnGap

UiExPageTitle(gAutoRunGui, exText["AutoRunPageTitle"], contentRight, gAutoRunLayout, AutoRunHelp)
UiLabel(gAutoRunGui, UiLayoutRect(gAutoRunLayout, ExLayout.MarginLeft(), 54, 72, 26), exText["AutoRunLeftKey"])
UiEdit(gAutoRunCtrls, gAutoRunGui, "AutoRunLeftKey", UiLayoutRect(gAutoRunLayout, fieldX, 54, fieldW, 24, "+ReadOnly -WantCtrlA -E0x200 Border"))
UiPlainButton(gAutoRunGui, UiLayoutRect(gAutoRunLayout, fieldX, 84, fieldW, 24), exText["SetKey"], AutoRunSetLeftKey)

UiLabel(gAutoRunGui, UiLayoutRect(gAutoRunLayout, ExLayout.MarginLeft(), 118, 72, 26), exText["AutoRunRightKey"])
UiEdit(gAutoRunCtrls, gAutoRunGui, "AutoRunRightKey", UiLayoutRect(gAutoRunLayout, fieldX, 118, fieldW, 24, "+ReadOnly -WantCtrlA -E0x200 Border"))
UiPlainButton(gAutoRunGui, UiLayoutRect(gAutoRunLayout, fieldX, 148, fieldW, 24), exText["SetKey"], AutoRunSetRightKey)

UiLabel(gAutoRunGui, UiLayoutRect(gAutoRunLayout, ExLayout.MarginLeft(), 182, 72, 26), exText["AutoRunDelay"])
UiEdit(gAutoRunCtrls, gAutoRunGui, "AutoRunDelay", UiLayoutRect(gAutoRunLayout, fieldX, 182, smallFieldW, 24, "+Number -E0x200 Border"))

UiLabel(gAutoRunGui, UiLayoutRect(gAutoRunLayout, ExLayout.MarginLeft(), 216, 72, 26), exText["AutoRunPauseKey"])
UiEdit(gAutoRunCtrls, gAutoRunGui, "AutoRunPauseKey", UiLayoutRect(gAutoRunLayout, fieldX, 216, fieldW, 24, "+ReadOnly -WantCtrlA -E0x200 Border"))
UiPlainButton(gAutoRunGui, UiLayoutRect(gAutoRunLayout, fieldX, 246, pauseSetBtnW, 24), exText["SetKey"], AutoRunSetPauseKey)
UiPlainButton(gAutoRunGui, UiLayoutRect(gAutoRunLayout, fieldX + pauseSetBtnW + pauseBtnGap, 246, clearBtnW, 24), exText["AutoRunClearPauseKey"], AutoRunClearPauseKey)

autoRunSaveRects := UiExSplitButtonRects(gAutoRunLayout, ExLayout.MarginLeft(), 282, contentRight - ExLayout.MarginLeft(), 8, 32)
UiPlainButton(gAutoRunGui, autoRunSaveRects[1], exText["CommonSaveToAll"], AutoRunSaveToAll, "secondary")
UiPlainButton(gAutoRunGui, autoRunSaveRects[2], exText["CommonSave"], AutoRunSave, "primary")

AutoRunGetCtrl(name) {
    global gAutoRunCtrls
    return gAutoRunCtrls.Has(name) ? gAutoRunCtrls[name] : ""
}

ShowGuiAutoRun(*) {
    global gMainGui, gAutoRunGui, gAutoRunLayout
    if IsObject(gMainGui) {
        gAutoRunGui.Opt("+Owner" gMainGui.Hwnd)
    }
    gAutoRunGui.Title := exText["AutoRunTitle"]
    gAutoRunGui.Show("w" gAutoRunLayout.Width() " h" gAutoRunLayout.Height())
    AutoRunLoadConfig()
    DisableGuiMain()
}

HideGuiAutoRun() {
    gAutoRunGui.Hide()
    EnableGuiMain()
}

AutoRunGuiEscape(*) {
    AutoRunSave()
}

AutoRunGuiClose(*) {
    AutoRunSave()
}

AutoRunHelp(*) {
    UiHelpMsgBox(exText["AutoRunHelp"], exText["AutoRunHelpTitle"])
}

AutoRunSetLeftKey(*) {
    AutoRunGetCtrl("AutoRunLeftKey").Text := GetPressKey()
}

AutoRunSetRightKey(*) {
    AutoRunGetCtrl("AutoRunRightKey").Text := GetPressKey()
}

AutoRunSetPauseKey(*) {
    AutoRunGetCtrl("AutoRunPauseKey").Text := GetPressKey()
}

AutoRunClearPauseKey(*) {
    AutoRunGetCtrl("AutoRunPauseKey").Text := ""
}

AutoRunReadFields() {
    delay := Round((Trim(AutoRunGetCtrl("AutoRunDelay").Text) = "" ? 30 : AutoRunGetCtrl("AutoRunDelay").Text) + 0)
    if (delay < 1) {
        delay := 1
    } else if (delay > 400) {
        delay := 400
    }
    AutoRunGetCtrl("AutoRunDelay").Text := delay
    return Map(
        "AutoRunLeftKey", AutoRunGetCtrl("AutoRunLeftKey").Text,
        "AutoRunRightKey", AutoRunGetCtrl("AutoRunRightKey").Text,
        "AutoRunDelay", delay,
        "AutoRunPauseKey", Trim(AutoRunGetCtrl("AutoRunPauseKey").Text)
    )
}

AutoRunWritePreset(presetName, fields) {
    SavePreset(presetName, "AutoRunLeftKey", fields["AutoRunLeftKey"])
    SavePreset(presetName, "AutoRunRightKey", fields["AutoRunRightKey"])
    SavePreset(presetName, "AutoRunDelay", fields["AutoRunDelay"])
    SavePreset(presetName, "AutoRunPauseKey", fields["AutoRunPauseKey"])
}

AutoRunSave(*) {
    AutoRunWritePreset(GetNowSelectPreset(), AutoRunReadFields())
    HideGuiAutoRun()
}

AutoRunSaveToAll(*) {
    fields := AutoRunReadFields()
    for presetName in LoadAllPreset() {
        AutoRunWritePreset(presetName, fields)
    }
    HideGuiAutoRun()
}

AutoRunLoadConfig() {
    delay := Round(LoadPreset(GetNowSelectPreset(), "AutoRunDelay", 30) + 0)
    if (delay < 1) {
        delay := 1
    } else if (delay > 400) {
        delay := 400
    }
    AutoRunGetCtrl("AutoRunLeftKey").Text := LoadPreset(GetNowSelectPreset(), "AutoRunLeftKey", "Left")
    AutoRunGetCtrl("AutoRunRightKey").Text := LoadPreset(GetNowSelectPreset(), "AutoRunRightKey", "Right")
    AutoRunGetCtrl("AutoRunPauseKey").Text := LoadPreset(GetNowSelectPreset(), "AutoRunPauseKey", "")
    AutoRunGetCtrl("AutoRunDelay").Text := delay
}
