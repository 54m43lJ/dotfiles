import QtQuick
import QtQuick.Controls
import QtQuick.Effects

// Shared dropdown shell: rounded panel, soft shadow and a slide-in reveal.
// growUp chooses whether the menu slides up from below or down from above.
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

    padding: 4

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
                property: "opacity"
                from: 0
                to: 1
                duration: root.expandDuration * 0.6
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                property: "y"
                from: root.growUp ? root.y + root.slideDistance : root.y - root.slideDistance
                to: root.y
                duration: root.expandDuration
                easing.type: Easing.OutCubic
            }
        }
    }

    exit: Transition {
        ParallelAnimation {
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
                to: root.growUp ? root.y + root.slideDistance : root.y - root.slideDistance
                duration: root.collapseDuration
                easing.type: Easing.InCubic
            }
        }
    }
}
