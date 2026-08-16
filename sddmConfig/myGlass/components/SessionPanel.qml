import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQml.Models 2.12

Item {
    property var session: sessionList.currentIndex

    implicitHeight: sessionButton.height
    implicitWidth: sessionButton.width

    DelegateModel {
        id: sessionWrapper

        model: sessionModel
        delegate: ItemDelegate {
            id: sessionEntry

            height: inputHeight
            width: parent.width
            highlighted: sessionList.currentIndex == index

            // Efecto zoom hover en cada opción
            scale: sessionEntry.hovered ? 1.0 : 0.9
            Behavior on scale {
                NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
            }

            contentItem: Text {
                renderType: Text.NativeRendering
                font.family: config.Font
                font.pointSize: config.GeneralFontSize
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: "white"
                text: name
            }

            background: Rectangle {
                id: sessionEntryBg

                color: highlighted
                       ? "#22ffffff"
                       : (sessionEntry.hovered ? "#11ffffff" : "#11ffffff")
                radius: config.CornerRadius
                border.color: "#44ffffff"
                border.width: 0

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    sessionList.currentIndex = index
                    sessionPopup.close()
                }
            }
        }
    }

    Button {
        id: sessionButton

        height: inputHeight
        width: inputHeight
        hoverEnabled: true

        icon.source: Qt.resolvedUrl("../icons/settings.svg")
        icon.height: height * 0.55
        icon.width: width * 0.55
        icon.color: "white"

        // Efecto zoom hover
        scale: sessionButton.hovered ? 1.20 : 1.05
        Behavior on scale {
            NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
        }

        background: Rectangle {
            id: sessionButtonBg

            color: sessionButton.hovered || sessionButton.down || sessionPopup.visible
                   ? "#11ffffff"
                   : "#11ffffff"
            radius: config.CornerRadius
            border.color: "#66ffffff"
            border.width: 0

            Behavior on color {
                ColorAnimation { duration: 150 }
            }
        }

        onClicked: {
            sessionPopup.visible ? sessionPopup.close() : sessionPopup.open()
        }
    }

    Popup {
        id: sessionPopup

        width: inputWidth + padding * 2
        x: sessionButton.x - (width + sessionList.spacing)
        y: -(contentHeight + padding * 2) + sessionButton.height
        padding: 10

        background: Rectangle {
            radius: config.CornerRadius * 1.0
            color: "#11ffffff"
            border.color: "#66ffffff"
            border.width: 0
        }

        contentItem: ListView {
            id: sessionList

            implicitHeight: contentHeight
            spacing: 6
            model: sessionWrapper
            currentIndex: sessionModel.lastIndex
            clip: true
        }

        enter: Transition {
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: 200
                easing.type: Easing.InOutQuad
            }
        }

        exit: Transition {
            NumberAnimation {
                property: "opacity"
                from: 1
                to: 0
                duration: 200
                easing.type: Easing.InOutQuad
            }
        }
    }
}
