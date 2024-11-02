
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

    function getColorForSystem(shortName) {
        const xhr = new XMLHttpRequest();
        xhr.open("GET", "assets/colorshortname.txt", false);
        xhr.send();

        if (xhr.status === 200) {
            const lines = xhr.responseText.split("\n");
            for (let line of lines) {
                const [system, color] = line.split("=").map(s => s.trim());
                if (system === shortName) {
                    return color;
                }
            }
        }
        return "#000000";
    }

    Rectangle {
        id: background
        anchors.fill: parent
        color: root.backgroundColor

        Behavior on color {
            ColorAnimation { duration: 500 }
        }
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
        font.pixelSize: 24
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
            interval: 1000
            running: true
            repeat: true
            onTriggered: clock.text = clock.formatTime()
        }
    }

    Row {
        id: batteryIndicator
        anchors {
            top: parent.top
            right: parent.right
            topMargin: 20
            rightMargin: 20
        }
        spacing: 8

        Text {
            id: batteryText
            color: "white"
            font.pixelSize: 24
            text: "N/A" // Por defecto "N/A"
        }

        Image {
            id: batteryIcon
            source: "assets/icons/charging.png"
            width: 40
            height: 24
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            mipmap: true
            anchors.verticalCenter: parent.verticalCenter
        }

        // Timer para actualizar el estado de la batería
        Timer {
            interval: 5000 // Actualizar cada 5 segundos
            running: true
            repeat: true
            onTriggered: updateBatteryStatus()
        }
    }

    function updateBatteryStatus() {
        if (typeof navigator.getBattery === "function") {
            navigator.getBattery().then(function(battery) {
                let level = battery.level * 100;
                let isCharging = battery.charging;

                if (isCharging || level > 95) {
                    batteryText.text = "95%+";
                    batteryIcon.source = "assets/icons/charging.png";
                } else if (level > 90) {
                    batteryText.text = "90%";
                    batteryIcon.source = "assets/icons/95.png";
                } else if (level > 75) {
                    batteryText.text = "75%";
                    batteryIcon.source = "assets/icons/75.png";
                } else if (level > 50) {
                    batteryText.text = "50%";
                    batteryIcon.source = "assets/icons/50.png";
                } else if (level > 25) {
                    batteryText.text = "25%";
                    batteryIcon.source = "assets/icons/25.png";
                } else {
                    batteryText.text = "10%";
                    batteryIcon.source = "assets/icons/10.png";
                }
            });
        } else {
            batteryText.text = "N/A";
            batteryIcon.source = "assets/icons/charging.png";
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
                    margins: -parent.width * 0.025  // Márgenes proporcionales
                    topMargin: -parent.width * 0.05
                    bottomMargin: -systemView.height * 0.6
                }
                color: "transparent"
                border.color: "white"
                border.width: Math.max(2, parent.width * 0.015)  // Grosor del borde proporcional
                radius: parent.width * 0.2  // Radio proporcional
                opacity: delegateItem.PathView.isCurrentItem ? 1 : 0
                Behavior on opacity {
                    NumberAnimation { duration: 300 }
                }
            }

            Image {
                id: systemIcon
                anchors {
                    fill: parent
                    margins: parent.width * 0.05  // Márgenes proporcionales
                }
                source: "assets/shortnames/" + modelData.shortName + ".png"
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                mipmap: true
            }

            Column {
                anchors {
                    bottom: selectionRect.bottom
                    bottomMargin: selectionRect.height * 0.05
                    horizontalCenter: parent.horizontalCenter
                }
                spacing: parent.height * 0.01  // Espaciado proporcional

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: modelData.shortName.toUpperCase() || ""
                    color: "white"
                    font.bold: true
                    font.pixelSize: delegateItem.width * 0.1  // Tamaño de fuente proporcional
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "(1992)"
                    color: "white"
                    font.pixelSize: delegateItem.width * 0.1  // Tamaño de fuente proporcional
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
        Keys.onLeftPressed: decrementCurrentIndex()
        Keys.onRightPressed: incrementCurrentIndex()

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
            gameListView.model = selectedCollection.games; // juegos de cada colección seleccionada.
            currentCollectionName = model.get(currentIndex).name;
            currentShortName = model.get(currentIndex).shortName;
            root.backgroundColor = getColorForSystem(currentShortName);
        }

        Component.onCompleted: {
            currentIndex = 0
            const initialCollection = api.collections.get(0);
            gameListView.model = initialCollection.games;
            const selectedCollection = api.collections.get(currentIndex);
            currentCollectionName = model.get(currentIndex).name;
            currentShortName = model.get(currentIndex).shortName;
            root.backgroundColor = getColorForSystem(currentShortName);
        }
    }

    Text {
        id: gamesCount
        anchors {
            bottom: dotsRow.top
            horizontalCenter: parent.horizontalCenter
            bottomMargin: 10
        }
        text: api.collections.get(systemView.currentIndex).games.count + " games"
        color: "white"
        font.pixelSize: 16
        visible: collectionsVisible
    }

    Row {
        id: dotsRow
        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
            bottomMargin: 20
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

        Rectangle {
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

        ListView {
            id: gameListView
            anchors {
                left: parent.left
                leftMargin: 20
                verticalCenter: parent.verticalCenter
            }
            width: parent.width * 0.4
            height: parent.height * 0.80
            spacing: 5

            delegate: Item {
                width: gameListView.width
                height: 40

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
                        `${number} - ${model.title}`;
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

            focus: gamesFocused
            Keys.onUpPressed: gameListView.decrementCurrentIndex()
            Keys.onDownPressed: gameListView.incrementCurrentIndex()

            Keys.onPressed: {
                if (!event.isAutoRepeat && api.keys.isCancel(event)) {
                    event.accepted = true;
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
