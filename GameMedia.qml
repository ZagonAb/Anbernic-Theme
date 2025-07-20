import QtQuick 2.15
import QtMultimedia 5.15
import SortFilterProxyModel 0.2

Item {
    id: gameMediaContainer
    anchors {
        left: parent.left
        leftMargin: parent.width * 0.4 + 40
        right: parent.right
        rightMargin: 20
        verticalCenter: parent.verticalCenter
    }
    height: parent.height * 0.70

    property string currentSource: ""
    property int currentMediaType: 0
    property bool isVideoType: false
    property var availableMediaTypes: []
    property var mediaTypeNames: {
        "boxFront": qsTr("Box Front"),
        "boxBack": qsTr("Box Back"),
        "boxSpine": qsTr("Box Spine"),
        "boxFull": qsTr("Full Box"),
        "cartridge": qsTr("Cartridge"),
        "logo": qsTr("Logo"),
        "marquee": qsTr("Marquee"),
        "bezel": qsTr("Bezel"),
        "panel": qsTr("Panel"),
        "cabinetLeft": qsTr("Cabinet Left"),
        "cabinetRight": qsTr("Cabinet Right"),
        "tile": qsTr("Tile"),
        "banner": qsTr("Banner"),
        "steam": qsTr("Steam Grid"),
        "poster": qsTr("Poster"),
        "background": qsTr("Background"),
        "screenshot": qsTr("Screenshot"),
        "titlescreen": qsTr("Title Screen"),
        "video": qsTr("Video"),
        "info": qsTr("Game Info")
    }

    property real savedVolume: api.memory.has("volume") ? api.memory.get("volume") : 0.03
    property real displayVolume: Math.pow(savedVolume, 0.3)
    property bool isMuted: api.memory.has("muted") ? api.memory.get("muted") : false

    function displayToVolume(displayPos) {
        return Math.pow(displayPos, 3.33)
    }

    function setVideoVolume(newVolume) {
        savedVolume = Math.max(0.01, Math.min(1.0, newVolume))
        displayVolume = Math.pow(savedVolume, 0.3)
        api.memory.set("volume", savedVolume)

        if (videoLoader.item && videoLoader.item.children && videoLoader.item.children.length > 0) {
            var videoOutput = videoLoader.item.children[0]
            if (videoOutput && videoOutput.mediaPlayer && !isMuted) {
                videoOutput.mediaPlayer.volume = savedVolume
            }
        }
    }

    Loader {
        id: infoLoader
        anchors.fill: parent
        active: false
        sourceComponent: GameInfo {
            game: gameListView.game
        }
    }

    Connections {
        target: gameListView
        function onUpdateImageSource(newSource) {
            if (currentSource === newSource) return;

            if (isVideoType) {
                resetMedia();
            }

            currentSource = newSource;

            if (availableMediaTypes[currentMediaType] === "video" || newSource.endsWith(".mp4") || newSource.endsWith(".avi")) {
                gameImage.source = "";
                videoLoader.active = true;
            } else {
                videoLoader.active = false;
                gameImage.source = currentSource;
            }
        }

        function onUpdateMediaType(mediaType) {
            currentMediaType = mediaType;
            isVideoType = (availableMediaTypes[currentMediaType] === "video");

            if (isVideoType) {
                gameImage.source = "";
                gameImage.visible = false;
                infoLoader.active = false;
                if (videoLoader.active) videoLoader.active = false;
                Qt.callLater(() => { videoLoader.active = true; });
            }
            else if (availableMediaTypes[currentMediaType] === "info") {
                gameImage.visible = false;
                infoLoader.active = true;
                if (videoLoader.active) videoLoader.active = false;
            }
            else {
                infoLoader.active = false;
                if (videoLoader.active) videoLoader.active = false;
                gameImage.visible = true;
                if (currentSource) {
                    gameImage.source = "";
                    Qt.callLater(() => { gameImage.source = currentSource; });
                }
            }
        }

        function onUpdateAvailableMediaTypes(types) {
            availableMediaTypes = types;
            if (currentMediaType >= availableMediaTypes.length) {
                currentMediaType = 0;
                gameListView.currentMediaType = 0;
            }
            isVideoType = (availableMediaTypes[currentMediaType] === "video");
        }
    }

    Connections {
        target: systemView
        function onCurrentIndexChanged() {
            resetToDefault();
            Qt.callLater(function() {
                if (gameListView.game) {
                    gameListView.updateGameImage();
                }
            });
        }
    }

    Image {
        id: gameImage
        anchors.fill: parent
        source: ""
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        mipmap: true
        visible: !isVideoType && source !== ""
    }

    Loader {
        id: videoLoader
        anchors.fill: parent
        active: false
        property var videoComponent: Component {
            Item {
                anchors.fill: parent

                VideoOutput {
                    id: videoOutput
                    anchors.fill: parent
                    fillMode: VideoOutput.PreserveAspectFit

                    property alias mediaPlayer: player

                    source: MediaPlayer {
                        id: player
                        source: currentSource
                        autoPlay: true
                        loops: MediaPlayer.Infinite
                        volume: isMuted ? 0 : savedVolume

                        onStatusChanged: {
                            if (status === MediaPlayer.EndOfMedia) {
                                videoLoader.active = false;
                                Qt.callLater(function() {
                                    if (gameListView.game && gameListView.game.assets) {
                                        currentSource = gameListView.getCurrentMediaSource();
                                        if (currentSource && !isVideoType) {
                                            gameImage.source = "";
                                            gameImage.source = currentSource;
                                        }
                                    }
                                });
                            }
                            else if (status === MediaPlayer.Loaded) {
                                if (videoLoader.active && availableMediaTypes[gameListView.currentMediaType] === "video") {
                                    play();
                                }
                            }
                        }

                        onErrorChanged: {
                            if (error !== MediaPlayer.NoError) {
                                console.log("Error en video:", errorString);
                                videoLoader.active = false;
                            }
                        }
                    }

                    onVisibleChanged: {
                        if (!visible && player.playbackState === MediaPlayer.PlayingState) {
                            player.stop();
                        }
                    }

                    Component.onDestruction: {
                        if (player.playbackState === MediaPlayer.PlayingState) {
                            player.stop();
                        }
                        player.source = "";
                    }
                }

                Item {
                    id: volumeControls
                    anchors {
                        right: parent.right
                        rightMargin: parent.width * 0.05
                        verticalCenter: parent.verticalCenter
                    }
                    width: 40
                    height: parent.height * 0.6
                    visible: videoOutput.visible

                    Rectangle {
                        id: volumeBackground
                        anchors.fill: parent
                        radius: 8
                        color: "#40000000"
                        border.color: "#60FFFFFF"
                        border.width: 1
                        opacity: volumeMouseArea.containsMouse || muteButton.hovered ? 1.0 : 0.3

                        Behavior on opacity {
                            NumberAnimation { duration: 200 }
                        }
                    }

                    Item {
                        id: muteButton
                        anchors {
                            top: parent.top
                            topMargin: 8
                            horizontalCenter: parent.horizontalCenter
                        }
                        width: 24
                        height: 24

                        property bool hovered: muteMouseArea.containsMouse

                        Image {
                            anchors.fill: parent
                            source: isMuted ? "assets/icons/mute.png" : "assets/icons/volume.png"
                            fillMode: Image.PreserveAspectFit
                            opacity: parent.hovered ? 1.0 : 0.8

                            Behavior on opacity {
                                NumberAnimation { duration: 150 }
                            }
                            mipmap: true
                        }

                        MouseArea {
                            id: muteMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                isMuted = !isMuted;
                                api.memory.set("muted", isMuted);
                                player.volume = isMuted ? 0 : savedVolume;
                            }
                        }
                    }

                    Item {
                        id: volumeSlider
                        anchors {
                            top: muteButton.bottom
                            topMargin: 10
                            bottom: parent.bottom
                            bottomMargin: 8
                            horizontalCenter: parent.horizontalCenter
                        }
                        width: 10

                        Rectangle {
                            id: volumeTrack
                            anchors.fill: parent
                            radius: width / 2
                            color: "#40FFFFFF"
                        }

                        Rectangle {
                            id: volumeLevel
                            anchors {
                                bottom: parent.bottom
                                horizontalCenter: parent.horizontalCenter
                            }
                            width: parent.width
                            height: parent.height * (isMuted ? 0 : displayVolume)
                            radius: width / 2
                            color: isMuted ? "#FF6B6B" : "#FFFFFF"

                            Behavior on height {
                                NumberAnimation { duration: 100 }
                            }
                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }
                        }

                        Rectangle {
                            id: volumeHandle
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: parent.height * (1 - (isMuted ? 0 : displayVolume)) - height / 2
                            width: 15
                            height: 15
                            radius: 6
                            color: volumeHandleArea.pressed ? "#FFFFFF" : "#E0E0E0"
                            border.color: "#80000000"
                            border.width: 1

                            Behavior on y {
                                NumberAnimation { duration: 100 }
                            }
                        }

                        MouseArea {
                            id: volumeHandleArea
                            anchors.fill: parent
                            anchors.margins: -10
                            hoverEnabled: true

                            onPressed: {
                                if (isMuted) {
                                    isMuted = false;
                                    api.memory.set("muted", false);
                                }
                            }

                            onPositionChanged: {
                                if (pressed) {
                                    var displayPosition = 1.0 - Math.max(0, Math.min(1, mouseY / volumeSlider.height));
                                    var newVolume = displayToVolume(displayPosition);
                                    setVideoVolume(newVolume);

                                    if (!isMuted) {
                                        player.volume = savedVolume;
                                    }
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: volumeMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                    }
                }
            }
        }

        onActiveChanged: {
            if (active) {
                sourceComponent = videoComponent;
            } else {
                if (item && item.children && item.children.length > 0) {
                    var videoOutput = item.children[0];
                    if (videoOutput && videoOutput.mediaPlayer) {
                        videoOutput.mediaPlayer.stop();
                    }
                }
                sourceComponent = undefined;
            }
        }

        Connections {
            target: gameListView
            function onUpdateMediaType(mediaType) {
                currentMediaType = mediaType;
                isVideoType = (availableMediaTypes[mediaType] === "video");
                videoLoader.active = (isVideoType && currentSource !== "");
            }
        }

        Connections {
            target: gameMediaContainer
            function onCurrentSourceChanged() {
                if (availableMediaTypes[gameListView.currentMediaType] === "video") {
                    if (item && item.children && item.children.length > 0) {
                        var videoOutput = item.children[0];
                        if (videoOutput && videoOutput.mediaPlayer) {
                            videoOutput.mediaPlayer.source = currentSource;
                            videoOutput.mediaPlayer.volume = isMuted ? 0 : savedVolume;
                            videoOutput.mediaPlayer.play();
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id: mediaTypeIndicator
        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
            bottomMargin: parent.height * 0.01
        }
        width: Math.min(parent.width * 0.5, (availableMediaTypes.length * parent.height * 0.05) + ((availableMediaTypes.length - 1) * 8))
        height: parent.height * 0.05
        radius: height / 2
        color: "#80000000"
        border.color: "#60FFFFFF"
        border.width: 1

        visible: gameListView.game !== null && availableMediaTypes.length > 0
        property string currentMediaName: {
            if (availableMediaTypes.length === 1 && availableMediaTypes[0] === "info") {
                return mediaTypeNames["info"];
            }
            return availableMediaTypes.length > 0 ?
            (mediaTypeNames[availableMediaTypes[gameListView.currentMediaType]] ||
            availableMediaTypes[gameListView.currentMediaType]) : "";
        }

        Row {
            id: dotsRow
            anchors.centerIn: parent
            spacing: 8

            Repeater {
                model: availableMediaTypes.length
                Rectangle {
                    width: parent.parent.height * 0.35
                    height: width
                    radius: width / 2
                    color: gameListView.currentMediaType === index ? "white" : "#60FFFFFF"
                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            gameListView.currentMediaType = index;
                            gameListView.updateGameImage();
                        }
                    }
                }
            }
        }
    }

    function cleanupMediaPlayer() {
        if (videoLoader.item && videoLoader.item.children && videoLoader.item.children.length > 0) {
            var videoOutput = videoLoader.item.children[0];
            if (videoOutput && videoOutput.mediaPlayer) {
                videoOutput.mediaPlayer.stop();
                videoOutput.mediaPlayer.source = "";
            }
        }
        videoLoader.active = false;
        currentSource = "";
        currentMediaType = 0;
        isVideoType = false;
    }

    function resetMedia() {
        if (isVideoType && videoLoader.item && videoLoader.item.children && videoLoader.item.children.length > 0) {
            var videoOutput = videoLoader.item.children[0];
            if (videoOutput && videoOutput.mediaPlayer) {
                videoOutput.mediaPlayer.stop();
                videoOutput.mediaPlayer.source = "";
            }
            videoLoader.active = false;
            isVideoType = false;
        }
    }

    function resetToDefault() {
        cleanupMediaPlayer();
        currentMediaType = 0;
        isVideoType = false;
        gameListView.currentMediaType = 0;

        if (gameListView.game && gameListView.availableMediaTypes &&
            (gameListView.availableMediaTypes.length === 0 ||
            (gameListView.availableMediaTypes.length === 1 &&
            gameListView.availableMediaTypes[0] === "info"))) {
            infoLoader.active = true;
        gameImage.visible = false;
        currentSource = "";
        currentMediaType = gameListView.availableMediaTypes.indexOf("info");
        gameListView.currentMediaType = currentMediaType;
            } else {
                infoLoader.active = false;
                gameImage.visible = true;
                if (gameListView.game && gameListView.game.assets) {
                    currentSource = gameListView.getFirstAvailableMedia();
                    gameImage.source = currentSource;
                }
            }
    }

    Connections {
        target: systemView
        function onCurrentIndexChanged() {
            resetToDefault();
        }
    }
}
