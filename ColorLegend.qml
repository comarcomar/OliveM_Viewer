import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    
    property int colorMapIndex: 0
    property var colorMaps: []
    property string imagePath: ""
    property real minValue: 0
    property real maxValue: 255
    property var processor: null
    
    color: "#252525"
    
    // Update statistics when image changes
    onImagePathChanged: {
        if (imagePath !== "" && processor !== null) {
            updateStatistics()
        }
    }

    Component.onCompleted: {
        if (imagePath !== "" && processor !== null) {
            updateStatistics()
        }
    }
    
    function updateStatistics() {
        if (processor === null || imagePath === "") return
        
        try {
            var stats = processor.getImageStatistics(imagePath)
            if (stats.valid) {
                minValue = stats.min
                maxValue = stats.max
                console.log("ColorLegend updated stats - Min:", minValue, "Max:", maxValue)
            }
        } catch (e) {
            console.error("Error getting statistics:", e)
        }
    }
    
    function getColorMapColor(position) {
        if (colorMaps.length === 0 || colorMapIndex >= colorMaps.length) {
            return "#888888"
        }
        
        var colors = colorMaps[colorMapIndex].colors
        var index = Math.floor(position * (colors.length - 1))
        index = Math.max(0, Math.min(index, colors.length - 1))
        return colors[index]
    }
    
    function formatValue(value) {
        if (value >= 1000) {
            return (value / 1000).toFixed(1) + "k"
        } else if (value >= 100) {
            return value.toFixed(0)
        } else if (value >= 10) {
            return value.toFixed(1)
        } else {
            return value.toFixed(2)
        }
    }
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 3
        spacing: 2
        
        // Max value
        Label {
            text: formatValue(maxValue)
            font.pixelSize: 8
            color: "#aaaaaa"
            Layout.alignment: Qt.AlignHCenter
        }
        
        // Gradient
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            gradient: Gradient {
                GradientStop { position: 0.0; color: getColorMapColor(1.0) }
                GradientStop { position: 0.25; color: getColorMapColor(0.75) }
                GradientStop { position: 0.5; color: getColorMapColor(0.5) }
                GradientStop { position: 0.75; color: getColorMapColor(0.25) }
                GradientStop { position: 1.0; color: getColorMapColor(0.0) }
            }
            
            // Value markers
            Column {
                anchors.fill: parent
                spacing: 0
                
                Repeater {
                    model: 3 // 3 intermediate values
                    
                    Item {
                        width: parent.width
                        height: parent.height / 4
                        
                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width * 0.3
                            height: 1
                            color: "#666666"
                        }
                        
                        Label {
                            anchors.bottom: parent.bottom
                            anchors.right: parent.right
                            anchors.rightMargin: -25
                            text: formatValue(maxValue - (maxValue - minValue) * (index + 1) / 4)
                            font.pixelSize: 7
                            color: "#888888"
                        }
                    }
                }
            }
        }
        
        // Min value
        Label {
            text: formatValue(minValue)
            font.pixelSize: 8
            color: "#aaaaaa"
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
