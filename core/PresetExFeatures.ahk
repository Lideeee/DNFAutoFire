#Requires AutoHotkey v2.0

; 扩展功能是否启用：与主界面写入 INI 的字段一致（不读 GUI 控件）

class PresetExFeatures {
    static _IniKey := PresetManager.FeatureFieldMap

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
        return PresetManager.LoadFeatureState(featureName, presetName) != 0
    }
}
