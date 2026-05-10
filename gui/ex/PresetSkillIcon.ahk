#Requires AutoHotkey v2.0
#Include ./ExWindowHost.ahk

global gPresetSkillGui := Gui("-MinimizeBox -MaximizeBox -Theme +Owner", ExText.PresetSkillIconTitle(""))
global gPresetSkillCtrls := Map()
global gPresetSkillPvW := 224
global gPresetSkillPvH := 126
global gPresetSkillTargetPreset := ""

GuiTheme_Apply(gPresetSkillGui)

gPresetSkillGui.OnEvent("Escape", PresetSkillGuiEscape)
gPresetSkillGui.OnEvent("Close", PresetSkillGuiClose)

gPresetSkillCtrls["Preview"] := gPresetSkillGui.Add("Picture", "x16 y16 w224 h126")
gPresetSkillGui.Add("Text", "x16 y146 w224 h44", ExText.PresetSkillIconHint())
GuiTheme_FlatBtn(gPresetSkillGui, "x16 y196 w108 h28", ExText.PresetSkillIconCapture(), PresetSkillDoUpdate, false)
GuiTheme_FlatBtn(gPresetSkillGui, "x132 y196 w108 h28", ExText.PresetSkillIconDelete(), PresetSkillDoDelete, false)
GuiTheme_FlatBtn(gPresetSkillGui, "x16 y230 w224 h32", ExText.SaveButton(), PresetSkillSaveClose, true)

PresetSkillGetCtrl(name) {
    global gPresetSkillCtrls
    return gPresetSkillCtrls.Has(name) ? gPresetSkillCtrls[name] : ""
}

PresetSkillLockPreviewFrame(pic) {
    global gPresetSkillPvW, gPresetSkillPvH
    if IsObject(pic) {
        pic.Move(16, 16, gPresetSkillPvW, gPresetSkillPvH)
    }
}

ShowGuiPresetSkillIcon(presetName := "") {
    global gPresetSkillTargetPreset
    gPresetSkillTargetPreset := Trim(presetName)
    gPresetSkillGui.Title := ExText.PresetSkillIconTitle(PresetSkillTargetPreset())
    PresetSkillRefreshPreview()
    ExWindowHost.ShowOwnedFit(gPresetSkillGui, gPresetSkillGui.Title)
}

HideGuiPresetSkillIcon() {
    global gPresetSkillGui, gPresetSkillTargetPreset
    PresetRegionPickCancelIfOpen()
    gPresetSkillTargetPreset := ""
    ExWindowHost.HideOwned(gPresetSkillGui)
}

PresetSkillTargetPreset() {
    global gPresetSkillTargetPreset
    return (gPresetSkillTargetPreset != "") ? gPresetSkillTargetPreset : GetNowSelectPreset()
}

PresetSkillGuiEscape(*) {
    HideGuiPresetSkillIcon()
}

PresetSkillGuiClose(*) {
    HideGuiPresetSkillIcon()
}

PresetSkillRefreshPreview() {
    global gPresetSkillPvW, gPresetSkillPvH
    pic := PresetSkillGetCtrl("Preview")
    path := PresetSkillIconPath(PresetSkillTargetPreset())
    pic.Value := ""
    PresetSkillLockPreviewFrame(pic)
    if FileExist(path) {
        tmp := PresetSkillIcon_FitPreviewTempPath()
        if PresetSkillIcon_RenderFitPreviewToFile(path, gPresetSkillPvW, gPresetSkillPvH, tmp) && FileExist(tmp) {
            pic.Value := tmp
            PresetSkillLockPreviewFrame(pic)
        }
    }
}

PresetSkillDoUpdate(*) {
    global gPresetSkillPvW, gPresetSkillPvH
    PresetRegionPickCommitSkillRegionIfOpen()
    try {
        path := PresetSkillIcon_UpdateForPreset(PresetSkillTargetPreset())
        pic := PresetSkillGetCtrl("Preview")
        pic.Value := ""
        PresetSkillLockPreviewFrame(pic)
        tmp := PresetSkillIcon_FitPreviewTempPath()
        if PresetSkillIcon_RenderFitPreviewToFile(path, gPresetSkillPvW, gPresetSkillPvH, tmp) && FileExist(tmp) {
            pic.Value := tmp
            PresetSkillLockPreviewFrame(pic)
        }
    } catch Error as e {
        MsgBox(e.Message,, "Icon!")
    }
}

PresetSkillDoDelete(*) {
    name := PresetSkillTargetPreset()
    if (name = "") {
        return
    }
    if !FileExist(PresetSkillIconPath(name)) {
        return
    }
    PresetSkillIcon_DeleteForPreset(name)
    PresetSkillRefreshPreview()
}

PresetSkillSaveClose(*) {
    PresetRegionPickCommitIfOpen()
    HideGuiPresetSkillIcon()
}

MainPresetSkill(*) {
    ShowGuiPresetSkillIcon()
}
