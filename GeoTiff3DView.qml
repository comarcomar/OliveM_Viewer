import QtQuick
import QtQuick3D
import QtQuick3D.Helpers

Item {
    id: root
    
    property string imagePath: ""
    property int colorMapIndex: 0
    
    View3D {
        anchors.fill: parent
        camera: camera
        environment: sceneEnvironment
        
        SceneEnvironment {
            id: sceneEnvironment
            clearColor: "#1e1e1e"
            backgroundMode: SceneEnvironment.Color
            antialiasingMode: SceneEnvironment.MSAA
            antialiasingQuality: SceneEnvironment.High
        }
        
        PerspectiveCamera {
            id: camera
            position: Qt.vector3d(0, 150, 300)
            eulerRotation.x: -20
            clipNear: 1
            clipFar: 10000
        }
        
        DirectionalLight {
            eulerRotation.x: -30
            eulerRotation.y: -70
            brightness: 1.0
            castsShadow: true
        }
        
        DirectionalLight {
            eulerRotation.x: 30
            eulerRotation.y: 110
            brightness: 0.3
        }
        
        // Terrain mesh
        Model {
            id: terrainModel
            source: "#Rectangle"
            scale: Qt.vector3d(20, 1, 20)
            eulerRotation.x: -90
            
            materials: PrincipledMaterial {
                baseColor: "#4a7a4a"
                metalness: 0.0
                roughness: 0.8
            }
        }
        
        // Grid plane
        Model {
            source: "#Rectangle"
            position: Qt.vector3d(0, -5, 0)
            scale: Qt.vector3d(20, 1, 20)
            eulerRotation.x: -90
            
            materials: PrincipledMaterial {
                baseColor: "#2a2a2a"
                metalness: 0.0
                roughness: 1.0
            }
        }
    }
    
    // Camera controller
    WasdController {
        controlledObject: camera
        speed: 0.5
    }
    
    // Mouse area for rotation
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        
        property real lastX: 0
        property real lastY: 0
        
        onPressed: (mouse) => {
            lastX = mouse.x
            lastY = mouse.y
        }
        
        onPositionChanged: (mouse) => {
            if (pressed) {
                var deltaX = mouse.x - lastX
                var deltaY = mouse.y - lastY
                
                camera.eulerRotation.y += deltaX * 0.5
                camera.eulerRotation.x = Math.max(-89, Math.min(89, camera.eulerRotation.x - deltaY * 0.5))
                
                lastX = mouse.x
                lastY = mouse.y
            }
        }
        
        onWheel: (wheel) => {
            var delta = wheel.angleDelta.y
            var newZ = camera.position.z - delta * 0.5
            camera.position.z = Math.max(50, Math.min(1000, newZ))
        }
    }
    
    // Overlay text
    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 10
        width: 180
        height: 80
        color: Qt.rgba(0, 0, 0, 0.7)
        radius: 5
        
        Column {
            anchors.centerIn: parent
            spacing: 5
            
            Text {
                text: "3D Relief View"
                color: "white"
                font.pixelSize: 12
                font.bold: true
                anchors.horizontalCenter: parent.horizontalCenter
            }
            
            Text {
                text: "Drag to rotate"
                color: "#aaaaaa"
                font.pixelSize: 10
                anchors.horizontalCenter: parent.horizontalCenter
            }
            
            Text {
                text: "Scroll to zoom"
                color: "#aaaaaa"
                font.pixelSize: 10
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }
    
    Text {
        anchors.centerIn: parent
        text: root.imagePath === "" ? "No image loaded" : "Loading 3D data..."
        color: "#666666"
        font.pixelSize: 14
        visible: root.imagePath === ""
    }
}
