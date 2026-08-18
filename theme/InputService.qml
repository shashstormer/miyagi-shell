pragma Singleton
import QtQuick

QtObject {
    id: root

    // Three Input Modalities: "keyboard" | "mouse" | "gamepad"
    property string mode: "keyboard"

    readonly property bool isKeyboard: mode === "keyboard"
    readonly property bool isMouse: mode === "mouse"
    readonly property bool isGamepad: mode === "gamepad"
    readonly property bool isNonMouse: mode !== "mouse"

    // 1-Second Input Modality Lock (Arbitration)
    property string lockedMode: ""
    property int lockDurationMs: 1000

    property Timer lockTimer: Timer {
        id: lockTimer
        interval: root.lockDurationMs
        repeat: false
        onTriggered: {
            root.lockedMode = "";
        }
    }

    function lockModality(modality) {
        var m = modality || root.mode || "keyboard";
        root.mode = m;
        root.lockedMode = m;
        lockTimer.restart();
    }

    function canAcceptInput(requestedMode) {
        if (lockTimer.running && root.lockedMode !== "" && root.lockedMode !== requestedMode) {
            return false; // Suppress inputs from other modalities during the 1-second exclusivity period
        }
        return true;
    }

    // Universal Navigation Signals
    signal navUp()
    signal navDown()
    signal navLeft()
    signal navRight()
    signal navSelect()
    signal navBack()
    signal navNextTab()
    signal navPrevTab()
    signal navContextMenu()

    // Mode Switchers (returns boolean indicating if modality change / input was accepted)
    function setMode(newMode) {
        if (!canAcceptInput(newMode)) return false;
        if (root.mode !== newMode) {
            root.mode = newMode;
        }
        return true;
    }

    function useKeyboard() {
        return setMode("keyboard");
    }

    function useMouse() {
        return setMode("mouse");
    }

    function useGamepad() {
        return setMode("gamepad");
    }

    // Directional Trigger Helpers
    function triggerUp() {
        navUp();
    }

    function triggerDown() {
        navDown();
    }

    function triggerLeft() {
        navLeft();
    }

    function triggerRight() {
        navRight();
    }

    function triggerSelect() {
        navSelect();
    }

    function triggerBack() {
        navBack();
    }

    function triggerNextTab() {
        navNextTab();
    }

    function triggerPrevTab() {
        navPrevTab();
    }

    function triggerContextMenu() {
        navContextMenu();
    }

    // Gamepad / Controller Specific Bindings
    // A = Enter / Select
    function buttonA() {
        if (!useGamepad()) return;
        triggerSelect();
    }

    // B = Exit / Close / Back
    function buttonB() {
        if (!useGamepad()) return;
        triggerBack();
    }

    // X / Y Buttons
    function buttonX() {
        if (!useGamepad()) return;
        triggerPrevTab();
    }

    function buttonY() {
        if (!useGamepad()) return;
        triggerNextTab();
    }

    // Controller `>` (Start / Menu / Options = Context Menu)
    function buttonStart() {
        if (!useGamepad()) return;
        triggerContextMenu();
    }

    function buttonMenu() {
        if (!useGamepad()) return;
        triggerContextMenu();
    }

    function buttonOptions() {
        if (!useGamepad()) return;
        triggerContextMenu();
    }

    // Right Click
    function rightClick() {
        if (!useMouse()) return;
        triggerContextMenu();
    }

    // Single Panel Focus & Auto-Close Signal
    signal closePanelsExcept(var exceptPanel)

    function closeOtherPanels(exceptPanel) {
        closePanelsExcept(exceptPanel);
    }

    // Global Settings Panel Signals & Actions
    signal requestOpenSettings()
    signal requestToggleSettings()
    signal requestCloseSettings()

    function openSettings() {
        requestOpenSettings();
    }

    function toggleSettings() {
        requestToggleSettings();
    }

    function closeSettings() {
        requestCloseSettings();
    }

    function togglePanel(targetPanel) {
        if (!targetPanel) return;
        if (targetPanel.isOpen) {
            if (typeof targetPanel.close === "function") targetPanel.close();
        } else {
            closePanelsExcept(targetPanel);
            if (typeof targetPanel.open === "function") targetPanel.open();
        }
    }

    // Universal Panel Navigation & Hierarchy Stack
    function openPanel(targetPanel, fromPanel, preferredMode) {
        if (!targetPanel) return;
        var m = preferredMode || root.mode || "keyboard";
        lockModality(m);
        if (fromPanel && fromPanel !== targetPanel) {
            targetPanel.openedFrom = fromPanel;
            if (typeof fromPanel.close === "function") fromPanel.close();
        }
        if (typeof targetPanel.open === "function") {
            targetPanel.open();
        }
    }

    function closeOrReturn(currentPanel) {
        if (currentPanel && currentPanel.openedFrom) {
            var prev = currentPanel.openedFrom;
            currentPanel.openedFrom = null;
            if (typeof currentPanel.close === "function") currentPanel.close();
            if (prev && typeof prev.open === "function") {
                prev.open();
                return true;
            }
        }
        if (currentPanel && typeof currentPanel.close === "function") {
            currentPanel.close();
        }
        return false;
    }

    // Bumpers: LB / RB for category / tab switching
    function lb() {
        if (!useGamepad()) return;
        triggerPrevTab();
    }

    function rb() {
        if (!useGamepad()) return;
        triggerNextTab();
    }

    // D-Pad / Left Thumbstick directional controls (= Arrow keys)
    function dpadUp() {
        if (!useGamepad()) return;
        triggerUp();
    }

    function dpadDown() {
        if (!useGamepad()) return;
        triggerDown();
    }

    function dpadLeft() {
        if (!useGamepad()) return;
        triggerLeft();
    }

    function dpadRight() {
        if (!useGamepad()) return;
        triggerRight();
    }

    function stickUp() {
        dpadUp();
    }

    function stickDown() {
        dpadDown();
    }

    function stickLeft() {
        dpadLeft();
    }

    function stickRight() {
        dpadRight();
    }
}
