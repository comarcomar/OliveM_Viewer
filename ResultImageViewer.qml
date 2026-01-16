import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

Item {
    id: root
    
    property string resultPath: ""
    property string displayPath: ""
    ////
    // Layer visibility controls
    property bool showRgbLayer: true
    property bool showResultLayer: true
    
    // Result overlay settings
    property color overlayColor: "#ff0000"  // Red default
    property real overlayOpacity: 0.8
    property int colormapMode: 0  // 0=Jet, 1=Viridis, 2=Turbo
    
    onOverlayColorChanged: {
        console.log("Overlay color changed to:", overlayColor)
    }
    
    onOverlayOpacityChanged: {
        console.log("Overlay opacity changed to:", overlayOpacity)
    }
    
    function updateImage(path) {
        console.log("updateImage called with:", path)
        resultPath = path
        loadResultImage()
    }
    
    function loadRgbImage() {
        if (displayPath === "") {
            rgbImage.source = ""
            return
        }
        
        var normalizedPath = displayPath.replace(/\\/g, '/')
        
        if (normalizedPath.endsWith('.tif') || normalizedPath.endsWith('.tiff')) {
            var cleanPath = normalizedPath
            if (cleanPath.startsWith("file:///")) cleanPath = cleanPath.substring(8)
            else if (cleanPath.startsWith("file://")) cleanPath = cleanPath.substring(7)
            var encodedPath = encodeURIComponent(cleanPath)
            var imageUrl = "image://geotiff/" + encodedPath + "?colormap=-1&t=" + Date.now()
            rgbImage.source = ""
            rgbImage.source = imageUrl
        } else {
            var fileUrl = normalizedPath.startsWith("file://") ? normalizedPath : "file:///" + normalizedPath
            rgbImage.source = ""
            rgbImage.source = fileUrl
        }
    }
    
    function loadResultImage() {
        if (resultPath === "") {
            resultImage.source = ""
            return
        }
        var normalizedPath = resultPath.replace(/\\/g, '/')
        var rgbPath = displayPath.replace(/\\/g, '/')
        // Rimuovi prefisso file:/// se presente
        var cleanPath = normalizedPath
        if (cleanPath.startsWith("file:///")) cleanPath = cleanPath.substring(8)
        else if (cleanPath.startsWith("file://")) cleanPath = cleanPath.substring(7)
        var cleanRgbPath = rgbPath
        if (cleanRgbPath.startsWith("file:///")) cleanRgbPath = cleanRgbPath.substring(8)
        else if (cleanRgbPath.startsWith("file://")) cleanRgbPath = cleanRgbPath.substring(7)
        
        var imageUrl = "image://geotiff/" + encodeURIComponent(cleanPath)
        if (displayPath !== "") {
            imageUrl += "?alignTo=" + encodeURIComponent(cleanRgbPath) + "&t=" + Date.now()
        } else {
            imageUrl += "?t=" + Date.now()
        }
        resultImage.source = ""
        resultImage.source = imageUrl
    }
    
    onDisplayPathChanged: {
        console.log("RGB path changed:", displayPath)
        loadRgbImage()
    }
    
    onResultPathChanged: {
        console.log("Result path changed:", resultPath)
        loadResultImage()
    }
    
    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        
        // Main viewer area
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#1a1a1a"
            
            Flickable {
                id: flickable
                anchors.fill: parent
                contentWidth: imageContainer.width
                contentHeight: imageContainer.height
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                interactive: false  // Disabilita scroll/pan nativo, gestito manualmente
                
                property real imageScale: 1.0
                
                // Funzione per adattare l'immagine al viewport
                function fitToView() {
                    if (rgbImage.implicitWidth > 0 && rgbImage.implicitHeight > 0) {
                        var scaleX = flickable.width / rgbImage.implicitWidth
                        var scaleY = flickable.height / rgbImage.implicitHeight
                        imageScale = Math.min(scaleX, scaleY, 1.0) * 0.95
                        // Centra l'immagine
                        contentX = 0
                        contentY = 0
                    }
                }
                
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded; active: true }
                ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AsNeeded; active: true }
                
                // Mouse area per pan e zoom
                MouseArea {
                    id: dragArea
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    hoverEnabled: true
                    
                    property real lastX: 0
                    property real lastY: 0
                    
                    cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                    
                    onPressed: (mouse) => {
                        lastX = mouse.x
                        lastY = mouse.y
                    }
                    
                    onPositionChanged: (mouse) => {
                        if (pressed) {
                            var dx = mouse.x - lastX
                            var dy = mouse.y - lastY
                            flickable.contentX = Math.max(0, Math.min(flickable.contentWidth - flickable.width, flickable.contentX - dx))
                            flickable.contentY = Math.max(0, Math.min(flickable.contentHeight - flickable.height, flickable.contentY - dy))
                            lastX = mouse.x
                            lastY = mouse.y
                        }
                    }
                    
                    onWheel: (wheel) => {
                        wheel.accepted = true
                        var delta = wheel.angleDelta.y
                        var factor = delta > 0 ? 1.2 : 0.83
                        var newScale = flickable.imageScale * factor
                        newScale = Math.max(0.05, Math.min(10.0, newScale))
                        flickable.imageScale = newScale
                    }
                }

                Item {
                    id: imageContainer
                    width: rgbImage.implicitWidth * flickable.imageScale
                    height: rgbImage.implicitHeight * flickable.imageScale
                    
                    // Centra quando l'immagine è più piccola del viewport
                    x: Math.max(0, (flickable.width - width) / 2)
                    y: Math.max(0, (flickable.height - height) / 2)
                    
                    // Layer 1: RGB background
                    Image {
                        id: rgbImage
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectFit
                        cache: false
                        asynchronous: true
                        sourceSize.width: 4096
                        sourceSize.height: 4096
                        visible: root.showRgbLayer && root.displayPath !== ""
                        z: 0
                        onStatusChanged: {
                            if (status === Image.Ready) {
                                console.log("✓ RGB layer loaded, size:", implicitWidth, "x", implicitHeight)
                                flickable.fitToView()
                            }
                        }
                    }

                    // Layer 2: Result image (maschera) - anchors.fill per allinearsi all'RGB
                    Image {
                        id: resultImage
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectFit
                        cache: false
                        asynchronous: true
                        sourceSize.width: 4096
                        sourceSize.height: 4096
                        visible: root.showResultLayer && root.resultPath !== "" && !colorModeCheck.checked
                        z: 1
                        opacity: 1
                        onStatusChanged: {
                            if (status === Image.Ready) {
                                console.log("✓ Result layer loaded, size:", implicitWidth, "x", implicitHeight)
                            }
                        }
                    }

                    // Layer 3: Maschera colorata con ColorOverlay
                    Image {
                        id: resultImageForColor
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectFit
                        cache: false
                        asynchronous: true
                        sourceSize.width: 4096
                        sourceSize.height: 4096
                        source: resultImage.source
                        visible: false  // Nascosto, usato come sorgente per ColorOverlay
                    }
                    
                    ColorOverlay {
                        anchors.fill: parent
                        source: resultImageForColor
                        color: root.overlayColor
                        visible: root.showResultLayer && root.resultPath !== "" && colorModeCheck.checked
                        opacity: root.overlayOpacity
                        z: 2
                    }
                }
            }
            
            // No image label
            Label {
                anchors.centerIn: parent
                text: {
                    if (root.displayPath === "" && root.resultPath === "") return "No image loaded"
                    if (!root.showRgbLayer && !root.showResultLayer) return "All layers hidden"
                    return ""
                }
                color: "#666666"
                font.pixelSize: 14
                visible: text !== ""
            }
        }
        
        // Control bar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            color: "#2b2b2b"
            border.color: "#404040"
            border.width: 1
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 4
                spacing: 8
                
                // Layer visibility toggles
                CheckBox {
                    id: rgbLayerCheck
                    text: "RGB"
                    checked: root.showRgbLayer
                    enabled: root.displayPath !== ""
                    onCheckedChanged: root.showRgbLayer = checked
                }
                
                CheckBox {
                    id: resultLayerCheck
                    text: "Result"
                    checked: root.showResultLayer
                    enabled: root.resultPath !== ""
                    onCheckedChanged: root.showResultLayer = checked
                }
                
                Rectangle { width: 1; Layout.fillHeight: true; color: "#404040" }
                
                // Color mode toggle
                CheckBox {
                    id: colorModeCheck
                    text: "False Color"
                    checked: false
                    enabled: root.resultPath !== ""
                }
                
                // Palette colori per la maschera
                Label {
                    text: "Colore:"
                    color: "#cccccc"
                    visible: colorModeCheck.checked
                }
                Row {
                    spacing: 3
                    visible: colorModeCheck.checked
                    Repeater {
                        model: ["#ff0000", "#00ff00", "#0000ff", "#ffff00", "#ff00ff", "#00ffff", "#ffffff", "#ff8800"]
                        Rectangle {
                            width: 30
                            height: 30
                            color: modelData
                            border.color: Qt.colorEqual(root.overlayColor, modelData) ? "#ffffff" : "#666666"
                            border.width: Qt.colorEqual(root.overlayColor, modelData) ? 3 : 1
                            radius: 3
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    root.overlayColor = modelData
                                    console.log("Color selected:", modelData)
                                }
                            }
                        }
                    }
                }
                
                // Opacity slider
                Label {
                    text: "Opacity:"
                    color: "#cccccc"
                    visible: colorModeCheck.checked
                }
                
                Slider {
                    id: opacitySlider
                    from: 0.0
                    to: 1.0
                    value: root.overlayOpacity
                    Layout.preferredWidth: 100
                    visible: colorModeCheck.checked
                    onValueChanged: root.overlayOpacity = value
                }
                
                Label {
                    text: Math.round(opacitySlider.value * 100) + "%"
                    color: "#cccccc"
                    font.pixelSize: 11
                    visible: colorModeCheck.checked
                }
                
                Item { Layout.fillWidth: true }
                
                // Zoom controls
                Rectangle { width: 1; Layout.fillHeight: true; color: "#404040" }
                
                Label {
                    text: "Zoom:"
                    color: "#cccccc"
                }
                
                Button {
                    text: "+"; width: 24; height: 24
                    onClicked: flickable.imageScale = Math.min(flickable.imageScale * 1.25, 10.0)
                    background: Rectangle { color: parent.pressed ? "#006600" : "#004400"; radius: 4 }
                    contentItem: Text { text: parent.text; color: "#fff"; font.pixelSize: 14; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }
                Button {
                    text: "−"; width: 24; height: 24
                    onClicked: flickable.imageScale = Math.max(flickable.imageScale / 1.25, 0.05)
                    background: Rectangle { color: parent.pressed ? "#006600" : "#004400"; radius: 4 }
                    contentItem: Text { text: parent.text; color: "#fff"; font.pixelSize: 14; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }
                Button {
                    text: "Fit"; width: 32; height: 24
                    onClicked: flickable.fitToView()
                    background: Rectangle { color: parent.pressed ? "#006600" : "#004400"; radius: 4 }
                    contentItem: Text { text: parent.text; color: "#fff"; font.pixelSize: 10; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }
                
                Label {
                    text: Math.round(flickable.imageScale * 100) + "%"
                    color: "#cccccc"
                    font.pixelSize: 11
                    Layout.preferredWidth: 40
                }
            }
        }
    }
}
