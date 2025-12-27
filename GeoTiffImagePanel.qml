import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.Window

Item {
    id: root
    
    property string panelTitle: "Image"
    property var colorMaps: []
    property string imagePath: ""
    property int currentColorMap: 0
    property bool show3D: false
    
    signal imageChanged(string imagePath)
    
    // Detached window for image
    Window {
        id: detachedWindow
        visible: false
        width: 800
        height: 600
        title: root.panelTitle + " - Detached View"
        
        Rectangle {
            anchors.fill: parent
            color: "#1e1e1e"
            
            ImageViewerContent {
                anchors.fill: parent
                imagePath: root.imagePath
                colorMapIndex: root.currentColorMap
                showLegend: true
            }
        }
    }
    
    ColumnLayout {
        anchors.fill: parent
        spacing: 5
        
        // Header with title and controls
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 45
            color: "#2a2a2a"
            border.color: "#404040"
            border.width: 1
            radius: 3
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 5
                spacing: 5
                
                Label {
                    text: root.panelTitle
                    font.pixelSize: 14
                    font.bold: true
                    color: "#ffffff"
                }
                
                Item { Layout.fillWidth: true }
                
                // Zoom In
                ToolButton {
                    implicitWidth: 32
                    implicitHeight: 32
                    enabled: root.imagePath !== ""
                    
                    contentItem: Text {
                        text: "+"
                        font.pixelSize: 18
                        font.bold: true
                        color: parent.enabled ? "#ffffff" : "#666666"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    background: Rectangle {
                        color: parent.pressed ? "#0066cc" : (parent.hovered ? "#004499" : "#003366")
                        radius: 3
                    }
                    
                    onClicked: imageViewer.zoomIn()
                    
                    ToolTip.visible: hovered
                    ToolTip.text: "Zoom In"
                    ToolTip.delay: 500
                }
                
                // Zoom Out
                ToolButton {
                    implicitWidth: 32
                    implicitHeight: 32
                    enabled: root.imagePath !== ""
                    
                    contentItem: Text {
                        text: "−"
                        font.pixelSize: 18
                        font.bold: true
                        color: parent.enabled ? "#ffffff" : "#666666"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    background: Rectangle {
                        color: parent.pressed ? "#0066cc" : (parent.hovered ? "#004499" : "#003366")
                        radius: 3
                    }
                    
                    onClicked: imageViewer.zoomOut()
                    
                    ToolTip.visible: hovered
                    ToolTip.text: "Zoom Out"
                    ToolTip.delay: 500
                }
                
                // Reset View
                ToolButton {
                    implicitWidth: 32
                    implicitHeight: 32
                    enabled: root.imagePath !== ""
                    
                    contentItem: Text {
                        text: "⟲"
                        font.pixelSize: 16
                        color: parent.enabled ? "#ffffff" : "#666666"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    background: Rectangle {
                        color: parent.pressed ? "#0066cc" : (parent.hovered ? "#004499" : "#003366")
                        radius: 3
                    }
                    
                    onClicked: imageViewer.resetView()
                    
                    ToolTip.visible: hovered
                    ToolTip.text: "Reset View"
                    ToolTip.delay: 500
                }
                
                Rectangle {
                    width: 1
                    height: 30
                    color: "#404040"
                }
                
                // Detach Window
                ToolButton {
                    implicitWidth: 32
                    implicitHeight: 32
                    enabled: root.imagePath !== ""
                    
                    contentItem: Text {
                        text: "⧉"
                        font.pixelSize: 16
                        color: parent.enabled ? "#ffffff" : "#666666"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    background: Rectangle {
                        color: parent.pressed ? "#0066cc" : (parent.hovered ? "#004499" : "#003366")
                        radius: 3
                    }
                    
                    onClicked: detachedWindow.visible = !detachedWindow.visible
                    
                    ToolTip.visible: hovered
                    ToolTip.text: "Detach Window"
                    ToolTip.delay: 500
                }
                
                Rectangle {
                    width: 1
                    height: 30
                    color: "#404040"
                }
                
                // Load Button
                Button {
                    text: "Load TIFF"
                    implicitHeight: 32
                    
                    onClicked: fileDialog.open()
                    
                    background: Rectangle {
                        color: parent.pressed ? "#006600" : (parent.hovered ? "#007700" : "#008800")
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
                    
                    // 2D Image view with pan/zoom
                    ImageViewerContent {
                        id: imageViewer
                        anchors.fill: parent
                        anchors.margins: 5
                        visible: !root.show3D
                        imagePath: root.imagePath
                        colorMapIndex: root.currentColorMap
                        showLegend: false
                    }
                    
                    // 3D view
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
            var path = selectedFile.toString()
            // Remove file:/// prefix
            if (path.startsWith("file:///")) {
                path = path.substring(8)
            } else if (path.startsWith("file://")) {
                path = path.substring(7)
            }
            
            console.log("Loading image from:", path)
            root.imagePath = path
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
        
        if (index === nextIndex) {
            return colors[index]
        }
        
        return colors[index]
    }
}
