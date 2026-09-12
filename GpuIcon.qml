import QtQuick
import qs.Commons

// 2013 Mac Pro cylinder as an Omarchy mark: theme fill, lid + vent band.
Item {
  id: root

  property real iconSize: Style.font.icon
  property color color: Color.foreground
  property bool offloadActive: false
  property color cut: Color.background

  width: iconSize
  height: iconSize
  implicitWidth: iconSize
  implicitHeight: iconSize

  readonly property real bw: width * 0.56
  readonly property real cx: (width - bw) / 2
  readonly property real cap: bw * 0.34
  readonly property real top: height * 0.10
  readonly property real bodyTop: top + cap * 0.45
  readonly property real bodyH: height * 0.72

  Rectangle {
    x: root.cx
    y: root.bodyTop
    width: root.bw
    height: root.bodyH
    color: root.color
    radius: 1
  }

  Rectangle {
    x: root.cx
    y: root.top + root.bodyH + root.cap * 0.15
    width: root.bw
    height: root.cap
    radius: height / 2
    color: root.color
  }

  Rectangle {
    id: lid
    x: root.cx
    y: root.top
    width: root.bw
    height: root.cap
    radius: height / 2
    color: root.color
  }

  Rectangle {
    anchors.centerIn: lid
    width: lid.width * 0.70
    height: lid.height * 0.42
    radius: height / 2
    color: root.cut
    opacity: 0.35
  }

  Row {
    id: vents
    visible: root.iconSize >= 12
    x: root.cx + root.bw * 0.10
    y: root.bodyTop + root.cap * 0.28
    width: root.bw * 0.80
    spacing: Math.max(1, (width - (repeater.count * dotW)) / Math.max(1, repeater.count - 1))
    readonly property real dotW: Math.max(1.4, root.iconSize * 0.07)

    Repeater {
      id: repeater
      model: root.iconSize >= 18 ? 9 : 6
      Rectangle {
        width: vents.dotW
        height: width
        radius: width / 2
        color: root.cut
        opacity: 0.85
      }
    }
  }
}
