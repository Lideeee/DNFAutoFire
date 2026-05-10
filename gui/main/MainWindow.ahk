#Requires AutoHotkey v2.0

#Include ./layout/MainLayout.ahk
#Include ./layout/MainKeyLayoutData.ahk
#Include ./builders/MainKeyPanelBuilder.ahk
#Include ./builders/MainConfigPanelBuilder.ahk
#Include ./layout/MainExFeatureLayoutData.ahk
#Include ./builders/MainExFeatureBuilder.ahk
#Include ./builders/MainActionButtonBuilder.ahk
#Include ../MainWindowText.ahk

class MainWindow {
    Gui := 0
    Ctrls := 0
    ExSwitchUi := 0

    static BuildSections() {
        MainKeyPanelBuilder.Build()
        MainConfigPanelBuilder.Build()
        MainActionButtonBuilder.Build()
        MainExFeatureBuilder.Build()
    }

    static EnsureBuilt() {
        static _singleton := unset
        if IsSet(_singleton) {
            return _singleton
        }
        global gMainGui, gMainCtrls, gMainExSwitchUi, gMainKeyCaps
        gMainGui := Gui("-MinimizeBox -MaximizeBox -Theme +OwnDialogs")
        gMainCtrls := Map()
        gMainExSwitchUi := Map()
        gMainKeyCaps := Map()
        gMainGui.OnEvent("Escape", MainGuiEscape)
        gMainGui.OnEvent("Close", MainGuiClose)
        gMainGui.OnEvent("ContextMenu", MainGuiContextMenu)
        OnMessage(0x0201, MainPresetListOnLButtonDown)
        OnMessage(0x0202, MainPresetListOnLButtonUp)
        OnMessage(0x0200, MainPresetListOnMouseMove)
        GuiTheme_Apply(gMainGui)
        this.BuildSections()

        inst := MainWindow()
        inst.Gui := gMainGui
        inst.Ctrls := gMainCtrls
        inst.ExSwitchUi := gMainExSwitchUi
        _singleton := inst
        return inst
    }

    GetCtrl(name) {
        global gMainCtrls
        return gMainCtrls.Has(name) ? gMainCtrls[name] : ""
    }
}
