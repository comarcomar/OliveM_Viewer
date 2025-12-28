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
    property var processor: null
    property var themeColors: ({
        panelColor: "#2a2a2a",
        borderColor: "#404040",
        textColor: "#ffffff",
        textSecondaryColor: "#cccccc",
        buttonColor: "#003366",
        buttonHoverColor: "#004499",
        buttonPressedColor: "#0066cc"
    })
    
    signal imageChanged(string imagePath)
    
    // Detached window for image
    Window {
        id: detachedWindow
        visible: false
        width: 800
        height: 600
        title: root.panelTitle + " - Detached View"
        color: root.themeColors.panelColor
        
        ColumnLayout {
            anchors.fill: parent
            spacing: 0
            
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 45
                color: root.themeColors.panelColor
                border.color: root.themeColors.borderColor
                border.width: 1
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 5
                    spacing: 5
                    
                    Label {
                        text: root.panelTitle
                        font.pixelSize: 12
                        font.bold: true
                        color: root.themeColors.textColor
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    ToolButton {
                        implicitWidth: 32
                        implicitHeight: 32
                        contentItem: Text {
                            text: "+"
                            font.pixelSize: 18
                            font.bold: true
                            color: root.themeColors.textColor
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            color: parent.pressed ? root.themeColors.buttonPressedColor : 
                                   (parent.hovered ? root.themeColors.buttonHoverColor : root.themeColors.buttonColor)
                            radius: 3
                        }
                        onClicked: detachedImageViewer.zoomIn()
                    }
                    
                    ToolButton {
                        implicitWidth: 32
                        implicitHeight: 32
                        contentItem: Text {
                            text: "−"
                            font.pixelSize: 18
                            font.bold: true
                            color: root.themeColors.textColor
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            color: parent.pressed ? root.themeColors.buttonPressedColor : 
                                   (parent.hovered ? root.themeColors.buttonHoverColor : root.themeColors.buttonColor)
                            radius: 3
                        }
                        onClicked: detachedImageViewer.zoomOut()
                    }
                    
                    ToolButton {
                        implicitWidth: 32
                        implicitHeight: 32
                        contentItem: Text {
                            text: "⟲"
                            font.pixelSize: 16
                            color: root.themeColors.textColor
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            color: parent.pressed ? root.themeColors.buttonPressedColor : 
                                   (parent.hovered ? root.themeColors.buttonHoverColor : root.themeColors.buttonColor)
                            radius: 3
                        }
                        onClicked: detachedImageViewer.resetView()
                    }
                }
            }
            
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0
                
                ImageViewerContent {
                    id: detachedImageViewer
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    imagePath: root.imagePath
                    colorMapIndex: root.currentColorMap
                    showLegend: false
                    hideInstructionsDelay: 5000
                }
                
                ColorLegend {
                    Layout.preferredWidth: 30
                    Layout.fillHeight: true
                    visible: root.imagePath !== ""
                    colorMapIndex: root.currentColorMap
                    colorMaps: root.colorMaps
                    imagePath: root.imagePath
                    processor: root.processor
                }
            }
        }
    }
    
    ColumnLayout {
        anchors.fill: parent
        spacing: 5
        
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 45
            color: root.themeColors.panelColor
            border.color: root.themeColors.borderColor
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
                    color: root.themeColors.textColor
                }
                
                Item { Layout.fillWidth: true }
                
                ToolButton {
                    implicitWidth: 32
                    implicitHeight: 32
                    enabled: root.imagePath !== ""
                    contentItem: Text {
                        text: "+"
                        font.pixelSize: 18
                        font.bold: true
                        color: parent.enabled ? root.themeColors.textColor : "#666666"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: parent.pressed ? root.themeColors.buttonPressedColor : 
                               (parent.hovered ? root.themeColors.buttonHoverColor : root.themeColors.buttonColor)
                        radius: 3
                    }
                    onClicked: imageViewer.zoomIn()
                    ToolTip.visible: hovered
                    ToolTip.text: "Zoom In"
                    ToolTip.delay: 500
                }
                
                ToolButton {
                    implicitWidth: 32
                    implicitHeight: 32
                    enabled: root.imagePath !== ""
                    contentItem: Text {
                        text: "−"
                        font.pixelSize: 18
                        font.bold: true
                        color: parent.enabled ? root.themeColors.textColor : "#666666"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: parent.pressed ? root.themeColors.buttonPressedColor : 
                               (parent.hovered ? root.themeColors.buttonHoverColor : root.themeColors.buttonColor)
                        radius: 3
                    }
                    onClicked: imageViewer.zoomOut()
                    ToolTip.visible: hovered
                    ToolTip.text: "Zoom Out"
                    ToolTip.delay: 500
                }
                
                ToolButton {
                    implicitWidth: 32
                    implicitHeight: 32
                    enabled: root.imagePath !== ""
                    contentItem: Text {
                        text: "⟲"
                        font.pixelSize: 16
                        color: parent.enabled ? root.themeColors.textColor : "#666666"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: parent.pressed ? root.themeColors.buttonPressedColor : 
                               (parent.hovered ? root.themeColors.buttonHoverColor : root.themeColors.buttonColor)
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
                    color: root.themeColors.borderColor
                }
                
                ToolButton {
                    implicitWidth: 32
                    implicitHeight: 32
                    enabled: root.imagePath !== ""
                    contentItem: Text {
                        text: "⧉"
                        font.pixelSize: 16
                        color: parent.enabled ? root.themeColors.textColor : "#666666"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: parent.pressed ? root.themeColors.buttonPressedColor : 
                               (parent.hovered ? root.themeColors.buttonHoverColor : root.themeColors.buttonColor)
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
                    color: root.themeColors.borderColor
                }
                
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
        
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: root.themeColors.panelColor
            border.color: root.themeColors.borderColor
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
                        processor: root.processor
                    }
                }
                
                ColorLegend {
                    Layout.preferredWidth: 30
                    Layout.fillHeight: true
                    visible: root.imagePath !== ""
                    colorMapIndex: root.currentColorMap
                    colorMaps: root.colorMaps
                    imagePath: root.imagePath
                    processor: root.processor
                }
            }
        }
        
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            
            Label {
                text: "Color Map:"
                font.pixelSize: 11
                color: root.themeColors.textSecondaryColor
            }
            
            ComboBox {
                id: colorMapCombo
                Layout.preferredWidth: 180
                model: root.colorMaps
                currentIndex: root.currentColorMap
                textRole: "name"
                onCurrentIndexChanged: {
                    root.currentColorMap = currentIndex
                }
                
                delegate: ItemDelegate {
                    width: colorMapCombo.width
                    contentItem: RowLayout {
                        spacing: 8
                        
                        Rectangle {
                            width: 50
                            height: 16
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop {
                                    position: 0.0
                                    color: modelData.colors[0]
                                }
                                GradientStop {
                                    position: 0.5
                                    color: modelData.colors[Math.floor(modelData.colors.length / 2)]
                                }
                                GradientStop {
                                    position: 1.0
                                    color: modelData.colors[modelData.colors.length - 1]
                                }
                            }
                            border.color: root.themeColors.borderColor
                            border.width: 1
                        }
                        
                        Text {
                            text: modelData.name
                            color: root.themeColors.textColor
                            font.pixelSize: 11
                            Layout.fillWidth: true
                        }
                    }
                }
                
                contentItem: Item {
                    implicitWidth: contentRow.implicitWidth + 10
                    implicitHeight: contentRow.implicitHeight
                    
                    RowLayout {
                        id: contentRow
                        anchors.fill: parent
                        anchors.leftMargin: 5
                        anchors.rightMargin: 5
                        spacing: 5
                        
                        Rectangle {
                            width: 40
                            height: 14
                        visible: root.colorMaps.length > 0 && colorMapCombo.currentIndex >= 0
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop {
                                position: 0.0
                                color: {
                                    if (root.colorMaps.length > 0 && colorMapCombo.currentIndex < root.colorMaps.length) {
                                        return root.colorMaps[colorMapCombo.currentIndex].colors[0]
                                    }
                                    return "#000000"
                                }
                            }
                            GradientStop {
                                position: 0.5
                                color: {
                                    if (root.colorMaps.length > 0 && colorMapCombo.currentIndex < root.colorMaps.length) {
                                        var colors = root.colorMaps[colorMapCombo.currentIndex].colors
                                        return colors[Math.floor(colors.length / 2)]
                                    }
                                    return "#888888"
                                }
                            }
                            GradientStop {
                                position: 1.0
                                color: {
                                    if (root.colorMaps.length > 0 && colorMapCombo.currentIndex < root.colorMaps.length) {
                                        var colors = root.colorMaps[colorMapCombo.currentIndex].colors
                                        return colors[colors.length - 1]
                                    }
                                    return "#ffffff"
                                }
                            }
                        }
                        border.color: root.themeColors.borderColor
                        border.width: 1
                    }
                    
                    Text {
                        text: colorMapCombo.displayText
                        color: root.themeColors.textColor
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: 11
                        Layout.fillWidth: true
                    }
                    }
                }
                
                background: Rectangle {
                    color: {
                        if (parent.pressed) {
                            return root.themeColors.panelColor === "#ffffff" ? "#f0f0f0" : "#1a1a1a"
                        }
                        return root.themeColors.panelColor
                    }
                    border.color: root.themeColors.borderColor
                    border.width: 1
                    radius: 3
                }
            }
            
            CheckBox {
                text: "3D View"
                checked: root.show3D
                onCheckedChanged: root.show3D = checked
                contentItem: Text {
                    text: parent.text
                    color: root.themeColors.textSecondaryColor
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
            if (path.startsWith("file:///")) {
                path = path.substring(8)
            } else if (path.startsWith("file://")) {
                path = path.substring(7)
            }
            root.imagePath = path
            root.imageChanged(root.imagePath)
        }
    }
}
