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
    property alias consoleYears: consoleYearsObj.data
    property alias consoleColors: consoleColorsObj.data

    ConsoleYears {
        id: consoleYearsObj
    }

    ConsoleColors {
        id: consoleColorsObj
    }

    function getBatteryIcon() {
        if (isNaN(api.device.batteryPercent) || api.device.batteryCharging) {
            return "assets/icons/charging.png";
        } else {
            const batteryPercent = api.device.batteryPercent * 100;
            if (batteryPercent <= 20) {
                return "assets/icons/10.png";
            } else if (batteryPercent <= 40) {
                return "assets/icons/25.png";
            } else if (batteryPercent <= 60) {
                return "assets/icons/50.png";
            } else if (batteryPercent <= 80) {
                return "assets/icons/75.png";
            } else if (batteryPercent <= 90) {
                return "assets/icons/90.png";
            } else {
                return "assets/icons/95.png";
            }
        }
    }

    function getConsoleYear(shortName) {
        return consoleYears[shortName.toLowerCase()] || "none";
    }

    function getColorForSystem(shortName) {
        return consoleColors[shortName.toLowerCase()] || "#000000";
    }

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

    Rectangle {
        id: background
        anchors.fill: parent
        color: root.backgroundColor
        Behavior on color {
            ColorAnimation { duration: 500 }
        }
    }

    SoundEffect {
        id: naviSound
        source: "assets/sound/mov.wav"
        volume: 0.05
    }

    SoundEffect {
        id: faviSound
        source: "assets/sound/fav.wav"
        volume: 0.3
    }

    Text {
        id: clock
        anchors {
            top: parent.top
            left: parent.left
            topMargin: 20
            leftMargin: 20
        }
        color: "white"
        font.pixelSize: root.width * 0.025
        font.bold: true
        visible: collectionsVisible

        function formatTime() {
            let date = new Date();
            let hours = date.getHours();
            let minutes = date.getMinutes();
            let ampm = hours >= 12 ? "PM" : "AM";
            hours = hours % 12;
            hours = hours ? hours : 12;
            let minutesStr = minutes < 10 ? "0" + minutes : minutes;

            return hours + ":" + minutesStr + " " + ampm;
        }
        text: formatTime()
        Timer {
            running: true
            interval: 1000
            repeat: true
            onTriggered: clock.text = clock.formatTime()
        }
    }

    Item {
        id: batteryIndicator
        width: parent.width
        height: 40
        anchors {
            top: parent.top
            topMargin: root.height * 0.04
        }

        Timer {
            id: batteryUpdateTimer
            triggeredOnStart: true
            interval: 5000
            running: true
            repeat: true
            onTriggered: batteryIcon.source = getBatteryIcon()
        }

        Row {
            anchors {
                right: parent.right
                rightMargin: 10
                verticalCenter: parent.verticalCenter
            }
            spacing: 5

            Image {
                id: batteryIcon
                source: getBatteryIcon()
                width: root.width * 0.1
                height: root.height * 0.05
                fillMode: Image.PreserveAspectFit
                mipmap: true
                asynchronous: true
                visible: collectionsVisible
            }
        }
    }

    CollectionView {
        id: systemView
    }

    GameCount {
        id: gamesCount
    }

    DotsView {
        id: dotsRow
    }

    Item {
        width: parent.width
        height: parent.height
        visible: gamesVisible

        Item {
            id: animatableItem
            width: parent.width
            height: parent.height

            y: !gamesVisible ? -height : 0

            SequentialAnimation on y {
                NumberAnimation {
                    from: -height
                    to: 0
                    duration: 300
                    easing.type: Easing.OutCubic
                }
                running: gamesVisible
            }

            SequentialAnimation on y {
                NumberAnimation {
                    from: 0
                    to: -height
                    duration: 300
                    easing.type: Easing.InCubic
                }
                running: !gamesVisible
            }

            Row {
                width: parent.width
                height: parent.height
                spacing: root.width * 0.05
                padding: root.width * 0.01

                Item {
                    width: root.width * 0.01
                    height: parent.height
                }

                Row {
                    width: parent.width / 2
                    height: parent.height
                    spacing: root.width * 0.03

                    Text {
                        id: favoritesText
                        color: "white"
                        opacity: root.filterState === 1 ? 1.0 : 0.2
                        font.pixelSize: root.width * 0.02
                        font.bold: true
                        text: "Favorites"

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                naviSound.play();
                                root.filterState = 1;
                                gameListView.currentIndex = 0;
                                gameListView.updateGameImage();
                            }
                        }
                    }

                    Text {
                        id: allText
                        color: "white"
                        opacity: root.filterState === 0 ? 1.0 : 0.2
                        font.pixelSize: root.width * 0.02
                        font.bold: true
                        text: "All"

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                naviSound.play();
                                root.filterState = 0;
                                gameListView.currentIndex = 0;
                                gameListView.updateGameImage();
                            }
                        }
                    }

                    Text {
                        id: recentText
                        color: "white"
                        opacity: root.filterState === 2 ? 1.0 : 0.2
                        font.pixelSize: root.width * 0.02
                        font.bold: true
                        text: "Recently Played"

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                naviSound.play();
                                root.filterState = 2;
                                gameListView.currentIndex = 0;
                                gameListView.updateGameImage();
                            }
                        }
                    }
                }

                Row {
                    width: parent.width / 3
                    height: parent.height
                    spacing: root.width * 0.15

                    Text {
                        color: "white"
                        font.pixelSize: root.width * 0.02
                        font.bold: true
                        text: currentShortName
                    }

                    Item {
                        width: parent.width * 0.14
                        height: parent.height * 0.14
                        y: -root.height * 0.03

                        Image {
                            id: collectionImage
                            source: currentShortName ? "assets/shortnames/" + currentShortName + ".png" : ""
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
            radius: 10
            border.color: "transparent"
        }

        GameListView {
            id: gameListView
            opacity: gamesVisible ? 1 : 0
            visible: gamesVisible
            Behavior on opacity {
                NumberAnimation { duration: 300 }
            }
        }

        GameMedia {
            id: gameImage
            visible: gamesVisible
        }

        Item {
            id: buttons
            width: parent.width
            height: parent.height * 0.08
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            Text {
                id: gamesCountText
                text: {
                    if (gameListView.model.count === 0) {
                        return "Game 0/0"
                    }
                    return "Game " + (gameListView.currentIndex + 1) + "/" + gameListView.model.count
                }
                font.pixelSize: root.width * 0.022
                color: "white"
                font.bold: true
                y: gamesVisible ? parent.height - height : parent.height
                anchors {
                    left: parent.left
                    leftMargin: parent.width * 0.17
                }

                SequentialAnimation on y {
                    NumberAnimation {
                        to: parent.height - height
                        duration: 300
                        easing.type: Easing.OutCubic
                    }
                    running: gamesVisible
                }

                SequentialAnimation on y {
                    NumberAnimation {
                        to: parent.height
                        duration: 300
                        easing.type: Easing.InCubic
                    }
                    running: !gamesVisible
                }
            }

            Row {
                id: mainRow
                spacing: root.width * 0.02

                anchors {
                    right: parent.right
                    rightMargin: root.width * 0.1
                }

                y: buttons.height

                SequentialAnimation on y {
                    NumberAnimation {
                        from: buttons.height
                        to: (buttons.height - mainRow.height) / 2
                        duration: 300
                        easing.type: Easing.OutCubic
                    }
                    running: gamesVisible
                }

                SequentialAnimation on y {
                    NumberAnimation {
                        from: (buttons.height - mainRow.height) / 2
                        to: buttons.height
                        duration: 300
                        easing.type: Easing.InCubic
                    }
                    running: !gamesVisible
                }

                Item {
                    width: row1.width
                    height: row1.height
                    scale: btnArea1.pressed ? 0.88 : 1.0
                    Behavior on scale { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }

                    Row {
                        id: row1
                        spacing: root.width * 0.001
                        Image {
                            id: row1Icon
                            source: "assets/icons/x.png"
                            width: root.width * 0.032
                            height: root.width * 0.032
                            mipmap: true
                            layer.enabled: true
                            layer.effect: DropShadow {
                                horizontalOffset: 2
                                verticalOffset: 2
                                radius: 6
                                samples: 13
                                color: "#CC000000"
                            }
                        }
                        Text {
                            text: "Favorite"
                            color: "white"
                            font.pixelSize: root.width * 0.021
                            font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                            layer.enabled: true
                            layer.effect: DropShadow {
                                horizontalOffset: 2
                                verticalOffset: 2
                                radius: 6
                                samples: 13
                                color: "#CC000000"
                            }
                        }
                    }
                    MouseArea {
                        id: btnArea1
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            faviSound.play();
                            gameListView.toggleFavorite();
                        }
                    }
                }

                Item {
                    width: row2.width
                    height: row2.height
                    scale: btnArea2.pressed ? 0.88 : 1.0
                    Behavior on scale { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }

                    Row {
                        id: row2
                        spacing: root.width * 0.001
                        Image {
                            source: "assets/icons/a.png"
                            width: root.width * 0.032
                            height: root.width * 0.032
                            mipmap: true
                            layer.enabled: true
                            layer.effect: DropShadow {
                                horizontalOffset: 2
                                verticalOffset: 2
                                radius: 6
                                samples: 13
                                color: "#CC000000"
                            }
                        }
                        Text {
                            text: "OK"
                            color: "white"
                            font.pixelSize: root.width * 0.021
                            font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                            layer.enabled: true
                            layer.effect: DropShadow {
                                horizontalOffset: 2
                                verticalOffset: 2
                                radius: 6
                                samples: 13
                                color: "#CC000000"
                            }
                        }
                    }
                    MouseArea {
                        id: btnArea2
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            naviSound.play();
                            gameListView.handleGameLaunch();
                        }
                    }
                }

                Item {
                    width: row3.width
                    height: row3.height
                    scale: btnArea3.pressed ? 0.88 : 1.0
                    Behavior on scale { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }

                    Row {
                        id: row3
                        spacing: root.width * 0.001
                        Image {
                            source: "assets/icons/y.png"
                            width: root.width * 0.032
                            height: root.width * 0.032
                            mipmap: true
                            layer.enabled: true
                            layer.effect: DropShadow {
                                horizontalOffset: 2
                                verticalOffset: 2
                                radius: 6
                                samples: 13
                                color: "#CC000000"
                            }
                        }
                        Text {
                            text: "Filter"
                            color: "white"
                            font.pixelSize: root.width * 0.021
                            font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                            layer.enabled: true
                            layer.effect: DropShadow {
                                horizontalOffset: 2
                                verticalOffset: 2
                                radius: 6
                                samples: 13
                                color: "#CC000000"
                            }
                        }
                    }
                    MouseArea {
                        id: btnArea3
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (gameImage && gameImage.isVideoPlaying) {
                                if (gameImage.filterBlockedNotification) {
                                    gameImage.filterBlockedNotification.show();
                                }
                                return;
                            }
                            naviSound.play();
                            root.filterState = (root.filterState + 1) % 3;
                            gameListView.currentIndex = 0;
                            gameListView.updateGameImage();
                        }
                    }
                }

                Item {
                    width: row4.width
                    height: row4.height
                    scale: btnArea4.pressed ? 0.88 : 1.0
                    Behavior on scale { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }

                    Row {
                        id: row4
                        spacing: root.width * 0.001
                        Image {
                            source: "assets/icons/b.png"
                            width: root.width * 0.032
                            height: root.width * 0.032
                            mipmap: true
                            layer.enabled: true
                            layer.effect: DropShadow {
                                horizontalOffset: 2
                                verticalOffset: 2
                                radius: 6
                                samples: 13
                                color: "#CC000000"
                            }
                        }
                        Text {
                            text: "Back"
                            color: "white"
                            font.pixelSize: root.width * 0.021
                            font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                            layer.enabled: true
                            layer.effect: DropShadow {
                                horizontalOffset: 2
                                verticalOffset: 2
                                radius: 6
                                samples: 13
                                color: "#CC000000"
                            }
                        }
                    }
                    MouseArea {
                        id: btnArea4
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            naviSound.play();
                            if (gameImage && gameImage.isVideoType) {
                                gameImage.resetMedia();
                            }
                            collectionsVisible = true;
                            collectionsFocused = true;
                            gamesVisible = false;
                            gamesFocused = false;
                            systemView.forceActiveFocus();
                        }
                    }
                }
            }
        }
    }

    Keys.onPressed: {
        if (event.isAutoRepeat) {
            return;
        }

        /*if (api.keys.isPageUp(event)) {
            event.accepted = true;
            musicPlayer.nextTrack();
        }
        else if (api.keys.isPageDown(event)) {
            event.accepted = true;
            musicPlayer.previousTrack();
        }*/

        else if (gamesVisible && gameImage.visible) {
            if (api.keys.isNextPage(event)) {
                event.accepted = true;
                var newVolume = Math.min(1.0, gameImage.savedVolume + 0.05);
                gameImage.setVideoVolume(newVolume);
                showVolumeFeedback(true);
            }
            else if (api.keys.isPrevPage(event)) {
                event.accepted = true;
                var newVolume = Math.max(0.01, gameImage.savedVolume - 0.05);
                gameImage.setVideoVolume(newVolume);
                showVolumeFeedback(false);
            }
        }
    }

    function showVolumeFeedback(isUp) {
        volumeFeedback.text = Math.round(gameImage.savedVolume * 100) + "%";
        volumeFeedback.opacity = 1;
        volumeFeedbackTimer.restart();
    }

    Item {
        id: volumeFeedbackContainer
        anchors.centerIn: parent
        width: volumeFeedback.width + root.width * 0.06
        height: volumeFeedback.height + root.height * 0.025
        z: 10000
        opacity: volumeFeedback.opacity

        Behavior on opacity {
            NumberAnimation { duration: 200 }
        }

        Rectangle {
            anchors.fill: parent
            radius: 14
            color: root.backgroundColor
            opacity: 0.75

            layer.enabled: true
            layer.effect: FastBlur {
                radius: 48
                transparentBorder: true
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: 14
            color: "transparent"
            border.color: getColorForSystem(currentShortName)
            border.width: 0
            opacity: 0.9
        }

        Text {
            id: volumeFeedback
            anchors.centerIn: parent
            color: "white"
            font.pixelSize: root.width * 0.03
            font.bold: true
            opacity: 0

            Behavior on opacity {
                NumberAnimation { duration: 200 }
            }
        }
    }

    Timer {
        id: volumeFeedbackTimer
        interval: 1000
        onTriggered: volumeFeedback.opacity = 0
    }

    Connections {
        target: proxyModel
        function onCountChanged() {
            gameListView.updateGameImage();
        }
    }

    Connections {
        target: systemView
        function onCurrentIndexChanged() {
            if (systemView.currentIndex >= 0) {
                const selectedCollection = api.collections.get(systemView.currentIndex);
                proxyModel.sourceModel = selectedCollection.games;
                gameListView.currentIndex = 0;
                gameListView.updateGameImage();
            }
        }
    }
}
