import QtQuick 2.15

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
