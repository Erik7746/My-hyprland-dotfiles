import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.12
import QtGraphicalEffects 1.12
import QtMultimedia 5.12
import "components"

Item {
    id: root
    height: Screen.height
    width: Screen.width

    readonly property var videoExts: ["mp4", "webm", "mkv", "avi", "mov"]

    function fileExt(path) {
        var parts = path.split(".")
        return parts[parts.length - 1].toLowerCase()
    }

    Component.onCompleted: {
        var chosen = (config.RandomBackground === "true") ? pickRandom() : config.Background
        applyBackground(chosen)
    }

    function pickRandom() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", Qt.resolvedUrl("backgrounds/index.txt"), false)
        xhr.send()

        if (xhr.status === 0 || xhr.responseText === "") {
            console.log("SDDM Theme: backgrounds/index.txt no encontrado, usando Background del config")
            return config.Background
        }

        var lines = xhr.responseText.split("\n")
        var files = []
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()
            if (line.length > 0) files.push(line)
        }

        if (files.length === 0) return config.Background

        var idx = Math.floor(Math.random() * files.length)
        return "backgrounds/" + files[idx]
    }

    function applyBackground(path) {
        var ext = fileExt(path)
        if (videoExts.indexOf(ext) !== -1) {
            bgImage.visible = false
            bgVideo.visible = true
            bgMediaPlayer.source = Qt.resolvedUrl(path)
            bgMediaPlayer.play()
        } else {
            bgMediaPlayer.stop()
            bgVideo.visible = false
            bgImage.visible = true
            bgImage.source = Qt.resolvedUrl(path)
        }
    }

    // ── Fondo negro base ──────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: "black"
        z: -1
    }

    // ── Fondo: Imagen ────────────────────────────────────────────────────────
    Image {
        id: bgImage
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: false
        cache: true
        mipmap: true
        clip: true
        visible: true
    }

    // ── Fondo: Video ─────────────────────────────────────────────────────────
    MediaPlayer {
        id: bgMediaPlayer
        autoPlay: false
        muted: true

        // Reinicio manual cerca del final
        onPositionChanged: {
            if (duration > 0 && position >= duration - 1000) {
                seek(0)
                play()
            }
        }

        onStopped: {
            seek(0)
            play()
        }
    }

    VideoOutput {
        id: bgVideo
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop
        source: bgMediaPlayer
        visible: false
    }

    // ── Panel Frosted ─────────────────────────────────────────────────────────
    Item {
        id: frostedPanel
        width: 600
        anchors {
            top: parent.top
            bottom: parent.bottom
            right: parent.right
        }
        layer.enabled: true

        ShaderEffectSource {
            id: bgSlice
            sourceItem: bgImage.visible ? bgImage : bgVideo
            sourceRect: Qt.rect(frostedPanel.x, frostedPanel.y,
                                frostedPanel.width, frostedPanel.height)
            live: true
            hideSource: false
        }

        GaussianBlur {
            id: blur
            anchors.fill: parent
            source: bgSlice
            radius: 22
            samples: 32
            cached: false
        }

        Rectangle {
            anchors.fill: parent
            color: "#111111"
            opacity: 0.4
        }
    }

    // ── Contenido ─────────────────────────────────────────────────────────────
    Item {
        id: contentPanel
        anchors.fill: parent

        DateTimePanel {
            id: dateTimePanel
            anchors {
                top: parent.top
                right: parent.right
                topMargin: 20
                rightMargin: 140
            }
        }

        LoginPanel {
            id: loginPanel
            anchors.fill: parent
        }
    }
}
