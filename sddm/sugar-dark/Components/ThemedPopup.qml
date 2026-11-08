import QtQuick
import QtQuick.Controls
import QtQuick.Effects

// Shared dropdown shell: rounded panel, soft shadow and a slide-expand reveal.
// The menu grows by height and slides into place; there is no fade.
// growUp chooses whether the menu expands upward or downward.
Popup {
    id: root

    property color fillColor: "#444"
    property color borderColor: "#55ca33ac"
    property real cornerRadius: 30
    property color shadowColor: "#88000000"
    property bool growUp: false
    property int expandDuration: 200
    property int collapseDuration: 140
    property int slideDistance: 16

    padding: 0

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
                property: "y"
                from: root.growUp ? root.y + root.implicitHeight + root.slideDistance : root.y - root.slideDistance
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
                property: "y"
                from: root.y
                to: root.growUp ? root.y + root.implicitHeight + root.slideDistance : root.y - root.slideDistance
                duration: root.collapseDuration
                easing.type: Easing.InCubic
            }
        }
    }
}
