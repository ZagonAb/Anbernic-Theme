import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.12
import SortFilterProxyModel 0.2
import QtMultimedia 5.8
import QtQuick.Window 2.15

FocusScope {
    id: root
    focus: true

    property string currentShortName: ""
    property string currentCollectionName: ""
    property string backgroundColor: "#000000"
    property bool collectionsVisible: true
    property bool collectionsFocused: true
    property bool gamesVisible: false
    property bool gamesFocused: false
    property var game : null
    property int filterState: 0

    SortFilterProxyModel {
        id: proxyModel
        sourceModel: systemView.currentIndex >= 0 ? api.collections.get(systemView.currentIndex).games : []

        filters: AllOf {
            ExpressionFilter {
                expression: {
                    if (root.filterState === 1) {
                        return model.favorite === true;
                    }
                    if (root.filterState === 2) {
                        var currentDate = new Date();
                        var sevenDaysAgo = new Date(currentDate.getTime() - 7 * 24 * 60 * 60 * 1000);
                        var lastPlayedDate = new Date(model.lastPlayed);
                        return lastPlayedDate >= sevenDaysAgo && (model.playTime / 60) > 1;
                    }
                    return true;
                }
            }
        }

        sorters: RoleSorter {
            id: gameSorter
            roleName: root.filterState === 2 ? "lastPlayed" : "title"
            sortOrder: root.filterState === 2 ? Qt.DescendingOrder : Qt.AscendingOrder
        }
    }

    Connections {
        target: systemView
        function onCurrentIndexChanged() {
            if (systemView.currentIndex >= 0) {
                const selectedCollection = api.collections.get(systemView.currentIndex);
                proxyModel.sourceModel = selectedCollection.games;
                gameListView.currentIndex = 0;
                game = proxyModel.get(gameListView.currentIndex);
                gameImage.source = game && game.assets.boxFront ? game.assets.boxFront : "assets/nofound.png";
            }
        }
    }

    Rectangle {
        id: background
        anchors.fill: parent
        color: root.backgroundColor
        Behavior on color {
            ColorAnimation { duration: 500 }
        }
    }

    Item {
        width: parent.width
        height: parent.height
        visible: gamesVisible

        Item {

            Row {
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    topMargin: 10
                    leftMargin: root.width * 0.05
                    rightMargin: root.width * 0.03
                }
                width: parent.width
                height: parent.height
                spacing: root.width * 0.05

                Row {
                    width: parent.width / 2
                    height: parent.height
                    spacing: root.width * 0.03

                    Text {
                        id: favoritesText
                        color: root.filterState === 1 ? "white" : "#808080"
                        font.pixelSize: root.width * 0.02
                        font.bold: true
                        text: "Favorites"
                    }

                    Text {
                        id: allText
                        color: root.filterState === 0 ? "white" : "#808080"
                        font.pixelSize: root.width * 0.02
                        font.bold: true
                        text: "All"
                    }

                    Text {
                        id: recentText
                        color: root.filterState === 2 ? "white" : "#808080"
                        font.pixelSize: root.width * 0.02
                        font.bold: true
                        text: "Recently Played"
                    }
                }

                Row {
                    width: parent.width / 3
                    height: parent.height
                    spacing: root.width * 0.15
                    anchors.right: parent.right

                    Text {
                        color: "white"
                        font.pixelSize: root.width * 0.02
                        font.bold: true
                        text: currentShortName
                    }

                    Item {
                        width: parent.width * 0.14
                        height: parent.height * 0.14
                        anchors.top: parent.top
                        anchors.topMargin: -root.height * 0.03

                        Image {
                            id: collectionImage
                            source: "assets/shortnames/" + currentShortName + ".png"
                            width: parent.width
                            height: parent.height
                            fillMode: Image.PreserveAspectFit
                            mipmap: true
                            asynchronous: true
                            visible: status !== Image.Error
                        }

                        Image {
                            id: defaultImage
                            source: "assets/shortnames/default.png"
                            width: parent.width
                            height: parent.height
                            fillMode: Image.PreserveAspectFit
                            mipmap: true
                            visible: collectionImage.status === Image.Error
                        }
                    }
                }
            }
        }


        Rectangle {
            id: gameRectangle
            anchors {
                left: parent.left
                leftMargin: 20
                verticalCenter: parent.verticalCenter
            }
            width: parent.width * 0.4
            height: parent.height * 0.80
            color: "black"
            opacity: 0.2
            radius: 5
            border.color: "transparent"
        }

        Image {
            id: gamepadImage
            anchors {
                left: gameRectangle.right
                right: parent.right
                leftMargin: 20
                rightMargin: 20
                verticalCenter: parent.verticalCenter
            }
            height: parent.height * 0.50
            source: {
                if (systemView.model && systemView.model.shortName) {
                    return "assets/gamepad/" + systemView.model.shortName + ".png"
                }
                return "assets/gamepad/default.png"
            }
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            visible: !gameImage.source || gameImage.status === Image.Error
            onStatusChanged: {
                if (status === Image.Error) {
                    source = "assets/gamepad/default.png";
                }
            }
            mipmap: true
        }

        Image {
            id: gameImage
            anchors {
                left: gameRectangle.right
                right: parent.right
                leftMargin: 20
                rightMargin: 20
                verticalCenter: parent.verticalCenter
            }
            height: parent.height * 0.70
            source: ""
            fillMode: Image.PreserveAspectFit
            asynchronous: true
        }

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

            Keys.onUpPressed: gameListView.decrementCurrentIndex(naviSound.play())
            Keys.onDownPressed: gameListView.incrementCurrentIndex(naviSound.play())

            Keys.onPressed: function(event) {
                if (api.keys.isFilters(event)) {
                    naviSound.play();
                    root.filterState = (root.filterState + 1) % 3;
                    gameListView.currentIndex = 0;
                    game = proxyModel.get(gameListView.currentIndex);
                    gameImage.source = game && game.assets.boxFront ? game.assets.boxFront : "assets/gamepad/default.png";
                    event.accepted = true;

                } else if (!event.isAutoRepeat && api.keys.isCancel(event)) {
                    naviSound.play();
                    event.accepted = true;
                    collectionsVisible = true;
                    collectionsFocused = true;
                    gamesVisible = false;
                    gamesFocused = false;
                    systemView.forceActiveFocus();

                } else if (!event.isAutoRepeat && api.keys.isAccept(event)) {
                    naviSound.play();
                    event.accepted = true;
                    const currentCollection = api.collections.get(systemView.currentIndex);
                    if (currentCollection && currentCollection.games) {
                        const filteredGame = proxyModel.get(gameListView.currentIndex);
                        if (filteredGame) {
                            let originalGameIndex = -1;
                            for (let i = 0; i < currentCollection.games.count; i++) {
                                const game = currentCollection.games.get(i);
                                if (game.title === filteredGame.title) {
                                    originalGameIndex = i;
                                    break;
                                }
                            }
                            console.log("Colección actual:", currentCollection.name);
                            console.log("Título del juego filtrado:", filteredGame.title);
                            if (originalGameIndex !== -1) {
                                const gameToLaunch = currentCollection.games.get(originalGameIndex);
                                console.log("Lanzando juego:", gameToLaunch.title);
                                gameToLaunch.launch();
                            } else {
                                console.log("No se encontró el juego en la colección original");
                            }
                        } else {
                            console.log("No se pudo obtener el juego del modelo filtrado");
                        }
                    } else {
                        console.log("No se pudo obtener la colección actual o sus juegos");
                    }

                } else if (!event.isAutoRepeat && api.keys.isDetails(event)) {
                    // Obtener el juego en el modelo original y alternar el estado de favorito
                    const currentCollection = api.collections.get(systemView.currentIndex);
                    if (currentCollection && currentCollection.games) {
                        const filteredGame = proxyModel.get(gameListView.currentIndex);
                        if (filteredGame) {
                            // Encontrar el índice del juego en el modelo original
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
                                proxyModel.invalidate(); // Actualiza el modelo filtrado
                                console.log(`Juego '${gameToToggleFavorite.title}' ${gameToToggleFavorite.favorite ? 'agregado a favoritos' : 'eliminado de favoritos'}`);
                            } else {
                                console.log("No se encontró el juego en la colección original");
                            }
                        }
                    }
                    event.accepted = true;
                }
            }

            onCurrentIndexChanged: {
                game = proxyModel.get(gameListView.currentIndex);
                gameImage.source = game && game.assets.boxFront ? game.assets.boxFront : "assets/gamepad/default.png";
            }
        }
    }
}
