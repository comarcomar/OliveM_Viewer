import QtQuick
import QtQuick.Controls

Item {
    id: root
    
    property string resultPath: ""
    property string displayPath: ""
    
    function updateImage(path) {
        console.log("updateImage called with:", path)
        resultPath = path
        loadCurrentImage()
    }
    
    function loadCurrentImage() {
        var pathToLoad = displayPath !== "" ? displayPath : resultPath
        
        if (pathToLoad === "") {
            console.log("No image to load")
            resultImage.source = ""
            return
        }
        
        // Normalize path separators
        var normalizedPath = pathToLoad.replace(/\\/g, '/')
        console.log("Normalized path:", normalizedPath)
        
        // Build proper file URL based on path type
        var fileUrl = ""
        
        if (normalizedPath.startsWith("file://")) {
            // Already a URL
            fileUrl = normalizedPath
        } else if (normalizedPath.startsWith("/")) {
            // Unix/Linux absolute path
            fileUrl = "file://" + normalizedPath
        } else if (normalizedPath.match(/^[A-Za-z]:\//)) {
            // Windows absolute path (C:/, D:/, etc.)
            fileUrl = "file:///" + normalizedPath
        } else {
            // Fallback - assume Windows-style path
            fileUrl = "file:///" + normalizedPath
        }
        
        console.log("Final URL:", fileUrl)
        
        // Force reload by clearing first
        resultImage.source = ""
        resultImage.source = fileUrl
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
                } else if (resultImage.status === Image.Error) {
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
