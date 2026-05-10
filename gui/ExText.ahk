#Requires AutoHotkey v2.0

class ExText {
    static SaveButton() {
        return "保存"
    }

    static AddButton() {
        return "添加"
    }

    static DeleteButton() {
        return "删除"
    }

    static CancelButton() {
        return "取消"
    }

    static InvalidKey() {
        return "无效按键，请重新输入。"
    }

    static DuplicateKey() {
        return "该按键已存在。"
    }

    static LvRenTitle() {
        return "旅人自动流星"
    }

    static LvRenListLabel() {
        return "已添加技能键"
    }

    static LvRenShotKeyLabel() {
        return "流星发射键"
    }

    static LvRenHelp() {
        return "1. 添加需要触发的技能键。`n2. 设置射击键。`n3. 保存后生效。"
    }

    static LvRenHelpTitle() {
        return "设置说明"
    }

    static GuanYuTitle() {
        return "关闭自动战戟猛攻"
    }

    static GuanYuListLabel() {
        return "已添加技能键"
    }

    static GuanYuShotKeyLabel() {
        return "猛攻发射键"
    }

    static GuanYuDelayLabel() {
        return "手动延迟(ms)"
    }

    static GuanYuHelp() {
        return "1. 添加需要触发的技能键。`n2. 设置戳刺键和技能延迟。`n3. 保存后生效。"
    }

    static GuanYuHelpTitle() {
        return "设置说明"
    }

    static PetSkillTitle() {
        return "自动宠物技能"
    }

    static PetSkillListLabel() {
        return "已添加触发键"
    }

    static PetSkillShotKeyLabel() {
        return "宠物快捷键"
    }

    static PetSkillHelp() {
        return "1. 添加宠物快捷键。`n2. 设置释放键。`n3. 保存后生效。"
    }

    static PetSkillHelpTitle() {
        return "设置说明"
    }

    static ZhanFaTitle() {
        return "战法自动炫纹"
    }

    static ZhanFaListLabel() {
        return "已添加技能键"
    }

    static ZhanFaShotKeyLabel() {
        return "炫纹发射键"
    }

    static ZhanFaHelp() {
        return "1. 添加需要触发的技能键。`n2. 设置释放键。`n3. 保存后生效。"
    }

    static ZhanFaHelpTitle() {
        return "设置说明"
    }

    static JianZongTitle() {
        return "帝国剑术延迟"
    }

    static JianZongDelayLabel() {
        return "延迟时间(ms)"
    }

    static JianZongSkillKeyLabel() {
        return "帝国剑术快捷键"
    }

    static JianZongHelp() {
        return "1. 设置要触发的技能键。`n2. 设置技能延迟。`n3. 保存后生效。`n`nPS：仅对当前预设生效。"
    }

    static JianZongHelpTitle() {
        return "设置说明"
    }

    static AutoRunTitle() {
        return "自动奔跑设置"
    }

    static AutoRunLeftLabel() {
        return "左方向键"
    }

    static AutoRunRightLabel() {
        return "右方向键"
    }

    static AutoRunHelp() {
        return "设置自动跑图时使用的左右方向键。默认可直接使用 Left / Right。"
    }

    static AutoRunHelpTitle() {
        return "设置说明"
    }

    static ComboTitle() {
        return "一键连招设置"
    }

    static ComboProfilesLabel() {
        return "连招方案"
    }

    static ComboSequenceLabel() {
        return "连招技能（双击可修改）"
    }

    static ComboAddProfile() {
        return "新建方案"
    }

    static ComboRemoveProfile() {
        return "删除方案"
    }

    static ComboAddSkill() {
        return "添加技能"
    }

    static ComboDeleteSkill() {
        return "删除技能"
    }

    static ComboTriggerLabel() {
        return "触发键"
    }

    static ComboLoopMode() {
        return "循环触发"
    }

    static ComboApplyProfile() {
        return "应用方案"
    }

    static ComboHelp() {
        return "1. 添加技能后可双击修改按键和延迟。`n2. 每套方案都可以设置独立触发键。`n3. 触发键不能重复。`n4. 保存后写入当前预设。"
    }

    static ComboHelpTitle() {
        return "设置说明"
    }

    static ComboProfileMax(maxCount) {
        return "最多支持 " maxCount " 套连招方案。"
    }

    static ComboKeepOneProfile() {
        return "至少保留一套方案。"
    }

    static ComboDuplicateTrigger(triggerKey) {
        return "多套方案的触发键不能相同：" triggerKey
    }

    static ComboProfileUnsetTrigger() {
        return "(未设置)"
    }

    static ComboProfileSummary(triggerKey, skillCount) {
        return triggerKey " : " skillCount " 个技能"
    }

    static ComboEditTitle() {
        return "编辑连招技能"
    }

    static ComboEditChangeKey() {
        return "修改按键"
    }

    static ComboCurrentKeyLabel() {
        return "当前技能键"
    }

    static ComboDelayLabel() {
        return "技能延迟(ms)"
    }

    static ComboInvalidSkillKey() {
        return "仅支持主连发键盘上的按键。"
    }

    static PresetSkillIconTitle(presetName) {
        return "自动识别配置 - " presetName
    }

    static PresetSkillIconHint() {
        return "框选后按 Enter 确认，Esc 取消。不要截取到技能图标外。"
    }

    static PresetSkillIconCapture() {
        return "截取图像"
    }

    static PresetSkillIconDelete() {
        return "清除图像"
    }
}
