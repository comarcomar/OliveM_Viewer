import QtQuick
import QtQuick.Controls

Item {
    id: root
    
    property string resultPath: ""
    property string displayPath: ""
    
    function updateImage(path) {
        console.log("updateImage called with:", path)
        resultPath = path
        
        // Only load if NO RGB is active
        if (displayPath === "") {
            loadCurrentImage()
        } else {
            console.log("RGB is active - keeping RGB displayed")
        }
    }
    
    function loadCurrentImage() {
        // Priority: displayPath (RGB) over resultPath (analysis)
        var pathToLoad = displayPath !== "" ? displayPath : (resultPath !== "" ? resultPath : "")
        
        if (pathToLoad === "") {
            console.log("No image to load")
            resultImage.source = ""
            return
        }
        
        console.log("Loading from:", displayPath !== "" ? "RGB" : "Result")
        
        // Normalize path separators
        var normalizedPath = pathToLoad.replace(/\\/g, '/')
        console.log("Normalized path:", normalizedPath)
        
        // For RGB (displayPath), use image provider to control memory
        // For analysis result, try direct load first (smaller files)
        if (displayPath !== "") {
            // RGB - use image provider with grayscale colormap (index 2)
            var cleanPath = normalizedPath
            if (cleanPath.startsWith("file:///")) cleanPath = cleanPath.substring(8)
            else if (cleanPath.startsWith("file://")) cleanPath = cleanPath.substring(7)
            var encodedPath = encodeURIComponent(cleanPath)
            var imageUrl = "image://geotiff/" + encodedPath + "?colormap=2&t=" + Date.now()
            console.log("Using image provider:", imageUrl)
            resultImage.source = ""
            resultImage.source = imageUrl
        } else {
            // Analysis result - direct file URL
            var fileUrl = ""
            if (normalizedPath.startsWith("file://")) {
                fileUrl = normalizedPath
            } else if (normalizedPath.startsWith("/")) {
                fileUrl = "file://" + normalizedPath
            } else if (normalizedPath.match(/^[A-Za-z]:\//)) {
                fileUrl = "file:///" + normalizedPath
            } else {
                fileUrl = "file:///" + normalizedPath
            }
            
            console.log("Final URL:", fileUrl)
            resultImage.source = ""
            resultImage.source = fileUrl
        }
    }
    
    onDisplayPathChanged: {
        console.log("=== DisplayPath changed to:", displayPath)
        if (displayPath !== "" || resultPath !== "") {
            loadCurrentImage()
        } else {
            resultImage.source = ""
        }
    }
    
    onResultPathChanged: {
        console.log("=== ResultPath changed to:", resultPath)
        if (displayPath === "" && resultPath !== "") {
            loadCurrentImage()
        }
    }
    
    Rectangle {
        anchors.fill: parent
        color: "#1a1a1a"
        
        Image {
            id: resultImage
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            cache: false
            asynchronous: true
            sourceSize.width: 2048  // Limit size to prevent memory overflow
            sourceSize.height: 2048
            
            onStatusChanged: {
                console.log(">>> Image status:", 
                    status === Image.Null ? "Null" :
                    status === Image.Ready ? "Ready" :
                    status === Image.Loading ? "Loading" :
                    status === Image.Error ? "ERROR" : "Unknown")
                
                if (status === Image.Error) {
                    console.error("!!! Failed to load:", source)
                } else if (status === Image.Ready) {
                    console.log("✓ Image loaded successfully")
                    console.log("  Size:", sourceSize.width, "x", sourceSize.height)
                }
            }
            
            BusyIndicator {
                anchors.centerIn: parent
                running: resultImage.status === Image.Loading
                visible: running
            }
        }
        
        Label {
            anchors.centerIn: parent
            text: {
                if (root.displayPath === "" && root.resultPath === "") {
                    return "No image loaded"
                } else if (resultImage.status === Image.Error && resultImage.source !== "") {
                    return "Failed to load image\nCheck console for details"
                }
                return ""
            }
            color: resultImage.status === Image.Error ? "#ff6666" : "#666666"
            font.pixelSize: 14
            horizontalAlignment: Text.AlignHCenter
            visible: text !== "" && resultImage.status !== Image.Loading
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
                width: 32
                height: 32
                onClicked: resultImage.scale = Math.min(resultImage.scale * 1.2, 5.0)
                
                background: Rectangle {
                    color: parent.pressed ? "#006600" : (parent.hovered ? "#008800" : "#004400")
                    radius: 4
                    opacity: 0.9
                }
                
                contentItem: Text {
                    text: parent.text
                    color: "#ffffff"
                    font.pixelSize: 18
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
            
            Button {
                text: "−"
                width: 32
                height: 32
                onClicked: resultImage.scale = Math.max(resultImage.scale / 1.2, 0.5)
                
                background: Rectangle {
                    color: parent.pressed ? "#006600" : (parent.hovered ? "#008800" : "#004400")
                    radius: 4
                    opacity: 0.9
                }
                
                contentItem: Text {
                    text: parent.text
                    color: "#ffffff"
                    font.pixelSize: 18
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
            
            Button {
                text: "1:1"
                width: 40
                height: 32
                onClicked: resultImage.scale = 1.0
                
                background: Rectangle {
                    color: parent.pressed ? "#006600" : (parent.hovered ? "#008800" : "#004400")
                    radius: 4
                    opacity: 0.9
                }
                
                contentItem: Text {
                    text: parent.text
                    color: "#ffffff"
                    font.pixelSize: 11
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }
}
