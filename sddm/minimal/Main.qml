// Minimal SDDM greeter.
// Depends only on QtQuick (a hard dependency of the sddm package itself),
// so it cannot be broken by unrelated Qt module updates.
// Colors from palette/README.md (dark mode).
import QtQuick

Rectangle {
    id: root

    readonly property color cBg: "#231F1F"
    readonly property color cSurface: "#3E3542"
    readonly property color cFg: "#D6CAB6"
    readonly property color cMuted: "#B0B4BC"
    readonly property color cPurpleLight: "#E593E7"
    readonly property color cGold: "#9D7E4D"
    readonly property color cCream: "#FFF7E4"
    readonly property color cRed: "#CC2A47"

    // Scale UI from a 1080p baseline so 4K screens stay readable.
    // If Qt HiDPI scaling is enabled, Screen already reports logical pixels
    // and the ratio stays 1.0 while Qt scales fonts -- both paths converge.
    readonly property real uiScale: Math.min(3, Math.max(1, Screen.desktopAvailableHeight / 1080))

    property int sessionIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
    property var sessionNames: []
    property int sessionCount: 0
    property var userNames: []
    property int userCount: 0
    property int selectedUser: userModel.lastIndex >= 0 ? userModel.lastIndex : 0

    function currentUser() {
        return userCount > 0 ? userNames[selectedUser] : userModel.lastUser
    }

    function cycleSession() {
        if (sessionCount > 0)
            sessionIndex = (sessionIndex + 1) % sessionCount
    }

    function doLogin() {
        if (password.text === "")
            return
        sddm.login(currentUser(), password.text, sessionIndex)
    }

    width: 640
    height: 480
    color: cBg

    Image {
        anchors.fill: parent
        source: "Background.jpg"
        fillMode: Image.PreserveAspectCrop
    }

    // Click on the background closes the user dropdown
    MouseArea {
        anchors.fill: parent
        z: 1
        visible: userSelect.open
        enabled: userSelect.open
        onClicked: userSelect.open = false
    }

    // Full-height form panel on the right
    Rectangle {
        id: panel

        z: 2
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: Math.min(parent.width * 0.4, 600 * root.uiScale)
        color: "#D9231F1F"

        Column {
            id: formColumn
            anchors.centerIn: parent
            spacing: 16 * root.uiScale

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 4 * root.uiScale

                Text {
                    id: clock
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: root.cFg
                    font.pixelSize: 72 * root.uiScale
                    font.weight: Font.Light
                    text: Qt.formatTime(new Date(), "HH:mm")
                }

                Text {
                    id: dateLabel
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: root.cMuted
                    font.pixelSize: 17 * root.uiScale
                    text: Qt.formatDate(new Date(), "dddd, MMMM d")
                }

                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    triggeredOnStart: true
                    onTriggered: {
                        clock.text = Qt.formatTime(new Date(), "HH:mm")
                        dateLabel.text = Qt.formatDate(new Date(), "dddd, MMMM d")
                    }
                }
            }

            Item { width: 1; height: 14 * root.uiScale }

            Rectangle {
                width: 280 * root.uiScale
                height: 1
                anchors.horizontalCenter: parent.horizontalCenter
                color: root.cGold
            }

            Item { width: 1; height: 8 * root.uiScale }

            // User selector
            Item {
                id: userSelect
                property bool open: false

                z: 10
                width: 280 * root.uiScale
                height: 44 * root.uiScale

                Rectangle {
                    anchors.fill: parent
                    radius: 4
                    color: root.cSurface
                    border.width: 1
                    border.color: userSelect.open ? root.cCream : root.cGold
                    Behavior on border.color { ColorAnimation { duration: 120 } }
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 14 * root.uiScale
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 60 * root.uiScale
                    color: root.cCream
                    font.pixelSize: 16 * root.uiScale
                    elide: Text.ElideRight
                    text: root.currentUser()
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 14 * root.uiScale
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.cMuted
                    font.pixelSize: 14 * root.uiScale
                    text: userSelect.open ? "▴" : "▾"
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: userSelect.open = !userSelect.open
                }

                Rectangle {
                    id: dropdown
                    visible: userSelect.open
                    anchors.top: parent.bottom
                    anchors.topMargin: 4 * root.uiScale
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width
                    height: userListColumn.implicitHeight + 12 * root.uiScale
                    radius: 6
                    color: "#F0231F1F"
                    border.color: root.cGold
                    border.width: 1

                    Column {
                        id: userListColumn
                        anchors.centerIn: parent
                        width: parent.width - 8 * root.uiScale
                        spacing: 2 * root.uiScale

                        Repeater {
                            model: root.userCount

                            delegate: Item {
                                width: userListColumn.width
                                height: 34 * root.uiScale

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 4
                                    color: userDelegateArea.containsMouse ? root.cSurface : "transparent"
                                }

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 10 * root.uiScale
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 20 * root.uiScale
                                    color: index === root.selectedUser ? root.cPurpleLight : root.cFg
                                    font.pixelSize: 15 * root.uiScale
                                    elide: Text.ElideRight
                                    text: root.userNames[index]
                                }

                                MouseArea {
                                    id: userDelegateArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.selectedUser = index
                                        password.text = ""
                                        userSelect.open = false
                                        password.forceActiveFocus()
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Password box
            Rectangle {
                width: 280 * root.uiScale
                height: 48 * root.uiScale
                anchors.horizontalCenter: parent.horizontalCenter
                radius: 4
                color: root.cSurface
                border.width: 1
                border.color: password.activeFocus ? root.cCream : root.cGold
                Behavior on border.color { ColorAnimation { duration: 120 } }

                TextInput {
                    id: password
                    anchors.fill: parent
                    anchors.leftMargin: 14 * root.uiScale
                    anchors.rightMargin: 14 * root.uiScale
                    verticalAlignment: TextInput.AlignVCenter
                    color: root.cFg
                    font.pixelSize: 17 * root.uiScale
                    clip: true
                    echoMode: TextInput.Password
                    focus: true
                    onAccepted: root.doLogin()
                    onTextChanged: {
                        errorBox.opacity = 0
                        userSelect.open = false
                    }
                    Keys.onEscapePressed: userSelect.open = false

                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        color: root.cMuted
                        font.pixelSize: 16 * root.uiScale
                        text: "Password"
                        visible: password.text === "" && !password.activeFocus
                    }
                }
            }

            Rectangle {
                id: errorBox
                anchors.horizontalCenter: parent.horizontalCenter
                radius: 4
                color: root.cRed
                width: errorLabel.implicitWidth + 24 * root.uiScale
                height: 30 * root.uiScale
                opacity: 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 150 } }

                Text {
                    id: errorLabel
                    anchors.centerIn: parent
                    color: root.cCream
                    font.pixelSize: 14 * root.uiScale
                    text: "Login failed"
                }
            }

            Item { width: 1; height: 8 * root.uiScale }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 10 * root.uiScale

                Text {
                    id: sessionText
                    color: sessionArea.containsMouse ? root.cPurpleLight : root.cMuted
                    font.pixelSize: 15 * root.uiScale
                    text: sessionCount > 0 ? sessionNames[sessionIndex] : ""
                    Behavior on color { ColorAnimation { duration: 120 } }

                    MouseArea {
                        id: sessionArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.cycleSession()
                    }
                }

                Text {
                    color: root.cMuted
                    font.pixelSize: 15 * root.uiScale
                    text: "·"
                }

                Text {
                    color: shutdownArea.containsMouse ? root.cCream : root.cMuted
                    font.pixelSize: 15 * root.uiScale
                    opacity: sddm.canPowerOff ? 1 : 0.3
                    text: "Shut down"
                    Behavior on color { ColorAnimation { duration: 120 } }

                    MouseArea {
                        id: shutdownArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (sddm.canPowerOff) sddm.powerOff()
                    }
                }

                Text {
                    color: root.cMuted
                    font.pixelSize: 15 * root.uiScale
                    text: "·"
                }

                Text {
                    color: rebootArea.containsMouse ? root.cCream : root.cMuted
                    font.pixelSize: 15 * root.uiScale
                    opacity: sddm.canReboot ? 1 : 0.3
                    text: "Reboot"
                    Behavior on color { ColorAnimation { duration: 120 } }

                    MouseArea {
                        id: rebootArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (sddm.canReboot) sddm.reboot()
                    }
                }
            }
        }
    }

    // Build user/session name lists (C++ models expose no count property)
    Repeater {
        model: sessionModel
        delegate: Item {
            Component.onCompleted: {
                root.sessionNames.push(name)
                root.sessionCount = root.sessionNames.length
            }
        }
    }

    Repeater {
        model: userModel
        delegate: Item {
            Component.onCompleted: {
                root.userNames.push(name)
                root.userCount = root.userNames.length
            }
        }
    }

    Connections {
        target: sddm

        function onLoginFailed() {
            errorLabel.text = "Login failed"
            errorBox.opacity = 1
            hideError.restart()
            password.text = ""
            password.forceActiveFocus()
        }

        function onInformationMessage(message) {
            errorLabel.text = message
            errorBox.opacity = 1
            hideError.restart()
        }
    }

    Timer {
        id: hideError
        interval: 4000
        onTriggered: errorBox.opacity = 0
    }
}
