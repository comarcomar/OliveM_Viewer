import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtCore
import GeoTiffProcessor

ApplicationWindow {
    id: mainWindow
    visible: true
    width: 1600
    height: 900
    title: "OM Tree Crown Segmentation Tool"
    
    // Theme management
    property bool isDarkTheme: true
    property color backgroundColor: isDarkTheme ? "#2b2b2b" : "#e8f4f8"
    property color panelColor: isDarkTheme ? "#1e1e1e" : "#ffffff"
    property color borderColor: isDarkTheme ? "#404040" : "#b0d4e0"
    property color textColor: isDarkTheme ? "#ffffff" : "#1a1a1a"
    property color textSecondaryColor: isDarkTheme ? "#cccccc" : "#555555"
    property color buttonColor: isDarkTheme ? "#003366" : "#4a90e2"
    property color buttonHoverColor: isDarkTheme ? "#004499" : "#357abd"
    property color buttonPressedColor: isDarkTheme ? "#0066cc" : "#2e6da4"
    
    // Settings
    property bool denoiseEnabled: true
    property int areaThreshold: 70
    
    // Persistent settings
    Settings {
        id: appSettings
        category: "Application"
        
        property alias isDarkTheme: mainWindow.isDarkTheme
        property alias denoiseEnabled: mainWindow.denoiseEnabled
        property alias areaThreshold: mainWindow.areaThreshold
    }
    
    // Processor backend
    GeoTiffProcessor {
        id: processor
        onAnalysisCompleted: (resultPath, param1, param2) => {
            // Only update result image if NO RGB is loaded
            if (rgbImagePath === "") {
                resultImage.updateImage(resultPath)
            }
            param1Text.text = param1.toFixed(4)
            param2Text.text = param2.toFixed(4)
        }
        onErrorOccurred: (errorMessage) => {
            errorDialog.text = errorMessage
            errorDialog.open()
        }
    }
    
    // Color maps definition (verified correct order)
    property var colorMaps: [
        { name: "Jet", colors: ["#000080", "#0000FF", "#00FFFF", "#00FF00", "#FFFF00", "#FF0000", "#800000"] },
        { name: "Hot", colors: ["#000000", "#FF0000", "#FFFF00", "#FFFFFF"] },
        { name: "Grayscale", colors: ["#000000", "#FFFFFF"] },
        { name: "Viridis", colors: ["#440154", "#31688e", "#35b779", "#fde724"] }
    ]
    
    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        
        // Toolbar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            color: mainWindow.panelColor
            border.color: mainWindow.borderColor
            border.width: 1
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 5
                spacing: 10
                
                // Settings button
                ToolButton {
                    implicitWidth: 40
                    implicitHeight: 40
                    
                    contentItem: Text {
                        text: "⚙"
                        font.pixelSize: 22
                        color: mainWindow.textColor
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    background: Rectangle {
                        color: parent.pressed ? mainWindow.buttonPressedColor : 
                               (parent.hovered ? mainWindow.buttonHoverColor : mainWindow.buttonColor)
                        radius: 4
                    }
                    
                    onClicked: settingsDialog.open()
                    
                    ToolTip.visible: hovered
                    ToolTip.text: "Settings"
                }
                
                // Reset button
                ToolButton {
                    implicitWidth: 40
                    implicitHeight: 40
                    
                    contentItem: Text {
                        text: "↻"
                        font.pixelSize: 22
                        color: mainWindow.textColor
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    background: Rectangle {
                        color: parent.pressed ? mainWindow.buttonPressedColor : 
                               (parent.hovered ? mainWindow.buttonHoverColor : mainWindow.buttonColor)
                        radius: 4
                    }
                    
                    onClicked: resetSystem()
                    
                    ToolTip.visible: hovered
                    ToolTip.text: "Reset System"
                }
                
                Item { Layout.fillWidth: true }
            }
        }
        
        // Input controls panel
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            color: mainWindow.panelColor
            border.color: mainWindow.borderColor
            border.width: 1
            enabled: image1Panel.imagePath !== "" || image2Panel.imagePath !== ""
            opacity: enabled ? 1.0 : 0.5
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 15
                
                Label {
                    text: "Input Data:"
                    font.pixelSize: 12
                    font.bold: true
                    color: mainWindow.textColor
                }
                
                Button {
                    text: "Shapefile (.zip)"
                    implicitHeight: 28
                    onClicked: shapefileDialog.open()
                    
                    background: Rectangle {
                        color: parent.pressed ? mainWindow.buttonPressedColor : 
                               (parent.hovered ? mainWindow.buttonHoverColor : mainWindow.buttonColor)
                        radius: 4
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        color: "#ffffff"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: 11
                    }
                }
                
                Button {
                    text: "RGB Orthophoto"
                    implicitHeight: 28
                    onClicked: rgbDialog.open()
                    
                    background: Rectangle {
                        color: parent.pressed ? mainWindow.buttonPressedColor : 
                               (parent.hovered ? mainWindow.buttonHoverColor : mainWindow.buttonColor)
                        radius: 4
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        color: "#ffffff"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: 11
                    }
                }
                
                Label {
                    id: rgbStatusLabel
                    text: rgbImagePath !== "" ? "RGB: " + rgbImagePath.split('/').pop() : ""
                    font.pixelSize: 10
                    color: mainWindow.textSecondaryColor
                    elide: Text.ElideMiddle
                    Layout.fillWidth: true
                }
                
                Item { Layout.fillWidth: true }
            }
        }
        
        // Main content area
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 2
            
            // Left panel - Two GeoTIFF images
            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: parent.width * 0.35
                color: mainWindow.backgroundColor
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 5
                    spacing: 5
                    
                    // Image 1
                    GeoTiffImagePanel {
                        id: image1Panel
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        panelTitle: "Ortofoto DSM"
                        colorMaps: mainWindow.colorMaps
                        processor: processor
                        themeColors: ({
                            panelColor: mainWindow.panelColor,
                            borderColor: mainWindow.borderColor,
                            textColor: mainWindow.textColor,
                            textSecondaryColor: mainWindow.textSecondaryColor,
                            buttonColor: mainWindow.buttonColor,
                            buttonHoverColor: mainWindow.buttonHoverColor,
                            buttonPressedColor: mainWindow.buttonPressedColor
                        })
                        onImageChanged: (imagePath) => {
                            processor.setImage1(imagePath)
                        }
                    }
                    
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 2
                        color: mainWindow.borderColor
                    }
                    
                    // Image 2
                    GeoTiffImagePanel {
                        id: image2Panel
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        panelTitle: "Ortofoto NDVI"
                        colorMaps: mainWindow.colorMaps
                        processor: processor
                        themeColors: ({
                            panelColor: mainWindow.panelColor,
                            borderColor: mainWindow.borderColor,
                            textColor: mainWindow.textColor,
                            textSecondaryColor: mainWindow.textSecondaryColor,
                            buttonColor: mainWindow.buttonColor,
                            buttonHoverColor: mainWindow.buttonHoverColor,
                            buttonPressedColor: mainWindow.buttonPressedColor
                        })
                        onImageChanged: (imagePath) => {
                            processor.setImage2(imagePath)
                        }
                    }
                }
            }
            
            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 2
                color: mainWindow.borderColor
            }
            
            // Right panel - Analysis result or RGB  
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true  // Match left panel height
                color: mainWindow.backgroundColor
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10
                    
                    // Header with title
                    Label {
                        text: rgbImagePath !== "" ? "RGB Orthophoto" : "Analysis Result"
                        font.pixelSize: 18
                        font.bold: true
                        color: mainWindow.textColor
                        Layout.fillWidth: true
                    }
                    
                    // Result viewer - fills all remaining space
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: mainWindow.panelColor
                        border.color: mainWindow.borderColor
                        border.width: 1
                        
                        ResultImageViewer {
                            id: resultImage
                            anchors.fill: parent
                            anchors.margins: 5
                            displayPath: rgbImagePath !== "" ? rgbImagePath : ""
                        }
                    }
                }
            }
        }
        
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 2
            color: mainWindow.borderColor
        }
        
        // Bottom panel - Button and Parameters
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 80
            color: mainWindow.panelColor
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 15
                spacing: 20
                
                // Left spacer - aligns button with left panel width
                Item {
                    Layout.preferredWidth: parent.width * 0.35
                }
                
                // Run Analysis button - ALWAYS VISIBLE ✓
                Button {
                    text: "▶ Run Analysis"
                    Layout.preferredHeight: 50
                    Layout.preferredWidth: 200
                    enabled: processor.hasValidImages
                    // NO visible property - always shown!
                    onClicked: processor.runAnalysis()
                    
                    background: Rectangle {
                        color: parent.enabled ? (parent.pressed ? "#006600" : 
                               (parent.hovered ? "#008800" : "#00aa00")) : "#404040"
                        radius: 4
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        color: "#ffffff"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: 14
                        font.bold: true
                    }
                }
                
                // Spacer between button and parameters
                Item {
                    Layout.fillWidth: true
                }
                
                // Parameters - aligned to right (RGB panel right edge)
                RowLayout {
                    spacing: 10
                    Layout.alignment: Qt.AlignRight
                    
                    Rectangle {
                        width: 200
                        height: 50
                        color: mainWindow.panelColor
                        border.color: mainWindow.buttonColor
                        border.width: 2
                        radius: 5
                        
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 2
                            
                            Label {
                                text: "Fraction Coverage"
                                font.pixelSize: 11
                                color: mainWindow.textSecondaryColor
                                Layout.alignment: Qt.AlignHCenter
                            }
                            
                            Label {
                                id: param1Text
                                text: "---"
                                font.pixelSize: 16
                                font.bold: true
                                color: mainWindow.isDarkTheme ? "#00ff00" : "#008800"
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }
                    
                    Rectangle {
                        width: 200
                        height: 50
                        color: mainWindow.panelColor
                        border.color: mainWindow.buttonColor
                        border.width: 2
                        radius: 5
                        
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 2
                            
                            Label {
                                text: "Mean NDVI"
                                font.pixelSize: 11
                                color: mainWindow.textSecondaryColor
                                Layout.alignment: Qt.AlignHCenter
                            }
                            
                            Label {
                                id: param2Text
                                text: "---"
                                font.pixelSize: 16
                                font.bold: true
                                color: mainWindow.isDarkTheme ? "#00ff00" : "#008800"
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Settings Dialog
    Dialog {
        id: settingsDialog
        title: "Settings"
        width: 400
        height: 350
        modal: true
        anchors.centerIn: parent
        standardButtons: Dialog.Ok | Dialog.Cancel
        
        onAccepted: {
            mainWindow.isDarkTheme = darkThemeRadio.checked
            mainWindow.denoiseEnabled = denoiseCheck.checked
            mainWindow.areaThreshold = areaSlider.value
            
            // Update processor settings
            processor.setDenoiseFlag(mainWindow.denoiseEnabled)
            processor.setAreaThreshold(mainWindow.areaThreshold)
        }
        
        ColumnLayout {
            anchors.fill: parent
            spacing: 15
            
            // Appearance section
            GroupBox {
                title: "Appearance"
                Layout.fillWidth: true
                
                ColumnLayout {
                    anchors.fill: parent
                    
                    RadioButton {
                        id: darkThemeRadio
                        text: "Dark Theme"
                        checked: mainWindow.isDarkTheme
                    }
                    
                    RadioButton {
                        id: lightThemeRadio
                        text: "Light Theme"
                        checked: !mainWindow.isDarkTheme
                    }
                }
            }
            
            // Settings section
            GroupBox {
                title: "Processing Settings"
                Layout.fillWidth: true
                
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10
                    
                    CheckBox {
                        id: denoiseCheck
                        text: "Denoise"
                        checked: mainWindow.denoiseEnabled
                    }
                    
                    Label {
                        text: "Area Threshold: " + areaSlider.value
                        font.pixelSize: 11
                        enabled: denoiseCheck.checked
                        opacity: denoiseCheck.checked ? 1.0 : 0.5
                    }
                    
                    Slider {
                        id: areaSlider
                        from: 5
                        to: 500
                        value: mainWindow.areaThreshold
                        stepSize: 1
                        Layout.fillWidth: true
                        enabled: denoiseCheck.checked
                        opacity: denoiseCheck.checked ? 1.0 : 0.5
                    }
                }
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
    
    // File dialogs
    property string rgbImagePath: ""
    
    FileDialog {
        id: shapefileDialog
        title: "Select Shapefile Archive"
        fileMode: FileDialog.OpenFile
        nameFilters: ["ZIP files (*.zip)", "All files (*)"]
        onAccepted: {
            var path = selectedFile.toString()
            if (path.startsWith("file:///")) {
                path = path.substring(8)
            } else if (path.startsWith("file://")) {
                path = path.substring(7)
            }
            
            console.log("Shapefile selected:", path)
            processor.setShapefileZip(path)
        }
    }
    
    FileDialog {
        id: rgbDialog
        title: "Select RGB Orthophoto"
        fileMode: FileDialog.OpenFile
        nameFilters: ["Image files (*.tif *.tiff *.jpg *.jpeg *.png)", "All files (*)"]
        onAccepted: {
            var path = selectedFile.toString()
            if (path.startsWith("file:///")) {
                path = path.substring(8)
            } else if (path.startsWith("file://")) {
                path = path.substring(7)
            }
            
            console.log("RGB file selected:", path)
            rgbImagePath = path
            
            // Force update of result image
            resultImage.displayPath = ""
            resultImage.displayPath = path
        }
    }
    
    function resetSystem() {
        console.log("=== RESET SYSTEM START ===")
        
        // Turn off 3D first
        image1Panel.show3D = false
        image2Panel.show3D = false
        
        // Wait a bit for 3D to shut down
        Qt.callLater(function() {
            // Clear paths
            image1Panel.imagePath = ""
            image2Panel.imagePath = ""
            rgbImagePath = ""
            resultImage.displayPath = ""
            
            // Reset UI
            param1Text.text = "---"
            param2Text.text = "---"
            
            // Clear processor
            processor.clearCache()
            
            console.log("=== RESET SYSTEM COMPLETE ===")
        })
    }
}
