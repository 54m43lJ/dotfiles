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
import QtQuick.Controls
import QtQuick.Effects

Item {
    id: sessionButton
    height: root.font.pointSize
    width: parent.width * 0.5

    property var selectedSession: selectSession.currentIndex
    property string textConstantSession

    ComboBox {
        id: selectSession

        anchors.left: parent.left
        anchors.leftMargin: parent.width * 0.5
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.font.pointSize * 0.9

        model: sessionModel
        currentIndex: model.lastIndex
        textRole: "name"
        hoverEnabled: true

        height: root.font.pointSize * root.fieldHeightFactor
        leftPadding: root.font.pointSize * 2
        rightPadding: root.font.pointSize
        topPadding: 0
        bottomPadding: 0

        delegate: ItemDelegate {
            width: parent.width
            anchors.horizontalCenter: parent.horizontalCenter
            contentItem: Text {
                text: model.name
                font.pointSize: root.font.pointSize * 0.8
                color: root.palette.text
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
            }
            highlighted: parent.highlightedIndex === index
            background: Item {
                HoverFill {
                    anchors.fill: parent
                    anchors.margins: 4
                    radius: root.cornerRadius * 0.5
                    active: selectSession.highlightedIndex === index
                    fillColor: root.palette.highlight
                    activeOpacity: 0.14
                }
            }
        }

        indicator: Item {}

        contentItem: Text {
            id: displayedItem
            text: (config.TranslateSession || (textConstantSession + ":")) + " " + selectSession.currentText
            color: selectSession.visualFocus ? root.palette.highlight : root.palette.text
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            font.pointSize: root.font.pointSize * 0.9
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        background: Item {
            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: "transparent"
                border.width: selectSession.visualFocus ? 2 : 1
                border.color: selectSession.visualFocus ? root.palette.highlight : root.palette.text
                Behavior on border.color { ColorAnimation { duration: 150 } }
            }
            HoverFill {
                anchors.fill: parent
                anchors.margins: 2
                radius: height / 2
                active: selectSession.hovered || selectSession.visualFocus
                pressed: selectSession.down
                fillColor: root.palette.highlight
                activeOpacity: 0.12
                pressedOpacity: 0.2
            }
        }

        popup: ThemedPopup {
            id: popupHandler
            x: root.font.pointSize * 2 - displayedItem.implicitWidth * 0.1
            y: -contentItem.implicitHeight - 10
            rightMargin: config.ForceRightToLeft == "true" ? root.padding + sessionButton.width * 0.6 : undefined
            width: sessionButton.width * 0.55
            implicitHeight: contentItem.implicitHeight
            cornerRadius: root.cornerRadius
            borderColor: Qt.rgba(root.palette.highlight.r, root.palette.highlight.g, root.palette.highlight.b, 0.35)
            growUp: true

            contentItem: ListView {
                clip: true
                implicitHeight: contentHeight + 20
                model: selectSession.popup.visible ? selectSession.delegateModel : null
                currentIndex: selectSession.highlightedIndex
                ScrollIndicator.vertical: ScrollIndicator { }
            }
        }
    }

}
