#Requires AutoHotkey v2.0

class QuickSwitchController {
    static Start(*) {
        presetName := QuickSwitchGetCtrl("QuickSwitchList").Text
        AutoFireController.ChangePreset(presetName)
        AutoFireController.Start()
        this.Hide()
    }

    static Stop(*) {
        AutoFireController.Stop()
        this.Hide()
    }

    static Show(*) {
        global gQuickSwitchGui
        HideGuiMain()
        gQuickSwitchGui.Title := GuiText.QuickSwitchTitle()
        GuiTheme_ShowFit(gQuickSwitchGui, "", 12, 18)
        nowSelectPreset := GetNowSelectPreset()
        presetList := LoadAllPresetString()
        ctrl := QuickSwitchGetCtrl("QuickSwitchList")
        ctrl.Delete()
        idx := 0
        cnt := 0
        presetItems := StrSplit(presetList, "|")
        loop presetItems.Length {
            if !presetItems.Has(A_Index) {
                continue
            }
            item := presetItems[A_Index]
            if (item != "") {
                ctrl.Add([item])
                cnt++
                if (item = nowSelectPreset) {
                    idx := cnt
                }
            }
        }
        if (idx > 0) {
            ctrl.Choose(idx)
        } else if (cnt > 0) {
            ctrl.Choose(1)
        }
        ctrl.Focus()
        OnMessage(0x0100, QuickSwitchOnSpacePress)
    }

    static Hide() {
        global gQuickSwitchGui
        gQuickSwitchGui.Hide()
        OnMessage(0x0100, QuickSwitchOnSpacePress, 0)
    }

    static OnSpacePress(wParam, lParam, msg, hwnd) {
        global gQuickSwitchGui
        if (!IsObject(gQuickSwitchGui) || !WinExist("ahk_id " gQuickSwitchGui.Hwnd) || !WinActive("ahk_id " gQuickSwitchGui.Hwnd)) {
            return
        }
        key := GetKeyName(Format("vk{1:02X}", wParam))
        if (key = "Space" || key = "Enter") {
            this.Start()
        }
    }

    static ChangeList(*) {
        this.Start()
    }
}
