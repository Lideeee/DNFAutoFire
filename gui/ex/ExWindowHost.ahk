#Requires AutoHotkey v2.0

class ExWindowHost {
    static ShowOwned(guiObj, title, sizeSpec, loadCallback := "") {
        global gMainGui
        if IsObject(gMainGui) {
            guiObj.Opt("+Owner" gMainGui.Hwnd)
        }
        guiObj.Title := title
        guiObj.Show(sizeSpec)
        if IsObject(loadCallback) {
            loadCallback.Call()
        }
        DisableGuiMain()
    }

    static ShowOwnedFit(guiObj, title, loadCallback := "", rightPad := 16, bottomPad := 16, minW := 0, minH := 0, extraOpts := "") {
        global gMainGui
        if IsObject(gMainGui) {
            guiObj.Opt("+Owner" gMainGui.Hwnd)
        }
        guiObj.Title := title
        GuiTheme_ShowFit(guiObj, extraOpts, rightPad, bottomPad, minW, minH)
        if IsObject(loadCallback) {
            loadCallback.Call()
        }
        DisableGuiMain()
    }

    static HideOwned(guiObj) {
        guiObj.Hide()
        EnableGuiMain()
    }
}
