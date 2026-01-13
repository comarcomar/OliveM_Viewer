import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

Item {
    id: root
    
    property string resultPath: ""
    property string displayPath: ""
    //
    // Layer visibility controls
    property bool showRgbLayer: true
    property bool showResultLayer: true
    
    // Result overlay settings
    property color overlayColor: "#ff0000"  // Red default
    property real overlayOpacity: 0.6
    
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
        var fileUrl = normalizedPath.startsWith("file://") ? normalizedPath : "file:///" + normalizedPath
        resultImage.source = ""
        resultImage.source = fileUrl
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
                contentWidth: Math.max(rgbImage.width, resultImage.width) * imageScale
                contentHeight: Math.max(rgbImage.height, resultImage.height) * imageScale
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                
                property real imageScale: 1.0
                
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded; active: true }
                ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AsNeeded; active: true }
                
                // Mouse wheel zoom
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    
                    onWheel: (wheel) => {
                        var delta = wheel.angleDelta.y
                        var factor = delta > 0 ? 1.1 : 0.9
                        var newScale = flickable.imageScale * factor
                        newScale = Math.max(0.1, Math.min(5.0, newScale))
                        flickable.imageScale = newScale
                    }
                }
                
                Item {
                    width: flickable.width
                    height: flickable.height
                    scale: flickable.imageScale
                    transformOrigin: Item.Center
                    
                    // Layer 1: RGB background
                    Image {
                        id: rgbImage
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectFit
                        cache: false
                        asynchronous: true
                        sourceSize.width: 2048
                        sourceSize.height: 2048
                        visible: root.showRgbLayer && root.displayPath !== ""
                        
                        onStatusChanged: {
                            if (status === Image.Ready) {
                                console.log("✓ RGB layer loaded")
                            }
                        }
                    }
                    
                    // Layer 2: Result overlay
                    Item {
                        anchors.fill: parent
                        visible: root.showResultLayer && root.resultPath !== ""
                        
                        // Source image - ALWAYS visible (shader needs texture)
                        // Hidden visually by z-order when false color active
                        Image {
                            id: resultImage
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectFit
                            cache: false
                            asynchronous: true
                            sourceSize.width: 2048
                            sourceSize.height: 2048
                            visible: true  // ALWAYS visible for shader
                            opacity: colorModeCheck.checked ? 0 : 1  // Hidden in false color mode
                            
                            onStatusChanged: {
                                console.log("Result loaded, status:", status)
                            }
                        }
                        
                        // False color shader effect
                        ShaderEffect {
                            anchors.fill: parent
                            visible: colorModeCheck.checked && resultImage.status === Image.Ready
                            z: 1  // Above resultImage
                            
                            property variant src: resultImage
                            property vector4d colorVec: Qt.vector4d(
                                root.overlayColor.r,
                                root.overlayColor.g, 
                                root.overlayColor.b,
                                root.overlayOpacity
                            )
                            
                            vertexShader: "
                                attribute highp vec4 qt_Vertex;
                                attribute highp vec2 qt_MultiTexCoord0;
                                uniform highp mat4 qt_Matrix;
                                varying highp vec2 qt_TexCoord0;
                                void main() {
                                    qt_TexCoord0 = qt_MultiTexCoord0;
                                    gl_Position = qt_Matrix * qt_Vertex;
                                }
                            "
                            
                            fragmentShader: "
                                varying highp vec2 qt_TexCoord0;
                                uniform sampler2D src;
                                uniform lowp vec4 colorVec;
                                uniform lowp float qt_Opacity;
                                
                                void main() {
                                    lowp vec4 tex = texture2D(src, qt_TexCoord0);
                                    lowp float gray = (tex.r + tex.g + tex.b) / 3.0;
                                    
                                    if (gray < 0.1) {
                                        gl_FragColor = vec4(0.0, 0.0, 0.0, 0.0);
                                    } else {
                                        gl_FragColor = vec4(colorVec.rgb, colorVec.a * gray * qt_Opacity);
                                    }
                                }
                            "
                        }
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
            
            // Zoom controls
            Row {
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.margins: 10
                spacing: 5
                
                Button {
                    text: "+"; width: 32; height: 32
                    onClicked: flickable.imageScale = Math.min(flickable.imageScale * 1.2, 5.0)
                    background: Rectangle { color: parent.pressed ? "#006600" : "#004400"; radius: 4; opacity: 0.9 }
                    contentItem: Text { text: parent.text; color: "#fff"; font.pixelSize: 18; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }
                Button {
                    text: "−"; width: 32; height: 32
                    onClicked: flickable.imageScale = Math.max(flickable.imageScale / 1.2, 0.5)
                    background: Rectangle { color: parent.pressed ? "#006600" : "#004400"; radius: 4; opacity: 0.9 }
                    contentItem: Text { text: parent.text; color: "#fff"; font.pixelSize: 18; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }
                Button {
                    text: "1:1"; width: 40; height: 32
                    onClicked: flickable.imageScale = 1.0
                    background: Rectangle { color: parent.pressed ? "#006600" : "#004400"; radius: 4; opacity: 0.9 }
                    contentItem: Text { text: parent.text; color: "#fff"; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }
            }
        }
        
        // Control bar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            color: "#2b2b2b"
            border.color: "#404040"
            border.width: 1
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 5
                spacing: 10
                
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
                
                // Color picker
                Label {
                    text: "Color:"
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
                            border.color: root.overlayColor === modelData ? "#ffffff" : "#666666"
                            border.width: root.overlayColor === modelData ? 3 : 1
                            radius: 3
                            
                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.overlayColor = modelData
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
            }
        }
    }
}
