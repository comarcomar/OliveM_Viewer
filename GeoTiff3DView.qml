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
        clearColor: "#e8e8e8"
        backgroundMode: SceneEnvironment.Color
        antialiasingMode: SceneEnvironment.MSAA
    }
    
    // Orthographic camera looking straight down
    OrthographicCamera {
        id: camera
        position: Qt.vector3d(0, 500, 0)
        eulerRotation: Qt.vector3d(-90, 0, 0)
        clipFar: 2000
        clipNear: 1
        
        property real viewportScale: 1.0
        horizontalMagnification: viewportScale
        verticalMagnification: viewportScale
    }
    
    // Directional light from above
    DirectionalLight {
        eulerRotation: Qt.vector3d(-60, -30, 0)
        brightness: 1.5
        castsShadow: false
    }
    
    // Fill light
    DirectionalLight {
        eulerRotation: Qt.vector3d(-60, 150, 0)
        brightness: 0.5
    }
    
    Node {
        id: sceneRoot
        
        Model {
            source: "#Rectangle"
            scale: Qt.vector3d(10, 10, 1)
            position: Qt.vector3d(0, -5, 0)
            eulerRotation.x: -90
            materials: PrincipledMaterial {
                baseColor: "#cccccc"
                roughness: 0.9
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
        width: 180
        height: 40
        color: Qt.rgba(0, 0, 0, 0.7)
        radius: 4
        
        Text {
            anchors.centerIn: parent
            text: "Scroll: Zoom | Vista in Pianta"
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
    
    // Mouse controls - ONLY ZOOM, no rotation
    MouseArea {
        anchors.fill: parent
        
        onWheel: (wheel) => {
            var factor = wheel.angleDelta.y > 0 ? 0.9 : 1.1
            var newScale = camera.viewportScale * factor
            newScale = Math.max(0.3, Math.min(3.0, newScale))
            camera.viewportScale = newScale
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
            generateHeightmap()
        }
    }
    
    function clearBars() {
        console.log("Clearing 3D heightmap...")
        var count = 0
        while (barsContainer.children.length > 0 && count < 5000) {
            barsContainer.children[0].destroy()
            count++
        }
    }
    
    function generateHeightmap() {
        if (!root.processor || root.imagePath === "") {
            console.log("No processor or path")
            return
        }
        
        console.log("Loading heightmap data...")
        var data = root.processor.getHeightData(root.imagePath, 50, 50)
        
        if (data.length === 0) {
            console.log("No data")
            return
        }
        
        console.log("Got", data.length, "points")
        
        // Find dimensions
        var maxX = 0, maxY = 0
        for (var i = 0; i < data.length; i++) {
            maxX = Math.max(maxX, data[i].x)
            maxY = Math.max(maxY, data[i].y)
        }
        
        var gridW = maxX + 1
        var gridH = maxY + 1
        
        console.log("Creating heightmap", gridW, "x", gridH)
        
        // Calculate spacing to maintain proportions
        var targetSize = 400  // Total size in scene units
        var aspectRatio = gridW / gridH
        
        var spacingX, spacingZ
        if (aspectRatio > 1) {
            // Wider than tall
            spacingX = targetSize / gridW
            spacingZ = spacingX  // Keep square pixels
        } else {
            // Taller than wide
            spacingZ = targetSize / gridH
            spacingX = spacingZ  // Keep square pixels
        }
        
        console.log("Spacing:", spacingX, "x", spacingZ, "aspect:", aspectRatio.toFixed(2))
        
        var heightScale = 80  // Moderate relief
        
        // Create flat quads with height-based color
        for (var i = 0; i < data.length; i++) {
            var pt = data[i]
            
            // Exaggerate height slightly for visibility
            var ht = Math.pow(pt.height, 0.85) * heightScale
            
            var px = (pt.x - gridW/2) * spacingX
            var pz = (pt.y - gridH/2) * spacingZ
            var py = ht / 2
            
            // Inverted colormap (high = blue, low = red)
            var col = getColor(1.0 - pt.height)
            
            // Create thin box with correct aspect
            var qml = `
                import QtQuick; import QtQuick3D
                Model {
                    source: "#Cube"
                    position: Qt.vector3d(${px}, ${py}, ${pz})
                    scale: Qt.vector3d(${spacingX*0.98/100}, ${ht/100}, ${spacingZ*0.98/100})
                    materials: PrincipledMaterial {
                        baseColor: "${col}"
                        metalness: 0.0
                        roughness: 0.7
                    }
                }
            `
            
            try {
                Qt.createQmlObject(qml, barsContainer)
            } catch (e) {
                // Skip errors
            }
        }
        
        console.log("Heightmap ready:", barsContainer.children.length, "elements")
    }
    
    function getColor(h) {
        // Jet colormap with smooth interpolation
        if (root.colorMapIndex === 1) { // Hot
            var r = Math.min(1, h * 3)
            var g = Math.max(0, Math.min(1, (h - 0.33) * 3))
            var b = Math.max(0, Math.min(1, (h - 0.67) * 3))
            return Qt.rgba(r, g, b, 1)
        } else if (root.colorMapIndex === 2) { // Grayscale
            return Qt.rgba(h, h, h, 1)
        } else if (root.colorMapIndex === 3) { // Viridis
            if (h < 0.25) {
                var f = h / 0.25
                return Qt.rgba(0.267 + f * (0.192 - 0.267), 0.005 + f * (0.407 - 0.005), 0.329 + f * (0.557 - 0.329), 1)
            } else if (h < 0.50) {
                var f = (h - 0.25) / 0.25
                return Qt.rgba(0.192 + f * (0.208 - 0.192), 0.407 + f * (0.718 - 0.407), 0.557 + f * (0.475 - 0.557), 1)
            } else if (h < 0.75) {
                var f = (h - 0.50) / 0.25
                return Qt.rgba(0.208 + f * (0.941 - 0.208), 0.718 + f * (0.906 - 0.718), 0.475 + f * (0.145 - 0.475), 1)
            } else {
                return Qt.rgba(0.941, 0.906, 0.145, 1)
            }
        }
        
        // Jet (default) - smooth interpolation
        if (h < 0.125) {
            return Qt.rgba(0, 0, 0.5 + h * 4, 1)
        } else if (h < 0.375) {
            var f = (h - 0.125) / 0.25
            return Qt.rgba(0, f, 1, 1)
        } else if (h < 0.625) {
            var f = (h - 0.375) / 0.25
            return Qt.rgba(0, 1, 1 - f, 1)
        } else if (h < 0.875) {
            var f = (h - 0.625) / 0.25
            return Qt.rgba(f, 1, 0, 1)
        } else {
            var f = (h - 0.875) / 0.125
            return Qt.rgba(1, 1 - f, 0, 1)
        }
    }
}
