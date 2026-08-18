pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: theme

    // Matugen Material 3 Color Palette (Exact 1:1 Fields from API)
    property color background: "#101417"
    property color error: "#ffb4ab"
    property color error_container: "#93000a"
    property color inverse_on_surface: "#2d3135"
    property color inverse_primary: "#2a638a"
    property color inverse_surface: "#e0e3e8"
    property color on_background: "#e0e3e8"
    property color on_error: "#690005"
    property color on_error_container: "#ffdad6"
    property color on_primary: "#003450"
    property color on_primary_container: "#cbe6ff"
    property color on_primary_fixed: "#001e30"
    property color on_primary_fixed_variant: "#024b71"
    property color on_secondary: "#22323f"
    property color on_secondary_container: "#d4e4f6"
    property color on_secondary_fixed: "#0d1d29"
    property color on_secondary_fixed_variant: "#394856"
    property color on_surface: "#e0e3e8"
    property color on_surface_variant: "#c1c7ce"
    property color on_tertiary: "#372b4a"
    property color on_tertiary_container: "#ecdcff"
    property color on_tertiary_fixed: "#211634"
    property color on_tertiary_fixed_variant: "#4d4162"
    property color outline: "#8c9198"
    property color outline_variant: "#42474d"
    property color primary: "#97ccf9"
    property color primary_container: "#024b71"
    property color primary_fixed: "#cbe6ff"
    property color primary_fixed_dim: "#97ccf9"
    property color scrim: "#000000"
    property color secondary: "#b8c8d9"
    property color secondary_container: "#394856"
    property color secondary_fixed: "#d4e4f6"
    property color secondary_fixed_dim: "#b8c8d9"
    property color shadow: "#000000"
    property color source_color: "#869fb6"
    property color surface: "#101417"
    property color surface_bright: "#363a3e"
    property color surface_container: "#1c2024"
    property color surface_container_high: "#262a2e"
    property color surface_container_highest: "#313539"
    property color surface_container_low: "#181c20"
    property color surface_container_lowest: "#0b0f12"
    property color surface_dim: "#101417"
    property color surface_tint: "#97ccf9"
    property color surface_variant: "#42474d"
    property color tertiary: "#d0bfe7"
    property color tertiary_container: "#4d4162"
    property color tertiary_fixed: "#ecdcff"
    property color tertiary_fixed_dim: "#d0bfe7"

    // Geometry & Angles
    readonly property real skewAngle: -15
    readonly property real bannerHeight: 52
    readonly property real bannerWidth: 360
    
    // Fonts (Set to JetBrains Mono in all places)
    readonly property string fontFamilyDisplay: "JetBrains Mono"
    readonly property string fontFamilyMono: "JetBrains Mono"
    readonly property string fontFamilySans: "JetBrains Mono"

    property Timer colorTimer: Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: ConfigService.fetchMatugenColors(theme.updateColors)
    }

    function updateColors(c) {
        if (!c) return;
        for (var key in c) {
            if (theme.hasOwnProperty(key)) {
                theme[key] = c[key];
            }
        }
    }
}
