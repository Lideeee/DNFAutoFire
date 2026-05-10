#Requires AutoHotkey v2.0
#Include ./ExWindowHost.ahk

global gPresetSkillGui := Gui("-MinimizeBox -MaximizeBox -Theme +Owner", ExText.PresetSkillIconTitle(""))
global gPresetSkillCtrls := Map()
global gPresetSkillPvW := 224
global gPresetSkillPvH := 126

GuiTheme_Apply(gPresetSkillGui)

gPresetSkillGui.OnEvent("Escape", PresetSkillGuiEscape)
gPresetSkillGui.OnEvent("Close", PresetSkillGuiClose)

gPresetSkillCtrls["Preview"] := gPresetSkillGui.Add("Picture", "x8 y8 w224 h126")
gPresetSkillGui.Add("Text", "x8 y138 w224 h44", ExText.PresetSkillIconHint())
GuiTheme_FlatBtn(gPresetSkillGui, "x8 y188 w108 h28", ExText.PresetSkillIconCapture(), PresetSkillDoUpdate, false)
GuiTheme_FlatBtn(gPresetSkillGui, "x124 y188 w108 h28", ExText.PresetSkillIconDelete(), PresetSkillDoDelete, false)
GuiTheme_FlatBtn(gPresetSkillGui, "x8 y222 w224 h32", ExText.SaveButton(), PresetSkillSaveClose, true)

PresetSkillGetCtrl(name) {
    global gPresetSkillCtrls
    return gPresetSkillCtrls.Has(name) ? gPresetSkillCtrls[name] : ""
}

PresetSkillLockPreviewFrame(pic) {
    global gPresetSkillPvW, gPresetSkillPvH
    if IsObject(pic) {
        pic.Move(8, 8, gPresetSkillPvW, gPresetSkillPvH)
    }
}

ShowGuiPresetSkillIcon(*) {
    gPresetSkillGui.Title := ExText.PresetSkillIconTitle(GetNowSelectPreset())
    PresetSkillRefreshPreview()
    ExWindowHost.ShowOwned(gPresetSkillGui, gPresetSkillGui.Title, "w240 h266")
}

HideGuiPresetSkillIcon() {
    global gPresetSkillGui
    PresetRegionPickCancelIfOpen()
    ExWindowHost.HideOwned(gPresetSkillGui)
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
    path := PresetSkillIconPath(GetNowSelectPreset())
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
        path := PresetSkillIcon_UpdateCurrent()
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
    name := GetNowSelectPreset()
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
