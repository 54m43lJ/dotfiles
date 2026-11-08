import QtQuick
import QtQuick.Controls
import QtQuick.Effects

// Custom dropdown menu.
//
// QtQuick.Controls.Popup positions itself with its top-left corner and exposes
// the *effective* position through x/y, so animating y made upward and downward
// menus disagree and drift. This item only animates height: a downward menu
// keeps its top edge fixed, while an upward menu binds y to the animated height
// so its bottom edge stays fixed. The menu is clipped by an inner viewport and
// reveals its rows instead of scaling/repositioning a popup window.
Item {
    id: root

    // The item the menu is attached to. The menu must be a sibling of this item
    // so that x/y are resolved in the same coordinate space.
    property Item triggerItem: parent

    property var model: null
    property string textRole: "name"
    // Returns the label for a row. Override this when the row wording differs
    // from the value used for currentText (for example realName vs name).
    property var rowText: function(modelData) {
        if (!modelData)
            return ""
        var value = modelData[root.textRole]
        return value === undefined || value === null ? "" : String(value)
    }
    // Returns the value shown in the trigger and exposed as currentText.
    property var valueText: function(modelData) {
        if (!modelData)
            return ""
        var value = modelData[root.textRole]
        return value === undefined || value === null ? "" : String(value)
    }

    property int currentIndex: -1
    property bool growUp: false
    property bool opened: false

    // Color API. The component does not know about the theme palette: every
    // color is injected by the consumer (fillColor = surface, borderColor =
    // purple-light/muted, textColor = fg, highlightedTextColor = cream,
    // highlightColor = purple, shadowColor = gold alpha).
    property color fillColor: "#3E3542"
    property color borderColor: "#B0B4BC"
    property int borderWidth: 1
    property color shadowColor: "#8C9D7E4D"
    property color textColor: "#D6CAB6"
    property color highlightedTextColor: textColor
    property color highlightColor: "#89338E"
    property real hoverOpacity: 0.14
    property real cornerRadius: 30
    property real rowHeight: 40
    property real rowFontSize: 12
    property int rowCapitalization: Font.MixedCase

    property int expandDuration: 200
    property int collapseDuration: 140
    property int heightDuration: collapseDuration
    property int heightEasing: Easing.InCubic
    property real slideDistance: 16

    property int highlightedIndex: -1
    property Item restoreFocusItem: null

    signal activated(int index)

    readonly property real triggerHeight: triggerItem ? triggerItem.height : 0
    readonly property real contentHeight: list.contentHeight
    readonly property int count: list.count
    property real revealHeight: opened ? contentHeight : 0
    // Used by the panel background to drop focus only when a dropdown is open.
    readonly property bool dropdownMenu: true
    readonly property string currentText: {
        if (currentIndex < 0 || currentIndex >= labelCache.count)
            return ""
        var item = labelCache.itemAt(currentIndex)
        return item ? item["value"] : ""
    }

    function open() {
        if (opened || list.count === 0)
            return
        heightDuration = expandDuration
        heightEasing = Easing.OutCubic
        highlightedIndex = currentIndex
        opened = true
        forceActiveFocus()
        list.positionViewAtIndex(currentIndex, ListView.Contain)
    }

    function close() {
        if (!opened)
            return
        var hadFocus = activeFocus
        heightDuration = collapseDuration
        heightEasing = Easing.InCubic
        opened = false
        highlightedIndex = -1
        if (hadFocus && restoreFocusItem)
            restoreFocusItem.forceActiveFocus()
    }

    function toggle() {
        opened ? close() : open()
    }

    function select(index) {
        if (index < 0 || index >= list.count)
            return
        currentIndex = index
        close()
        activated(index)
    }

    function step(delta) {
        if (!opened || list.count === 0)
            return
        var next = Math.max(0, Math.min(list.count - 1, highlightedIndex + delta))
        highlightedIndex = next
        list.positionViewAtIndex(next, ListView.Contain)
    }

    x: triggerItem ? triggerItem.x : 0
    width: triggerItem ? triggerItem.width : 0
    y: triggerItem
       ? (growUp ? triggerItem.y + triggerItem.height - height
                 : triggerItem.y)
       : 0
    height: triggerHeight + revealHeight
    // The panel is the trigger's own background, so it must be visible even
    // while the menu is closed.
    visible: triggerItem ? triggerItem.visible : false
    // Sit just behind the trigger content, but above the surrounding form.
    z: triggerItem ? triggerItem.z - 0.5 : 0

    Behavior on revealHeight {
        NumberAnimation {
            duration: root.heightDuration
            easing.type: root.heightEasing
        }
    }

    // The menu content slides 16U into place while the height opens. There is
    // no vertical scale/bounce: the panel and rows keep their natural size.
    property real listOffset: 0

    onOpenedChanged: {
        if (opened) {
            closeAnim.stop()
            listOffset = growUp ? slideDistance : -slideDistance
            openAnim.restart()
        } else {
            openAnim.stop()
            closeAnim.restart()
        }
    }

    onActiveFocusChanged: {
        if (opened && !activeFocus)
            close()
    }

    onCurrentIndexChanged: {
        if (opened)
            highlightedIndex = currentIndex
    }

    Keys.onEscapePressed: close()
    Keys.onUpPressed: step(-1)
    Keys.onDownPressed: step(1)
    Keys.onReturnPressed: if (highlightedIndex >= 0) select(highlightedIndex)
    Keys.onEnterPressed: if (highlightedIndex >= 0) select(highlightedIndex)
    Keys.onSpacePressed: if (highlightedIndex >= 0) select(highlightedIndex)

    NumberAnimation {
        id: openAnim
        target: root
        property: "listOffset"
        from: root.growUp ? root.slideDistance : -root.slideDistance
        to: 0
        duration: root.expandDuration
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: closeAnim
        target: root
        property: "listOffset"
        from: root.listOffset
        to: root.growUp ? root.slideDistance : -root.slideDistance
        duration: root.collapseDuration
        easing.type: Easing.InCubic
    }

    // Hidden label cache. Popup-based menus cannot read model data until the
    // popup is visible; a plain Repeater is always polished, so currentText is
    // available before the menu ever opens.
    Repeater {
        id: labelCache
        model: root.model

        delegate: Item {
            visible: false
            width: 0
            height: 0

            property string value: {
                if (!model)
                    return ""
                return root.valueText(model, index)
            }
        }
    }

    Rectangle {
        id: panel
        anchors.fill: parent
        radius: root.triggerHeight / 2
        // Keep the panel opaque for the whole open/close animation. Fading the
        // fill let the warm background image show through and briefly looked
        // like a gold flash.
        color: (root.opened || root.revealHeight > 0) ? root.fillColor : "transparent"
        border.width: root.borderWidth
        border.color: root.borderColor
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: root.opened || root.revealHeight > 0
            shadowColor: root.shadowColor
            shadowBlur: 1.0
        }

        Behavior on border.color {
            ColorAnimation { duration: 150 }
        }
    }

    Item {
        id: viewport
        y: root.growUp ? 0 : root.triggerHeight
        width: parent.width
        height: root.revealHeight
        clip: true

        ListView {
            id: list
            width: viewport.width
            height: contentHeight
            y: root.listOffset
            model: root.model
            currentIndex: root.highlightedIndex
            boundsBehavior: Flickable.StopAtBounds

            delegate: ItemDelegate {
                id: row

                width: root.width
                height: root.rowHeight
                topPadding: 0
                bottomPadding: 0
                leftPadding: 8
                rightPadding: 8
                hoverEnabled: true
                focusPolicy: Qt.NoFocus
                highlighted: root.highlightedIndex === index

                contentItem: Text {
                    text: root.rowText(model, index)
                    font.pointSize: root.rowFontSize
                    font.capitalization: root.rowCapitalization
                    color: root.highlightedIndex === index ? root.highlightedTextColor : root.textColor
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                background: Item {
                    HoverFill {
                        anchors.fill: parent
                        anchors.margins: 1
                        radius: Math.min(root.cornerRadius, root.rowHeight / 2)
                        active: root.highlightedIndex === index
                        fillColor: root.highlightColor
                        activeOpacity: root.hoverOpacity
                    }
                }

                onHoveredChanged: {
                    if (hovered)
                        root.highlightedIndex = index
                }

                onClicked: root.select(index)
            }
        }
    }
}
