import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    
    property var histogramData: []
    property var themeColors: ({
        panelColor: "#2a2a2a",
        borderColor: "#404040",
        textColor: "#ffffff",
        textSecondaryColor: "#cccccc",
        buttonColor: "#003366",
        buttonHoverColor: "#004499",
        buttonPressedColor: "#0066cc"
    })
    
    Rectangle {
        anchors.fill: parent
        color: root.themeColors.panelColor
        border.color: root.themeColors.borderColor
        border.width: 1
        
        Canvas {
            id: histogramCanvas
            anchors.fill: parent
            anchors.margins: 10
            
            onPaint: {
                let ctx = getContext("2d")
                ctx.fillStyle = root.themeColors.panelColor
                ctx.fillRect(0, 0, width, height)
                
                if (root.histogramData.length === 0) {
                    ctx.fillStyle = root.themeColors.textSecondaryColor
                    ctx.font = "12px Arial"
                    ctx.textAlign = "center"
                    ctx.fillText("No histogram data", width / 2, height / 2)
                    return
                }
                
                let barWidth = width / root.histogramData.length
                let maxHeight = height - 60  // More space for X-axis labels
                let chartLeft = 40  // Space for Y-axis labels
                let chartWidth = width - chartLeft - 10
                let chartHeight = maxHeight
                
                // Draw histogram bars
                ctx.fillStyle = "#4a90e2"
                ctx.strokeStyle = root.themeColors.borderColor
                
                for (let i = 0; i < root.histogramData.length; ++i) {
                    let bin = root.histogramData[i]
                    let barHeight = bin.normalized * chartHeight
                    let x = chartLeft + (i / root.histogramData.length) * chartWidth
                    let barActualWidth = (chartWidth / root.histogramData.length)
                    let y = height - 60 - barHeight
                    
                    ctx.fillRect(x, y, barActualWidth - 1, barHeight)
                    ctx.strokeRect(x, y, barActualWidth - 1, barHeight)
                }
                
                // Draw axes
                ctx.strokeStyle = root.themeColors.borderColor
                ctx.lineWidth = 1
                
                // X-axis
                ctx.beginPath()
                ctx.moveTo(chartLeft, height - 40)
                ctx.lineTo(width, height - 40)
                ctx.stroke()
                
                // Y-axis
                ctx.beginPath()
                ctx.moveTo(chartLeft, 0)
                ctx.lineTo(chartLeft, height - 40)
                ctx.stroke()
                
                // Draw X-axis tick marks and labels
                ctx.fillStyle = root.themeColors.textSecondaryColor
                ctx.font = "9px Arial"
                ctx.textAlign = "center"
                
                if (root.histogramData.length > 0) {
                    let minValue = root.histogramData[0].value
                    let maxValue = root.histogramData[root.histogramData.length - 1].value
                    
                    // Draw multiple reference points on X-axis
                    let numTicks = 5
                    for (let i = 0; i < numTicks; ++i) {
                        let fraction = i / (numTicks - 1)
                        let xPos = chartLeft + fraction * chartWidth
                        let value = minValue + fraction * (maxValue - minValue)
                        
                        // Draw tick mark
                        ctx.beginPath()
                        ctx.moveTo(xPos, height - 40)
                        ctx.lineTo(xPos, height - 35)
                        ctx.stroke()
                        
                        // Draw label
                        ctx.fillText(value.toFixed(2), xPos, height - 20)
                    }
                }
                
                // Draw Y-axis tick marks and labels
                ctx.textAlign = "right"
                let numYTicks = 5
                for (let i = 0; i < numYTicks; ++i) {
                    let fraction = i / (numYTicks - 1)
                    let yPos = height - 40 - fraction * chartHeight
                    
                    // Draw tick mark
                    ctx.beginPath()
                    ctx.moveTo(chartLeft - 5, yPos)
                    ctx.lineTo(chartLeft, yPos)
                    ctx.stroke()
                    
                    // Find max count for Y-axis scaling
                    let maxCount = 0
                    for (let j = 0; j < root.histogramData.length; ++j) {
                        if (root.histogramData[j].count > maxCount) {
                            maxCount = root.histogramData[j].count
                        }
                    }
                    
                    let yValue = Math.round(fraction * maxCount)
                    ctx.fillText(yValue, chartLeft - 10, yPos + 3)
                }
                
                // Draw axis labels
                ctx.font = "bold 10px Arial"
                ctx.textAlign = "center"
                ctx.fillStyle = root.themeColors.textColor
                ctx.fillText("Value", width / 2, height - 2)
                
                ctx.save()
                ctx.translate(10, height / 2)
                ctx.rotate(-Math.PI / 2)
                ctx.fillText("Count", 0, 0)
                ctx.restore()
            }
            
            Connections {
                target: root
                function onHistogramDataChanged() {
                    histogramCanvas.requestPaint()
                }
            }
        }
    }
}
