import QtQuick 2.15
import QtGraphicalEffects 1.12

PathView {
    id: systemView
    width: parent.width
    height: parent.height * 0.35
    anchors {
        horizontalCenter: parent.horizontalCenter
        top: parent.top
        topMargin: parent.height * 0.25
    }
    model: api.collections
    pathItemCount: Math.min(5, model.count)
    preferredHighlightBegin: 0.5
    preferredHighlightEnd: 0.5
    highlightRangeMode: PathView.StrictlyEnforceRange
    highlightMoveDuration: 300
    opacity: collectionsVisible ? 1 : 0
    visible: collectionsVisible
    property real itemSpacing: width * 0.2
    property real delegateSize: Math.min(itemSpacing * 0.8, height * 0.8)

    path: Path {
        startX: systemView.width/2 - ((systemView.pathItemCount - 1) * systemView.itemSpacing)/2
        startY: systemView.height/2
        PathLine {
            x: systemView.width/2 + ((systemView.pathItemCount - 1) * systemView.itemSpacing)/2
            y: systemView.height/2
        }
    }

    delegate: Item {
        id: delegateItem
        width: systemView.delegateSize
        height: systemView.delegateSize
        scale: PathView.isCurrentItem ? 1 : 0.85
        opacity: {
            const distance = Math.abs(PathView.view.currentIndex - index)
            return distance <= 2 ? 1 - (distance * 0.15) : 0.7
        }
        z: PathView.isCurrentItem ? 1 : 0

        Rectangle {
            id: selectionRect
            anchors {
                fill: parent
                margins: -parent.width * 0.025
                topMargin: -parent.width * 0.05
                bottomMargin: -systemView.height * 0.6
            }
            color: delegateItem.PathView.isCurrentItem ? "#33FFFFFF" : "transparent"
            border.color: "white"
            border.width: Math.max(2, parent.width * 0.015)
            radius: parent.width * 0.2
            opacity: delegateItem.PathView.isCurrentItem ? 1 : 0
            Behavior on opacity {
                NumberAnimation { duration: 300 }
            }
            Behavior on color {
                ColorAnimation { duration: 300 }
            }
        }

        Image {
            id: systemIcon
            anchors {
                fill: parent
                margins: parent.width * 0.05
            }

            source: "assets/shortnames/" + model.shortName + ".png"
            fillMode: Image.PreserveAspectFit
            mipmap: true
            asynchronous: true

            onStatusChanged: {
                if (status === Image.Error) {
                    source = "assets/shortnames/default.png";
                }
            }
        }

        Column {
            anchors {
                bottom: selectionRect.bottom
                bottomMargin: selectionRect.height * 0.05
                horizontalCenter: parent.horizontalCenter
            }
            spacing: parent.height * 0.01

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: modelData.shortName.toUpperCase() || ""
                color: "white"
                font.bold: true
                font.pixelSize: delegateItem.width * 0.1
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "(" + getConsoleYear(modelData.shortName) + ")"
                color: "white"
                font.pixelSize: delegateItem.width * 0.1
                font.bold: true
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutCubic
            }
        }
    }

    Behavior on opacity {
        NumberAnimation { duration: 300 }
    }

    focus: collectionsFocused
    Keys.onLeftPressed: decrementCurrentIndex(naviSound.play())
    Keys.onRightPressed: incrementCurrentIndex(naviSound.play())

    Keys.onPressed: {
        if (event.isAutoRepeat) {
            return;
        }

        if (api.keys.isAccept(event)) {
            naviSound.play();
            if (gameImage.videoLoader) {
                gameImage.videoLoader.active = true;
            }
            event.accepted = true;
            collectionsVisible = false;
            collectionsFocused = false;
            gamesVisible = true;
            gamesFocused = true;
            gameListView.forceActiveFocus();
        }
        else if (api.keys.isNextPage(event)) {
            naviSound.play();
            event.accepted = true;
            incrementCurrentIndex();
        }
        else if (api.keys.isPrevPage(event)) {
            naviSound.play();
            event.accepted = true;
            decrementCurrentIndex();
        }
    }

    onCurrentIndexChanged: {
        const selectedCollection = api.collections.get(currentIndex);
        proxyModel.sourceModel = selectedCollection.games;
        currentCollectionName = model.get(currentIndex).name;
        currentShortName = model.get(currentIndex).shortName;
        root.backgroundColor = getColorForSystem(currentShortName);

        if (gameImage && gameImage.isVideoType && gameImage.resetMedia) {
            gameImage.resetMedia();
        }
        proxyModel.invalidate();
    }

    Component.onCompleted: {
        currentIndex = 0
        const initialCollection = api.collections.get(currentIndex);
        proxyModel.sourceModel = initialCollection.games;
        currentCollectionName = model.get(currentIndex).name;
        currentShortName = model.get(currentIndex).shortName;
        root.backgroundColor = getColorForSystem(currentShortName);
        game = proxyModel.get(gameListView.currentIndex);
    }
}
