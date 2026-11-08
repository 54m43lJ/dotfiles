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

Column {
    id: inputContainer
    Layout.fillWidth: true

    property Item exposeLogin: submitButton
    property bool failed

    function submitLogin() {
        if (username.text != "" && password.text != "")
            sddm.login(username.text, password.text, sessionSelect.selectedSession)
    }

    // USERNAME INPUT
    Item {
        id: usernameField

        height: root.font.pointSize * root.fieldRowFactor
        width: parent.width * (root.fieldWidthPercent / 100)
        anchors.horizontalCenter: parent.horizontalCenter
        // The dropdown is a child of this item and must paint over the fields
        // that follow it in the form.
        z: 2

        HoverHandler { id: usernameHover }

        // The whole pill is the trigger. The text field is laid over the middle
        // of it for editing, so clicks on the icon and side padding open the
        // list while the center keeps editing the username.
        Item {
            id: selectUser

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: root.font.pointSize * root.fieldHeightFactor
            z: 1
            activeFocusOnTab: true

            readonly property bool active: username.activeFocus || selectUser.activeFocus || userDropdown.opened

            HoverFill {
                anchors.fill: parent
                anchors.margins: 2
                radius: height / 2
                active: !userDropdown.opened &&
                        (usernameHover.hovered || username.activeFocus || selectUser.activeFocus)
                pressed: usernameTriggerMouse.pressed
                fillColor: root.colorPurple
                activeOpacity: 0.12
                pressedOpacity: 0.2
            }

            Button {
                id: usernameIcon
                width: parent.height * 0.8
                height: parent.height
                anchors.left: parent.left
                anchors.leftMargin: parent.height * 0.125
                anchors.verticalCenter: parent.verticalCenter
                icon.height: parent.height * 0.25
                icon.width: parent.height * 0.25
                enabled: false
                icon.color: selectUser.active ? root.colorPurpleLight : root.colorMuted
                icon.source: Qt.resolvedUrl("../Assets/User.svgz")
                background: null
            }

            MouseArea {
                id: usernameTriggerMouse
                anchors.fill: parent
                onClicked: userDropdown.toggle()
            }

            Keys.onSpacePressed: userDropdown.open()
            Keys.onReturnPressed: userDropdown.open()
            Keys.onEnterPressed: userDropdown.open()
        }

        TextField {
            id: username
            text: config.ForceLastUser == "true" ? userDropdown.currentText : ""
            font.capitalization: Font.Capitalize
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: root.font.pointSize * root.fieldHeightFactor * 0.9
            anchors.rightMargin: root.font.pointSize * root.fieldHeightFactor * 0.9
            anchors.verticalCenter: parent.verticalCenter
            height: root.font.pointSize * root.fieldHeightFactor
            placeholderText: config.TranslateUsernamePlaceholder || textConstants.userName
            placeholderTextColor: root.colorMuted
            color: root.colorFg
            selectByMouse: true
            horizontalAlignment: TextInput.AlignHCenter
            renderType: Text.QtRendering
            background: null
            Keys.onReturnPressed: submitLogin()
            KeyNavigation.down: password
            z: 2

            states: [
                State {
                    name: "focused"
                    when: username.activeFocus
                    PropertyChanges {
                        target: username
                        color: root.colorPurpleLight
                    }
                }
            ]
        }

        ThemedDropdown {
            id: userDropdown

            triggerItem: selectUser
            model: userModel
            textRole: "name"
            rowText: function(modelData) {
                return modelData.realName ? modelData.realName : modelData.name
            }
            valueText: function(modelData) {
                return modelData.name
            }
            currentIndex: userModel.lastIndex
            rowHeight: selectUser.height
            rowFontSize: root.font.pointSize * 0.8
            rowCapitalization: Font.Capitalize
            cornerRadius: root.cornerRadius
            fillColor: root.colorSurface
            textColor: root.colorFg
            highlightedTextColor: root.colorCream
            highlightColor: root.colorPurple
            borderColor: selectUser.active ? root.colorPurpleLight : root.colorMuted
            borderWidth: selectUser.active ? 2 : 1
            shadowColor: root.colorShadow
            restoreFocusItem: username

            onActivated: {
                username.text = currentText
            }
        }

    }

    // PASSWORD INPUT
    Item {
        id: passwordField
        height: root.font.pointSize * root.fieldRowFactor
        width: parent.width * (root.fieldWidthPercent / 100)
        anchors.horizontalCenter: parent.horizontalCenter

        TextField {
            id: password
            anchors.centerIn: parent
            height: root.font.pointSize * root.fieldHeightFactor
            width: parent.width
            focus: config.ForcePasswordFocus == "true" ? true : false
            selectByMouse: true
            echoMode: revealSecret.checked ? TextInput.Normal : TextInput.Password
            placeholderText: config.TranslatePasswordPlaceholder || textConstants.password
            placeholderTextColor: root.colorMuted
            color: root.colorFg
            horizontalAlignment: TextInput.AlignHCenter
            passwordCharacter: "•"
            passwordMaskDelay: config.ForceHideCompletePassword == "true" ? undefined : 1000
            renderType: Text.QtRendering
            background: Rectangle {
                color: "transparent"
                border.color: root.colorMuted
                border.width: parent.activeFocus ? 2 : 1
                radius: Math.min(root.cornerRadius, height / 2)
            }
            Keys.onReturnPressed: submitLogin()
            KeyNavigation.down: revealSecret
        }

        Button {
            id: submitButton
            width: password.height * root.arrowSizeFactor
            height: width
            anchors.right: password.right
            anchors.rightMargin: password.height * root.arrowMarginFactor
            anchors.verticalCenter: password.verticalCenter
            // The arrow glyph sits slightly below the line-box centre.
            anchors.verticalCenterOffset: -root.font.pointSize * root.arrowNudgeFactor
            enabled: username.text != "" && password.text != ""
            hoverEnabled: true
            z: 2
            onClicked: submitLogin()

            contentItem: Text {
                text: "→"
                font.family: root.font.family
                font.pointSize: root.font.pointSize * 1.5
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: root.colorFg
                opacity: submitButton.enabled ? 1 : 0.3
            }

            background: Item {
                HoverFill {
                    anchors.fill: parent
                    anchors.margins: 2
                    radius: height / 2
                    active: submitButton.hovered || submitButton.visualFocus
                    pressed: submitButton.down
                    fillColor: root.colorPurple
                    activeOpacity: 0.16
                    pressedOpacity: 0.26
                }
            }

            states: [
                State {
                    name: "pressed"
                    when: submitButton.down
                    PropertyChanges {
                        target: submitButton.contentItem
                        color: root.colorCream
                        opacity: 1
                    }
                },
                State {
                    name: "hovered"
                    when: submitButton.hovered
                    PropertyChanges {
                        target: submitButton.contentItem
                        color: root.colorPurpleLight
                        opacity: 1
                    }
                },
                State {
                    name: "focused"
                    when: submitButton.visualFocus
                    PropertyChanges {
                        target: submitButton.contentItem
                        color: root.colorPurpleLight
                        opacity: 1
                    }
                }
            ]

            transitions: [
                Transition {
                    PropertyAnimation {
                        properties: "color, opacity"
                        duration: 150
                    }
                }
            ]
        }

        states: [
            State {
                name: "focused"
                when: password.activeFocus
                PropertyChanges {
                    target: password.background
                    border.color: root.colorPurpleLight
                }
                PropertyChanges {
                    target: password
                    color: root.colorPurpleLight
                }
            }
        ]

        transitions: [
            Transition {
                PropertyAnimation {
                    properties: "color, border.color"
                    duration: 150
                }
            }
        ]
    }

    // SHOW/HIDE PASS
    Item {
        id: secretCheckBox
        height: root.font.pointSize * 7
        width: parent.width * (root.fieldWidthPercent / 100)
        anchors.horizontalCenter: parent.horizontalCenter

        CheckBox {
            id: revealSecret
            width: parent.width
            hoverEnabled: true

            indicator: Rectangle {
                id: indicator
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.topMargin: 3
                anchors.leftMargin: 4
                implicitHeight: root.font.pointSize
                implicitWidth: root.font.pointSize
                color: "transparent"
                border.color: root.colorMuted
                border.width: parent.visualFocus ? 2 : 1
                Rectangle {
                    id: dot
                    anchors.centerIn: parent
                    implicitHeight: parent.width - 6
                    implicitWidth: parent.width - 6
                    color: root.colorFg
                    opacity: revealSecret.checked ? 1 : 0
                }
            }

            contentItem: Text {
                id: indicatorLabel
                text: config.TranslateShowPassword || "Show Password"
                anchors.verticalCenter: indicator.verticalCenter
                anchors.verticalCenterOffset: 0
                horizontalAlignment: Text.AlignLeft
                anchors.left: indicator.right
                anchors.leftMargin: indicator.width / 2
                font.pointSize: root.font.pointSize * 0.8
                color: root.colorFg
            }

            Keys.onReturnPressed: toggle()
            KeyNavigation.down: submitButton

            background: Rectangle {
                color: "transparent"
                border.width: parent.visualFocus ? 1 : 0
                border.color: parent.visualFocus ? root.colorPurpleLight : "transparent"
                height: parent.visualFocus ? 2 : 0
                width: (indicator.width + indicatorLabel.contentWidth + indicatorLabel.anchors.leftMargin + 2)
                anchors.top: indicatorLabel.bottom
                anchors.left: parent.left
                anchors.leftMargin: 3
                anchors.topMargin: 8
            }
        }

        states: [
            State {
                name: "pressed"
                when: revealSecret.down
                PropertyChanges {
                    target: revealSecret.contentItem
                    color: root.colorCream
                }
                PropertyChanges {
                    target: dot
                    color: root.colorCream
                }
                PropertyChanges {
                    target: indicator
                    border.color: root.colorPurpleLight
                }
                PropertyChanges {
                    target: revealSecret.background
                    border.color: root.colorPurpleLight
                }
            },
            State {
                name: "hovered"
                when: revealSecret.hovered
                PropertyChanges {
                    target: indicatorLabel
                    color: root.colorPurpleLight
                }
                PropertyChanges {
                    target: indicator
                    border.color: root.colorPurpleLight
                }
                PropertyChanges {
                    target: dot
                    color: root.colorPurpleLight
                }
                PropertyChanges {
                    target: revealSecret.background
                    border.color: root.colorPurpleLight
                }
            },
            State {
                name: "focused"
                when: revealSecret.visualFocus
                PropertyChanges {
                    target: indicatorLabel
                    color: root.colorPurpleLight
                }
                PropertyChanges {
                    target: indicator
                    border.color: root.colorPurpleLight
                }
                PropertyChanges {
                    target: dot
                    color: root.colorPurpleLight
                }
                PropertyChanges {
                    target: revealSecret.background
                    border.color: root.colorPurpleLight
                }
            }
        ]

        transitions: [
            Transition {
                PropertyAnimation {
                    properties: "color, border.color, opacity"
                    duration: 150
                }
            }
        ]

    }

    // ERROR FIELD
    Item {
        height: root.font.pointSize * 2.3
        width: parent.width * (root.fieldWidthPercent / 100)
        anchors.horizontalCenter: parent.horizontalCenter
        Label {
            id: errorMessage
            width: parent.width
            text: failed ? config.TranslateLoginFailed || textConstants.loginFailed + "!" : keyboard.capsLock ? textConstants.capslockWarning : null
            horizontalAlignment: Text.AlignHCenter
            font.pointSize: root.font.pointSize * 0.8
            color: failed ? root.colorRed : root.colorMuted
            opacity: 0
            states: [
                State {
                    name: "fail"
                    when: failed
                    PropertyChanges {
                        target: errorMessage
                        opacity: 1
                    }
                },
                State {
                    name: "capslock"
                    when: keyboard.capsLock
                    PropertyChanges {
                        target: errorMessage
                        opacity: 1
                    }
                }
            ]
            transitions: [
                Transition {
                    PropertyAnimation {
                        properties: "opacity"
                        duration: 100
                    }
                }
            ]
        }
    }

    Connections {
        target: sddm
        function onLoginSucceeded() {}
        function onLoginFailed() {
            failed = true
            resetError.restart()
        }
    }

    Timer {
        id: resetError
        interval: 2000
        onTriggered: failed = false
        running: false
    }
}
