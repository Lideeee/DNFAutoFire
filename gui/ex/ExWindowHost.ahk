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

    static HideOwned(guiObj) {
        guiObj.Hide()
        EnableGuiMain()
    }
}
