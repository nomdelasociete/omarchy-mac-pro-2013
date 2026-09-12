import QtQuick
import qs.Commons

// Filled 3/4 cylinder — 2013 Mac Pro weight, not a wireframe pill.
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

  readonly property real bw: width * 0.72
  readonly property real bx: (width - bw) / 2
  readonly property real cap: bw * 0.38
  readonly property real top: height * 0.06
  readonly property real bodyH: height * 0.70

  // Bottom cap
  Rectangle {
    x: root.bx
    y: root.top + root.bodyH - root.cap * 0.15
    width: root.bw
    height: root.cap
    radius: height / 2
    color: root.color
  }

  // Body
  Rectangle {
    x: root.bx
    y: root.top + root.cap * 0.42
    width: root.bw
    height: root.bodyH - root.cap * 0.20
    color: root.color
  }

  // Top cap
  Rectangle {
    id: lid
    x: root.bx
    y: root.top
    width: root.bw
    height: root.cap
    radius: height / 2
    color: root.color
  }

  // Throat of the cylinder
  Rectangle {
    x: lid.x + lid.width * 0.18
    y: lid.y + lid.height * 0.22
    width: lid.width * 0.64
    height: lid.height * 0.56
    radius: height / 2
    color: root.cut
  }

  // Specular slash
  Rectangle {
    x: root.bx + root.bw * 0.16
    y: root.top + root.cap * 0.85
    width: Math.max(1.6, root.iconSize * 0.08)
    height: root.bodyH * 0.48
    radius: width / 2
    color: root.cut
    opacity: 0.85
    rotation: 4
  }
}
