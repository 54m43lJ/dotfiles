import QtQuick

// Small, semi-transparent hover fill shared by buttons and dropdown items.
// Consumers inset it with anchors.margins to keep the highlight compact.
Rectangle {
    id: root

    property bool active: false
    property bool pressed: false
    property color fillColor: "#E593E7"
    property real activeOpacity: 0.12
    property real pressedOpacity: 0.2
    property int fadeDuration: 150

    color: root.fillColor
    opacity: root.pressed ? root.pressedOpacity : root.active ? root.activeOpacity : 0.0
    Behavior on opacity {
        NumberAnimation {
            duration: root.fadeDuration
            easing.type: Easing.OutCubic
        }
    }
}
