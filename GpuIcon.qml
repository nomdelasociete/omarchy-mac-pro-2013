import QtQuick
import qs.Commons

// Original mark in the Noun-style Mac Pro language: outline cylinder,
// lid ellipse, one highlight. Theme stroke. Reads at bar size.
Item {
  id: root

  property real iconSize: Style.font.icon
  property color color: Color.foreground
  property bool offloadActive: false

  width: iconSize
  height: iconSize
  implicitWidth: iconSize
  implicitHeight: iconSize

  readonly property real sw: Math.max(1.4, iconSize * 0.09)
  readonly property real bw: width * 0.62
  readonly property real bh: height * 0.86
  readonly property real bx: (width - bw) / 2
  readonly property real by: (height - bh) / 2
  readonly property real cap: bw * 0.36

  // Body outline (stadium / cylinder)
  Rectangle {
    x: root.bx
    y: root.by
    width: root.bw
    height: root.bh
    radius: root.bw / 2
    color: "transparent"
    border.color: root.color
    border.width: root.sw
  }

  // Lid ellipse
  Rectangle {
    x: root.bx + root.bw * 0.16
    y: root.by + root.bh * 0.16
    width: root.bw * 0.68
    height: root.cap * 0.72
    radius: height / 2
    color: "transparent"
    border.color: root.color
    border.width: root.sw
  }

  // Specular highlight
  Rectangle {
    x: root.bx + root.bw * 0.28
    y: root.by + root.bh * 0.38
    width: root.sw
    height: root.bh * 0.34
    radius: width / 2
    color: root.color
    opacity: root.offloadActive ? 1 : 0.9
  }
}
