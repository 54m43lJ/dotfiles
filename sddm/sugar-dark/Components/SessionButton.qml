//
// This file is part of Sugar Dark, a theme for the Simple Display Desktop Manager.
//
// Copyright 2018 Marian Arlt
//
// Sugar Dark is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Sugar Dark is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Sugar Dark. If not, see <https://www.gnu.org/licenses/>.
//

import QtQuick

Item {
    id: sessionButton
    height: root.font.pointSize
    width: parent.width * 0.5

    property alias selectedSession: sessionDropdown.currentIndex
    property string textConstantSession

    Text {
        id: sessionCaption
        text: config.TranslateSession || "Session:"
        anchors.right: selectSession.left
        anchors.rightMargin: root.font.pointSize * 0.6
        anchors.verticalCenter: selectSession.verticalCenter
        font.pointSize: root.font.pointSize * 0.9
        color: root.colorMuted
    }

    Item {
        id: selectSession

        anchors.left: parent.left
        anchors.leftMargin: parent.width * 0.5
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.font.pointSize * 0.9
        height: root.font.pointSize * root.fieldHeightFactor
        width: displayedItem.implicitWidth + root.font.pointSize * 1.6
        z: 1

        activeFocusOnTab: true
        readonly property bool active: activeFocus || sessionDropdown.opened

        HoverFill {
            anchors.fill: parent
            anchors.margins: 2
            radius: height / 2
            active: !sessionDropdown.opened &&
                    (sessionMouse.containsMouse || selectSession.activeFocus)
            pressed: sessionMouse.pressed
            fillColor: root.colorPurpleLight
            activeOpacity: 0.12
            pressedOpacity: 0.2
        }

        Text {
            id: displayedItem
            anchors.centerIn: parent
            text: sessionDropdown.currentText
            color: selectSession.active ? root.colorPurpleLight : root.colorFg
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            font.pointSize: root.font.pointSize * 0.9
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        MouseArea {
            id: sessionMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: sessionDropdown.toggle()
        }

        Keys.onSpacePressed: sessionDropdown.open()
        Keys.onReturnPressed: sessionDropdown.open()
        Keys.onEnterPressed: sessionDropdown.open()
    }

    ThemedDropdown {
        id: sessionDropdown

        triggerItem: selectSession
        model: sessionModel
        textRole: "name"
        valueText: function(modelData) {
            return modelData.name
        }
        currentIndex: sessionModel.lastIndex
        growUp: true
        rowHeight: selectSession.height
        rowFontSize: root.font.pointSize * 0.8
        cornerRadius: root.cornerRadius
        fillColor: root.colorSurface
        textColor: root.colorFg
        highlightedTextColor: root.colorPurpleLight
        highlightColor: root.colorPurpleLight
        borderColor: selectSession.active ? root.colorPurple : root.colorMuted
        borderWidth: selectSession.active ? 2 : 1
        shadowColor: root.colorShadow
        restoreFocusItem: selectSession
    }

}
