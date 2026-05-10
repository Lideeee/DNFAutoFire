#Requires AutoHotkey v2.0

class MainExFeatureLayoutData {
    static GetFeatureNames() {
        names := []
        for column in this.GetColumns(0, 0) {
            for row in column.rows {
                names.Push(row.name)
            }
        }
        return names
    }

    static GetColumns(leftX, rightX) {
        return [
            {
                x: leftX,
                linkWidth: 104,
                rows: [
                    { name: "LvRen", label: MainWindowText.FeatureLabelLvRen(), handler: MainLvRen },
                    { name: "GuanYu", label: MainWindowText.FeatureLabelGuanYu(), handler: MainGuanYu },
                    { name: "JianZong", label: MainWindowText.FeatureLabelJianZong(), handler: MainJianZong },
                    { name: "ZhanFa", label: MainWindowText.FeatureLabelZhanFa(), handler: MainZhanFa },
                ]
            },
            {
                x: rightX,
                linkWidth: 84,
                rows: [
                    { name: "PetSkill", label: MainWindowText.FeatureLabelPetSkill(), handler: MainPetSkill },
                    { name: "AutoRun", label: MainWindowText.FeatureLabelAutoRun(), handler: MainAutoRun },
                    { name: "Combo", label: MainWindowText.FeatureLabelCombo(), handler: MainCombo },
                ]
            }
        ]
    }
}
