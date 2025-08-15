import QtQuick 2.15

Text {
    id: gamesCount
    anchors {
        bottom: parent.bottom
        horizontalCenter: parent.horizontalCenter
        bottomMargin: root.width * 0.015
    }
    text: api.collections.get(systemView.currentIndex).games.count + " games"
    color: "white"
    font.pixelSize: root.width * 0.015
    font.bold: true
    visible: collectionsVisible
}
