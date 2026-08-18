import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../theme"
import "../components"

ColumnLayout {
    id: root

    property int focusIndex: -1
    property int actionIndex: 0

    property string selectedShaderId: (ConfigService.activeShaders && ConfigService.activeShaders.length > 0) 
        ? ConfigService.activeShaders[0] 
        : "bluelight"

    readonly property var currentShaderInfo: {
        var list = ConfigService.shadersList || [];
        for (var i = 0; i < list.length; i++) {
            if (list[i].id === root.selectedShaderId) {
                return list[i];
            }
        }
        if (list.length > 0) return list[0];
        return null;
    }

    readonly property string activeShadersSummary: {
        var active = ConfigService.activeShaders || [];
        if (active.length === 0) return "Daylight Standard RGB";
        var list = ConfigService.shadersList || [];
        var names = [];
        for (var i = 0; i < list.length; i++) {
            if (active.indexOf(list[i].id) !== -1) {
                names.push(list[i].name);
            }
        }
        return names.join(" + ");
    }

    readonly property var shaderOptions: [
        { id: "bluelight", label: "Blue Light" },
        { id: "monochrome", label: "Monochrome" },
        { id: "invert", label: "Invert" },
        { id: "vibrance", label: "Vibrance" },
        { id: "sepia", label: "Sepia" },
        { id: "gamma", label: "Gamma" },
        { id: "solarized", label: "Solarized" },
        { id: "high_contrast", label: "High Contrast" }
    ]

    function getSelectedShaderIndex() {
        for (var i = 0; i < shaderOptions.length; i++) {
            if (shaderOptions[i].id === root.selectedShaderId) return i;
        }
        return 0;
    }

    function getItemCount() {
        var pCount = (currentShaderInfo && currentShaderInfo.parameters) ? currentShaderInfo.parameters.length : 0;
        return 6 + pCount;
    }

    function handleHorizontal(delta) {
        var pCount = (currentShaderInfo && currentShaderInfo.parameters) ? currentShaderInfo.parameters.length : 0;

        if (focusIndex === 0) {
            // 0: Screen Backlight
            var newB = Math.max(1, Math.min(100, BrightnessService.brightnessPercent + delta * 5));
            BrightnessService.setBrightness(newB);
        } else if (focusIndex === 1) {
            // 1: Shader Preset Selector
            var currentIdx = getSelectedShaderIndex();
            var nextIdx = (currentIdx + delta + shaderOptions.length) % shaderOptions.length;
            root.selectedShaderId = shaderOptions[nextIdx].id;
        } else if (focusIndex === 2) {
            // 2: Selected Shader Pipeline Toggle
            ConfigService.toggleShader(root.selectedShaderId);
        } else if (focusIndex >= 3 && focusIndex < 3 + pCount) {
            // 3..(2+pCount): Parameter Sliders & Selectors
            var paramIdx = focusIndex - 3;
            var param = currentShaderInfo.parameters[paramIdx];
            if (param) {
                if (param.type === "select") {
                    var opts = param.options || [];
                    if (opts.length > 0) {
                        var oIdx = Math.max(0, opts.indexOf(param.value));
                        var nOIdx = (oIdx + delta + opts.length) % opts.length;
                        var uObj = {};
                        uObj[param.name] = opts[nOIdx];
                        ConfigService.updateShaderConfig(root.selectedShaderId, uObj);
                    }
                } else {
                    var step = (param.step !== null && param.step !== undefined) ? Number(param.step) : (param.type === "int" ? 1 : 0.05);
                    var minV = (param.min_val !== null && param.min_val !== undefined) ? Number(param.min_val) : 0;
                    var maxV = (param.max_val !== null && param.max_val !== undefined) ? Number(param.max_val) : (param.type === "int" ? 100 : 1.0);
                    var curVal = Number(param.value);
                    var newVal = Math.max(minV, Math.min(maxV, curVal + delta * step));
                    var updateVal = (param.type === "int" ? Math.round(newVal) : parseFloat(newVal.toFixed(2)));
                    var uObj = {};
                    uObj[param.name] = updateVal;
                    ConfigService.updateShaderConfig(root.selectedShaderId, uObj);
                }
            }
        } else if (focusIndex === 4 + pCount) {
            // Theme Palette Selector
            schemeSelector.cycle(delta);
        } else if (focusIndex === 5 + pCount) {
            // Appearance Mode Selector
            modeSelector.cycle(delta);
        }
    }

    function triggerItem() {
        var pCount = (currentShaderInfo && currentShaderInfo.parameters) ? currentShaderInfo.parameters.length : 0;

        if (focusIndex === 1) {
            ConfigService.toggleShader(root.selectedShaderId);
        } else if (focusIndex === 2) {
            ConfigService.toggleShader(root.selectedShaderId);
        } else if (focusIndex >= 3 && focusIndex < 3 + pCount) {
            var paramIdx = focusIndex - 3;
            var param = currentShaderInfo.parameters[paramIdx];
            if (param && param.type === "select") {
                var opts = param.options || [];
                if (opts.length > 0) {
                    var oIdx = Math.max(0, opts.indexOf(param.value));
                    var nOIdx = (oIdx + 1) % opts.length;
                    var uObj = {};
                    uObj[param.name] = opts[nOIdx];
                    ConfigService.updateShaderConfig(root.selectedShaderId, uObj);
                }
            }
        } else if (focusIndex === 3 + pCount) {
            ConfigService.resetShaderConfig(root.selectedShaderId);
        } else if (focusIndex === 4 + pCount) {
            schemeSelector.cycle(1);
        } else if (focusIndex === 5 + pCount) {
            modeSelector.cycle(1);
        }
    }

    Component.onCompleted: {
        ConfigService.fetchShadersStatus(function() {
            if (ConfigService.activeShaders && ConfigService.activeShaders.length > 0) {
                root.selectedShaderId = ConfigService.activeShaders[0];
            }
        });
    }

    Layout.fillWidth: true
    spacing: 12

    // ==========================================
    // 1. DISPLAY & SHADERS HERO CARD
    // ==========================================
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 88
        radius: 14
        color: Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 0.55)
        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.15)
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 14

            Rectangle {
                width: 48
                height: 48
                radius: 12
                color: ConfigService.shadersEnabled 
                    ? Qt.rgba(255/255, 179/255, 100/255, 0.18) 
                    : Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.14)
                Layout.alignment: Qt.AlignVCenter

                VectorIcon {
                    anchors.centerIn: parent
                    name: ConfigService.shadersEnabled 
                        ? ((root.currentShaderInfo && ConfigService.isShaderActive(root.selectedShaderId)) ? (root.currentShaderInfo.icon || "moon") : "sparkle") 
                        : "sun"
                    iconSize: 22
                    color: ConfigService.shadersEnabled ? "#FFB366" : Theme.primary
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 2

                RowLayout {
                    spacing: 8
                    Layout.fillWidth: true

                    Text {
                        text: "Display & Multi-Shaders"
                        color: Theme.on_surface
                        font.pixelSize: 16
                        font.bold: true
                        font.family: Theme.fontFamilyDisplay
                    }

                    PillBadge {
                        text: {
                            var count = ConfigService.activeShaders ? ConfigService.activeShaders.length : 0;
                            if (count === 0) return "Pipeline Inactive";
                            if (count === 1) return "1 Shader Active";
                            return count + " Shaders Active (Composite)";
                        }
                        isInteractive: false
                        defaultColor: ConfigService.shadersEnabled 
                            ? Qt.rgba(255/255, 179/255, 100/255, 0.18) 
                            : Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
                        defaultTextColor: ConfigService.shadersEnabled ? "#FFB366" : Theme.primary
                    }
                }

                Text {
                    text: "Brightness: " + BrightnessService.brightnessPercent + "%  •  Pipeline: " + root.activeShadersSummary
                    color: Theme.on_surface_variant
                    font.pixelSize: 11
                    font.family: Theme.fontFamilyDisplay
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            SquareButton {
                text: ConfigService.shadersEnabled ? "Turn Off All" : "Enable Filter"
                iconName: ConfigService.shadersEnabled ? "moon" : "sparkle"
                size: 32
                customRadius: 16
                isActive: ConfigService.shadersEnabled
                activeColor: Qt.rgba(255/255, 179/255, 100/255, 0.20)
                customIconColor: ConfigService.shadersEnabled ? "#FFB366" : Theme.primary
                Layout.alignment: Qt.AlignVCenter
                onClicked: {
                    if (ConfigService.shadersEnabled) {
                        ConfigService.turnOffShader();
                    } else {
                        ConfigService.enableShader(root.selectedShaderId || "bluelight");
                    }
                }
            }
        }
    }

    // ==========================================
    // 2. DISPLAY BRIGHTNESS
    // ==========================================
    SettingCardGroup {
        titleText: "Display Brightness"

        SettingSliderRow {
            id: brightnessSlider
            labelText: "Screen Backlight"
            descriptionText: "Adjust hardware display backlight intensity"
            iconName: "sun"
            value: BrightnessService.brightnessPercent
            fromValue: 1
            toValue: 100
            unitText: "%"
            isFocused: root.focusIndex === 0
            onValueModified: newValue => BrightnessService.setBrightness(newValue)
        }
    }

    // ==========================================
    // 3. SCREEN SHADERS & COLOR FILTERS
    // ==========================================
    SettingCardGroup {
        titleText: "Screen Shaders Pipeline"

        // Preset Selector Row (Standard SettingPillSelector)
        SettingPillSelector {
            id: shaderSelector
            labelText: "Active Preset"
            descriptionText: "Select a shader preset to configure parameters and toggle in pipeline"
            iconName: root.currentShaderInfo ? (root.currentShaderInfo.icon || "palette") : "palette"
            options: root.shaderOptions
            selectedIndex: root.getSelectedShaderIndex()
            isFocused: root.focusIndex === 1
            onOptionSelected: (idx, opt) => {
                root.selectedShaderId = opt.id;
            }
        }

        // Active State Toggle for Selected Shader in Pipeline
        SettingToggleRow {
            id: activeShaderToggle
            labelText: "Enable " + (root.currentShaderInfo ? root.currentShaderInfo.name : "Shader") + " in Pipeline"
            descriptionText: root.currentShaderInfo 
                ? (ConfigService.isShaderActive(root.selectedShaderId) ? "Active in screen composite shader pipeline" : root.currentShaderInfo.description) 
                : "Toggle shader in composite pipeline"
            checked: ConfigService.isShaderActive(root.selectedShaderId)
            isFocused: root.focusIndex === 2
            onToggled: newValue => {
                ConfigService.toggleShader(root.selectedShaderId);
            }
        }

        // Dynamic Parameter Sliders & Selectors for Selected Shader (using SettingSliderRow & SettingPillSelector)
        Repeater {
            model: (root.currentShaderInfo && root.currentShaderInfo.parameters) ? root.currentShaderInfo.parameters : []
            delegate: Item {
                id: paramDelegate
                required property var modelData
                required property int index

                Layout.fillWidth: true
                implicitHeight: paramSliderLoader.implicitHeight

                Loader {
                    id: paramSliderLoader
                    anchors.fill: parent
                    sourceComponent: paramDelegate.modelData.type === "select" ? selectComponent : sliderComponent
                }

                Component {
                    id: sliderComponent
                    SettingSliderRow {
                        labelText: paramDelegate.modelData.label || paramDelegate.modelData.name
                        descriptionText: paramDelegate.modelData.name === "temperature" 
                            ? "Warm light (1000K) to Daylight (6500K)" 
                            : (paramDelegate.modelData.name === "strength" ? "Filter blending opacity" : "")
                        value: Number(paramDelegate.modelData.value)
                        fromValue: paramDelegate.modelData.min_val !== null && paramDelegate.modelData.min_val !== undefined ? Number(paramDelegate.modelData.min_val) : 0
                        toValue: paramDelegate.modelData.max_val !== null && paramDelegate.modelData.max_val !== undefined ? Number(paramDelegate.modelData.max_val) : (paramDelegate.modelData.type === "int" ? 100 : 1.0)
                        stepSize: paramDelegate.modelData.step !== null && paramDelegate.modelData.step !== undefined ? Number(paramDelegate.modelData.step) : (paramDelegate.modelData.type === "int" ? 1 : 0.05)
                        unitText: paramDelegate.modelData.unit || ""
                        isFocused: root.focusIndex === (3 + paramDelegate.index)
                        onValueModified: val => {
                            var updateObj = {};
                            updateObj[paramDelegate.modelData.name] = (paramDelegate.modelData.type === "int" ? Math.round(val) : parseFloat(val.toFixed(2)));
                            ConfigService.updateShaderConfig(root.selectedShaderId, updateObj, null, true);
                        }
                        onValueCommitted: finalVal => {
                            var updateObj = {};
                            updateObj[paramDelegate.modelData.name] = (paramDelegate.modelData.type === "int" ? Math.round(finalVal) : parseFloat(finalVal.toFixed(2)));
                            ConfigService.updateShaderConfig(root.selectedShaderId, updateObj);
                        }
                    }
                }

                Component {
                    id: selectComponent
                    SettingPillSelector {
                        labelText: paramDelegate.modelData.label || paramDelegate.modelData.name
                        options: paramDelegate.modelData.options || []
                        selectedIndex: (paramDelegate.modelData.options && paramDelegate.modelData.options.indexOf(paramDelegate.modelData.value) !== -1)
                            ? paramDelegate.modelData.options.indexOf(paramDelegate.modelData.value)
                            : 0
                        isFocused: root.focusIndex === (3 + paramDelegate.index)
                        onOptionSelected: (idx, opt) => {
                            var updateObj = {};
                            updateObj[paramDelegate.modelData.name] = opt;
                            ConfigService.updateShaderConfig(root.selectedShaderId, updateObj);
                        }
                    }
                }
            }
        }

        // Preset Actions Row: Reset Defaults / Toggle In Pipeline
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            readonly property int pCount: (root.currentShaderInfo && root.currentShaderInfo.parameters) ? root.currentShaderInfo.parameters.length : 0

            SquareButton {
                text: "Reset " + (root.currentShaderInfo ? root.currentShaderInfo.name : "Shader") + " to Defaults"
                iconName: "undo"
                size: 32
                customRadius: 16
                isActive: root.focusIndex === (3 + parent.pCount)
                onClicked: {
                    ConfigService.resetShaderConfig(root.selectedShaderId);
                }
            }

            Item { Layout.fillWidth: true }

            SquareButton {
                text: ConfigService.isShaderActive(root.selectedShaderId) ? "Remove from Pipeline" : "Add to Pipeline"
                iconName: ConfigService.isShaderActive(root.selectedShaderId) ? "cross" : "check"
                size: 32
                customRadius: 16
                isActive: ConfigService.isShaderActive(root.selectedShaderId)
                activeColor: Qt.rgba(255/255, 179/255, 100/255, 0.20)
                customIconColor: ConfigService.isShaderActive(root.selectedShaderId) ? "#FFB366" : Theme.primary
                onClicked: {
                    ConfigService.toggleShader(root.selectedShaderId);
                }
            }
        }
    }

    // ==========================================
    // 4. MATERIAL 3 THEME & COLOR SCHEME
    // ==========================================
    SettingCardGroup {
        titleText: "Theme & Palette"

        readonly property int pCount: (root.currentShaderInfo && root.currentShaderInfo.parameters) ? root.currentShaderInfo.parameters.length : 0

        SettingPillSelector {
            id: schemeSelector
            labelText: "Color Palette"
            options: ["Tonal Spot", "Vibrant", "Expressive", "Fruit Salad", "Rainbow"]
            readonly property var schemeKeys: ["scheme-tonal-spot", "scheme-vibrant", "scheme-expressive", "scheme-fruit-salad", "scheme-rainbow"]
            selectedIndex: Math.max(0, schemeKeys.indexOf(ConfigService.matugenScheme))
            isFocused: root.focusIndex === (4 + parent.pCount)
            onOptionSelected: (idx, opt) => {
                var s = schemeKeys[idx] || "scheme-tonal-spot";
                ConfigService.setColorScheme(s, ConfigService.isDarkMode);
            }
        }

        SettingPillSelector {
            id: modeSelector
            labelText: "Appearance Mode"
            options: ["Dark Mode", "Light Mode"]
            selectedIndex: ConfigService.isDarkMode ? 0 : 1
            isFocused: root.focusIndex === (5 + parent.pCount)
            onOptionSelected: (idx, opt) => {
                var isDark = (idx === 0);
                ConfigService.setColorScheme(ConfigService.matugenScheme, isDark);
            }
        }
    }
}
