import QtQuick 2.15
import SortFilterProxyModel 0.2

Image {
    id: gameImage
    anchors {
        left: parent.left
        leftMargin: parent.width * 0.4 + 40
        right: parent.right
        rightMargin: 20
        verticalCenter: parent.verticalCenter
    }
    height: parent.height * 0.70
    source: ""
    fillMode: Image.PreserveAspectFit
    asynchronous: true
    mipmap: true

    Connections {
        target: gameListView
        function onUpdateImageSource(newSource) {
            gameImage.source = newSource;
        }
    }

    Rectangle {
        id: mediaTypeIndicator
        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
            bottomMargin: parent.height * 0.01
        }
        width: parent.width * 0.1
        height: parent.height * 0.05
        radius: height / 2
        color: "#80000000"
        border.color: "#60FFFFFF"
        border.width: 1
        visible: gameListView.game !== null

        Row {
            anchors.centerIn: parent
            spacing: 10

            Rectangle {
                width: parent.parent.height * 0.4
                height: width
                radius: width / 2
                color: gameListView.currentMediaType === 0 ? "white" : "#60FFFFFF"
                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }

            Rectangle {
                width: parent.parent.height * 0.4
                height: width
                radius: width / 2
                color: gameListView.currentMediaType === 1 ? "white" : "#60FFFFFF"
                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }
        }
    }
}
