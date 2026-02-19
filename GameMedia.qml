import QtQuick 2.15
import QtMultimedia 5.15
import SortFilterProxyModel 0.2
import QtGraphicalEffects 1.12

Item {
    id: gameMediaContainer

    anchors {
        left: parent.left
        leftMargin: parent.width * 0.4 + 40
        right: parent.right
        rightMargin: 20
        verticalCenter: parent.verticalCenter
    }

    height: parent.height * 0.75

    property string currentSource: ""
    property int currentMediaType: 0
    property bool isVideoType: false
    property var availableMedia: []

    function currentItem() {
        return (availableMedia.length > 0 && currentMediaType < availableMedia.length)
        ? availableMedia[currentMediaType] : null;
    }
    function currentIsVideo() {
        var it = currentItem();
        return it ? it.isVideo : false;
    }
    function currentIsInfo() {
        var it = currentItem();
        return it ? (it.type === "info") : false;
    }

    property real savedVolume: api.memory.has("volume") ? api.memory.get("volume") : 0.03
    property real displayVolume: Math.pow(savedVolume, 0.3)
    property bool isMuted: api.memory.has("muted") ? api.memory.get("muted") : false
    property alias filterBlockedNotification: filterBlockedNotification
    property bool isVideoPlaying: videoLoader.active && videoLoader.item && videoLoader.item.children &&
    videoLoader.item.children.length > 0 &&
    videoLoader.item.children[0].mediaPlayer &&
    videoLoader.item.children[0].mediaPlayer.playbackState === MediaPlayer.PlayingState

    signal videoPlayingChanged(bool isPlaying)

    function displayToVolume(displayPos) { return Math.pow(displayPos, 3.33) }

    function setVideoVolume(newVolume) {
        savedVolume = Math.max(0.01, Math.min(1.0, newVolume));
        displayVolume = Math.pow(savedVolume, 0.3);
        api.memory.set("volume", savedVolume);
        if (videoLoader.item && videoLoader.item.children && videoLoader.item.children.length > 0) {
            var videoOutput = videoLoader.item.children[0];
            if (videoOutput && videoOutput.mediaPlayer && !isMuted) {
                videoOutput.mediaPlayer.volume = savedVolume;
            }
        }
    }

    function getVolume() { return savedVolume; }

    Rectangle {
        id: filterBlockedNotification
        anchors.centerIn: parent
        color: "#AA000000"
        radius: 10
        border.color: "white"
        border.width: 2
        opacity: 0
        visible: opacity > 0
        property real horizontalMargin: 20
        property real verticalMargin: 10

        width: Math.min(
            messageText.implicitWidth + horizontalMargin * 2,
            parent.width * 0.8
        )
        height: messageText.implicitHeight + verticalMargin * 2
        z: 1

        Text {
            id: messageText
            anchors.centerIn: parent
            width: parent.width - parent.horizontalMargin * 2
            text: "You can't filter while the video is playing"
            color: "white"
            font.pixelSize: 16
            font.bold: true
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
        }

        Behavior on opacity { NumberAnimation { duration: 300 } }

        function show() { opacity = 1; hideTimer.restart(); }

        Timer {
            id: hideTimer
            interval: 2000
            onTriggered: filterBlockedNotification.opacity = 0
        }
    }

    Connections {
        target: videoLoader.item && videoLoader.item.children && videoLoader.item.children.length > 0
        ? videoLoader.item.children[0].mediaPlayer : null
        function onPlaybackStateChanged() { videoPlayingChanged(isVideoPlaying); }
    }

    Loader {
        id: infoLoader
        anchors.fill: parent
        active: false
        sourceComponent: GameInfo { game: gameListView.game }
    }

    Connections {
        target: gameListView

        function onUpdateImageSource(newSource) {
            if (currentSource === newSource && !isVideoType) return;

            if (videoLoader.active) {
                if (videoLoader.item && videoLoader.item.children && videoLoader.item.children.length > 0) {
                    var vo = videoLoader.item.children[0];
                    if (vo && vo.mediaPlayer) {
                        vo.mediaPlayer.stop();
                        vo.mediaPlayer.source = "";
                    }
                }
                videoLoader.active = false;
                isVideoType = false;
            }

            currentSource = newSource;

            if (!newSource || newSource === "") {
                gameImage.source = "";
                return;
            }

            var isVid = currentIsVideo() || newSource.endsWith(".mp4") || newSource.endsWith(".avi");

            if (isVid) {
                gameImage.source = "";
                gameImage.visible = false;
                videoReloadTimer.restart();
            } else {
                gameImage.visible = true;
                gameImage.source = "";
                Qt.callLater(() => { gameImage.source = currentSource; });
            }
        }

        function onUpdateMediaType(mediaType) {
            currentMediaType = mediaType;
            isVideoType = currentIsVideo();

            if (isVideoType) {
                gameImage.source = "";
                gameImage.visible = false;
                infoLoader.active = false;
                if (videoLoader.active) {
                    if (videoLoader.item && videoLoader.item.children && videoLoader.item.children.length > 0) {
                        var vo = videoLoader.item.children[0];
                        if (vo && vo.mediaPlayer) {
                            vo.mediaPlayer.stop();
                            vo.mediaPlayer.source = "";
                        }
                    }
                    videoLoader.active = false;
                }
                videoReloadTimer.restart();
            } else if (currentIsInfo()) {
                gameImage.visible = false;
                infoLoader.active = true;
                if (videoLoader.active) videoLoader.active = false;
            } else {
                infoLoader.active = false;
                if (videoLoader.active) videoLoader.active = false;
                gameImage.visible = true;
                if (currentSource) {
                    gameImage.source = "";
                    Qt.callLater(() => { gameImage.source = currentSource; });
                }
            }
        }

        function onUpdateAvailableMedia(media) {
            availableMedia = media;
            if (currentMediaType >= availableMedia.length) {
                currentMediaType = 0;
                gameListView.currentMediaType = 0;
            }
            isVideoType = currentIsVideo();
        }
    }

    Timer {
        id: videoReloadTimer
        interval: 80
        repeat: false
        onTriggered: {
            if (currentSource && currentSource !== "" && currentIsVideo()) {
                isVideoType = true;
                videoLoader.active = true;
            }
        }
    }

    Connections {
        target: systemView
        function onCurrentIndexChanged() {
            resetToDefault();
            Qt.callLater(function() {
                if (gameListView.game) gameListView.updateGameImage();
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

    DropShadow {
        id: imageDropShadow
        anchors.fill: gameImage
        source: gameImage
        visible: gameImage.visible && gameImage.status === Image.Ready
        color: "#80000000"
        radius: 20
        samples: 25
        spread: 0.1
        horizontalOffset: 5
        verticalOffset: 5
        transparentBorder: true

        Behavior on opacity { NumberAnimation { duration: 200 } }
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
                            } else if (status === MediaPlayer.Loaded) {
                                var it = gameMediaContainer.currentItem();
                                if (videoLoader.active && it && it.isVideo) {
                                    play();
                                }
                            }
                        }

                        onErrorChanged: {
                            if (error !== MediaPlayer.NoError) {
                                console.log("Video error:", errorString);
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
                        if (player.playbackState === MediaPlayer.PlayingState) player.stop();
                        player.source = "";
                    }
                }

                Rectangle {
                    id: videoProgressBar
                    x: videoOutput.contentRect.x
                    y: videoOutput.contentRect.y + videoOutput.contentRect.height - height
                    width: videoOutput.contentRect.width
                    height: 3
                    color: "#40FFFFFF"
                    z: 10
                    visible: player.duration > 0

                    Rectangle {
                        id: videoProgressFill
                        anchors {
                            left: parent.left
                            top: parent.top
                            bottom: parent.bottom
                        }
                        width: player.duration > 0
                        ? parent.width * (player.position / player.duration)
                        : 0
                        color: "white"
                        opacity: 0.9
                    }

                    Timer {
                        id: progressTimer
                        interval: 32
                        running: player.playbackState === MediaPlayer.PlayingState
                        repeat: true
                        property real lastPosition: 0
                        property real lastTimestamp: 0

                        onTriggered: {
                            var now = Date.now();
                            var elapsed = (now - lastTimestamp);
                            if (player.playbackState === MediaPlayer.PlayingState && player.duration > 0) {
                                var interpolated = Math.min(player.position + elapsed, player.duration);
                                videoProgressFill.width = videoProgressBar.width * (interpolated / player.duration);
                            }
                            lastTimestamp = now;
                        }

                        onRunningChanged: {
                            if (running) lastTimestamp = Date.now();
                        }
                    }
                }

                DropShadow {
                    x: videoOutput.contentRect.x
                    y: videoOutput.contentRect.y
                    width: videoOutput.contentRect.width
                    height: videoOutput.contentRect.height
                    source: videoOutput
                    color: "#80000000"
                    radius: 20
                    samples: 25
                    spread: 0.1
                    horizontalOffset: 5
                    verticalOffset: 5
                    transparentBorder: true
                    visible: videoOutput.visible
                }

                Item {
                    id: volumeControls
                    anchors {
                        right: parent.right
                        rightMargin: parent.width * 0.01
                        verticalCenter: parent.verticalCenter
                    }
                    width: parent.width * 0.06
                    height: parent.height * 0.6
                    visible: videoOutput.visible
                    z: 9999

                    Rectangle {
                        id: volumeBackground
                        anchors.fill: parent
                        radius: 8
                        color: "#80000000"
                        border.color: "#80FFFFFF"
                        border.width: 1
                        opacity: volumeMouseArea.containsMouse || muteButton.hovered || volumeHandleArea.pressed ? 1.0 : 0.5
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }

                    Item {
                        id: muteButton
                        anchors {
                            top: parent.top
                            topMargin: 8
                            horizontalCenter: parent.horizontalCenter
                        }
                        width: parent.width * 0.7
                        height: width
                        property bool hovered: muteMouseArea.containsMouse

                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: muteMouseArea.pressed ? "#40FFFFFF" : "transparent"
                        }

                        Image {
                            anchors.fill: parent
                            source: isMuted ? "assets/icons/mute.png" : "assets/icons/volume.png"
                            fillMode: Image.PreserveAspectFit
                            opacity: parent.hovered ? 1.0 : 0.9
                            mipmap: true
                        }

                        MouseArea {
                            id: muteMouseArea
                            anchors.fill: parent
                            anchors.margins: -5
                            hoverEnabled: true
                            onClicked: {
                                isMuted = !isMuted;
                                api.memory.set("muted", isMuted);
                                if (player) player.volume = isMuted ? 0 : savedVolume;
                                mouse.accepted = true;
                            }
                        }
                    }

                    Item {
                        id: volumeSlider
                        anchors {
                            top: muteButton.bottom
                            topMargin: 15
                            bottom: parent.bottom
                            bottomMargin: 15
                            horizontalCenter: parent.horizontalCenter
                        }
                        width: parent.width * 0.4

                        Rectangle {
                            id: volumeTrack
                            anchors.fill: parent
                            radius: width / 2
                            color: "#40FFFFFF"
                        }

                        Rectangle {
                            id: volumeLevel
                            anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
                            width: parent.width
                            height: parent.height * (isMuted ? 0 : savedVolume)
                            radius: width / 2
                            color: isMuted ? "#FF6B6B" : "#FFFFFF"
                            Behavior on height { NumberAnimation { duration: 100 } }
                        }

                        Rectangle {
                            id: volumeHandle
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: parent.height * (1 - (isMuted ? 0 : savedVolume)) - height / 2
                            width: parent.width * 2
                            height: width
                            radius: width / 2
                            color: volumeHandleArea.pressed ? "#FFFFFF" : "#E0E0E0"
                            border.color: "#80000000"
                            border.width: 1
                            Behavior on y { NumberAnimation { duration: 100 } }
                        }

                        MouseArea {
                            id: volumeHandleArea
                            anchors.fill: parent
                            anchors.margins: -15
                            hoverEnabled: true

                            property bool draggingFromHandle: false
                            property real dragOffsetY: 0

                            onPressed: {
                                if (isMuted) { isMuted = false; api.memory.set("muted", false); }
                                var adjustedY = mouseY - 15;
                                var handleCenterY = volumeHandle.y + volumeHandle.height / 2;
                                if (Math.abs(adjustedY - handleCenterY) <= volumeHandle.height) {
                                    draggingFromHandle = true;
                                    dragOffsetY = adjustedY - handleCenterY;
                                } else {
                                    draggingFromHandle = false;
                                    dragOffsetY = 0;
                                    updateVolumeFromY(adjustedY);
                                }
                                mouse.accepted = true;
                            }

                            onPositionChanged: {
                                if (pressed) {
                                    var adjustedY = mouseY - 15;
                                    updateVolumeFromY(draggingFromHandle ? adjustedY - dragOffsetY : adjustedY);
                                    mouse.accepted = true;
                                }
                            }

                            onReleased: { draggingFromHandle = false; dragOffsetY = 0; mouse.accepted = true; }

                            function updateVolumeFromY(y) {
                                var linearPos = 1.0 - Math.max(0, Math.min(1, y / volumeSlider.height));
                                setVideoVolume(linearPos);
                                if (!isMuted && player) player.volume = savedVolume;
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
                    var vo = item.children[0];
                    if (vo && vo.mediaPlayer) vo.mediaPlayer.stop();
                }
                sourceComponent = undefined;
            }
        }
    }

    Item {
        id: swipeArea
        anchors.fill: parent
        visible: gameListView.game !== null && availableMedia.length > 1

        property real startX: 0
        property bool swipeDetected: false
        property real threshold: width * 0.1

        MouseArea {
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
                right: parent.right
                rightMargin: isVideoType ? parent.width * 0.08 : 0
            }
            property real pressX: 0
            propagateComposedEvents: true

            onPressed: (mouse) => {
                pressX = mouse.x;
                swipeArea.startX = mouse.x;
                swipeArea.swipeDetected = false;
            }

            onPositionChanged: (mouse) => {
                if (swipeArea.swipeDetected) return;
                var deltaX = mouse.x - pressX;
                if (Math.abs(deltaX) > swipeArea.threshold) {
                    swipeArea.swipeDetected = true;
                    if (deltaX > 0) swipeLeft(); else swipeRight();
                }
            }

            onReleased: {
                if (!swipeArea.swipeDetected) {
                    if (!gameListView.activeFocus) gameListView.forceActiveFocus();
                }
            }

            function swipeRight() {
                if (availableMedia.length > 0) {
                    naviSound.play();
                    if (isVideoType && videoLoader.item) gameMediaContainer.resetMedia();
                    var newIndex = (gameListView.currentMediaType + 1) % availableMedia.length;
                    gameListView.currentMediaType = newIndex;
                    gameListView.updateGameImage();
                }
            }

            function swipeLeft() {
                if (availableMedia.length > 0) {
                    naviSound.play();
                    if (isVideoType && videoLoader.item) gameMediaContainer.resetMedia();
                    var newIndex = (gameListView.currentMediaType - 1 + availableMedia.length) % availableMedia.length;
                    gameListView.currentMediaType = newIndex;
                    gameListView.updateGameImage();
                }
            }
        }

        Rectangle {
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            width: parent.width * 0.1
            color: "white"
            opacity: swipeArea.containsMouse ? 0.1 : 0
            visible: gameListView.game !== null && availableMedia.length > 1
            Behavior on opacity { NumberAnimation { duration: 200 } }
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#00FFFFFF" }
                GradientStop { position: 1.0; color: "#20FFFFFF" }
            }
        }

        Rectangle {
            anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
            width: parent.width * 0.1
            color: "white"
            opacity: swipeArea.containsMouse ? 0.1 : 0
            visible: gameListView.game !== null && availableMedia.length > 1
            Behavior on opacity { NumberAnimation { duration: 200 } }
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#20FFFFFF" }
                GradientStop { position: 1.0; color: "#00FFFFFF" }
            }
        }
    }

    Rectangle {
        id: mediaTypeIndicator
        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
            bottomMargin: -parent.height * 0.06
        }
        width: Math.min(parent.width * 0.5,
                        (availableMedia.length * parent.height * 0.05) + ((availableMedia.length - 1) * 8))
        height: parent.height * 0.05
        radius: height / 2
        color: "#80000000"
        border.color: "#60FFFFFF"
        border.width: 1

        visible: gameListView.game !== null && availableMedia.length > 0

        property string currentMediaName: {
            var it = gameMediaContainer.currentItem();
            return it ? it.label : "";
        }

        Row {
            id: dotsRow
            anchors.centerIn: parent
            spacing: 8

            Repeater {
                model: availableMedia.length
                Rectangle {
                    width: parent.parent.height * 0.35
                    height: width
                    radius: width / 2
                    color: gameListView.currentMediaType === index ? "white" : "#60FFFFFF"
                    Behavior on color { ColorAnimation { duration: 150 } }
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -10
                        onClicked: {
                            naviSound.play();
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
            var vo = videoLoader.item.children[0];
            if (vo && vo.mediaPlayer) { vo.mediaPlayer.stop(); vo.mediaPlayer.source = ""; }
        }
        videoLoader.active = false;
        currentSource = "";
        currentMediaType = 0;
        isVideoType = false;
    }

    function resetMedia() {
        if (isVideoType && videoLoader.item && videoLoader.item.children && videoLoader.item.children.length > 0) {
            var vo = videoLoader.item.children[0];
            if (vo && vo.mediaPlayer) { vo.mediaPlayer.stop(); vo.mediaPlayer.source = ""; }
            videoLoader.active = false;
            isVideoType = false;
        }
    }

    function resetToDefault() {
        cleanupMediaPlayer();
        currentMediaType = 0;
        isVideoType = false;
        gameListView.currentMediaType = 0;

        var onlyInfo = (gameListView.availableMedia.length === 0 ||
        (gameListView.availableMedia.length === 1 &&
        gameListView.availableMedia[0].type === "info"));

        if (gameListView.game && onlyInfo) {
            infoLoader.active = true;
            gameImage.visible = false;
            currentSource = "";
            currentMediaType = 0;
            gameListView.currentMediaType = 0;
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
        function onCurrentIndexChanged() { resetToDefault(); }
    }
}
