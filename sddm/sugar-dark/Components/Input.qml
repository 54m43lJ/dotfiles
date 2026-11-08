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
import QtQuick.Effects

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

        HoverHandler { id: usernameHover }

        ComboBox {
            id: selectUser

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: root.font.pointSize * root.fieldHeightFactor
            z: 1

            model: userModel
            currentIndex: model.lastIndex
            textRole: "name"
            displayText: ""
            hoverEnabled: true
            onActivated: {
                username.text = currentText
            }

            delegate: ItemDelegate {
                width: parent.width
                anchors.horizontalCenter: parent.horizontalCenter
                contentItem: Text {
		    text: model.realName != "" ? model.realName : model.name
                    font.pointSize: root.font.pointSize * 0.8
                    font.capitalization: Font.Capitalize
                    width: parent.width
                    color: root.palette.text
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }
                highlighted: parent.highlightedIndex === index
                background: Item {
                    HoverFill {
                        anchors.fill: parent
                        anchors.margins: 4
                        radius: root.cornerRadius / 2
                        active: selectUser.highlightedIndex === index
                        fillColor: root.palette.highlight
                        activeOpacity: 0.14
                    }
                }
            }

            indicator: Button {
                id: usernameIcon
                width: parent.height * 0.8
                height: parent.height
                anchors.left: parent.left
                anchors.leftMargin: parent.height * 0.125
                anchors.verticalCenter: parent.verticalCenter
                icon.height: parent.height * 0.25
                icon.width: parent.height * 0.25
                enabled: false
                icon.color: root.palette.text
                icon.source: Qt.resolvedUrl("../Assets/User.svgz")
                background: null
            }

            background: Item {
                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: "transparent"
                    border.width: username.activeFocus || selectUser.visualFocus ? 2 : 1
                    border.color: username.activeFocus || selectUser.visualFocus ? root.palette.highlight : root.palette.text
                    Behavior on border.color { ColorAnimation { duration: 150 } }
                }
                HoverFill {
                    anchors.fill: parent
                    anchors.margins: 2
                    radius: height / 2
                    active: selectUser.hovered || usernameHover.hovered || username.activeFocus
                    pressed: selectUser.down
                    fillColor: root.palette.highlight
                    activeOpacity: 0.12
                    pressedOpacity: 0.2
                }
            }

            popup: ThemedPopup {
                y: parent.height + 8
                rightMargin: config.ForceRightToLeft == "true" ? root.padding + usernameField.width / 2 : undefined
                width: usernameField.width
                implicitHeight: contentItem.implicitHeight
                cornerRadius: root.cornerRadius
                borderColor: Qt.rgba(root.palette.highlight.r, root.palette.highlight.g, root.palette.highlight.b, 0.35)

                contentItem: ListView {
                    clip: true
                    implicitHeight: contentHeight + 20
                    model: selectUser.popup.visible ? selectUser.delegateModel : null
                    currentIndex: selectUser.highlightedIndex
                    ScrollIndicator.vertical: ScrollIndicator { }
                }
            }
        }

        TextField {
            id: username
            text: config.ForceLastUser == "true" ? selectUser.currentText : null
            font.capitalization: Font.Capitalize
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: root.font.pointSize * root.fieldHeightFactor * 0.9
            anchors.rightMargin: root.font.pointSize * root.fieldHeightFactor * 0.9
            anchors.verticalCenter: parent.verticalCenter
            height: root.font.pointSize * root.fieldHeightFactor
            placeholderText: config.TranslateUsernamePlaceholder || textConstants.userName
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
                        color: root.palette.highlight
                    }
                }
            ]
        }

        Item {
            id: usernameIconArea

            width: root.font.pointSize * root.fieldHeightFactor * 0.8
            height: root.font.pointSize * root.fieldHeightFactor
            anchors.left: parent.left
            anchors.leftMargin: root.font.pointSize * root.fieldHeightFactor * 0.125
            anchors.verticalCenter: parent.verticalCenter
            z: 3

            MouseArea {
                anchors.fill: parent
                onClicked: selectUser.popup.open()
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
            horizontalAlignment: TextInput.AlignHCenter
            passwordCharacter: "•"
            passwordMaskDelay: config.ForceHideCompletePassword == "true" ? undefined : 1000
            renderType: Text.QtRendering
            background: Rectangle {
                color: "transparent"
                border.color: root.palette.text
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
                color: root.palette.text
                opacity: submitButton.enabled ? 1 : 0.3
            }

            background: Item {
                HoverFill {
                    anchors.fill: parent
                    anchors.margins: 2
                    radius: height / 2
                    active: submitButton.hovered || submitButton.visualFocus
                    pressed: submitButton.down
                    fillColor: root.palette.highlight
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
                        color: Qt.darker(root.palette.highlight, 1.1)
                        opacity: 1
                    }
                },
                State {
                    name: "hovered"
                    when: submitButton.hovered
                    PropertyChanges {
                        target: submitButton.contentItem
                        color: root.palette.highlight
                        opacity: 1
                    }
                },
                State {
                    name: "focused"
                    when: submitButton.visualFocus
                    PropertyChanges {
                        target: submitButton.contentItem
                        color: root.palette.highlight
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
                    border.color: root.palette.highlight
                }
                PropertyChanges {
                    target: password
                    color: root.palette.highlight
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
                border.color: root.palette.text
                border.width: parent.visualFocus ? 2 : 1
                Rectangle {
                    id: dot
                    anchors.centerIn: parent
                    implicitHeight: parent.width - 6
                    implicitWidth: parent.width - 6
                    color: root.palette.text
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
                color: root.palette.text
            }

            Keys.onReturnPressed: toggle()
            KeyNavigation.down: submitButton

            background: Rectangle {
                color: "transparent"
                border.width: parent.visualFocus ? 1 : 0
                border.color: parent.visualFocus ? root.palette.text : "transparent"
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
                    color: Qt.darker(root.palette.highlight, 1.1)
                }
                PropertyChanges {
                    target: dot
                    color: Qt.darker(root.palette.highlight, 1.1)
                }
                PropertyChanges {
                    target: indicator
                    border.color: Qt.darker(root.palette.highlight, 1.1)
                }
                PropertyChanges {
                    target: revealSecret.background
                    border.color: Qt.darker(root.palette.highlight, 1.1)
                }
            },
            State {
                name: "hovered"
                when: revealSecret.hovered
                PropertyChanges {
                    target: indicatorLabel
                    color: Qt.lighter(root.palette.highlight, 1.1)
                }
                PropertyChanges {
                    target: indicator
                    border.color: Qt.lighter(root.palette.highlight, 1.1)
                }
                PropertyChanges {
                    target: dot
                    color: Qt.lighter(root.palette.highlight, 1.1)
                }
                PropertyChanges {
                    target: revealSecret.background
                    border.color: Qt.lighter(root.palette.highlight, 1.1)
                }
            },
            State {
                name: "focused"
                when: revealSecret.visualFocus
                PropertyChanges {
                    target: indicatorLabel
                    color: root.palette.highlight
                }
                PropertyChanges {
                    target: indicator
                    border.color: root.palette.highlight
                }
                PropertyChanges {
                    target: dot
                    color: root.palette.highlight
                }
                PropertyChanges {
                    target: revealSecret.background
                    border.color: root.palette.highlight
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
            color: root.palette.text
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
