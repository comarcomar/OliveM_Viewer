import QtQuick
import QtQuick3D
import QtQuick.Controls

View3D {
    id: root
    
    property string imagePath: ""
    property int colorMapIndex: 0
    property var processor: null
    
    anchors.fill: parent
    
    environment: SceneEnvironment {
        clearColor: "#e0e0e0"
        backgroundMode: SceneEnvironment.Color
        antialiasingMode: SceneEnvironment.MSAA
    }
    
    PerspectiveCamera {
        id: camera
        position: Qt.vector3d(250, 200, 250)
        eulerRotation: Qt.vector3d(-30, 45, 0)
        clipFar: 3000
        clipNear: 1
    }
    
    DirectionalLight {
        eulerRotation: Qt.vector3d(-45, -20, 0)
        brightness: 1.2
    }
    
    DirectionalLight {
        eulerRotation: Qt.vector3d(30, 160, 0)
        brightness: 0.5
    }
    
    Node {
        id: sceneRoot
        
        Model {
            source: "#Rectangle"
            scale: Qt.vector3d(5, 5, 1)
            position: Qt.vector3d(0, -10, 0)
            eulerRotation.x: -90
            materials: PrincipledMaterial {
                baseColor: "#999999"
                roughness: 0.8
            }
        }
        
        Node {
            id: barsContainer
        }
    }
    
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 10
        width: 200
        height: 40
        color: Qt.rgba(0, 0, 0, 0.7)
        radius: 4
        
        Text {
            anchors.centerIn: parent
            text: "Drag: Rotate | Scroll: Zoom"
            color: "#ffffff"
            font.pixelSize: 11
        }
    }
    
    Label {
        anchors.centerIn: parent
        text: {
            if (root.imagePath === "") return "No image"
            if (barsContainer.children.length === 0) return "Loading..."
            return ""
        }
        color: "#666666"
        font.pixelSize: 14
        visible: text !== ""
    }
    
    MouseArea {
        anchors.fill: parent
        property real lastX: 0
        property real lastY: 0
        property bool dragging: false
        
        onPressed: (mouse) => {
            lastX = mouse.x
            lastY = mouse.y
            dragging = true
        }
        
        onReleased: {
            dragging = false
        }
        
        onPositionChanged: (mouse) => {
            if (dragging) {
                var dx = mouse.x - lastX
                var dy = mouse.y - lastY
                
                var rot = camera.eulerRotation
                rot.y += dx * 0.5
                rot.x += dy * 0.5
                rot.x = Math.max(-85, Math.min(-5, rot.x))
                camera.eulerRotation = rot
                
                lastX = mouse.x
                lastY = mouse.y
            }
        }
        
        onWheel: (wheel) => {
            var factor = wheel.angleDelta.y > 0 ? 0.9 : 1.1
            var pos = camera.position
            var dist = Math.sqrt(pos.x*pos.x + pos.y*pos.y + pos.z*pos.z)
            var newDist = Math.max(100, Math.min(800, dist * factor))
            var ratio = newDist / dist
            camera.position = Qt.vector3d(pos.x * ratio, pos.y * ratio, pos.z * ratio)
        }
    }
    
    onImagePathChanged: {
        if (imagePath !== "") {
            loadTimer.start()
        }
    }
    
    Timer {
        id: loadTimer
        interval: 300
        onTriggered: {
            clearBars()
            generateBars()
        }
    }
    
    function clearBars() {
        console.log("Clearing 3D bars...")
        var count = 0
        while (barsContainer.children.length > 0 && count < 5000) {
            barsContainer.children[0].destroy()
            count++
        }
    }
    
    function generateBars() {
        if (!root.processor || root.imagePath === "") {
            console.log("No processor or path")
            return
        }
        
        console.log("Loading 3D data...")
        var data = root.processor.getHeightData(root.imagePath, 30, 30)
        
        if (data.length === 0) {
            console.log("No data")
            return
        }
        
        console.log("Got", data.length, "points")
        
        var maxX = 0, maxY = 0
        for (var i = 0; i < data.length; i++) {
            maxX = Math.max(maxX, data[i].x)
            maxY = Math.max(maxY, data[i].y)
        }
        
        var w = maxX + 1
        var h = maxY + 1
        var spacing = 300.0 / Math.max(w, h)
        var heightScale = 100.0
        
        console.log("Creating", data.length, "bars")
        
        for (var i = 0; i < data.length; i++) {
            var pt = data[i]
            var ht = Math.pow(pt.height, 0.8) * heightScale + 2
            
            var px = (pt.x - w/2) * spacing
            var pz = (pt.y - h/2) * spacing
            var py = ht / 2
            
            var col = getColor(1.0 - pt.height) // Inverted
            
            var qml = `
                import QtQuick; import QtQuick3D
                Model {
                    source: "#Cube"
                    position: Qt.vector3d(${px}, ${py}, ${pz})
                    scale: Qt.vector3d(${spacing*0.85/100}, ${ht/100}, ${spacing*0.85/100})
                    materials: PrincipledMaterial {
                        baseColor: "${col}"
                        metalness: 0.1
                        roughness: 0.6
                    }
                }
            `
            
            try {
                Qt.createQmlObject(qml, barsContainer)
            } catch (e) {
                // Skip errors
            }
        }
        
        console.log("3D view ready")
    }
    
    function getColor(h) {
        if (root.colorMapIndex === 1) { // Hot
            return Qt.rgba(h, h*h, h*h*h, 1)
        } else if (root.colorMapIndex === 2) { // Gray
            return Qt.rgba(h, h, h, 1)
        } else if (root.colorMapIndex === 3) { // Viridis
            var colors = ["#440154", "#31688e", "#35b779", "#fde724"]
            var idx = Math.min(3, Math.floor(h * 4))
            return colors[idx]
        }
        
        // Jet (default)
        if (h < 0.14) return Qt.rgba(0, 0, 0.5 + h*3.5, 1)
        if (h < 0.28) return Qt.rgba(0, (h-0.14)*7, 1, 1)
        if (h < 0.42) return Qt.rgba(0, 1, 1-(h-0.28)*7, 1)
        if (h < 0.56) return Qt.rgba((h-0.42)*7, 1, 0, 1)
        if (h < 0.70) return Qt.rgba(1, 1-(h-0.56)*7, 0, 1)
        if (h < 0.84) return Qt.rgba(1, 0, 0, 1)
        return Qt.rgba(0.5 + (1-h)*3, 0, 0, 1)
    }
}
