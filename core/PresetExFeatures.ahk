#Requires AutoHotkey v2.0

; 扩展功能是否启用：与主界面写入 INI 的字段一致（不读 GUI 控件）

class PresetExFeatures {
    static _IniKey := Map(
        "LvRen", "LvRenState",
        "GuanYu", "GuanYuState",
        "PetSkill", "PetSkillState",
        "JianZong", "JianZongState",
        "AutoRun", "AutoRunState",
        "Combo", "ComboState",
        "ZhanFa", "ZhanFaState",
    )

    ; featureName 与 Main 中控件名一致；presetName 省略时用当前会话预设
    static IsOn(featureName, presetName := unset) {
        if !IsSet(presetName) {
            presetName := SessionState.GetCurrentPreset()
        }
        presetName := Trim(presetName "")
        if (presetName = "") {
            return false
        }
        if !this._IniKey.Has(featureName) {
            return false
        }
        return LoadPresetBool01(presetName, this._IniKey[featureName], false) != 0
    }
}
