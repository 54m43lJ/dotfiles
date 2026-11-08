import QtQuick
import QtQuick.Controls
import QtQuick.Effects

// Shared dropdown shell: rounded panel, soft shadow and a height reveal.
// Grow-up popups keep their bottom edge pinned to the trigger by animating y
// together with height.
Popup {
    id: root

    property color fillColor: "#444"
    property color borderColor: "#55ca33ac"
    property real cornerRadius: 30
    property color shadowColor: "#88000000"
    property bool growUp: false
    property int expandDuration: 200
    property int collapseDuration: 140

    padding: 10

    background: Rectangle {
        radius: root.cornerRadius
        color: root.fillColor
        border.width: 1
        border.color: root.borderColor
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: root.shadowColor
            shadowBlur: 1.0
        }
    }

    enter: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "height"
                from: 0
                to: root.implicitHeight
                duration: root.expandDuration
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: root.expandDuration
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                property: "y"
                from: root.growUp ? root.y + root.implicitHeight : root.y
                to: root.y
                duration: root.expandDuration
                easing.type: Easing.OutCubic
            }
        }
    }

    exit: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "height"
                from: root.height
                to: 0
                duration: root.collapseDuration
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                property: "opacity"
                from: 1
                to: 0
                duration: root.collapseDuration
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                property: "y"
                from: root.y
                to: root.growUp ? root.y + root.implicitHeight : root.y
                duration: root.collapseDuration
                easing.type: Easing.InCubic
            }
        }
    }
}
