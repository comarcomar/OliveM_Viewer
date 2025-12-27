import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Item {
    id: root
    
    property string panelTitle: "Image"
    property var colorMaps: []
    property string imagePath: ""
    property int currentColorMap: 0
    property bool show3D: false
    
    signal imageChanged(string imagePath)
    
    ColumnLayout {
        anchors.fill: parent
        spacing: 5
        
        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            
            Label {
                text: root.panelTitle
                font.pixelSize: 14
                font.bold: true
                color: "#ffffff"
            }
            
            Item { Layout.fillWidth: true }
            
            Button {
                text: "Load TIFF"
                onClicked: fileDialog.open()
                
                background: Rectangle {
                    color: parent.pressed ? "#006600" : "#008800"
                    radius: 3
                }
                
                contentItem: Text {
                    text: parent.text
                    color: "#ffffff"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 11
                }
            }
        }
        
        // Image viewer area
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#1e1e1e"
            border.color: "#404040"
            border.width: 1
            
            RowLayout {
                anchors.fill: parent
                spacing: 0
                
                // Main image area
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    
                    // 2D Image view
                    Image {
                        id: imageView
                        anchors.fill: parent
                        anchors.margins: 5
                        fillMode: Image.PreserveAspectFit
                        visible: !root.show3D
                        source: root.imagePath !== "" ? "image://geotiff/" + root.imagePath + "?colormap=" + root.currentColorMap : ""
                        
                        BusyIndicator {
                            anchors.centerIn: parent
                            running: imageView.status === Image.Loading
                        }
                        
                        Label {
                            anchors.centerIn: parent
                            text: "No image loaded"
                            color: "#666666"
                            visible: root.imagePath === "" && imageView.status !== Image.Loading
                        }
                    }
                    
                    // 3D view placeholder
                    GeoTiff3DView {
                        id: view3D
                        anchors.fill: parent
                        anchors.margins: 5
                        visible: root.show3D
                        imagePath: root.imagePath
                        colorMapIndex: root.currentColorMap
                    }
                }
                
                // Color legend
                Rectangle {
                    Layout.preferredWidth: 60
                    Layout.fillHeight: true
                    color: "#252525"
                    visible: root.imagePath !== ""
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 5
                        spacing: 5
                        
                        Label {
                            text: "Max"
                            font.pixelSize: 9
                            color: "#aaaaaa"
                            Layout.alignment: Qt.AlignHCenter
                        }
                        
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
                        }
                        
                        Label {
                            text: "Min"
                            font.pixelSize: 9
                            color: "#aaaaaa"
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
            }
        }
        
        // Controls
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            
            Label {
                text: "Color Map:"
                font.pixelSize: 11
                color: "#cccccc"
            }
            
            ComboBox {
                id: colorMapCombo
                Layout.fillWidth: true
                model: root.colorMaps.map(function(cm) { return cm.name })
                currentIndex: root.currentColorMap
                onCurrentIndexChanged: {
                    root.currentColorMap = currentIndex
                }
                
                background: Rectangle {
                    color: parent.pressed ? "#1a1a1a" : "#2a2a2a"
                    border.color: "#404040"
                    border.width: 1
                    radius: 3
                }
                
                contentItem: Text {
                    text: parent.displayText
                    color: "#ffffff"
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: 5
                    font.pixelSize: 11
                }
            }
            
            CheckBox {
                id: view3DCheck
                text: "3D View"
                checked: root.show3D
                onCheckedChanged: root.show3D = checked
                
                contentItem: Text {
                    text: parent.text
                    color: "#cccccc"
                    leftPadding: parent.indicator.width + 5
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 11
                }
            }
        }
    }
    
    FileDialog {
        id: fileDialog
        title: "Select GeoTIFF Image"
        fileMode: FileDialog.OpenFile
        nameFilters: ["GeoTIFF files (*.tif *.tiff)", "All files (*)"]
        
        onAccepted: {
            root.imagePath = selectedFile.toString().replace("file://", "")
            root.imageChanged(root.imagePath)
        }
    }
    
    function getColorMapColor(position) {
        if (root.colorMaps.length === 0 || root.currentColorMap >= root.colorMaps.length) {
            return "#888888"
        }
        
        var colors = root.colorMaps[root.currentColorMap].colors
        var index = Math.floor(position * (colors.length - 1))
        var nextIndex = Math.min(index + 1, colors.length - 1)
        var localPos = position * (colors.length - 1) - index
        
        // Simple color interpolation
        if (localPos < 0.01) {
            return colors[index]
        }
        
        return colors[index] // Simplified - full interpolation would be in C++
    }
}
