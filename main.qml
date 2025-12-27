import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import GeoTiffProcessor

ApplicationWindow {
    id: mainWindow
    visible: true
    width: 1600
    height: 900
    title: "Olive GeoTIFF Analysis Viewer"
    
    // Processor backend
    GeoTiffProcessor {
        id: processor
        onAnalysisCompleted: {
            resultImage.updateImage(resultPath)
            param1Text.text = param1.toFixed(4)
            param2Text.text = param2.toFixed(4)
        }
        onErrorOccurred: {
            errorDialog.text = errorMessage
            errorDialog.open()
        }
    }
    
    // Color maps definition
    property var colorMaps: [
        { name: "Jet", colors: ["#000080", "#0000FF", "#00FFFF", "#00FF00", "#FFFF00", "#FF0000", "#800000"] },
        { name: "Hot", colors: ["#000000", "#FF0000", "#FFFF00", "#FFFFFF"] },
        { name: "Cool", colors: ["#00FFFF", "#FF00FF"] },
        { name: "Gray", colors: ["#000000", "#FFFFFF"] },
        { name: "Viridis", colors: ["#440154", "#31688e", "#35b779", "#fde724"] },
        { name: "Plasma", colors: ["#0d0887", "#7e03a8", "#cc4778", "#f89540", "#f0f921"] }
    ]
    
    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        
        // Main content area
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 2
            
            // Left panel - Two GeoTIFF images
            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: parent.width * 0.35
                color: "#2b2b2b"
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 5
                    spacing: 5
                    
                    // Image 1
                    GeoTiffImagePanel {
                        id: image1Panel
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        panelTitle: "Image 1"
                        colorMaps: mainWindow.colorMaps
                        onImageChanged: {
                            processor.setImage1(imagePath)
                            updateAnalysis()
                        }
                    }
                    
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 2
                        color: "#404040"
                    }
                    
                    // Image 2
                    GeoTiffImagePanel {
                        id: image2Panel
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        panelTitle: "Image 2"
                        colorMaps: mainWindow.colorMaps
                        onImageChanged: {
                            processor.setImage2(imagePath)
                            updateAnalysis()
                        }
                    }
                }
            }
            
            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 2
                color: "#404040"
            }
            
            // Right panel - Analysis result
            Rectangle {
                Layout.fillHeight: true
                Layout.fillWidth: true
                color: "#2b2b2b"
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10
                    
                    Label {
                        text: "Analysis Result"
                        font.pixelSize: 18
                        font.bold: true
                        color: "#ffffff"
                    }
                    
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "#1e1e1e"
                        border.color: "#404040"
                        border.width: 1
                        
                        ResultImageViewer {
                            id: resultImage
                            anchors.fill: parent
                            anchors.margins: 5
                        }
                    }
                    
                    Button {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Run Analysis"
                        enabled: processor.hasValidImages
                        onClicked: processor.runAnalysis()
                        
                        background: Rectangle {
                            color: parent.enabled ? (parent.pressed ? "#0066cc" : "#0080ff") : "#404040"
                            radius: 4
                        }
                        
                        contentItem: Text {
                            text: parent.text
                            color: "#ffffff"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: 14
                        }
                    }
                }
            }
        }
        
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 2
            color: "#404040"
        }
        
        // Bottom panel - Parameters
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 80
            color: "#333333"
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 15
                spacing: 30
                
                Label {
                    text: "Analysis Parameters:"
                    font.pixelSize: 14
                    font.bold: true
                    color: "#ffffff"
                }
                
                RowLayout {
                    spacing: 10
                    
                    Rectangle {
                        width: 200
                        height: 50
                        color: "#1e1e1e"
                        border.color: "#0080ff"
                        border.width: 2
                        radius: 5
                        
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 2
                            
                            Label {
                                text: "Param1"
                                font.pixelSize: 11
                                color: "#888888"
                                Layout.alignment: Qt.AlignHCenter
                            }
                            
                            Label {
                                id: param1Text
                                text: "---"
                                font.pixelSize: 16
                                font.bold: true
                                color: "#00ff00"
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }
                    
                    Rectangle {
                        width: 200
                        height: 50
                        color: "#1e1e1e"
                        border.color: "#0080ff"
                        border.width: 2
                        radius: 5
                        
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 2
                            
                            Label {
                                text: "Param2"
                                font.pixelSize: 11
                                color: "#888888"
                                Layout.alignment: Qt.AlignHCenter
                            }
                            
                            Label {
                                id: param2Text
                                text: "---"
                                font.pixelSize: 16
                                font.bold: true
                                color: "#00ff00"
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }
                }
                
                Item { Layout.fillWidth: true }
            }
        }
    }
    
    // Error dialog
    Dialog {
        id: errorDialog
        property alias text: errorLabel.text
        title: "Error"
        standardButtons: Dialog.Ok
        modal: true
        anchors.centerIn: parent
        
        Label {
            id: errorLabel
            color: "#ff0000"
        }
    }
    
    function updateAnalysis() {
        if (processor.hasValidImages) {
            processor.runAnalysis()
        }
    }
}
