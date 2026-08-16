import QtQuick 2.12
import QtQuick.Controls 2.12
import QtGraphicalEffects 1.12

Item {
    implicitHeight: powerButton.height
    implicitWidth: powerButton.width

    ListModel {
        id: powerModel

        ListElement { name: " " }
        ListElement { name: " " }
        ListElement { name: " " }
    }

    Button {
        id: powerButton

        height: inputHeight
        width: inputHeight
        hoverEnabled: true

        icon.source: Qt.resolvedUrl("../icons/power.svg")
        icon.height: height * 0.55
        icon.width: width * 0.55
        icon.color: "white"

        // Efecto zoom hover
        scale: powerButton.hovered ? 1.15 : 1.05
        Behavior on scale {
            NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
        }

        background: Rectangle {
            id: powerButtonBg

            color: powerButton.hovered || powerButton.down || powerPopup.visible
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
            powerPopup.visible ? powerPopup.close() : powerPopup.open()
        }
    }

    Popup {
        id: powerPopup

        height: inputHeight * 2.2 + padding * 2
        x: powerButton.x - (width + powerList.spacing)
        y: -height + powerButton.height
        padding: 10

        background: Rectangle {
            radius: config.CornerRadius * 1.8
            color: "#11ffffff"
            border.color: "#66ffffff"
            border.width: 0

            layer.enabled: true
            layer.effect: GaussianBlur {
                radius: 2
                samples: 16
            }
        }

        contentItem: ListView {
            id: powerList

            implicitWidth: contentWidth
            spacing: 6
            orientation: Qt.Horizontal
            clip: true

            model: powerModel
            delegate: ItemDelegate {
                id: powerEntry

                height: inputHeight * 2.2
                width: inputHeight * 2.2
                display: AbstractButton.TextUnderIcon

                // Efecto zoom hover en cada opción
                scale: powerEntry.hovered ? 1.0 : 0.8
                Behavior on scale {
                    NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                }

                contentItem: Item {
                    Image {
                        id: powerIcon

                        anchors.centerIn: parent
                        source: index == 0 ? Qt.resolvedUrl("../icons/sleep.svg") : (index == 1 ? Qt.resolvedUrl("../icons/restart.svg") : Qt.resolvedUrl("../icons/power.svg"))
                        sourceSize: Qt.size(powerEntry.width * 0.5, powerEntry.height * 0.5)
                    }

                    ColorOverlay {
                        id: iconOverlay

                        anchors.fill: powerIcon
                        source: powerIcon
                        color: powerEntry.hovered ? "white" : "#ccffffff"

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                    }

                    Text {
                        id: powerText

                        anchors {
                            bottom: parent.bottom
                            bottomMargin: 4
                            horizontalCenter: parent.horizontalCenter
                        }
                        renderType: Text.NativeRendering
                        font.family: config.Font
                        font.pointSize: config.GeneralFontSize
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        color: "white"
                        text: name
                        opacity: powerEntry.hovered ? 1 : 0

                        Behavior on opacity {
                            NumberAnimation { duration: 150 }
                        }
                    }
                }

                background: Rectangle {
                    id: powerEntryBg

                    color: powerEntry.hovered ? "#11ffffff" : "#11ffffff"
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
                        powerPopup.close()
                        index == 0 ? sddm.suspend() : (index == 1 ? sddm.reboot() : sddm.powerOff())
                    }
                }
            }
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
