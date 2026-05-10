#Requires AutoHotkey v2.0

class MainWindowText {
    static Title() {
        return "DAF连发工具 - DNF AutoFire"
    }

    static TitleWithVersion(version) {
        return "DAF连发工具 - DNF AutoFire"
    }

    static KeyHelp() {
        return "按键设置 - [ 黑色=关闭 红色=启用 蓝色=独立间隔（右键可设置独立间隔） ]"
    }

    static VersionText(version) {
        return "版本信息：v" version "`n原作者：某亚瑟"
    }

    static VersionLine1(version) {
        return "版本信息：v" version
    }

    static VersionLine2() {
        return "原作者：某亚瑟"
    }

    static ClearButton() {
        return "清空"
    }

    static ConfigHelp() {
        return "配置设置 - [ 单击切换配置，右键配置列表管理 ]"
    }

    static PresetNameLabel() {
        return "当前配置名称："
    }

    static IntervalLabel() {
        return "连发间隔(ms)"
    }

    static PresetSkillButton() {
        return "自动识别配置"
    }

    static SettingButton() {
        return "软件设置"
    }

    static CheckUpdateButton() {
        return "检查更新"
    }

    static StartButton() {
        return "启动连发"
    }

    static ExFeatureTitle() {
        return "其他功能"
    }

    static OpenLinkFailed(postUrl) {
        return "无法打开链接，请手动访问：`n" postUrl
    }

    static PresetInvalid() {
        return "请选择有效的预设。"
    }

    static PresetNameExists() {
        return "预设名称已存在。"
    }

    static PresetKeepOne() {
        return "至少保留一个预设。"
    }

    static PresetDeleteConfirm(presetName) {
        return "确定删除预设：" presetName "？"
    }

    static PresetDeleteTitle() {
        return "删除预设"
    }

    static KeyIntervalPrompt() {
        return "设置独立连发间隔(ms)，范围 1-200。`n留空表示默认间隔。"
    }

    static KeyIntervalTitle() {
        return "按键连发间隔"
    }

    static KeyIntervalNotSet() {
        return "该按键未设置独立间隔。"
    }

    static CreatePresetPrompt() {
        return "请输入新预设名称"
    }

    static CreatePresetTitle() {
        return "新建预设"
    }

    static RenamePresetPrompt() {
        return "请输入新的预设名称"
    }

    static RenamePresetTitle() {
        return "重命名预设"
    }

    static ClonePresetPrompt() {
        return "请输入克隆后的预设名称"
    }

    static ClonePresetTitle() {
        return "克隆预设"
    }

    static PresetNameEmpty() {
        return "预设名称不能为空。"
    }

    static PresetNameInvalidChar() {
        return "预设名称不能包含 | 字符。"
    }

    static MenuNewPreset() {
        return "新建预设"
    }

    static MenuRenamePreset() {
        return "重命名预设"
    }

    static MenuClonePreset() {
        return "克隆预设"
    }

    static MenuDeletePreset() {
        return "删除预设"
    }

    static MenuEditKeyInterval() {
        return "设置该键连发间隔..."
    }

    static MenuClearKeyInterval() {
        return "恢复为默认间隔"
    }

    static FeatureLabelLvRen() {
        return "旅人自动流星"
    }

    static FeatureLabelGuanYu() {
        return "关羽自动猛攻"
    }

    static FeatureLabelJianZong() {
        return "帝国剑术延迟"
    }

    static FeatureLabelZhanFa() {
        return "战法自动炫纹"
    }

    static FeatureLabelPetSkill() {
        return "自动宠物技能"
    }

    static FeatureLabelAutoRun() {
        return "自动奔跑"
    }

    static FeatureLabelCombo() {
        return "一键连招"
    }
    
}
