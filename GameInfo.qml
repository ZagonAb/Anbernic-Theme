import QtQuick 2.15
import QtGraphicalEffects 1.12
import QtQuick.Layouts 1.15
import "qrc:/qmlutils" as PegasusUtils

Item {
    id: gameInfoRoot
    width: parent.width
    height: parent.height

    property var game: null
    property color textColor: "white"
    property color secondaryColor: "#AAAAAA"
    property color backgroundColor: "#40000000"
    property color shadowColor: "#80000000"
    property color highlightColor: "#4CAF50"
    property real cornerRadius: 10
    property real contentMargin: 0.05

    Rectangle {
        id: contentBounds
        anchors {
            fill: parent

        }
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: backgroundColor
            radius: cornerRadius
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: contentBounds.width
                    height: contentBounds.height
                    radius: cornerRadius
                }
            }
        }

        Column {
            width: parent.width
            anchors.centerIn: parent
            spacing: contentBounds.height * 0.02

            Text {
                width: parent.width
                text: game ? game.title : ""
                color: textColor
                font {
                    pixelSize: contentBounds.height * 0.05
                    bold: true
                    family: global.fonts.condensed
                    letterSpacing: 1.5
                    capitalization: Font.AllUppercase
                }
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                maximumLineCount: 2
                wrapMode: Text.Wrap
                lineHeight: 0.9

                layer.enabled: true
                layer.effect: DropShadow {
                    color: shadowColor
                    radius: 8
                    samples: 16
                }
            }

            Item {
                width: parent.width
                height: contentBounds.height * 0.4

                Grid {
                    id: metadataGrid
                    anchors.centerIn: parent
                    width: parent.width * 0.9
                    columns: 2
                    columnSpacing: contentBounds.width * 0.03
                    rowSpacing: contentBounds.height * 0.015

                    component MetadataContainer: Rectangle {
                        property alias labelText: metaLabel.text
                        property alias valueText: metaValue.text
                        property alias valueColor: metaValue.color
                        property alias valueVisible: metaValue.visible
                        property alias customContent: customContentLoader.sourceComponent

                        width: (metadataGrid.width - metadataGrid.columnSpacing) / 2
                        height: contentBounds.height * 0.09
                        color: "#20FFFFFF"
                        border.color: "#60FFFFFF"
                        border.width: 1
                        radius: 6

                        Column {
                            anchors.fill: parent
                            anchors.margins: 4
                            spacing: 1

                            Text {
                                id: metaLabel
                                width: parent.width
                                font {
                                    pixelSize: contentBounds.height * 0.03
                                    bold: true
                                    family: global.fonts.sans
                                }
                                color: secondaryColor
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                            }

                            Text {
                                id: metaValue
                                width: parent.width
                                font {
                                    pixelSize: contentBounds.height * 0.03
                                    family: global.fonts.sans
                                }
                                color: textColor
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                visible: text !== ""
                            }


                            Loader {
                                id: customContentLoader
                                width: parent.width
                                height: contentBounds.height * 0.045
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }

                    MetadataContainer {
                        labelText: "DEVELOPER"
                        valueText: game && game.developer ? game.developer : "Unknown"
                    }

                    MetadataContainer {
                        labelText: "RELEASE YEAR"
                        valueText: {
                            if (!game) return "-";
                            if (game.releaseYear) return game.releaseYear;
                            if (game.release && !isNaN(game.release.getTime()))
                                return game.release.getFullYear();
                            return "Unknown";
                        }
                    }

                    MetadataContainer {
                        labelText: "RATING"
                        valueText: ""
                        customContent: Component {
                            Item {
                                height: contentBounds.height * 0.05
                                width: parent.width
                                Row {
                                    spacing: contentBounds.width * 0.01
                                    anchors.centerIn: parent

                                    Text {
                                        id: ratingFallbackText
                                        text: game ? Math.round(game.rating * 100) + "%" : "0%"
                                        color: textColor
                                        font {
                                            pixelSize: contentBounds.height * 0.03
                                            bold: true
                                        }
                                        visible: false
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Repeater {
                                        id: starsRepeater
                                        model: 5
                                        Image {
                                            width: contentBounds.height * 0.035
                                            height: width
                                            source: {
                                                if (!game) return "assets/icons/star0.png";
                                                const ratingValue = game.rating * 5;
                                                const starIndex = index + 1;

                                                if (ratingValue >= starIndex) return "assets/icons/star1.png";
                                                else if (ratingValue >= starIndex - 0.5) return "assets/icons/star2.png";
                                                else return "assets/icons/star0.png";
                                            }
                                            fillMode: Image.PreserveAspectFit
                                            mipmap: true
                                            anchors.verticalCenter: parent.verticalCenter

                                            onStatusChanged: {
                                                if (status === Image.Error) {
                                                    starsRepeater.model = 0;
                                                    ratingFallbackText.visible = true;
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    MetadataContainer {
                        labelText: "LAST PLAYED"
                        valueText: {
                            if (!game || !game.lastPlayed || isNaN(game.lastPlayed.getTime()))
                                return "Never played";

                            let now = new Date();
                            let diff = Math.floor((now - game.lastPlayed) / (1000 * 60 * 60 * 24));

                            if (diff === 0) return "Today";
                            if (diff === 1) return "Yesterday";
                            if (diff < 7) return diff + " days ago";
                            if (diff < 30) return Math.floor(diff/7) + " weeks ago";
                            return game.lastPlayed.toLocaleDateString(Qt.locale(), "MMM d, yyyy");
                        }
                    }

                    MetadataContainer {
                        labelText: "PLAY COUNT"
                        valueText: game ? game.playCount : "0"
                        visible: game && game.playCount > 0
                    }

                    MetadataContainer {
                        labelText: "PLAY TIME"
                        valueText: {
                            if (!game || game.playTime <= 0) return "-";
                            const hours = Math.floor(game.playTime / 3600);
                            const minutes = Math.floor((game.playTime % 3600) / 60);
                            return (hours > 0 ? hours + "h " : "") + minutes + "m";
                        }
                        visible: game && game.playTime > 0
                    }

                    MetadataContainer {
                        labelText: "FAVORITE"
                        valueText: "❤️"
                        valueColor: highlightColor
                        visible: game && game.favorite
                    }
                }
            }

            Rectangle {
                id: descriptionContainer
                width: parent.width
                height: contentBounds.height * 0.45
                color: "transparent"
                clip: true

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Item {
                        width: descriptionContainer.width
                        height: descriptionContainer.height
                        Rectangle {
                            anchors.top: parent.top
                            width: parent.width
                            height: parent.height * 0.15
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "#00FFFFFF" }
                                GradientStop { position: 1.0; color: "#FFFFFFFF" }
                            }
                        }
                        Rectangle {
                            y: parent.height * 0.15
                            width: parent.width
                            height: parent.height * 0.7
                            color: "#FFFFFFFF"
                        }
                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: parent.height * 0.15
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "#FFFFFFFF" }
                                GradientStop { position: 1.0; color: "#00FFFFFF" }
                            }
                        }
                    }
                }

                PegasusUtils.AutoScroll {
                    id: autoscroll
                    anchors.fill: parent
                    pixelsPerSecond: 20
                    scrollWaitDuration: 2000

                    Text {
                        width: parent.width * 0.94
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: game && game.description ? game.description : "No description available..."
                        color: textColor
                        font {
                            pixelSize: contentBounds.height * 0.035
                            family: global.fonts.sans
                        }
                        wrapMode: Text.WordWrap
                        lineHeight: 1.4
                        textFormat: Text.RichText
                        onLinkActivated: Qt.openUrlExternally(link)
                        topPadding: contentBounds.height * 0.02

                        layer.enabled: true
                        layer.effect: DropShadow {
                            color: shadowColor
                            radius: 2
                            samples: 5
                        }
                    }
                }
            }
        }
    }
}
