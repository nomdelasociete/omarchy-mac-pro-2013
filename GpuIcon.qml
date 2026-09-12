import QtQuick
import qs.Commons

Item {
  id: root

  property real iconSize: Style.font.icon
  property color color: Color.foreground
  property bool offloadActive: false

  width: iconSize
  height: iconSize
  implicitWidth: iconSize
  implicitHeight: iconSize

  Rectangle {
    width: parent.width * 0.72
    height: parent.height * 0.46
    radius: Math.max(1, height * 0.18)
    color: "transparent"
    border.color: root.color
    border.width: Math.max(1, root.iconSize * 0.08)
    opacity: root.offloadActive ? 0.35 : 1.0
    x: parent.width * 0.04
    y: parent.height * 0.08
  }

  Rectangle {
    width: parent.width * 0.72
    height: parent.height * 0.46
    radius: Math.max(1, height * 0.18)
    color: "transparent"
    border.color: root.color
    border.width: Math.max(1, root.iconSize * 0.08)
    opacity: root.offloadActive ? 1.0 : 0.35
    x: parent.width * 0.24
    y: parent.height * 0.46
  }
}
