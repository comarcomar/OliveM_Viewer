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
        color: "#1e1e1e"
        
        ColumnLayout {
            anchors.fill: parent
            spacing: 0
            
            // Toolbar with zoom controls
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 45
                color: "#2a2a2a"
                border.color: "#404040"
                border.width: 1
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 5
                    spacing: 5
                    
                    Label {
                        text: root.panelTitle
                        font.pixelSize: 12
                        font.bold: true
                        color: "#ffffff"
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    ToolButton {
                        implicitWidth: 32
                        implicitHeight: 32
                        contentItem: Text { text: "+"; font.pixelSize: 18; font.bold: true; color: "#ffffff"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        background: Rectangle { color: parent.pressed ? "#0066cc" : (parent.hovered ? "#004499" : "#003366"); radius: 3 }
                        onClicked: detachedImageViewer.zoomIn()
                    }
                    
                    ToolButton {
                        implicitWidth: 32
                        implicitHeight: 32
                        contentItem: Text { text: "−"; font.pixelSize: 18; font.bold: true; color: "#ffffff"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        background: Rectangle { color: parent.pressed ? "#0066cc" : (parent.hovered ? "#004499" : "#003366"); radius: 3 }
                        onClicked: detachedImageViewer.zoomOut()
                    }
                    
                    ToolButton {
                        implicitWidth: 32
                        implicitHeight: 32
                        contentItem: Text { text: "⟲"; font.pixelSize: 16; color: "#ffffff"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        background: Rectangle { color: parent.pressed ? "#0066cc" : (parent.hovered ? "#004499" : "#003366"); radius: 3 }
                        onClicked: detachedImageViewer.resetView()
                    }
                }
            }
            
            ImageViewerContent {
                id: detachedImageViewer
                Layout.fillWidth: true
                Layout.fillHeight: true
                imagePath: root.imagePath
                colorMapIndex: root.currentColorMap
                showLegend: false
                hideInstructionsDelay: 5000
            }
        }
    }
    
    ColumnLayout {
        anchors.fill: parent
        spacing: 5
        
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
                
                ToolButton {
                    implicitWidth: 32; implicitHeight: 32; enabled: root.imagePath !== ""
                    contentItem: Text { text: "+"; font.pixelSize: 18; font.bold: true; color: parent.enabled ? "#ffffff" : "#666666"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    background: Rectangle { color: parent.pressed ? "#0066cc" : (parent.hovered ? "#004499" : "#003366"); radius: 3 }
                    onClicked: imageViewer.zoomIn()
                    ToolTip.visible: hovered; ToolTip.text: "Zoom In"; ToolTip.delay: 500
                }
                
                ToolButton {
                    implicitWidth: 32; implicitHeight: 32; enabled: root.imagePath !== ""
                    contentItem: Text { text: "−"; font.pixelSize: 18; font.bold: true; color: parent.enabled ? "#ffffff" : "#666666"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    background: Rectangle { color: parent.pressed ? "#0066cc" : (parent.hovered ? "#004499" : "#003366"); radius: 3 }
                    onClicked: imageViewer.zoomOut()
                    ToolTip.visible: hovered; ToolTip.text: "Zoom Out"; ToolTip.delay: 500
                }
                
                ToolButton {
                    implicitWidth: 32; implicitHeight: 32; enabled: root.imagePath !== ""
                    contentItem: Text { text: "⟲"; font.pixelSize: 16; color: parent.enabled ? "#ffffff" : "#666666"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    background: Rectangle { color: parent.pressed ? "#0066cc" : (parent.hovered ? "#004499" : "#003366"); radius: 3 }
                    onClicked: imageViewer.resetView()
                    ToolTip.visible: hovered; ToolTip.text: "Reset View"; ToolTip.delay: 500
                }
                
                Rectangle { width: 1; height: 30; color: "#404040" }
                
                ToolButton {
                    implicitWidth: 32; implicitHeight: 32; enabled: root.imagePath !== ""
                    contentItem: Text { text: "⧉"; font.pixelSize: 16; color: parent.enabled ? "#ffffff" : "#666666"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    background: Rectangle { color: parent.pressed ? "#0066cc" : (parent.hovered ? "#004499" : "#003366"); radius: 3 }
                    onClicked: detachedWindow.visible = !detachedWindow.visible
                    ToolTip.visible: hovered; ToolTip.text: "Detach Window"; ToolTip.delay: 500
                }
                
                Rectangle { width: 1; height: 30; color: "#404040" }
                
                Button {
                    text: "Load TIFF"; implicitHeight: 32
                    onClicked: fileDialog.open()
                    background: Rectangle { color: parent.pressed ? "#006600" : (parent.hovered ? "#007700" : "#008800"); radius: 3 }
                    contentItem: Text { text: parent.text; color: "#ffffff"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.pixelSize: 11 }
                }
            }
        }
        
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#1e1e1e"
            border.color: "#404040"
            border.width: 1
            
            RowLayout {
                anchors.fill: parent
                spacing: 0
                
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    
                    ImageViewerContent {
                        id: imageViewer
                        anchors.fill: parent
                        anchors.margins: 5
                        visible: !root.show3D
                        imagePath: root.imagePath
                        colorMapIndex: root.currentColorMap
                        showLegend: false
                        hideInstructionsDelay: 5000
                    }
                    
                    GeoTiff3DView {
                        id: view3D
                        anchors.fill: parent
                        anchors.margins: 5
                        visible: root.show3D
                        imagePath: root.imagePath
                        colorMapIndex: root.currentColorMap
                    }
                }
                
                ColorLegend {
                    Layout.preferredWidth: 30
                    Layout.fillHeight: true
                    visible: root.imagePath !== ""
                    colorMapIndex: root.currentColorMap
                    colorMaps: root.colorMaps
                    imagePath: root.imagePath
                }
            }
        }
        
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            
            Label { text: "Color Map:"; font.pixelSize: 11; color: "#cccccc" }
            
            ComboBox {
                id: colorMapCombo
                Layout.preferredWidth: 150
                model: root.colorMaps
                currentIndex: root.currentColorMap
                textRole: "name"
                onCurrentIndexChanged: { root.currentColorMap = currentIndex }
                
                delegate: ItemDelegate {
                    width: colorMapCombo.width
                    contentItem: RowLayout {
                        spacing: 8
                        Rectangle {
                            width: 60; height: 16
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: modelData.colors[0] }
                                GradientStop { position: 0.5; color: modelData.colors[Math.floor(modelData.colors.length / 2)] }
                                GradientStop { position: 1.0; color: modelData.colors[modelData.colors.length - 1] }
                            }
                            border.color: "#404040"; border.width: 1
                        }
                        Text { text: modelData.name; color: "#ffffff"; font.pixelSize: 11; Layout.fillWidth: true }
                    }
                }
                
                background: Rectangle { color: parent.pressed ? "#1a1a1a" : "#2a2a2a"; border.color: "#404040"; border.width: 1; radius: 3 }
                contentItem: Text { text: colorMapCombo.currentText; color: "#ffffff"; verticalAlignment: Text.AlignVCenter; leftPadding: 5; font.pixelSize: 11 }
            }
            
            CheckBox {
                text: "3D View"; checked: root.show3D; onCheckedChanged: root.show3D = checked
                contentItem: Text { text: parent.text; color: "#cccccc"; leftPadding: parent.indicator.width + 5; verticalAlignment: Text.AlignVCenter; font.pixelSize: 11 }
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
            if (path.startsWith("file:///")) path = path.substring(8)
            else if (path.startsWith("file://")) path = path.substring(7)
            root.imagePath = path
            root.imageChanged(root.imagePath)
        }
    }
}
