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
    property var mediaSources: ["boxFront", "screenshot"]

    signal updateImageSource(string source)

    delegate: Item {
        width: gameListView.width
        height: 45
        property var game: null

        Rectangle {
            id: highlightRect
            anchors.fill: parent
            color: gameListView.currentIndex === index ? "yellow" : "transparent"
            radius: 5
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
                currentMediaType = 0;
                updateGameImage();
                event.accepted = true;
                break;

            case (event.key === Qt.Key_Right):
                naviSound.play();
                currentMediaType = 1;
                updateGameImage();
                event.accepted = true;
                break;
        }
    }

    function updateGameImage() {
        if (proxyModel.count === 0) {
            currentGameImageSource = "assets/gamepad/default.png";
            game = null;
        } else {
            game = proxyModel.get(currentIndex);
            if (game && game.assets) {
                currentGameImageSource = game.assets[mediaSources[currentMediaType]] ?
                game.assets[mediaSources[currentMediaType]] :
                "assets/gamepad/default.png";
            } else {
                currentGameImageSource = "assets/gamepad/default.png";
            }
        }
        updateImageSource(currentGameImageSource);
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

    onCurrentIndexChanged: {
        updateGameImage();
    }
}
