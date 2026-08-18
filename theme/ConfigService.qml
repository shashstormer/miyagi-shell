pragma Singleton
import QtQuick
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

QtObject {
    id: configService

    // Initialization & Settings Loaded State
    property bool isLoaded: false

    property Timer loadFallbackTimer: Timer
    {
        interval: 600
        running: true
        repeat: false
        onTriggered: configService.isLoaded = true
    }

    // Centralized Desktop Window, Workspace & Fullscreen State (100% Python Service API)
    property int activeWorkspaceId: 1
    property string activeWindowTitle: ""
    property bool isHyprlandFullscreen: false
    property var windowsList: []

    readonly property bool hasActiveWindow: {
        var list = configService.windowsList;
        var activeId = configService.activeWorkspaceId;
        if (activeId < 1 || !list || list.length === 0) return false;
        for (var i = 0; i < list.length; i++) {
            var w = list[i];
            if (w && w.workspace_id === activeId && !w.is_minimized) {
                return true;
            }
        }
        return false;
    }

    property int islandWidthCollapsed: 270
    property int islandWidthExpanded: 340
    property int islandHeightCollapsed: 40
    property int islandHeightExpanded: 76
    property int islandRadiusCollapsed: 20
    property int islandRadiusExpanded: 24

    property string barPosition: "bottom"
    property string themeAccentColor: "#8AB4F8"

    property bool showClock: true
    property bool showMediaPlayer: true
    property bool showSystemTray: true
    property bool showWorkspaces: true
    property bool showBattery: true

    property int cavaBarsCount: 14
    property int cavaFramerate: 60

    property bool enableTopBar: true
    property bool enableLeftBar: true
    property bool enableDynamicIsland: true
    property bool showSystemBatteryWidget: true
    property bool islandStaticSize: false
    property bool islandPassThrough: false
    property bool autoHideFullscreen: true

    property bool topBarAutoHide: false
    property bool topBarFullscreenAutoHide: true
    property bool topBarDesktopAutoHide: false
    property bool topBarShowWorkspaces: true
    property bool topBarShowClock: true
    property bool topBarShowSystemTray: true
    property bool topBarShowMediaPlayer: true

    property bool leftBarAutoHide: false
    property bool leftBarFullscreenAutoHide: true
    property bool leftBarDesktopAutoHide: false
    property bool leftBarShowMenu: true
    property bool leftBarShowControls: true
    property string leftBarMenuPosition: "top"

    property bool islandFullscreenAutoHide: true
    property bool enableOverAmplify: false
    onEnableOverAmplifyChanged: {
        if (configService.isLoaded) {
            configService.saveConfig();
        }
    }

    property string serviceUrl: "http://localhost:8765/system/get_miyagi_config"

    property Timer winTimer: Timer
    {
        interval: 100
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: configService.fetchWindows()
    }

    property var batteryStatus: null

    property Timer batteryTimer: Timer
    {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: configService.fetchBatteryStatus()
    }

    // Dynamic System Status Properties (Centralized Reactive State)
    property bool bluetoothPowered: false
    property bool bluetoothDiscovering: false
    property bool bluetoothConnected: false
    property int bluetoothConnectedCount: 0
    property string bluetoothDeviceName: ""
    property int bluetoothBattery: -1

    property bool wifiEnabled: true
    property bool wifiScanning: false
    property bool wifiConnected: false
    property string wifiSsid: ""
    property int wifiSignal: 0
    property bool wifiRequiresPortal: false

    property int audioVolume: 100
    property bool audioMuted: false
    property string audioSinkName: ""
    property bool audioIsHeadphones: false
    property var audioStatus: null
    property var audioSinks: []
    property var audioStreams: []

    property int micVolume: 100
    property bool micMuted: false
    property string micSourceName: ""

    // Application Launcher State
    property var applicationsList: []
    property var recentApplicationsList: []
    property var applicationCategories: []
    property bool isAppLauncherLoading: false

    property Timer systemStatusTimer: Timer
    {
        interval: 2500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: configService.fetchAllSystemStatus()
    }

    function fetchAllSystemStatus() {
        fetchBluetoothStatus();
        fetchWifiStatus();
        fetchAudioStatus();
        fetchMicStatus();
    }

    function fetchBatteryStatus(callback) {
        _sendRequest("POST", "http://localhost:8765/system/get_battery_status", {}, function (res, ok) {
            if (ok && res) {
                configService.batteryStatus = res;
            }
            if (callback) callback(res, ok);
        });
    }

    function _sendRequest(method, url, payload, callback) {
        var xhr = new XMLHttpRequest();
        xhr.open(method, url, true);
        if (method === "POST") {
            xhr.setRequestHeader("Content-Type", "application/json");
        }
        let do_log = ![
            "http://localhost:8765/system/get_bluetooth_status",
            "http://localhost:8765/system/get_wifi_status",
            "http://localhost:8765/system/get_audio_status",
            "http://localhost:8765/system/get_mic_status",
            "http://localhost:8765/desktop/get_windows",
            "http://localhost:8765/system/get_battery_status",
            "http://localhost:8765/system/get_idle_status",
            "http://localhost:8765/system/get_applications",
            "http://localhost:8765/system/get_miyagi_config",
            "http://localhost:8765/system/get_notification_preferences",
            "http://localhost:8765/system/get_notification_stats",
            "http://localhost:5000/awww/matugen/colors?mode=dark&type=scheme-tonal-spot",
            "http://localhost:8765/system/get_shaders_status",
        ].includes(url)
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200 && xhr.responseText) {
                    try {
                        var parsed = JSON.parse(xhr.responseText);
                        if (do_log) {
                            console.log(url);
                            console.log(xhr.responseText);
                        }
                        if (callback) callback(parsed, true);
                    } catch (e) {
                        if (callback) callback(null, false);
                    }
                } else {
                    if (callback) callback(null, false);
                }
            }
        };
        try {
            let da_payload = payload ? (typeof payload === "string" ? payload : JSON.stringify(payload)) : null
            if (do_log) {
                console.log("Payload:", da_payload);
            }
            xhr.send(da_payload);
        } catch (e) {
            if (callback) callback(null, false);
        }
    }

    function fetchWindows() {
        _sendRequest("POST", "http://localhost:8765/desktop/get_windows", {}, function (res, ok) {
            if (ok && res) {
                if (res.windows !== undefined) configService.windowsList = res.windows;
                if (res.active_workspace_id !== undefined) configService.activeWorkspaceId = res.active_workspace_id;
                if (res.active_window_title !== undefined) configService.activeWindowTitle = res.active_window_title;
                if (res.is_fullscreen !== undefined) configService.isHyprlandFullscreen = res.is_fullscreen;
                if (res.workspace_layouts !== undefined) configService.workspaceLayouts = Object.assign({}, configService.workspaceLayouts, res.workspace_layouts);
            }
        });
    }

    function fetchConfig() {
        _sendRequest("POST", serviceUrl, {}, function (data, ok) {
            if (ok && data) {
                if (data.island_width_collapsed !== undefined) configService.islandWidthCollapsed = data.island_width_collapsed;
                if (data.island_width_expanded !== undefined) configService.islandWidthExpanded = data.island_width_expanded;
                if (data.island_height_collapsed !== undefined) configService.islandHeightCollapsed = data.island_height_collapsed;
                if (data.island_height_expanded !== undefined) configService.islandHeightExpanded = data.island_height_expanded;
                if (data.island_radius_collapsed !== undefined) configService.islandRadiusCollapsed = data.island_radius_collapsed;
                if (data.island_radius_expanded !== undefined) configService.islandRadiusExpanded = data.island_radius_expanded;
                if (data.show_clock !== undefined) configService.showClock = data.show_clock;
                if (data.show_media_player !== undefined) configService.showMediaPlayer = data.show_media_player;
                if (data.show_system_tray !== undefined) configService.showSystemTray = data.show_system_tray;
                if (data.show_workspaces !== undefined) configService.showWorkspaces = data.show_workspaces;
                if (data.show_battery !== undefined) configService.showBattery = data.show_battery;
                if (data.theme_accent_color !== undefined) configService.themeAccentColor = data.theme_accent_color;
                if (data.enable_top_bar !== undefined) configService.enableTopBar = data.enable_top_bar;
                if (data.enable_left_bar !== undefined) configService.enableLeftBar = data.enable_left_bar;
                if (data.enable_dynamic_island !== undefined) configService.enableDynamicIsland = data.enable_dynamic_island;
                if (data.top_bar_auto_hide !== undefined) configService.topBarAutoHide = data.top_bar_auto_hide;
                if (data.top_bar_fullscreen_auto_hide !== undefined) configService.topBarFullscreenAutoHide = data.top_bar_fullscreen_auto_hide;
                if (data.top_bar_desktop_auto_hide !== undefined) configService.topBarDesktopAutoHide = data.top_bar_desktop_auto_hide;
                if (data.top_bar_show_workspaces !== undefined) configService.topBarShowWorkspaces = data.top_bar_show_workspaces;
                if (data.top_bar_show_clock !== undefined) configService.topBarShowClock = data.top_bar_show_clock;
                if (data.top_bar_show_system_tray !== undefined) configService.topBarShowSystemTray = data.top_bar_show_system_tray;
                if (data.top_bar_show_media_player !== undefined) configService.topBarShowMediaPlayer = data.top_bar_show_media_player;
                if (data.left_bar_auto_hide !== undefined) configService.leftBarAutoHide = data.left_bar_auto_hide;
                if (data.left_bar_fullscreen_auto_hide !== undefined) configService.leftBarFullscreenAutoHide = data.left_bar_fullscreen_auto_hide;
                if (data.left_bar_desktop_auto_hide !== undefined) configService.leftBarDesktopAutoHide = data.left_bar_desktop_auto_hide;
                if (data.left_bar_show_menu !== undefined) configService.leftBarShowMenu = data.left_bar_show_menu;
                if (data.left_bar_show_controls !== undefined) configService.leftBarShowControls = data.left_bar_show_controls;
                if (data.left_bar_menu_position !== undefined) configService.leftBarMenuPosition = data.left_bar_menu_position;
                if (data.island_fullscreen_auto_hide !== undefined) configService.islandFullscreenAutoHide = data.island_fullscreen_auto_hide;
                if (data.bar_position !== undefined) configService.barPosition = data.bar_position;
                if (data.island_static_size !== undefined) configService.islandStaticSize = data.island_static_size;
                if (data.island_pass_through !== undefined) configService.islandPassThrough = data.island_pass_through;
                if (data.auto_hide_fullscreen !== undefined) configService.autoHideFullscreen = data.auto_hide_fullscreen;
                if (data.show_system_battery_widget !== undefined) configService.showSystemBatteryWidget = data.show_system_battery_widget;
                if (data.workspace_layouts !== undefined) configService.workspaceLayouts = Object.assign({}, configService.workspaceLayouts, data.workspace_layouts);
                if (data.enable_over_amplify !== undefined) configService.enableOverAmplify = data.enable_over_amplify;
            }
            configService.isLoaded = true;
        });
    }

    function saveConfig() {
        var payload = {
            "island_width_collapsed": configService.islandWidthCollapsed,
            "island_width_expanded": configService.islandWidthExpanded,
            "island_height_collapsed": configService.islandHeightCollapsed,
            "island_height_expanded": configService.islandHeightExpanded,
            "island_radius_collapsed": configService.islandRadiusCollapsed,
            "island_radius_expanded": configService.islandRadiusExpanded,
            "bar_position": configService.barPosition,
            "theme_accent_color": configService.themeAccentColor,
            "show_clock": configService.showClock,
            "show_media_player": configService.showMediaPlayer,
            "show_system_tray": configService.showSystemTray,
            "show_workspaces": configService.showWorkspaces,
            "show_battery": configService.showBattery,
            "cava_bars_count": configService.cavaBarsCount,
            "cava_framerate": configService.cavaFramerate,
            "enable_top_bar": configService.enableTopBar,
            "enable_left_bar": configService.enableLeftBar,
            "enable_dynamic_island": configService.enableDynamicIsland,
            "show_system_battery_widget": configService.showSystemBatteryWidget,
            "island_static_size": configService.islandStaticSize,
            "island_pass_through": configService.islandPassThrough,
            "auto_hide_fullscreen": configService.autoHideFullscreen,
            "top_bar_auto_hide": configService.topBarAutoHide,
            "top_bar_fullscreen_auto_hide": configService.topBarFullscreenAutoHide,
            "top_bar_desktop_auto_hide": configService.topBarDesktopAutoHide,
            "top_bar_show_workspaces": configService.topBarShowWorkspaces,
            "top_bar_show_clock": configService.topBarShowClock,
            "top_bar_show_system_tray": configService.topBarShowSystemTray,
            "top_bar_show_media_player": configService.topBarShowMediaPlayer,
            "left_bar_auto_hide": configService.leftBarAutoHide,
            "left_bar_fullscreen_auto_hide": configService.leftBarFullscreenAutoHide,
            "left_bar_desktop_auto_hide": configService.leftBarDesktopAutoHide,
            "left_bar_show_menu": configService.leftBarShowMenu,
            "left_bar_show_controls": configService.leftBarShowControls,
            "left_bar_menu_position": configService.leftBarMenuPosition,
            "island_fullscreen_auto_hide": configService.islandFullscreenAutoHide,
            "enable_over_amplify": configService.enableOverAmplify,
            "workspace_layouts": configService.workspaceLayouts || {}
        };
        _sendRequest("POST", "http://localhost:8765/system/update_miyagi_config", payload, function (res, ok) {
            console.log("MiyagiConfiguration saved via CommIPC:", ok);
        });
    }

    function executeAction(actionName, callback) {
        _sendRequest("POST", "http://localhost:8765/system/execute_action", {"action": actionName}, function (res, ok) {
            if (callback) callback(ok);
        });
    }

    function fetchIdleStatus(callback) {
        _sendRequest("POST", "http://localhost:8765/system/get_idle_status", {}, function (res, ok) {
            if (callback && ok && res && res.is_inhibited !== undefined) {
                callback(res.is_inhibited);
            }
        });
    }

    property string activeColorScheme: "scheme-tonal-spot"
    property bool isDarkMode: true

    function fetchMatugenColors(callback) {
        var mode = configService.isDarkMode ? "dark" : "light";
        var scheme = configService.activeColorScheme || "scheme-tonal-spot";
        _sendRequest("GET", "http://localhost:5000/awww/matugen/colors?mode=" + mode + "&type=" + scheme, null, function (parsed, ok) {
            if (callback && ok && parsed) callback(parsed);
        });
    }

    function setColorScheme(scheme, isDark, callback) {
        var s = scheme || configService.activeColorScheme;
        var mode = (isDark !== undefined ? isDark : configService.isDarkMode) ? "dark" : "light";
        configService.activeColorScheme = s;
        configService.isDarkMode = (mode === "dark");
        var url = "http://localhost:5000/awww/matugen/colors?mode=" + mode + "&type=" + s;
        _sendRequest("GET", url, null, function (parsed, ok) {
            if (ok && parsed) {
                if (typeof Theme !== "undefined" && typeof Theme.updateColors === "function") {
                    Theme.updateColors(parsed);
                }
                if (callback) callback(parsed, true);
            } else {
                if (callback) callback(null, false);
            }
        });
    }

    property var workspaceLayouts: ({})

    function setWorkspaceLayout(wsId, layout, callback) {
        var copy = Object.assign({}, configService.workspaceLayouts);
        copy[wsId.toString()] = layout;
        configService.workspaceLayouts = copy;
        _sendRequest("POST", "http://localhost:8765/desktop/set_workspace_layout", {
            "workspace": wsId.toString(),
            "layout": layout
        }, function (res, ok) {
            if (callback) callback(ok);
        });
    }

    function toggleMinimize(address, callback) {
        _sendRequest("POST", "http://localhost:8765/desktop/toggle_minimize", {"address": address || ""}, function (res, ok) {
            configService.fetchWindows();
            if (callback) callback(ok);
        });
    }

    function altTab(forward, callback) {
        _sendRequest("POST", "http://localhost:8765/desktop/alt_tab", {"forward": forward !== false}, function (res, ok) {
            configService.fetchWindows();
            if (callback) callback(ok);
        });
    }

    function switchWorkspace(wsId) {
        configService.activeWorkspaceId = wsId;
        executeAction("workspace_" + wsId);
        fetchWindows();
    }

    function fetchBluetoothStatus(callback) {
        _sendRequest("POST", "http://localhost:8765/system/get_bluetooth_status", {}, function (res, ok) {
            if (ok && res) {
                configService.bluetoothPowered = !!res.powered;
                configService.bluetoothDiscovering = !!res.discovering;
                var connectedDevs = [];
                if (res.devices) {
                    for (var i = 0; i < res.devices.length; i++) {
                        if (res.devices[i].connected) {
                            connectedDevs.push(res.devices[i]);
                        }
                    }
                }
                configService.bluetoothConnectedCount = connectedDevs.length;
                configService.bluetoothConnected = connectedDevs.length > 0;
                if (connectedDevs.length > 0) {
                    configService.bluetoothDeviceName = connectedDevs[0].alias || connectedDevs[0].name || "";
                    configService.bluetoothBattery = (connectedDevs[0].battery_percentage !== undefined && connectedDevs[0].battery_percentage !== null) ? connectedDevs[0].battery_percentage : -1;
                } else {
                    configService.bluetoothDeviceName = "";
                    configService.bluetoothBattery = -1;
                }
            }
            if (callback) callback(res, ok);
        });
    }

    function toggleBluetooth(powered, callback) {
        configService.bluetoothPowered = powered;
        _sendRequest("POST", "http://localhost:8765/system/toggle_bluetooth", {"powered": powered}, function (res, ok) {
            fetchBluetoothStatus();
            if (callback) callback(ok);
        });
    }

    function startBluetoothScan(callback) {
        configService.bluetoothDiscovering = true;
        _sendRequest("POST", "http://localhost:8765/system/start_bluetooth_scan", {}, function (res, ok) {
            fetchBluetoothStatus();
            if (callback) callback(ok);
        });
    }

    function connectBluetoothDevice(address, callback) {
        _sendRequest("POST", "http://localhost:8765/system/connect_bluetooth_device", {"address": address}, function (res, ok) {
            fetchBluetoothStatus();
            if (callback) callback(ok);
        });
    }

    function disconnectBluetoothDevice(address, callback) {
        _sendRequest("POST", "http://localhost:8765/system/disconnect_bluetooth_device", {"address": address}, function (res, ok) {
            fetchBluetoothStatus();
            if (callback) callback(ok);
        });
    }

    function pairBluetoothDevice(address, callback) {
        _sendRequest("POST", "http://localhost:8765/system/pair_bluetooth_device", {"address": address}, function (res, ok) {
            fetchBluetoothStatus();
            if (callback) callback(ok);
        });
    }

    function unpairBluetoothDevice(address, callback) {
        _sendRequest("POST", "http://localhost:8765/system/unpair_bluetooth_device", {"address": address}, function (res, ok) {
            fetchBluetoothStatus();
            if (callback) callback(ok);
        });
    }

    function stopBluetoothScan(callback) {
        configService.bluetoothDiscovering = false;
        _sendRequest("POST", "http://localhost:8765/system/stop_bluetooth_scan", {}, function (res, ok) {
            fetchBluetoothStatus();
            if (callback) callback(ok);
        });
    }

    function respondBluetoothAuth(address, accept, pin, callback) {
        _sendRequest("POST", "http://localhost:8765/system/respond_bluetooth_auth", {
            "address": address,
            "accept": accept,
            "pin": pin || ""
        }, function (res, ok) {
            fetchBluetoothStatus();
            if (callback) callback(ok);
        });
    }

    function setBluetoothAudioProfile(address, profile, callback) {
        _sendRequest("POST", "http://localhost:8765/system/set_bluetooth_audio_profile", {
            "address": address,
            "profile": profile
        }, function (res, ok) {
            fetchBluetoothStatus();
            if (callback) callback(ok);
        });
    }

    function setBluetoothDeviceTrust(address, trusted, callback) {
        _sendRequest("POST", "http://localhost:8765/system/set_bluetooth_device_trust", {
            "address": address,
            "trusted": !!trusted
        }, function (res, ok) {
            if (callback) callback(ok);
        });
    }

    function fetchWifiStatus(callback) {
        _sendRequest("POST", "http://localhost:8765/system/get_wifi_status", {}, function (res, ok) {
            if (ok && res) {
                configService.wifiEnabled = !!res.enabled;
                configService.wifiScanning = !!res.scanning;
                if (res.connected_network && res.connected_network.ssid) {
                    configService.wifiConnected = true;
                    configService.wifiSsid = res.connected_network.ssid || "";
                    configService.wifiSignal = res.connected_network.signal !== undefined ? res.connected_network.signal : 100;
                    configService.wifiRequiresPortal = !!res.connected_network.requires_portal;
                } else {
                    configService.wifiConnected = false;
                    configService.wifiSsid = "";
                    configService.wifiSignal = 0;
                    configService.wifiRequiresPortal = false;
                }
            }
            if (callback) callback(res, ok);
        });
    }

    function toggleWifi(enabled, callback) {
        configService.wifiEnabled = enabled;
        _sendRequest("POST", "http://localhost:8765/system/toggle_wifi", {"enabled": enabled}, function (res, ok) {
            fetchWifiStatus();
            if (callback) callback(ok);
        });
    }

    function startWifiScan(callback) {
        configService.wifiScanning = true;
        _sendRequest("POST", "http://localhost:8765/system/start_wifi_scan", {}, function (res, ok) {
            fetchWifiStatus();
            if (callback) callback(ok);
        });
    }

    function connectWifiNetwork(ssid, password, bssid, callback) {
        _sendRequest("POST", "http://localhost:8765/system/connect_wifi_network", {
            "ssid": ssid,
            "password": password || "",
            "bssid": bssid || ""
        }, function (res, ok) {
            fetchWifiStatus();
            if (callback) callback(ok);
        });
    }

    function disconnectWifiNetwork(callback) {
        _sendRequest("POST", "http://localhost:8765/system/disconnect_wifi_network", {}, function (res, ok) {
            fetchWifiStatus();
            if (callback) callback(ok);
        });
    }

    function forgetWifiNetwork(ssid, callback) {
        _sendRequest("POST", "http://localhost:8765/system/forget_wifi_network", {"ssid": ssid}, function (res, ok) {
            fetchWifiStatus();
            if (callback) callback(ok);
        });
    }

    function openCaptivePortal(callback) {
        _sendRequest("POST", "http://localhost:8765/system/open_captive_portal", {}, function (res, ok) {
            if (callback) callback(ok);
        });
    }

    // Audio & Microphone CommIPC Bridge Methods
    function fetchAudioStatus(callback) {
        _sendRequest("POST", "http://localhost:8765/system/get_audio_status", {}, function (res, ok) {
            if (ok && res) {
                configService.audioVolume = res.volume !== undefined ? res.volume : 100;
                configService.audioMuted = !!res.muted;
                configService.audioSinkName = res.active_sink_name || "";
                configService.audioStatus = res;
                configService.audioSinks = res.sinks || [];
                configService.audioStreams = res.streams || [];
                var sName = (configService.audioSinkName || "").toLowerCase();
                configService.audioIsHeadphones = sName.indexOf("headphone") !== -1 ||
                    sName.indexOf("headset") !== -1 ||
                    sName.indexOf("earbud") !== -1 ||
                    sName.indexOf("airpod") !== -1 ||
                    sName.indexOf("bluez") !== -1;
            }
            if (callback) callback(res, ok);
        });
    }

    function setAudioVolume(volume, callback, skipRefresh) {
        configService.audioVolume = volume;
        _sendRequest("POST", "http://localhost:8765/system/set_audio_volume", {"volume": volume}, function (res, ok) {
            if (!skipRefresh) fetchAudioStatus();
            if (callback) callback(ok);
        });
    }

    function toggleAudioMute(muted, callback) {
        configService.audioMuted = muted;
        _sendRequest("POST", "http://localhost:8765/system/toggle_audio_mute", {"muted": !!muted}, function (res, ok) {
            fetchAudioStatus();
            if (callback) callback(ok);
        });
    }

    function setDefaultAudioSink(deviceId, callback) {
        _sendRequest("POST", "http://localhost:8765/system/set_default_sink", {"device_id": deviceId}, function (res, ok) {
            fetchAudioStatus();
            if (callback) callback(ok);
        });
    }

    function fetchMicStatus(callback) {
        _sendRequest("POST", "http://localhost:8765/system/get_mic_status", {}, function (res, ok) {
            if (ok && res) {
                configService.micVolume = res.volume !== undefined ? res.volume : 100;
                configService.micMuted = !!res.muted;
                configService.micSourceName = res.active_source_name || "";
            }
            if (callback) callback(res, ok);
        });
    }

    function setMicVolume(volume, callback, skipRefresh) {
        configService.micVolume = volume;
        _sendRequest("POST", "http://localhost:8765/system/set_mic_volume", {"volume": volume}, function (res, ok) {
            if (!skipRefresh) fetchMicStatus();
            if (callback) callback(ok);
        });
    }

    function toggleMicMute(muted, callback) {
        configService.micMuted = muted;
        _sendRequest("POST", "http://localhost:8765/system/toggle_mic_mute", {"muted": !!muted}, function (res, ok) {
            fetchMicStatus();
            if (callback) callback(ok);
        });
    }

    function setDefaultAudioSource(deviceId, callback) {
        _sendRequest("POST", "http://localhost:8765/system/set_default_source", {"device_id": deviceId}, function (res, ok) {
            fetchMicStatus();
            if (callback) callback(ok);
        });
    }

    function playTestSound(deviceId, callback) {
        _sendRequest("POST", "http://localhost:8765/system/play_test_sound", {"device_id": deviceId || ""}, function (res, ok) {
            if (callback) callback(ok);
        });
    }

    function setStreamVolume(streamId, volume, callback, skipRefresh) {
        _sendRequest("POST", "http://localhost:8765/system/set_stream_volume", {
            "stream_id": streamId,
            "volume": volume
        }, function (res, ok) {
            if (!skipRefresh) fetchAudioStatus();
            if (callback) callback(ok);
        });
    }

    function setSourceVolume(deviceId, volume, callback, skipRefresh) {
        _sendRequest("POST", "http://localhost:8765/system/set_source_volume", {
            "device_id": deviceId,
            "volume": volume
        }, function (res, ok) {
            if (!skipRefresh) fetchMicStatus();
            if (callback) callback(ok);
        });
    }

    function toggleSourceMute(deviceId, muted, callback) {
        _sendRequest("POST", "http://localhost:8765/system/toggle_source_mute", {
            "device_id": deviceId,
            "muted": !!muted
        }, function (res, ok) {
            fetchMicStatus();
            if (callback) callback(ok);
        });
    }

    function setSinkVolume(deviceId, volume, callback, skipRefresh) {
        _sendRequest("POST", "http://localhost:8765/system/set_sink_volume", {
            "device_id": deviceId,
            "volume": volume
        }, function (res, ok) {
            if (!skipRefresh) fetchAudioStatus();
            if (callback) callback(ok);
        });
    }

    function toggleSinkMute(deviceId, muted, callback) {
        _sendRequest("POST", "http://localhost:8765/system/toggle_sink_mute", {
            "device_id": deviceId,
            "muted": !!muted
        }, function (res, ok) {
            fetchAudioStatus();
            if (callback) callback(ok);
        });
    }

    function setDeviceVolume(type, deviceId, volume, callback) {
        if (type === "sink") {
            setSinkVolume(deviceId, volume, callback);
        } else if (type === "source") {
            setSourceVolume(deviceId, volume, callback);
        } else if (type === "stream") {
            setStreamVolume(deviceId, volume, callback);
        }
    }

    function getToplevelForWin(winData) {
        if (!winData || typeof ToplevelManager === "undefined" || !ToplevelManager.toplevels) return null;
        var list = ToplevelManager.toplevels.values || [];
        var targetAddr = String(winData.address || "").toLowerCase().replace(/^0x/, "");
        if (!targetAddr) return null;

        for (var i = 0; i < list.length; i++) {
            var top = list[i];
            if (top) {
                var ht = null;
                try {
                    ht = HyprlandToplevel.of(top);
                } catch (e) {
                }
                if (!ht) {
                    try {
                        ht = top.HyprlandToplevel;
                    } catch (e2) {
                    }
                }

                var topAddr = "";
                if (ht && ht.address !== undefined && ht.address !== null) {
                    topAddr = String(ht.address).toLowerCase().replace(/^0x/, "");
                } else if (top.address !== undefined && top.address !== null) {
                    topAddr = String(top.address).toLowerCase().replace(/^0x/, "");
                }

                if (topAddr && topAddr === targetAddr) {
                    return top;
                }
            }
        }
        return null;
    }

    // Application Launcher API Methods
    function fetchApplications(query, category, callback) {
        configService.isAppLauncherLoading = true;
        var payload = {
            "query": query || "",
            "category": category || "All"
        };
        _sendRequest("POST", "http://localhost:8765/system/get_applications", payload, function (res, ok) {
            configService.isAppLauncherLoading = false;
            if (ok && res) {
                if (res.applications !== undefined) configService.applicationsList = res.applications;
                if (res.recent_applications !== undefined) configService.recentApplicationsList = res.recent_applications;
                if (res.categories !== undefined) configService.applicationCategories = res.categories;
            }
            if (callback) callback(res, ok);
        });
    }

    function launchApplication(appId, execCmd, desktopFile, callback) {
        var payload = {
            "app_id": appId || "",
            "exec": execCmd || "",
            "desktop_file": desktopFile || ""
        };
        _sendRequest("POST", "http://localhost:8765/system/launch_application", payload, function (res, ok) {
            fetchApplications();
            if (callback) callback(ok);
        });
    }

    function togglePinApp(appId, pinned, callback) {
        var payload = {
            "app_id": appId || "",
            "pinned": !!pinned
        };
        _sendRequest("POST", "http://localhost:8765/system/toggle_pin_app", payload, function (res, ok) {
            fetchApplications();
            if (callback) callback(ok);
        });
    }

    function refreshApplications(callback) {
        _sendRequest("POST", "http://localhost:8765/system/refresh_applications", {}, function (res, ok) {
            fetchApplications("", "All", callback);
        });
    }

    // Notification Preferences Management API
    property var silentNotificationApps: []
    property var blockedNotificationApps: []

    function fetchNotificationPreferences(callback) {
        _sendRequest("POST", "http://localhost:8765/system/get_notification_preferences", {}, function (res, ok) {
            if (ok && res) {
                if (res.silent_apps !== undefined) configService.silentNotificationApps = res.silent_apps;
                if (res.blocked_apps !== undefined) configService.blockedNotificationApps = res.blocked_apps;
            }
            if (callback) callback(res, ok);
        });
    }

    function toggleAppSilent(appName, silent, callback) {
        var cleanName = (appName || "").trim().toUpperCase();
        var payload = {
            "app_name": cleanName,
            "silent": !!silent
        };
        _sendRequest("POST", "http://localhost:8765/system/toggle_app_silent", payload, function (res, ok) {
            if (ok && res) {
                if (res.silent_apps !== undefined) configService.silentNotificationApps = res.silent_apps;
                if (res.blocked_apps !== undefined) configService.blockedNotificationApps = res.blocked_apps;
            }
            if (callback) callback(res, ok);
        });
    }

    function toggleAppBlocked(appName, blocked, callback) {
        var cleanName = (appName || "").trim().toUpperCase();
        var payload = {
            "app_name": cleanName,
            "blocked": !!blocked
        };
        _sendRequest("POST", "http://localhost:8765/system/toggle_app_blocked", payload, function (res, ok) {
            if (ok && res) {
                if (res.silent_apps !== undefined) configService.silentNotificationApps = res.silent_apps;
                if (res.blocked_apps !== undefined) configService.blockedNotificationApps = res.blocked_apps;
            }
            if (callback) callback(res, ok);
        });
    }

    function isAppSilent(appName) {
        if (!appName) return false;
        var clean = (appName || "").trim().toUpperCase();
        return (configService.silentNotificationApps || []).indexOf(clean) !== -1;
    }

    function isAppBlocked(appName) {
        if (!appName) return false;
        var clean = (appName || "").trim().toUpperCase();
        return (configService.blockedNotificationApps || []).indexOf(clean) !== -1;
    }

    // Notification Stats & History Tracking
    property var notificationAppStats: []
    property int totalNotificationsReceived: 0
    property int totalNotificationsBlocked: 0
    property var notificationStatsToday: ({ "received": 0, "blocked": 0 })
    property var notificationStatsWeek: ({ "received": 0, "blocked": 0 })
    property var notificationStatsMonth: ({ "received": 0, "blocked": 0 })
    property var notificationStatsAllTime: ({ "received": 0, "blocked": 0 })

    function recordNotification(appName, isBlocked, appIcon, callback) {
        var cleanName = (appName || "").trim().toUpperCase();
        var payload = {
            "app_name": cleanName || "SYSTEM",
            "is_blocked": !!isBlocked,
            "app_icon": (typeof appIcon === "string") ? appIcon : ""
        };
        _sendRequest("POST", "http://localhost:8765/system/record_notification", payload, function (res, ok) {
            if (callback) callback(ok);
        });
    }

    function fetchNotificationStats(callback) {
        _sendRequest("POST", "http://localhost:8765/system/get_notification_stats", {}, function (res, ok) {
            if (ok && res) {
                if (res.stats !== undefined) configService.notificationAppStats = res.stats;
                if (res.total_received !== undefined) configService.totalNotificationsReceived = res.total_received;
                if (res.total_blocked !== undefined) configService.totalNotificationsBlocked = res.total_blocked;
                if (res.today !== undefined) configService.notificationStatsToday = res.today;
                if (res.week !== undefined) configService.notificationStatsWeek = res.week;
                if (res.month !== undefined) configService.notificationStatsMonth = res.month;
                if (res.all_time !== undefined) configService.notificationStatsAllTime = res.all_time;
            }
            if (callback) callback(res, ok);
        });
    }

    function focusApp(appName) {
        if (!appName) return;
        var cleanName = appName.toLowerCase().trim();
        var windows = configService.windowsList || [];
        for (var i = 0; i < windows.length; i++) {
            var win = windows[i];
            if (!win) continue;
            var winClass = (win.class_name || "").toLowerCase();
            var winTitle = (win.title || "").toLowerCase();
            if (winClass.includes(cleanName) || cleanName.includes(winClass) || winTitle.includes(cleanName)) {
                configService.executeAction("focus_address_" + win.address);
                return;
            }
        }
        configService.executeAction("focus_app_" + cleanName);
    }

    function resolveAppIcon(rawIcon, appClass, appTitle) {
        var raw = (rawIcon || "").toString().trim();
        var cls = (appClass || "").toString().trim();
        var title = (appTitle || "").toString().trim();

        // 1. Steam App ID convention (steam_app_<id> -> steam_icon_<id>)
        if (raw.startsWith("steam_app_")) {
            var rAppId = raw.replace("steam_app_", "");
            if (rAppId) return "image://icon/steam_icon_" + rAppId;
        }
        if (cls.toLowerCase().startsWith("steam_app_")) {
            var cAppId = cls.toLowerCase().replace("steam_app_", "");
            if (cAppId) return "image://icon/steam_icon_" + cAppId;
        }

        // 2. Check explicit valid URIs and file paths
        if (raw !== "" && raw !== "grid") {
            if (raw.startsWith("file://") || raw.startsWith("http://") || raw.startsWith("https://") || raw.startsWith("data:") || raw.startsWith("image://")) {
                return raw;
            }
            if (raw.startsWith("/") || raw.indexOf("/") !== -1) {
                return "file://" + raw;
            }
            if (raw.startsWith("steam_icon_")) {
                return "image://icon/" + raw;
            }
        }

        var cleanClass = cls.toLowerCase();
        if (cleanClass.endsWith("client")) {
            cleanClass = cleanClass.replace(/client$/, "");
        }
        if (cleanClass.endsWith(".exe")) {
            cleanClass = cleanClass.replace(/\.exe$/, "");
        }

        if (cleanClass.startsWith("steam_icon_")) {
            return "image://icon/" + cleanClass;
        }

        // 3. Dynamic lookup in parsed system desktop applications list
        var apps = configService.applicationsList || [];
        var lowerTitle = title.toLowerCase();

        // 3a. Match by window title against application name
        if (lowerTitle !== "") {
            for (var i = 0; i < apps.length; i++) {
                var app = apps[i];
                if (!app || !app.name || !app.icon) continue;
                var appNameLower = app.name.toLowerCase();
                if (appNameLower === lowerTitle || lowerTitle === appNameLower || (appNameLower.length > 3 && (lowerTitle.indexOf(appNameLower) !== -1 || appNameLower.indexOf(lowerTitle) !== -1))) {
                    var appIcon = app.icon;
                    if (appIcon.startsWith("steam_app_")) {
                        appIcon = "steam_icon_" + appIcon.replace("steam_app_", "");
                    }
                    if (appIcon.startsWith("/") || appIcon.indexOf("/") !== -1) return "file://" + appIcon;
                    if (appIcon.startsWith("image://")) return appIcon;
                    return "image://icon/" + appIcon;
                }
            }
        }

        // 3b. Match by window class against application ID, desktop_file, or exec command
        if (cleanClass !== "") {
            for (var j = 0; j < apps.length; j++) {
                var appObj = apps[j];
                if (!appObj || !appObj.icon) continue;
                var appIdLower = (appObj.id || "").toLowerCase();
                var appDeskLower = (appObj.desktop_file || "").toLowerCase();
                var appExecLower = (appObj.exec || "").toLowerCase();
                var appNLower = (appObj.name || "").toLowerCase();

                if (appIdLower === cleanClass || appNLower === cleanClass || appDeskLower.indexOf(cleanClass) !== -1 || appExecLower.indexOf(cleanClass) !== -1) {
                    var iconRes = appObj.icon;
                    if (iconRes.startsWith("steam_app_")) {
                        iconRes = "steam_icon_" + iconRes.replace("steam_app_", "");
                    }
                    if (iconRes.startsWith("/") || iconRes.indexOf("/") !== -1) return "file://" + iconRes;
                    if (iconRes.startsWith("image://")) return iconRes;
                    return "image://icon/" + iconRes;
                }
            }
        }

        // 4. If rawIcon is provided, use it
        if (raw !== "" && raw !== "grid") {
            return "image://icon/" + raw;
        }

        // 5. Fallback for Steam wrappers if no specific game matched
        if (cleanClass === "steam" || cleanClass === "steam_proton" || cleanClass === "gamescope" || cleanClass.indexOf("steam") !== -1) {
            return "image://icon/steam";
        }

        // 6. Default icon theme lookup
        if (cleanClass !== "") {
            return "image://icon/" + cleanClass;
        }

        return "";
    }

    function getWorkspaceWindows(wsId) {
        var list = configService.windowsList || [];
        var targetWs = wsId !== undefined ? wsId : (configService.activeWorkspaceId || 1);
        var result = [];
        for (var i = 0; i < list.length; i++) {
            var win = list[i];
            if (!win) continue;
            var winWs = win.workspace_id !== undefined ? win.workspace_id : (win.original_workspace_id !== undefined ? win.original_workspace_id : ((win.workspace && win.workspace.id !== undefined) ? win.workspace.id : win.workspace));
            if (winWs === targetWs) {
                result.push(win);
            }
        }
        return result;
    }

    // ==========================================
    // SCREEN SHADERS API (:8765/system/...)
    // ==========================================
    property bool shadersEnabled: false
    property var activeShaders: []
    property string activeShader: activeShaders.length > 0 ? activeShaders[0] : ""
    property var shadersList: []

    function isShaderActive(shaderId) {
        return configService.activeShaders && configService.activeShaders.indexOf(shaderId) !== -1;
    }

    function fetchShadersStatus(callback) {
        _sendRequest("POST", "http://localhost:8765/system/get_shaders_status", {}, function (res, ok) {
            if (ok && res) {
                configService.shadersEnabled = !!res.is_enabled;
                configService.activeShaders = res.active_shaders || (res.active_shader ? [res.active_shader] : []);
                configService.activeShader = res.active_shader || (configService.activeShaders.length > 0 ? configService.activeShaders[0] : "");
                configService.shadersList = res.shaders || [];
            }
            if (callback) callback(res, ok);
        });
    }

    function setActiveShader(shaderId, exclusive, callback) {
        var isExcl = (exclusive === true);
        if (isExcl) {
            configService.activeShaders = [shaderId];
        } else if (configService.activeShaders.indexOf(shaderId) === -1) {
            var updated = configService.activeShaders.slice();
            updated.push(shaderId);
            configService.activeShaders = updated;
        }
        configService.shadersEnabled = true;
        configService.activeShader = shaderId;
        _sendRequest("POST", "http://localhost:8765/system/set_active_shader", {
            "shader_id": shaderId,
            "exclusive": isExcl
        }, function (res, ok) {
            fetchShadersStatus();
            if (callback) callback(ok);
        });
    }

    function setActiveShaders(shaderIds, callback) {
        configService.activeShaders = shaderIds || [];
        configService.shadersEnabled = configService.activeShaders.length > 0;
        configService.activeShader = configService.activeShaders.length > 0 ? configService.activeShaders[0] : "";
        _sendRequest("POST", "http://localhost:8765/system/set_active_shaders", {
            "shader_ids": shaderIds || []
        }, function (res, ok) {
            fetchShadersStatus();
            if (callback) callback(ok);
        });
    }

    function enableShader(shaderId, callback) {
        if (configService.activeShaders.indexOf(shaderId) === -1) {
            var updated = configService.activeShaders.slice();
            updated.push(shaderId);
            configService.activeShaders = updated;
            configService.shadersEnabled = true;
        }
        _sendRequest("POST", "http://localhost:8765/system/enable_shader", { "shader_id": shaderId }, function (res, ok) {
            fetchShadersStatus();
            if (callback) callback(ok);
        });
    }

    function disableShader(shaderId, callback) {
        var idx = configService.activeShaders.indexOf(shaderId);
        if (idx !== -1) {
            var updated = configService.activeShaders.slice();
            updated.splice(idx, 1);
            configService.activeShaders = updated;
            configService.shadersEnabled = updated.length > 0;
        }
        _sendRequest("POST", "http://localhost:8765/system/disable_shader", { "shader_id": shaderId }, function (res, ok) {
            fetchShadersStatus();
            if (callback) callback(ok);
        });
    }

    function turnOffShader(callback) {
        configService.shadersEnabled = false;
        configService.activeShaders = [];
        configService.activeShader = "";
        _sendRequest("POST", "http://localhost:8765/system/turn_off_shader", {}, function (res, ok) {
            fetchShadersStatus();
            if (callback) callback(ok);
        });
    }

    function toggleShader(shaderId, callback) {
        var idx = configService.activeShaders.indexOf(shaderId);
        var updated = configService.activeShaders.slice();
        if (idx !== -1) {
            updated.splice(idx, 1);
        } else {
            updated.push(shaderId);
        }
        configService.activeShaders = updated;
        configService.shadersEnabled = updated.length > 0;
        configService.activeShader = updated.length > 0 ? updated[0] : "";

        _sendRequest("POST", "http://localhost:8765/system/toggle_shader", { "shader_id": shaderId }, function (res, ok) {
            fetchShadersStatus();
            if (callback) callback(ok);
        });
    }

    function updateShaderConfig(shaderId, configObj, callback, skipRefresh) {
        // Eagerly update local shadersList config in-place
        if (configService.shadersList && configService.shadersList.length > 0) {
            var updated = [];
            for (var i = 0; i < configService.shadersList.length; i++) {
                var s = Object.assign({}, configService.shadersList[i]);
                if (s.id === shaderId) {
                    s.config = Object.assign({}, s.config, configObj);
                    if (s.parameters) {
                        var newParams = [];
                        for (var p = 0; p < s.parameters.length; p++) {
                            var param = Object.assign({}, s.parameters[p]);
                            if (configObj[param.name] !== undefined) {
                                param.value = configObj[param.name];
                            }
                            newParams.push(param);
                        }
                        s.parameters = newParams;
                    }
                }
                updated.push(s);
            }
            configService.shadersList = updated;
        }

        _sendRequest("POST", "http://localhost:8765/system/update_shader_config", {
            "shader_id": shaderId,
            "config": configObj
        }, function (res, ok) {
            if (!skipRefresh) fetchShadersStatus();
            if (callback) callback(ok);
        });
    }

    function resetShaderConfig(shaderId, callback) {
        _sendRequest("POST", "http://localhost:8765/system/reset_shader_config", {
            "shader_id": shaderId || null
        }, function (res, ok) {
            fetchShadersStatus();
            if (callback) callback(ok);
        });
    }

    // ==========================================
    // SYSTEM POWER PROFILES (powerprofilesctl)
    // ==========================================
    property string activePowerProfile: "balanced"
    property var availablePowerProfiles: ["performance", "balanced", "power-saver"]

    property Process powerProfileReaderProc: Process {
        id: powerProfileReader
        command: ["powerprofilesctl", "get"]
        stdout: SplitParser {
            onRead: data => {
                if (data) {
                    var p = data.trim().toLowerCase();
                    if (p) configService.activePowerProfile = p;
                }
            }
        }
    }

    function fetchPowerProfile() {
        if (powerProfileReaderProc && !powerProfileReaderProc.running) {
            powerProfileReaderProc.running = true;
        }
    }

    function setPowerProfile(profile) {
        var clean = (profile || "balanced").toLowerCase().trim();
        configService.activePowerProfile = clean;
        var setter = Qt.createQmlObject('import Quickshell.Io; Process { command: ["powerprofilesctl", "set", "' + clean + '"]; running: true }', configService, "PowerProfileSetter");
    }

    Component.onCompleted: {
        fetchConfig();
        fetchWindows();
        fetchAllSystemStatus();
        fetchApplications();
        fetchNotificationPreferences();
        fetchNotificationStats();
        fetchShadersStatus();
        fetchPowerProfile();
    }
}

