import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.12
import QtGraphicalEffects 1.12

Item {
    property var user: userPanel.username
    property var password: passwordField.text
    property var session: sessionPanel.session
    property var inputHeight: Screen.height * config.LoginScale * 0.25
    property var inputWidth: Screen.width * config.LoginScale
    
    Column {
        spacing: 8

        anchors {
            bottom: parent.bottom
            bottomMargin: 40
            right: parent.right
            rightMargin: 40
        }

        PowerPanel {
            id: powerPanel
        }

        SessionPanel {
            id: sessionPanel
        }
    }

    Column {
        spacing: 8

        width: inputWidth
        anchors {
            top: parent.top
            topMargin: 340  
            right: parent.right
            rightMargin: 110
        }
    
        UserPanel {
            id: userPanel
        }

        PasswordPanel {
            id: passwordField

            height: inputHeight
            width: parent.width

            onAccepted: {
                loginButton.clicked()
                passwordField.visible = false
                loginButton.visible = false
                
                fingerprintIcon.visible = true
                fingerprintIcon.playing = true

                restoreTimer.start()
            }   
        }

        Timer {
            id: restoreTimer
            interval: 10000
            repeat: false
            onTriggered: {
                passwordField.visible = true
                loginButton.visible = true
                fingerprintIcon.visible = false
                fingerprintIcon.playing = false
            }
        }

        Button {
            id: loginButton
            
            height: inputHeight
            width: parent.width

            enabled: user != "" && password != "" ? true : false
            hoverEnabled: true
            text: config.LoginButtonText

            // Efecto zoom hover
            scale: loginButton.hovered ? 1.05 : 1.0
            Behavior on scale {
                NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
            }

            contentItem: Text {
                id: buttonText

                renderType: Text.NativeRendering
                font.family: config.Font
                font.pointSize: config.GeneralFontSize
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                color: "white"
                opacity: loginButton.enabled ? 1.0 : 0.5
                text: config.LoginButtonText

                Behavior on opacity {
                    NumberAnimation { duration: 150 }
                }
            }
        
            background: Rectangle {
                id: buttonBackground

                color: loginButton.down
                       ? "#66ffffff"
                       : (loginButton.hovered ? "#55ffffff" : "#33ffffff")
                radius: config.CornerRadius
                border.color: "#66ffffff"
                border.width: 0
                opacity: loginButton.enabled ? 1.0 : 0.5

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }

            Rectangle {
                id: loginAnim

                radius: parent.width / 2
                anchors.centerIn: loginButton
                color: "black"
                opacity: 1

                NumberAnimation {
                    id: coverScreen

                    target: loginAnim
                    properties: "height, width"
                    from: 0
                    to: parent.width * 2
                    duration: 1000
                    easing.type: Easing.InExpo
                }
            }

            onClicked: sddm.login(user, password, session)
        }
    }

    Item {
        id: fingerprintIcon
        
        visible: false

        width: 200
        height: 200

        anchors {
            bottom: parent.bottom
            bottomMargin: 280
            right: parent.right
            rightMargin: 180
        }

        property int frameIndex: 0
        property int totalFrames: 95
        property int fps: 24
        property bool playing: false

        Image {
            id: logoFrame
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            cache: true

            smooth: true
            mipmap: true
            antialiasing: true

            source: "../AnimationFingerPrint/AnimacionHuella_" + ("00000" + (fingerprintIcon.frameIndex + 1)).slice(-5) + ".png"
        }

        Timer {
            id: frameTimer
            interval: 1000 / fingerprintIcon.fps
            repeat: true
            running: fingerprintIcon.playing

            onTriggered: {
                if (fingerprintIcon.frameIndex < fingerprintIcon.totalFrames - 1) {
                    fingerprintIcon.frameIndex++
                } else {
                    fingerprintIcon.frameIndex = 0
                }
            }
        }
    }
    
    Item {
        width: 50
        height: 50

        anchors {
            top: parent.top
            topMargin: 15
            right: parent.right
            rightMargin: 15
        }
        Image {
            id: logoArch
            anchors.fill: parent
            source: "../icons/arch-linux.svg" 
            visible: false
            smooth: true
            mipmap: true
        }
        ColorOverlay {
        anchors.fill: logoArch
        source: logoArch
        color: config.TextFieldTextColor
    }        
    }

    Connections {
        target: sddm
        function onLoginSucceeded() {
            coverScreen.start()
        }
        function onLoginFailed() {
            passwordField.text = ""
        }
    }
}
