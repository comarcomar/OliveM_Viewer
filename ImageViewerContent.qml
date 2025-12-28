import QtQuick
import QtQuick.Controls

Item {
    id: root
    
    property string imagePath: ""
    property int colorMapIndex: 0
    property bool showLegend: false
    property alias imageStatus: imageView.status
    property int hideInstructionsDelay: 5000
    
    property real zoomLevel: 1.0
    property real minZoom: 0.1
    property real maxZoom: 10.0
    property point offset: Qt.point(0, 0)
    
    function zoomIn() {
        var newZoom = Math.min(zoomLevel * 1.2, maxZoom)
        zoomLevel = newZoom
    }
    
    function zoomOut() {
        var newZoom = Math.max(zoomLevel / 1.2, minZoom)
        zoomLevel = newZoom
    }
    
    function resetView() {
        zoomLevel = 1.0
        offset = Qt.point(0, 0)
    }
    
    // Timer to hide instructions
    Timer {
        id: hideInstructionsTimer
        interval: root.hideInstructionsDelay
        running: root.imagePath !== "" && imageView.status === Image.Ready
        onTriggered: instructionsOverlay.visible = false
    }
    
    Rectangle {
        anchors.fill: parent
        color: "#1e1e1e"
        
        Flickable {
            id: flickable
            anchors.fill: parent
            contentWidth: imageContainer.width
            contentHeight: imageContainer.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
            ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AsNeeded }
            
            Item {
                id: imageContainer
                width: Math.max(flickable.width, imageView.width * imageView.scale)
                height: Math.max(flickable.height, imageView.height * imageView.scale)
                
                Image {
                    id: imageView
                    anchors.centerIn: parent
                    fillMode: Image.PreserveAspectFit
                    cache: false
                    asynchronous: true
                    smooth: false
                    scale: root.zoomLevel
                    
                    Component.onCompleted: {
                        console.log("ImageViewerContent created")
                    }
                    
                    Connections {
                        target: root
                        function onImagePathChanged() {
                            console.log("ImageViewerContent: imagePath changed to:", root.imagePath)
                            reloadImage()
                        }
                        function onColorMapIndexChanged() {
                            console.log("ImageViewerContent: colorMapIndex changed to:", root.colorMapIndex)
                            if (root.imagePath !== "") {
                                reloadImage()
                            }
                        }
                    }
                    
                    function reloadImage() {
                        imageView.source = ""
                        if (root.imagePath !== "") {
                            var cleanPath = root.imagePath
                            if (cleanPath.startsWith("file:///")) cleanPath = cleanPath.substring(8)
                            else if (cleanPath.startsWith("file://")) cleanPath = cleanPath.substring(7)
                            var encodedPath = encodeURIComponent(cleanPath)
                            var newSource = "image://geotiff/" + encodedPath + "?colormap=" + root.colorMapIndex + "&t=" + Date.now()
                            console.log("Loading image source:", newSource)
                            imageView.source = newSource
                        }
                    }
                    
                    onStatusChanged: {
                        if (status === Image.Ready) {
                            hideInstructionsTimer.restart()
                            updateImageSize()
                        } else if (status === Image.Error) {
                            console.error("Failed to load image:", source)
                        }
                    }
                    
                    // Update size when flickable size changes
                    Connections {
                        target: flickable
                        function onWidthChanged() { if (imageView.status === Image.Ready) updateImageSize() }
                        function onHeightChanged() { if (imageView.status === Image.Ready) updateImageSize() }
                    }
                    
                    function updateImageSize() {
                        if (sourceSize.width > 0 && sourceSize.height > 0) {
                            var aspectRatio = sourceSize.width / sourceSize.height
                            if (flickable.width / flickable.height > aspectRatio) {
                                imageView.width = flickable.height * aspectRatio
                                imageView.height = flickable.height
                            } else {
                                imageView.width = flickable.width
                                imageView.height = flickable.width / aspectRatio
                            }
                        }
                    }
                    
                    Behavior on scale {
                        NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
                    }
                }
            }
            
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.MiddleButton | Qt.LeftButton
                property point lastPos: Qt.point(0, 0)
                property bool isPanning: false
                
                onPressed: (mouse) => {
                    if (mouse.button === Qt.MiddleButton || (mouse.button === Qt.LeftButton && root.zoomLevel > 1.0)) {
                        isPanning = true
                        lastPos = Qt.point(mouse.x, mouse.y)
                        cursorShape = Qt.ClosedHandCursor
                    }
                }
                
                onReleased: {
                    isPanning = false
                    cursorShape = Qt.ArrowCursor
                }
                
                onPositionChanged: (mouse) => {
                    if (isPanning) {
                        var dx = mouse.x - lastPos.x
                        var dy = mouse.y - lastPos.y
                        flickable.contentX = Math.max(0, Math.min(flickable.contentWidth - flickable.width, flickable.contentX - dx))
                        flickable.contentY = Math.max(0, Math.min(flickable.contentHeight - flickable.height, flickable.contentY - dy))
                        lastPos = Qt.point(mouse.x, mouse.y)
                    }
                }
                
                onWheel: (wheel) => {
                    if (wheel.angleDelta.y > 0) root.zoomIn()
                    else root.zoomOut()
                    wheel.accepted = true
                }
            }
        }
        
        BusyIndicator {
            anchors.centerIn: parent
            running: imageView.status === Image.Loading
            visible: running
        }
        
        Label {
            anchors.centerIn: parent
            text: "No image loaded"
            color: "#666666"
            font.pixelSize: 14
            visible: root.imagePath === "" && imageView.status !== Image.Loading
        }
        
        Label {
            anchors.centerIn: parent
            text: "Failed to load image\nCheck console for details"
            color: "#ff6666"
            font.pixelSize: 12
            horizontalAlignment: Text.AlignHCenter
            visible: imageView.status === Image.Error
        }
        
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.margins: 10
            width: zoomText.width + 20
            height: 30
            color: Qt.rgba(0, 0, 0, 0.7)
            radius: 3
            visible: root.imagePath !== "" && imageView.status === Image.Ready
            
            Label {
                id: zoomText
                anchors.centerIn: parent
                text: Math.round(root.zoomLevel * 100) + "%"
                color: "#ffffff"
                font.pixelSize: 11
            }
        }
        
        Rectangle {
            id: instructionsOverlay
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.margins: 10
            width: instructionsText.width + 20
            height: instructionsText.height + 10
            color: Qt.rgba(0, 0, 0, 0.7)
            radius: 3
            visible: root.imagePath !== "" && imageView.status === Image.Ready
            
            Column {
                id: instructionsText
                anchors.centerIn: parent
                spacing: 2
                
                Label {
                    text: "• Scroll: Zoom"
                    color: "#cccccc"
                    font.pixelSize: 9
                }
                Label {
                    text: "• Drag: Pan"
                    color: "#cccccc"
                    font.pixelSize: 9
                }
            }
        }
    }
}
