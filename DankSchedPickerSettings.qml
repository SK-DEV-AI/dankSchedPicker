import QtQuick
import qs.Common
import qs.Modules.Plugins

PluginSettings {
    id: settings

    sectionTitle: "Scheduler Picker"
    sectionSubtitle: "sched-ext CPU scheduler switcher"

    SectionLabel { text: "Controls" }
    SettingsDescription {
        text: "Left-click bar widget to cycle modes (Auto → Gaming → PowerSave → LowLatency). "
            + "Click when 'none' to start default scheduler (scx_bpfland Auto)."
    }
}
