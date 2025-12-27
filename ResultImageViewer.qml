import QtQuick
import QtQuick.Controls

Item {
    id: root
    
    property string resultPath: ""
    
    function updateImage(path) {
        resultPath = path
        resultImage.source = ""
        resultImage.source = "file://" + path
    }
    
    Image {
        id: resultImage
        anchors.fill: parent
        fillMode: Image.PreserveAspectFit
        cache: false
        
        BusyIndicator {
            anchors.centerIn: parent
            running: resultImage.status === Image.Loading
        }
        
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: resultImage.status === Image.Ready ? "#00ff00" : "transparent"
            border.width: 2
        }
    }
    
    Label {
        anchors.centerIn: parent
        text: "Run analysis to see results"
        color: "#666666"
        font.pixelSize: 14
        visible: resultPath === "" && resultImage.status !== Image.Loading
    }
    
    // Zoom controls
    Row {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 10
        spacing: 5
        visible: resultImage.status === Image.Ready
        
        Button {
            text: "+"
            width: 30
            height: 30
            onClicked: {
                resultImage.scale = Math.min(resultImage.scale * 1.2, 5.0)
            }
            
            background: Rectangle {
                color: parent.pressed ? "#006600" : "#004400"
                radius: 3
                opacity: 0.8
            }
            
            contentItem: Text {
                text: parent.text
                color: "#ffffff"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 16
                font.bold: true
            }
        }
        
        Button {
            text: "-"
            width: 30
            height: 30
            onClicked: {
                resultImage.scale = Math.max(resultImage.scale / 1.2, 0.5)
            }
            
            background: Rectangle {
                color: parent.pressed ? "#006600" : "#004400"
                radius: 3
                opacity: 0.8
            }
            
            contentItem: Text {
                text: parent.text
                color: "#ffffff"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 16
                font.bold: true
            }
        }
        
        Button {
            text: "Reset"
            width: 50
            height: 30
            onClicked: {
                resultImage.scale = 1.0
            }
            
            background: Rectangle {
                color: parent.pressed ? "#006600" : "#004400"
                radius: 3
                opacity: 0.8
            }
            
            contentItem: Text {
                text: parent.text
                color: "#ffffff"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 10
            }
        }
    }
}
