#Requires AutoHotkey v2.0

class FeatureModuleRegistry {
    static StartEnabledModules(presetName := unset) {
        if !IsSet(presetName) {
            presetName := SessionState.GetCurrentPreset()
        }

        if PresetExFeatures.IsOn("LvRen", presetName) {
            LvRenRegisterHotkeys()
        }
        if PresetExFeatures.IsOn("GuanYu", presetName) {
            GuanYuRegisterHotkeys()
        }
        if PresetExFeatures.IsOn("PetSkill", presetName) {
            PetSkillRegisterHotkeys()
        }
        if PresetExFeatures.IsOn("JianZong", presetName) {
            this._PrepareJianZong(presetName)
            JianZongRegisterHotkeys()
        }
        if PresetExFeatures.IsOn("AutoRun", presetName) {
            ExAutoRun.RegisterHotkeys()
        }
        if PresetExFeatures.IsOn("Combo", presetName) {
            ComboRegisterHotkeys()
        }
        if PresetExFeatures.IsOn("ZhanFa", presetName) {
            ZhanFaRegisterHotkeys()
        }
    }

    static StopAllModules() {
        ZhanFaUnregisterHotkeys()
        LvRenUnregisterHotkeys()
        GuanYuUnregisterHotkeys()
        PetSkillUnregisterHotkeys()
        JianZongUnregisterHotkeys()
        ComboUnregisterHotkeys()
        ExAutoRun.UnregisterHotkeys()
    }

    static AnyModuleRunning() {
        return ExAutoRun._registered
    }

    static _PrepareJianZong(presetName) {
        skillKey := LoadPreset(presetName, "JianZongSkillKey")
        if (skillKey != "") {
            AutoFireController.UseBlockingOriginalKeyMode(skillKey)
        }
    }
}
