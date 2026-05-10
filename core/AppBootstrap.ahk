#Requires AutoHotkey v2.0

class AppBootstrap {
    static EnableHighTimerResolution() {
        global _MainProcessTimePeriodActive
        _MainProcessTimePeriodActive := false
        try {
            UnlockSystemTimeLimit()
            _MainProcessTimePeriodActive := true
        } catch {
        }
    }

    static ConfigureTray() {
        A_TrayMenu.Delete()
        A_TrayMenu.Add(GuiText.TrayMainSettings(), ShowGuiMain)
        A_TrayMenu.Add(GuiText.TrayAppSettings(), ShowGuiSetting)
        A_TrayMenu.Default := GuiText.TrayMainSettings()
        A_TrayMenu.Add()
        A_TrayMenu.Add(GuiText.TrayExit(), (*) => this.ExitRequested())
        A_TrayMenu.ClickCount := 1
        A_IconTip := GuiText.AppIconTip()
        try TraySetIcon(A_ScriptDir "\assets\icons\icon_main.ico")
    }

    static ExitRequested() {
        ExitApp()
    }

    static CleanupOnExit(*) {
        try SingleInstance_ReleaseMutex()
        try GdiPlusSession.Shutdown()
        try PresetRecognition_DisableAllHotkeys()
        try KeyRouter.StopFocusWatcher()
        try AutoFireController.Stop()
        try GameContext.Shutdown()
        global _MainProcessTimePeriodActive
        if (_MainProcessTimePeriodActive) {
            try RestoreSystemTimeLimit()
            _MainProcessTimePeriodActive := false
        }
    }

    static Run() {
        OnExit(this.CleanupOnExit)
        this.ConfigureTray()
        GameContext.Init()
        PresetRecognition_UpdateHotkeys()
        ShowGuiMain()
        KeyRouter.StartFocusWatcher()
        if (_AutoStart) {
            HideGuiMain()
            AutoFireController.Start()
            try PresetRecognition_StartSequenceFromMainStart()
        }
    }
}
