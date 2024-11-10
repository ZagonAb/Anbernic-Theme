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

    SoundEffect {
        id: naviSound
        source: "assets/sound/mov.wav"
        volume: 0.5
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

            //Agregar "%" de batería.

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
                color: "transparent"
                border.color: "white"
                border.width: Math.max(2, parent.width * 0.015)
                radius: parent.width * 0.2
                opacity: delegateItem.PathView.isCurrentItem ? 1 : 0
                Behavior on opacity {
                    NumberAnimation { duration: 300 }
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

        focus: collectionsFocused
        Keys.onLeftPressed: decrementCurrentIndex(naviSound.play())
        Keys.onRightPressed: incrementCurrentIndex(naviSound.play())

        Keys.onPressed: {
            if (!event.isAutoRepeat && api.keys.isAccept(event)) {
                event.accepted = true;
                collectionsVisible = false;
                collectionsFocused = false;
                gamesVisible = true;
                gamesFocused = true;
                gameListView.forceActiveFocus();
            }
        }

        onCurrentIndexChanged: {
            const selectedCollection = api.collections.get(currentIndex);
            proxyModel.sourceModel = selectedCollection.games;
            currentCollectionName = model.get(currentIndex).name;
            currentShortName = model.get(currentIndex).shortName;
            root.backgroundColor = getColorForSystem(currentShortName);
        }

        Component.onCompleted: {
            currentIndex = 0
            const initialCollection = api.collections.get(currentIndex);
            proxyModel.sourceModel = initialCollection.games;
            currentCollectionName = model.get(currentIndex).name;
            currentShortName = model.get(currentIndex).shortName;
            root.backgroundColor = getColorForSystem(currentShortName);
            game = proxyModel.get(gameListView.currentIndex);
            gameImage.source = game && game.assets.boxFront ? game.assets.boxFront : "assets/nofound.png";
        }
    }

    Text {
        id: gamesCount
        anchors {
            bottom: dotsRow.top
            horizontalCenter: parent.horizontalCenter
            bottomMargin: root.width * 0.015
        }
        text: api.collections.get(systemView.currentIndex).games.count + " games"
        color: "white"
        font.pixelSize: root.width * 0.015
        font.bold: true
        visible: collectionsVisible
    }

    Row {
        id: dotsRow
        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
            bottomMargin: root.width * 0.05
        }
        spacing: 8
        visible: collectionsVisible

        Repeater {
            model: api.collections.count

            Rectangle {
                width: 8
                height: 8
                radius: width/2
                color: "white"
                border {
                    width: 1
                    color: "white"
                }

                opacity: systemView.currentIndex === index ? 1 : 0.5

                Behavior on opacity {
                    NumberAnimation { duration: 200 }
                }
            }
        }
    }

    Item {
        width: parent.width
        height: parent.height
        visible: gamesVisible

        Row {
            anchors {
                top: parent.top
                left: parent.left
                topMargin: 20
                leftMargin: root.width * 0.05
            }
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
            anchors {
                top: parent.top
                right: parent.right
                topMargin: 20
                rightMargin: root.width * 0.02
            }
            width: parent.width / 3
            height: parent.height
            spacing: root.width * 0.20

            Text {
                color: "white"
                font.pixelSize: root.width * 0.02
                font.bold: true
                text: currentShortName
            }

            Item {
                anchors {
                    top: parent.top
                    topMargin: - root.height * 0.03
                }
                width: parent.width * 0.14
                height: parent.height * 0.14

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

        Text {
            text: "Games " +(gameListView.currentIndex + 1) + "/" + gameListView.model.count
            font.pixelSize: root.width * 0.01
            color: "white"
            font.bold: true
            anchors.top: gameRectangle.bottom
            anchors.horizontalCenter: gameRectangle.horizontalCenter
            anchors.topMargin: root.height * 0.03
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

                /*Text {
                 * id: noEnumerator
                 * text: model.title
                 * color: gameListView.currentIndex === index ? "black" : "white"
                 * font.pixelSize: gameListView.width * 0.05
                 * elide: Text.ElideRight
                 * anchors.verticalCenter: parent.verticalCenter
                 * anchors.left: parent.left
                 * anchors.leftMargin: 10
                 * width: parent.width - 20
            } */
            }

            focus: gamesFocused

            Keys.onUpPressed: gameListView.decrementCurrentIndex()
            Keys.onDownPressed: gameListView.incrementCurrentIndex()
            Keys.onPressed: function(event) {
                if (api.keys.isFilters(event)) {
                    root.filterState = (root.filterState + 1) % 3;
                    gameListView.currentIndex = 0;
                    game = proxyModel.get(gameListView.currentIndex);
                    gameImage.source = game && game.assets.boxFront ? game.assets.boxFront : "assets/default.png";
                    event.accepted = true;
                } else if (!event.isAutoRepeat && api.keys.isCancel(event)) {
                    event.accepted = true;
                    collectionsVisible = true;
                    collectionsFocused = true;
                    gamesVisible = false;
                    gamesFocused = false;
                    systemView.forceActiveFocus();
                }
            }


            onCurrentIndexChanged: {
                game = proxyModel.get(gameListView.currentIndex);
                gameImage.source = game && game.assets.boxFront ? game.assets.boxFront : "assets/default.png";
            }
        }
    }

    readonly property var consoleYears: {
        "mastersystem": "1985",
        "dreamcast": "1998",
        "satellaview": "1995",
        "megadrive": "1988",
        "turbografxcd": "1988",
        "electronicgames": "1977",
        "atarijaguar": "1993",
        "arcadia": "1982",
        "continueplaying": "various",
        "atari2600": "1977",
        "studioii": "1977",
        "quake": "1996",
        "psx": "1994",
        "3ds": "2011",
        "n64": "1996",
        "saturn": "1994",
        "wonderswan": "1999",
        "gamecube": "2001",
        "segapico": "1993",
        "3do-option2": "1993",
        "intellivision": "1979",
        "amstradcpc": "1984",
        "thomsonmoto": "1984",
        "superacan": "1995",
        "3do": "1993",
        "steam": "2003",
        "gp32": "2001",
        "wii": "2006",
        "sg1000": "1983",
        "atari8bit": "1979",
        "msx": "1983",
        "favorite": "various",
        "psp": "2004",
        "n64dd": "1999",
        "amstradgx4000": "1990",
        "xbox360": "2005",
        "watara": "1992",
        "gog": "2008",
        "sega32x": "1994",
        "loopy": "1995",
        "commodorepet": "1977",
        "commodore64": "1982",
        "necpc98": "1982",
        "cavestory": "2004",
        "rpgmaker": "1988",
        "gb": "1989",
        "commodorecdtv": "1991",
        "tiger": "1997",
        "adventurevision": "1982",
        "mame2003": "2003",
        "vectrex": "1982",
        "wonderswancolor": "2000",
        "vsmile": "2004",
        "videopac+": "1978",
        "segacd": "1991",
        "vircon32": "2021",
        "necpc8001": "1979",
        "mame2010": "2010",
        "commodoreplus4": "1984",
        "mame2003midway": "2003",
        "amigacd32": "1993",
        "tic80": "2016",
        "sufamiturbo": "1996",
        "arduboy": "2015",
        "jagaurcd": "1995",
        "snes": "1990",
        "cassettevision": "1981",
        "colecovision": "1982",
        "snkneogeo": "1990",
        "xbox": "2001",
        "nes": "1983",
        "ngp": "1998",
        "atarilynx": "1989",
        "ds": "2004",
        "naomi2": "2000",
        "gba": "2001",
        "pv1000": "1983",
        "switch": "2017",
        "atarist": "1985",
        "wasm4": "2021",
        "pokemini": "2001",
        "dos": "1981",
        "pcfx": "1994",
        "ngpc": "1999",
        "lutris": "2010",
        "creativision": "1981",
        "gamemaster": "1990",
        "zx81": "1981",
        "amiga": "1985",
        "msx2": "1985",
        "atari7800": "1986",
        "odyssey2": "1978",
        "scummvm": "2001",
        "doom": "1993",
        "gbc": "1998",
        "virtualboy": "1995",
        "supergrafx": "1989",
        "ports": "various",
        "naomi": "1998",
        "ps2": "2000",
        "channelf": "1976",
        "mame": "1997",
        "mrboom": "1999",
        "atomiswave": "2003",
        "mame2000": "2000",
        "ps3": "2006",
        "gc": "2001",
        "nesdisk": "1986",
        "ps4": "2013",
        "zxspectrum": "1982",
        "ngcd": "1994",
        "atari5200": "1982",
        "mame2003plus": "2003",
        "gamegear": "1990",
        "fbneo": "various",
        "leapster": "2003",
        "lutro": "N/A",
        "lowres": "2017",
        "turbografx16": "1987",
        "arcade": "various",
        "wiiu": "2012",
        "commodorevic20": "1980",
        "dsi": "2008",
        "vita": "2011"
    }

    readonly property var consoleColors: {
        "nesdisk": "#817d00",
        "mastersystem": "#4d0d0c",
        "dreamcast": "#5c5c5c",
        "megadrive": "#20346d",
        "turbografxcd": "#6a3921",
        "electronicgames": "#247f00",
        "arcadia": "#625a43",
        "continueplaying": "#048d2f",
        "atari2600": "#4e3621",
        "studioii": "#7f7660",
        "quake": "#333d3d",
        "psx": "#ad5200",
        "3ds": "#003145",
        "n64": "#00613f",
        "saturn": "#033a74",
        "wonderswan": "#1f2319",
        "segapico": "#9c8e63",
        "3do-option2": "#706002",
        "intellivision": "#6e614f",
        "amstradcpc": "#305539",
        "thomsonmoto": "#1e1e1b",
        "3do": "#746305",
        "atarijaguar": "#2a0000",
        "steam": "#091734",
        "gp32": "#145040",
        "wii": "#4d4d4d",
        "sg1000": "#636363",
        "atari8bit": "#3f3428",
        "msx": "#010101",
        "favorite": "#8d023e",
        "psp": "#003952",
        "n64dd": "#002f1f",
        "amstradgx4000": "#56010f",
        "xbox360": "#093b09",
        "watara": "#3f571d",
        "gog": "#230037",
        "sega32x": "#530000",
        "satellaview": "#2e3131",
        "loopy": "#431f2e",
        "necpc98": "#534d46",
        "cavestory": "#141421",
        "rpgmaker": "#171b16",
        "gb": "#5c6a66",
        "tiger": "#62684d",
        "adventurevision": "#240200",
        "mame2003": "#025a98",
        "wonderswancolor": "#001a37",
        "vsmile": "#934d10",
        "videopac+": "#303032",
        "segacd": "#777777",
        "vircon32": "#29443a",
        "necpc8001": "#252326",
        "mame2010": "#025a98",
        "mame2003midway": "#025a98",
        "gamegear": "#324361",
        "amigacd32": "#5a2b1d",
        "tic80": "#1f5076",
        "sufamiturbo": "#282825",
        "arduboy": "#565456",
        "jagaurcd": "#2a0000",
        "snes": "#690900",
        "cassettevision": "#284214",
        "colecovision": "#1d1e1f",
        "xbox": "#093b09",
        "nes": "#7b3832",
        "ngp": "#3e3d49",
        "atarilynx": "#7a510e",
        "ds": "#383838",
        "naomi2": "#701d0b",
        "gba": "#101542",
        "pv1000": "#1b3a2f",
        "switch": "#551610",
        "atarist": "#31679a",
        "wasm4": "#2e4219",
        "pokemini": "#2a4219",
        "dos": "#601d73",
        "pcfx": "#af917a",
        "ngpc": "#5a7787",
        "lutris": "#ff8600",
        "creativision": "#412c05",
        "snkneogeo": "#807130",
        "gamecube-option2": "#261c3d",
        "gamemaster": "#425621",
        "zx81": "#8a1f0c",
        "amiga": "#454743",
        "msx2": "#010101",
        "atari7800": "#4c4b4b",
        "odyssey2": "#f57d24",
        "scummvm": "#026e1d",
        "doom": "#793900",
        "gbc": "#631f2e",
        "virtualboy": "#1b0607",
        "supergrafx": "#6a3921",
        "ports": "#ac3903",
        "vectrex": "#151414",
        "commodoreplus4": "#150d08",
        "naomi": "#701d0b",
        "superarcan": "#2b2b2b",
        "ps2": "#0a006a",
        "commodore64": "#2c251e",
        "channelf": "#2b1e19",
        "mame": "#025a98",
        "mrboom": "#3a211d",
        "atomiswave": "#692c19",
        "commodorecdtv": "#393a3d",
        "mame2000": "#025a98",
        "ps3": "#003384",
        "gc": "#2a3472",
        "ps4": "#121215",
        "commodorevic20": "#1d1b3b",
        "zxspectrum": "#8a1f0c",
        "commodorepet": "#258179",
        "ngcd": "#201f1a",
        "atari5200": "#292524",
        "mame2003plus": "#025a98",
        "fbneo": "#99512f",
        "leapster": "#384a1e",
        "lutro": "#412037",
        "lowres": "#743e03",
        "turbografx16": "#6a3921",
        "arcade": "#631f08",
        "wiiu": "#012f3d",
        "dsi": "#2a2a2a",
        "vita": "#02013b"
    }
}
