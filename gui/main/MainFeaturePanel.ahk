#Requires AutoHotkey v2.0

class MainFeaturePanel {
    static IsFeatureEnabled(name) {
        ctrl := MainGetCtrl(name)
        if !IsObject(ctrl) {
            return false
        }
        try {
            return Integer(ctrl.Value) = 1
        } catch {
            return false
        }
    }

    static AddFeatureRow(name, colX, y, toggleW, linkW, linkText, linkHandler) {
        global gMainGui, gMainExSwitchUi
        switchHeight := 20
        ui := ToggleGdip(gMainGui, colX, y + 1, toggleW, switchHeight)
        gMainExSwitchUi[name] := ui
        ui.OnClick(MainExSwitchClick.Bind(name))
        linkX := colX + toggleW + 8
        textCtrl := MainAdd("Text", "vMainExLink_" name " x" linkX " y" y " w" linkW " h22 +0x200 +0x100", linkText)
        textCtrl.OnEvent("Click", linkHandler)
        GuiTheme_RegisterHandCursor(textCtrl)
        this.RegisterMutedLink(textCtrl)
    }

    static OnSwitchClick(name, *) {
        cb := MainGetCtrl(name)
        if !IsObject(cb) {
            return
        }
        cb.Value := this.IsFeatureEnabled(name) ? 0 : 1
        this.PaintSwitch(name)
        MainSaveExToggle()
    }

    static PaintSwitch(name) {
        global gMainExSwitchUi
        if !gMainExSwitchUi.Has(name) {
            return
        }
        ui := gMainExSwitchUi[name]
        if !IsObject(MainGetCtrl(name)) {
            return
        }
        if HasMethod(ui, "Draw") {
            ui.Draw(this.IsFeatureEnabled(name))
            return
        }
        GuiTheme_FlatSwitchPaint(ui, this.IsFeatureEnabled(name))
    }

    static PaintAllSwitches(*) {
        for name in MainExFeatureLayoutData.GetFeatureNames() {
            this.PaintSwitch(name)
        }
    }

    static RegisterMutedLink(ctrl) {
        global gMainMutedLinks
        if !IsObject(ctrl) {
            return
        }
        ctrl.SetFont("s10 norm c64748B", GuiTheme_Face)
        gMainMutedLinks.Push({ hwnd: ctrl.Hwnd, ctrl: ctrl, hover: false })
    }

    static PollMutedLinks(*) {
        global gMainMutedLinks
        if (gMainMutedLinks.Length = 0) {
            return
        }
        MouseGetPos(&_mx, &_my, &hwUnder)
        for item in gMainMutedLinks {
            isOver := (hwUnder = item.hwnd)
            if (isOver && !item.hover) {
                item.ctrl.SetFont("s10 underline c5B84D9", GuiTheme_Face)
                item.hover := true
            } else if (!isOver && item.hover) {
                item.ctrl.SetFont("s10 norm c64748B", GuiTheme_Face)
                item.hover := false
            }
        }
    }

    static OpenLvRen(*) {
        ShowGuiLvRen()
    }

    static OpenGuanYu(*) {
        ShowGuiGuanYu()
    }

    static OpenPetSkill(*) {
        ShowGuiPetSkill()
    }

    static OpenZhanFa(*) {
        ShowGuiZhanFa()
    }

    static OpenJianZong(*) {
        ShowGuiJianZong()
    }

    static OpenAutoRun(*) {
        ShowGuiAutoRun()
    }

    static OpenCombo(*) {
        ShowGuiCombo()
    }
}

MainCheckboxOn(name) => MainFeaturePanel.IsFeatureEnabled(name)
MainAddExFeatureRow(name, colX, y, toggleW, linkW, linkText, linkHandler) => MainFeaturePanel.AddFeatureRow(name, colX, y, toggleW, linkW, linkText, linkHandler)
MainExSwitchClick(name, *) => MainFeaturePanel.OnSwitchClick(name)
MainExSwitchPaint(name) => MainFeaturePanel.PaintSwitch(name)
MainExSwitchPaintAll(*) => MainFeaturePanel.PaintAllSwitches()
MainMutedLinkRegister(ctrl) => MainFeaturePanel.RegisterMutedLink(ctrl)
MainMutedLinkPoll(*) => MainFeaturePanel.PollMutedLinks()
MainLvRen(*) => MainFeaturePanel.OpenLvRen()
MainGuanYu(*) => MainFeaturePanel.OpenGuanYu()
MainPetSkill(*) => MainFeaturePanel.OpenPetSkill()
MainZhanFa(*) => MainFeaturePanel.OpenZhanFa()
MainJianZong(*) => MainFeaturePanel.OpenJianZong()
MainAutoRun(*) => MainFeaturePanel.OpenAutoRun()
MainCombo(*) => MainFeaturePanel.OpenCombo()
