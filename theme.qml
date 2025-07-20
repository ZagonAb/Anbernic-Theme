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
        font.pixelSize: root.width * 0.02
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
            topMargin: 20
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
                width: batteryIndicator.width * 0.1
                height: root.height * 0.04
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
                    }

                    Text {
                        id: allText
                        color: "white"
                        opacity: root.filterState === 0 ? 1.0 : 0.2
                        font.pixelSize: root.width * 0.02
                        font.bold: true
                        text: "All"
                    }

                    Text {
                        id: recentText
                        color: "white"
                        opacity: root.filterState === 2 ? 1.0 : 0.2
                        font.pixelSize: root.width * 0.02
                        font.bold: true
                        text: "Recently Played"
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
                        return "Games 0/0"
                    }
                    return "Games " + (gameListView.currentIndex + 1) + "/" + gameListView.model.count
                }
                font.pixelSize: root.width * 0.015
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
                spacing: root.width * 0.005


                anchors {
                    right: parent.right
                    rightMargin: root.width * 0.28
                    verticalCenter: parent.verticalCenter
                }
                y: gamesVisible ? 0 : parent.height

                SequentialAnimation on y {
                    NumberAnimation {
                        to: 0
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

                Row {
                    id: row1
                    spacing: root.width * 0.001
                    Image {
                        source: "assets/icons/x.png"
                        width: root.width * 0.022
                        height: root.width * 0.022
                        mipmap: true
                    }
                    Text {
                        text: "Favorite"
                        color: "white"
                        font.pixelSize: root.width * 0.011
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Row {
                    id: row2
                    spacing: root.width * 0.001
                    Image {
                        source: "assets/icons/a.png"
                        width: root.width * 0.022
                        height: root.width * 0.022
                        mipmap: true
                    }
                    Text {
                        text: "OK"
                        color: "white"
                        font.pixelSize: root.width * 0.011
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Row {
                    id: row3
                    spacing: root.width * 0.001
                    Image {
                        source: "assets/icons/y.png"
                        width: root.width * 0.022
                        height: root.width * 0.022
                        mipmap: true
                    }
                    Text {
                        text: "Filter"
                        color: "white"
                        font.pixelSize: root.width * 0.011
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Row {
                    id: row4
                    spacing: root.width * 0.001
                    Image {
                        source: "assets/icons/b.png"
                        width: root.width * 0.022
                        height: root.width * 0.022
                        mipmap: true
                    }
                    Text {
                        text: "Back"
                        color: "white"
                        font.pixelSize: root.width * 0.011
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
    }

    MusicPlayer {
        id: musicPlayer
        width: parent.width * 0.25
        height: parent.height * 0.08
        anchors {
            right: parent.right
            rightMargin: parent.width * 0.02
            bottom: parent.bottom
            bottomMargin: 5
        }
        z: 999
    }

    Item {
        id: musicControls
        width: parent.width * 0.25
        height: parent.height * 0.06
        anchors {
            right: parent.right
            rightMargin: parent.width * 0.02
            bottom: musicPlayer.top
        }
        z: 999

        Row {
            anchors.centerIn: parent
            spacing: 15

            Row {
                spacing: 8
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    width: 40
                    height: 25
                    radius: 12
                    color: "#333333"
                    border.color: "#555555"
                    border.width: 1

                    Text {
                        text: "LT"
                        color: "white"
                        font.pixelSize: 14
                        font.bold: true
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: musicPlayer.previousTrack()
                    }
                }

                Text {
                    text: "Previous Music"
                    color: "white"
                    font.pixelSize: 14
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Row {
                spacing: 8
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    width: 40
                    height: 25
                    radius: 12
                    color: "#333333"
                    border.color: "#555555"
                    border.width: 1

                    Text {
                        text: "RT"
                        color: "white"
                        font.pixelSize: 14
                        font.bold: true
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: musicPlayer.nextTrack()
                    }
                }

                Text {
                    text: "Next Music"
                    color: "white"
                    font.pixelSize: 14
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    Keys.onPressed: {
        if (event.isAutoRepeat) {
            return;
        }

        if (api.keys.isPageUp(event)) {
            event.accepted = true;
            musicPlayer.nextTrack();
        }
        else if (api.keys.isPageDown(event)) {
            event.accepted = true;
            musicPlayer.previousTrack();
        }
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
