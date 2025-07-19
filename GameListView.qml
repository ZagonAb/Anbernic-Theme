import QtQuick 2.15
import SortFilterProxyModel 0.2

ListView {
    id: gameListView
    anchors {
        left: parent.left
        leftMargin: 20
        verticalCenter: parent.verticalCenter
    }
    width: parent.width * 0.4
    height: parent.height * 0.72
    spacing: 5
    opacity: gamesVisible ? 1 : 0
    visible: gamesVisible
    model: proxyModel

    property var game: null
    property string currentGameImageSource: ""
    property int currentMediaType: 0
    property var availableMediaTypes: []

    signal updateImageSource(string source)
    signal updateMediaType(int mediaType)
    signal updateAvailableMediaTypes(var types)

    delegate: Item {
        width: gameListView.width
        height: 45
        property var game: null

        Rectangle {
            id: highlightRect
            anchors.fill: parent
            color: gameListView.currentIndex === index ? "yellow" : "transparent"
            radius: 10
        }

        Text {
            id: numerator
            text: {
                let number = (index + 1).toString().padStart(3, "0");
                `${number} - ${model.title} ${model.favorite ? "★" : ""}`
            }
            color: gameListView.currentIndex === index ? "black" : "white"
            font.bold: true
            font.pixelSize: gameListView.width * 0.05
            elide: Text.ElideRight
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 10
            width: parent.width - 20
        }
    }

    Behavior on opacity {
        NumberAnimation { duration: 300 }
    }

    Text {
        id: noGamesText
        text: "No games found"
        anchors.centerIn: parent
        visible: proxyModel.count === 0
        font.pixelSize: root.width *0.02
        color: "#FFFFFF"
    }

    focus: gamesFocused

    Keys.onUpPressed: decrementCurrentIndex(naviSound.play())
    Keys.onDownPressed: incrementCurrentIndex(naviSound.play())

    Keys.onPressed: function(event) {
        if (event.isAutoRepeat) {
            return;
        }

        switch(true) {
            case api.keys.isFilters(event):
                naviSound.play();
                root.filterState = (root.filterState + 1) % 3;
                currentIndex = 0;
                updateGameImage();
                event.accepted = true;
                break;
            case api.keys.isCancel(event):
                naviSound.play();
                if (gameImage && gameImage.isVideoType) {
                    gameImage.resetMedia();
                }
                event.accepted = true;
                collectionsVisible = true;
                collectionsFocused = true;
                gamesVisible = false;
                gamesFocused = false;
                systemView.forceActiveFocus();
                break;

            case api.keys.isAccept(event):
                naviSound.play();
                event.accepted = true;
                handleGameLaunch();
                break;

            case api.keys.isDetails(event):
                faviSound.play();
                toggleFavorite();
                event.accepted = true;
                break;

            case (event.key === Qt.Key_Left):
                naviSound.play();
                if (availableMediaTypes.length > 0) {
                    if (gameImage && gameImage.isVideoType) {
                        gameImage.resetMedia();
                    }
                    currentMediaType = (currentMediaType - 1 + availableMediaTypes.length) % availableMediaTypes.length;
                    currentGameImageSource = "";
                    updateGameImage();
                }
                event.accepted = true;
                break;

            case (event.key === Qt.Key_Right):
                naviSound.play();
                if (availableMediaTypes.length > 0) {
                    currentMediaType = (currentMediaType + 1) % availableMediaTypes.length;
                    currentGameImageSource = "";
                    Qt.callLater(function() {
                        updateGameImage();
                    });
                }
                event.accepted = true;
                break;
        }
    }

    function getFirstAvailableMedia() {
        if (!game || !game.assets) return "assets/gamepad/default.png";

        for (let i = 0; i < availableMediaTypes.length; i++) {
            const mediaType = availableMediaTypes[i];
            if (game.assets[mediaType]) {
                return game.assets[mediaType];
            }
        }
        return "assets/gamepad/default.png";
    }

    function getAvailableMediaTypes() {
        if (!game || !game.assets) return [];

        const allMediaTypes = [
            "boxFront", "boxBack", "boxSpine", "boxFull", "cartridge", "logo",
            "marquee", "bezel", "panel", "cabinetLeft", "cabinetRight",
            "tile", "banner", "steam", "poster", "background",
            "screenshot", "titlescreen", "video"
        ];

        const available = [];
        for (let i = 0; i < allMediaTypes.length; i++) {
            const mediaType = allMediaTypes[i];
            if (game.assets[mediaType]) {
                available.push(mediaType);
            }
        }

        available.push("info");

        return available.length > 0 ? available : ["boxFront"];
    }

    function updateGameImage() {
        if (gameImage && gameImage.videoLoader && gameImage.videoLoader.item && gameImage.videoLoader.item.mediaPlayer) {
            gameImage.videoLoader.item.mediaPlayer.stop();
        }

        if (proxyModel.count === 0) {
            currentGameImageSource = "assets/gamepad/default.png";
            game = null;
            availableMediaTypes = [];
            if (gameImage && gameImage.videoLoader) {
                gameImage.videoLoader.active = false;
            }
            if (gameImage && gameImage.infoLoader) {
                gameImage.infoLoader.active = false;
            }
        } else {
            game = proxyModel.get(currentIndex);
            availableMediaTypes = getAvailableMediaTypes();

            if (availableMediaTypes.length === 0 ||
                (availableMediaTypes.length === 1 && availableMediaTypes[0] === "info")) {
                currentGameImageSource = "";
            currentMediaType = availableMediaTypes.indexOf("info") >= 0 ?
            availableMediaTypes.indexOf("info") : 0;
            updateImageSource(currentGameImageSource);
            updateMediaType(currentMediaType);
            updateAvailableMediaTypes(availableMediaTypes);
            return;
                }

                if (game && game.assets) {
                    let attemptedMediaType = currentMediaType;
                    if (attemptedMediaType >= availableMediaTypes.length) {
                        attemptedMediaType = 0;
                        currentMediaType = 0;
                    }

                    const mediaType = availableMediaTypes[attemptedMediaType];

                    if (mediaType === "info") {
                        currentGameImageSource = "";
                    } else if (game.assets[mediaType]) {
                        currentGameImageSource = game.assets[mediaType];
                    } else {
                        for (let i = 0; i < availableMediaTypes.length; i++) {
                            const fallbackType = availableMediaTypes[i];
                            if (fallbackType !== "info" && game.assets[fallbackType]) {
                                currentGameImageSource = game.assets[fallbackType];
                                attemptedMediaType = i;
                                break;
                            }
                        }

                        if (!currentGameImageSource) {
                            if (availableMediaTypes.includes("info")) {
                                currentGameImageSource = "";
                                attemptedMediaType = availableMediaTypes.indexOf("info");
                            } else {
                                currentGameImageSource = "assets/gamepad/default.png";
                                attemptedMediaType = 0;
                            }
                        }
                    }

                    currentMediaType = attemptedMediaType;
                } else {
                    if (availableMediaTypes.includes("info")) {
                        currentGameImageSource = "";
                        currentMediaType = availableMediaTypes.indexOf("info");
                    } else {
                        currentGameImageSource = "assets/gamepad/default.png";
                        currentMediaType = 0;
                    }
                }
        }

        updateImageSource(currentGameImageSource);
        updateMediaType(currentMediaType);
        updateAvailableMediaTypes(availableMediaTypes);
    }

    function handleGameLaunch() {
        const currentCollection = api.collections.get(systemView.currentIndex);
        if (currentCollection && currentCollection.games) {
            const filteredGame = proxyModel.get(currentIndex);
            if (filteredGame) {
                let originalGameIndex = -1;
                for (let i = 0; i < currentCollection.games.count; i++) {
                    const game = currentCollection.games.get(i);
                    if (game.title === filteredGame.title) {
                        originalGameIndex = i;
                        break;
                    }
                }
                if (originalGameIndex !== -1) {
                    const gameToLaunch = currentCollection.games.get(originalGameIndex);
                    gameToLaunch.launch();
                }
            }
        }
    }

    function toggleFavorite() {
        const currentCollection = api.collections.get(systemView.currentIndex);
        if (currentCollection && currentCollection.games) {
            const filteredGame = proxyModel.get(currentIndex);
            if (filteredGame) {
                let originalGameIndex = -1;
                for (let i = 0; i < currentCollection.games.count; i++) {
                    const game = currentCollection.games.get(i);
                    if (game.title === filteredGame.title) {
                        originalGameIndex = i;
                        break;
                    }
                }
                if (originalGameIndex !== -1) {
                    const gameToToggleFavorite = currentCollection.games.get(originalGameIndex);
                    gameToToggleFavorite.favorite = !gameToToggleFavorite.favorite;
                    proxyModel.invalidate();
                }
            }
        }
    }

    function getCurrentMediaSource() {
        if (!game || !game.assets || availableMediaTypes.length === 0) {
            return "assets/gamepad/default.png";
        }

        const mediaType = availableMediaTypes[currentMediaType];
        if (game.assets[mediaType]) {
            return game.assets[mediaType];
        }

        return getFirstAvailableMedia();
    }

    function getFirstAvailableNonVideoMedia() {
        if (!game || !game.assets) return "assets/gamepad/default.png";

        for (let i = 0; i < availableMediaTypes.length; i++) {
            const mediaType = availableMediaTypes[i];
            if (mediaType !== "video" && game.assets[mediaType]) {
                return game.assets[mediaType];
            }
        }
        return "assets/gamepad/default.png";
    }

    onCurrentIndexChanged: {
        updateGameImage();
    }
}
