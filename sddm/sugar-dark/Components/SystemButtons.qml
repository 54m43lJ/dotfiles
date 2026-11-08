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
import QtQuick.Layouts
import QtQuick.Controls

RowLayout {

    spacing: root.font.pointSize

    property var suspend: ["Suspend", config.TranslateSuspend || textConstants.suspend, sddm.canSuspend]
    property var hibernate: ["Hibernate", config.TranslateHibernate || textConstants.hibernate, sddm.canHibernate]
    property var reboot: ["Reboot", config.TranslateReboot || textConstants.reboot, sddm.canReboot]
    property var shutdown: ["Shutdown", config.TranslateShutdown || textConstants.shutdown, sddm.canPowerOff]

    property Item exposedLogin

    Repeater {

        model: [suspend, hibernate, reboot, shutdown]

        RoundButton {
            id: icon
            text: modelData[1]
            font.pointSize: root.font.pointSize * 0.8
            Layout.alignment: Qt.AlignHCenter
            icon.source: modelData ? Qt.resolvedUrl("../Assets/" + modelData[0] + ".svgz") : ""
            icon.height: 2 * Math.round((root.font.pointSize * 3) / 2)
            icon.width: 2 * Math.round((root.font.pointSize * 3) / 2)
            display: AbstractButton.TextUnderIcon
            visible: modelData[2]
            hoverEnabled: true
            palette.buttonText: root.colorFg
            background: Item {
                HoverFill {
                    anchors.fill: parent
                    anchors.margins: 4
                    radius: Math.min(root.cornerRadius, height / 2)
                    active: icon.hovered || icon.visualFocus
                    pressed: icon.down
                    fillColor: root.colorPurple
                    activeOpacity: 0.12
                    pressedOpacity: 0.2
                    border.width: icon.visualFocus ? 1 : 0
                    border.color: root.colorPurpleLight
                }
            }
            Keys.onReturnPressed: clicked()
            onClicked: {
                parent.forceActiveFocus()
                index == 0 ? sddm.suspend() : index == 1 ? sddm.hibernate() : index == 2 ? sddm.reboot() : sddm.powerOff()
            }
            KeyNavigation.up: exposedLogin
            KeyNavigation.left: index == 0 ? exposedLogin : parent.children[index-1]

            states: [
                State {
                    name: "pressed"
                    when: parent.children[index].down
                    PropertyChanges {
                        target: parent.children[index]
                        palette.buttonText: root.colorCream
                    }
                    PropertyChanges {
                        target: parent.children[index].background
                        border.color: root.colorPurpleLight
                    }
                },
                State {
                    name: "hovered"
                    when: parent.children[index].hovered
                    PropertyChanges {
                        target: parent.children[index]
                        palette.buttonText: root.colorPurpleLight
                    }
                    PropertyChanges {
                        target: parent.children[index].background
                        border.color: root.colorPurpleLight
                    }
                },
                State {
                    name: "focused"
                    when: parent.children[index].visualFocus
                    PropertyChanges {
                        target: parent.children[index]
                        palette.buttonText: root.colorPurpleLight
                    }
                    PropertyChanges {
                        target: parent.children[index].background
                        border.color: root.colorPurpleLight
                    }
                }
            ]

            transitions: [
                Transition {
                    PropertyAnimation {
                        properties: "palette.buttonText, border.color"
                        duration: 150
                    }
                }
            ]

        }

    }

}
