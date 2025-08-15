import QtQuick 2.15
import QtMultimedia 5.8
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.12
Item {
    id: musicPlayer
    width: parent.width
    height: parent.height
    z: 999
    property bool isPlaying: false
    property real volume: 0.03
    property real displayVolume: Math.pow(volume, 0.3)
    property int currentTrackIndex: 0
    property string currentTrackName: ""
    property real trackDuration: 0
    property real trackPosition: 0
    property bool shuffleEnabled: true
    property real lastVolumeBeforeMute: 0.03
    property var playedTracks: []
    property var musicTracks: [
    ]

    signal playbackStateChanged()

    Component.onCompleted: {
        loadMusicList()
    }

    function loadMusicList() {
        var hardcodedTracks = [
            "assets/music/Crazy Taxi.mp3",
            "assets/music/Jester Elysium.mp3",
            "assets/music/Sonic the Hedgehog 3.mp3",
            "assets/music/Sled Storm.mp3",
            "assets/music/TOCA Ingame.mp3",
            "assets/music/Mortal Kombat.mp3"
        ]
        var availableTracks = []
        for (var i = 0; i < hardcodedTracks.length; i++) {
            availableTracks.push(hardcodedTracks[i])
        }

        musicTracks = availableTracks
        if (musicTracks.length > 0) initializePlayer()
    }

    MediaPlayer {
        id: audioPlayer
        autoPlay: false
        volume: musicPlayer.volume

        onStatusChanged: {
            if (status === MediaPlayer.EndOfMedia) {
                nextTrack()
            } else if (status === MediaPlayer.Loaded) {
                musicPlayer.trackDuration = duration
                if (musicPlayer.isPlaying) {
                    audioPlayer.play()
                }
            } else if (status === MediaPlayer.InvalidMedia) {
                nextTrack()
            }
        }

        onPlaybackStateChanged: {
            musicPlayer.isPlaying = (playbackState === MediaPlayer.PlayingState)
            musicPlayer.playbackStateChanged()
        }

        onPositionChanged: {
            musicPlayer.trackPosition = position
        }

        onError: {
            nextTrack()
        }
    }

    Timer {
        id: positionTimer
        interval: 1000
        running: musicPlayer.isPlaying
        repeat: true
        onTriggered: musicPlayer.trackPosition = audioPlayer.position
    }

    Timer {
        id: initTimer
        interval: 1000
        running: true
        repeat: false
        onTriggered: {
            if (musicTracks.length > 0) {
                initializePlayer()
                Qt.callLater(function() {
                    play()
                })
            }
        }
    }

    function initializePlayer() {
        if (musicTracks.length > 0) {
            playedTracks = []
            if (shuffleEnabled) {
                currentTrackIndex = Math.floor(Math.random() * musicTracks.length)
            } else {
                currentTrackIndex = 0
            }
            loadCurrentTrack()
        }
    }

    function loadCurrentTrack() {
        if (currentTrackIndex >= 0 && currentTrackIndex < musicTracks.length) {
            const trackPath = musicTracks[currentTrackIndex]
            audioPlayer.source = trackPath

            const fileName = trackPath.split('/').pop().replace(/\.[^/.]+$/, "")
            currentTrackName = fileName.replace(/_/g, " ")
            .replace(/-/g, " ")
            .replace(/\d+/g, "")
            .trim()

            if (currentTrackName === "") {
                currentTrackName = "Track " + (currentTrackIndex + 1)
            }
        }
    }

    function play() {
        if (musicTracks.length > 0) {
            isPlaying = true
            audioPlayer.play()
        }
    }

    function pause() {
        isPlaying = false
        audioPlayer.pause()
    }

    function togglePlayPause() {
        if (isPlaying) {
            pause()
        } else {
            play()
        }
    }

    function nextTrack() {
        if (musicTracks.length === 0) {
            return
        }

        var wasPlaying = isPlaying

        if (shuffleEnabled) {
            if (playedTracks.length >= musicTracks.length) {
                playedTracks = []
            }

            let attempts = 0
            var newTrackIndex
            do {
                newTrackIndex = Math.floor(Math.random() * musicTracks.length)
                attempts++
                if (attempts >= musicTracks.length * 2) break
            } while (playedTracks.includes(newTrackIndex) && musicTracks.length > 1)

            currentTrackIndex = newTrackIndex
            playedTracks.push(currentTrackIndex)
        } else {
            currentTrackIndex = (currentTrackIndex + 1) % musicTracks.length
        }
        loadCurrentTrack()

        if (wasPlaying) {
            Qt.callLater(function() {
                play()
            })
        }
    }

    function previousTrack() {
        if (musicTracks.length === 0) return

            var wasPlaying = isPlaying

            if (shuffleEnabled && playedTracks.length > 1) {
                playedTracks.pop()
                currentTrackIndex = playedTracks[playedTracks.length - 1] || 0
                if (playedTracks.length > 0) {
                    playedTracks.pop()
                }
            } else {
                currentTrackIndex = currentTrackIndex > 0 ? currentTrackIndex - 1 : musicTracks.length - 1
            }

            loadCurrentTrack()

            if (wasPlaying) {
                Qt.callLater(function() {
                    play()
                })
            }
    }

    function setVolume(newVolume) {
        if (newVolume > 0) {
            lastVolumeBeforeMute = newVolume
        }
        volume = Math.max(0, Math.min(1, newVolume))
        displayVolume = Math.pow(volume, 0.3)
        audioPlayer.volume = volume
    }

    function toggleShuffle() {
        shuffleEnabled = !shuffleEnabled
        playedTracks = []
        if (shuffleEnabled) {
            playedTracks.push(currentTrackIndex)
        }
    }

    Rectangle {
        id: playerBackground
        anchors.fill: parent
        color: "black"
        opacity: 0.3
        radius: parent.height * 0.15
        border.color: "transparent"
    }

    Row {
        anchors.fill: parent
        anchors.margins: parent.height * 0.15
        spacing: parent.width * 0.05

        Row {
            id: playerControls
            spacing: musicPlayer.width * 0.01
            width: parent.width * 0.5

            Rectangle {
                width: musicPlayer.height * 0.6
                height: width
                color: "transparent"
                border.color: "white"
                border.width: Math.max(1, width * 0.03)
                radius: width / 2
                opacity: 0.8

                Image {
                    id: prevIcon
                    anchors.centerIn: parent
                    source: "assets/icons/prev.png"
                    width: parent.width * 0.6
                    height: width
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                    visible: status === Image.Ready
                }

                Text {
                    anchors.centerIn: parent
                    text: "⏮"
                    color: "white"
                    font.pixelSize: parent.width * 0.4
                    visible: prevIcon.status !== Image.Ready
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: musicPlayer.previousTrack()
                    onPressed: parent.opacity = 0.5
                    onReleased: parent.opacity = 0.8
                }
            }

            Rectangle {
                width: musicPlayer.height * 0.8
                height: width
                color: "transparent"
                border.color: "white"
                border.width: Math.max(2, width * 0.05)
                radius: width / 2
                opacity: 0.9

                Image {
                    id: playPauseIcon
                    anchors.centerIn: parent
                    source: musicPlayer.isPlaying ? "assets/icons/pause.png" : "assets/icons/play.png"
                    width: parent.width * 0.6
                    height: width
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                    visible: status === Image.Ready
                }

                Text {
                    anchors.centerIn: parent
                    text: musicPlayer.isPlaying ? "⏸" : "▶"
                    color: "white"
                    font.pixelSize: parent.width * 0.4
                    visible: playPauseIcon.status !== Image.Ready
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: musicPlayer.togglePlayPause()
                    onPressed: parent.opacity = 0.5
                    onReleased: parent.opacity = 0.9
                }
            }

            Rectangle {
                width: musicPlayer.height * 0.6
                height: width
                color: "transparent"
                border.color: "white"
                border.width: Math.max(1, width * 0.03)
                radius: width / 2
                opacity: 0.8

                Image {
                    id: nextIcon
                    anchors.centerIn: parent
                    source: "assets/icons/next.png"
                    width: parent.width * 0.6
                    height: width
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                    visible: status === Image.Ready
                }

                Text {
                    anchors.centerIn: parent
                    text: "⏭"
                    color: "white"
                    font.pixelSize: parent.width * 0.4
                    visible: nextIcon.status !== Image.Ready
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: musicPlayer.nextTrack()
                    onPressed: parent.opacity = 0.5
                    onReleased: parent.opacity = 0.8
                }
            }

            Rectangle {
                width: musicPlayer.height * 0.5
                height: width
                color: musicPlayer.shuffleEnabled ? "white" : "transparent"
                border.color: "white"
                border.width: Math.max(1, width * 0.03)
                radius: width / 2
                opacity: 0.8

                Image {
                    id: shuffleIcon
                    anchors.centerIn: parent
                    source: "assets/icons/shuffle.png"
                    width: parent.width * 0.5
                    height: width
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                    visible: status === Image.Ready

                    ColorOverlay {
                        anchors.fill: parent
                        source: parent
                        color: musicPlayer.shuffleEnabled ? "black" : "white"
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: "🔀"
                    color: musicPlayer.shuffleEnabled ? "black" : "white"
                    font.pixelSize: parent.width * 0.3
                    visible: shuffleIcon.status !== Image.Ready
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: musicPlayer.toggleShuffle()
                    onPressed: parent.opacity = 0.4
                    onReleased: parent.opacity = 0.7
                }
            }
        }

        Column {
            id: volumeAndTrackInfo
            spacing: parent.height * 0.08
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width * 0.45

            Row {
                id: volumeControl
                spacing: parent.width * 0.05
                width: parent.width

                Image {
                    id: volumeIcon
                    anchors.verticalCenter: parent.verticalCenter
                    source: musicPlayer.volume === 0 ? "assets/icons/mute.png" : "assets/icons/volume.png"
                    width: musicPlayer.height * 0.4
                    height: width
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                    visible: status === Image.Ready

                    MouseArea {
                        anchors.fill: parent
                        onClicked: musicPlayer.setVolume(musicPlayer.volume === 0 ? musicPlayer.lastVolumeBeforeMute : 0)
                    }
                }

                Text {
                    text: musicPlayer.volume === 0 ? "🔇" : "🔊"
                    color: "white"
                    font.pixelSize: musicPlayer.height * 0.4
                    anchors.verticalCenter: parent.verticalCenter
                    visible: volumeIcon.status !== Image.Ready

                    MouseArea {
                        anchors.fill: parent
                        onClicked: musicPlayer.setVolume(musicPlayer.volume === 0 ? 0.3 : 0)
                    }
                }

                Rectangle {
                    width: parent.width * 0.7
                    height: musicPlayer.height * 0.15
                    color: "gray"
                    opacity: 0.8
                    radius: height / 2
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        width: parent.width * musicPlayer.displayVolume
                        height: parent.height
                        color: "white"
                        radius: parent.radius
                    }

                    Rectangle {
                        width: height * 1.0
                        height: parent.height * 1.8
                        radius: width / 2
                        color: "white"
                        x: parent.width * musicPlayer.displayVolume - width/2
                        y: (parent.height - height) / 2
                        visible: parent.width > 0
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            const displayPosition = mouse.x / parent.width
                            const newVolume = Math.pow(displayPosition, 3.33)
                            musicPlayer.setVolume(newVolume)
                        }

                        onPositionChanged: {
                            if (pressed) {
                                const displayPosition = Math.max(0, Math.min(1, mouse.x / parent.width))
                                const newVolume = Math.pow(displayPosition, 3.33)
                                musicPlayer.setVolume(newVolume)
                            }
                        }
                    }
                }
            }

            Text {
                width: parent.width
                text: musicPlayer.currentTrackName || "There is no music"
                color: "white"
                font.pixelSize: Math.max(8, musicPlayer.height * 0.25)
                font.bold: true
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }
}
