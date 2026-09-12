import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

Panel {
  id: root
  moduleName: "nomdelasociete.macpro"
  ipcTarget: "nomdelasociete.macpro"
  manageIpc: false

  property string pluginDir: {
    var u = String(Qt.resolvedUrl("."))
    if (u.indexOf("file://") === 0) u = u.substring(7)
    if (u.length > 1 && u.charAt(u.length - 1) === "/") u = u.substring(0, u.length - 1)
    return u
  }

  property int appIndex: 0
  property bool cursorActive: false
  property string focusSection: "apps"

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property bool headerHasCursor: cursorActive && focusSection === "header"
  readonly property bool offloadBusy: macpro.offloadCount > 0
  readonly property color barIconColor: root.foreground

  function ensureCursor() {
    if (macpro.apps.length === 0) {
      focusSection = "header"
      appIndex = 0
      return
    }
    if (focusSection !== "apps" && focusSection !== "header") focusSection = "apps"
    if (appIndex >= macpro.apps.length) appIndex = Math.max(0, macpro.apps.length - 1)
    if (appIndex < 0) appIndex = 0
  }

  function moveCursor(dx, dy) {
    cursorActive = true
    ensureCursor()
    if (dy === 0) return
    if (focusSection === "header") {
      if (dy > 0 && macpro.apps.length > 0) {
        focusSection = "apps"
        appIndex = 0
        scrollCursorIntoView()
      }
      return
    }
    if (focusSection === "apps") {
      if (dy < 0 && appIndex === 0) {
        focusSection = "header"
        return
      }
      appIndex = Math.max(0, Math.min(macpro.apps.length - 1, appIndex + dy))
      scrollCursorIntoView()
    }
  }

  function selectedApp() {
    if (macpro.apps.length === 0) return null
    return macpro.apps[Math.max(0, Math.min(appIndex, macpro.apps.length - 1))]
  }

  function activateCursor() {
    ensureCursor()
    if (focusSection === "header") macpro.refresh()
    else if (focusSection === "apps") macpro.moveApp(selectedApp())
  }

  function setAppCursor(index) {
    cursorActive = true
    focusSection = "apps"
    appIndex = index
    scrollCursorIntoView()
  }

  function scrollItemIntoView(item) {
    if (!panelFlick || !item) return
    Qt.callLater(function() {
      if (!item) return
      var margin = Style.space(6)
      var point = item.mapToItem(panelFlick.contentItem, 0, 0)
      var top = point.y
      var bottom = top + item.height
      var viewTop = panelFlick.contentY
      var viewBottom = viewTop + panelFlick.height
      var maxY = Math.max(0, panelFlick.contentHeight - panelFlick.height)
      if (top < viewTop + margin) panelFlick.contentY = Math.max(0, top - margin)
      else if (bottom > viewBottom - margin) panelFlick.contentY = Math.min(maxY, bottom + margin - panelFlick.height)
    })
  }

  function scrollCursorIntoView() {
    if (focusSection === "apps" && appColumn && appIndex >= 0 && appIndex < appColumn.children.length)
      scrollItemIntoView(appColumn.children[appIndex])
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onOpenedChanged: if (opened) {
    cursorActive = false
    if (panelFlick) panelFlick.contentY = 0
    macpro.refresh()
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  Service {
    id: macpro
    settings: root.settings
    pluginDir: root.pluginDir
  }

  IpcHandler {
    target: root.ipcTarget
    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.toggle() }
    function refresh(): string { macpro.refresh(); return "ok" }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "O"
    iconComponent: Component {
      Item {
        implicitWidth: Style.bar.iconCanvas
        implicitHeight: Style.bar.iconCanvas
        width: Style.bar.iconCanvas
        height: Style.bar.iconCanvas

        Image {
          id: mark
          anchors.centerIn: parent
          width: parent.width
          height: parent.height
          source: Qt.resolvedUrl("icon.png")
          sourceSize.width: parent.width * 2
          sourceSize.height: parent.height * 2
          fillMode: Image.PreserveAspectFit
          visible: status === Image.Ready
        }

        GpuIcon {
          anchors.centerIn: parent
          iconSize: parent.width
          color: root.foreground
          offloadActive: root.offloadBusy
          visible: mark.status !== Image.Ready
        }
      }
    }
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton) macpro.refresh()
      else root.toggle()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(420))
    contentHeight: panel.fittedContentHeight(column.implicitHeight, Style.space(560))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onMoveRequested: function(dx, dy) {
        if (!root.cursorActive) { root.cursorActive = true; return }
        root.moveCursor(dx, dy)
      }
      onActivateRequested: if (root.cursorActive) root.activateCursor()
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onTextKey: function(t) {
        if (t === "r" || t === "R") macpro.refresh()
      }

      Flickable {
        id: panelFlick
        anchors.fill: parent
        contentWidth: width
        contentHeight: column.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        interactive: contentHeight > height
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Column {
          id: column
          width: panelFlick.width
          spacing: Style.space(12)

          Item {
            id: header
            width: parent.width
            implicitHeight: hero.implicitHeight
            readonly property bool ringVisible: root.headerHasCursor
            function focusHero() { root.cursorActive = true; root.focusSection = "header" }

            PanelHero {
              id: hero
              width: parent.width
              title: !macpro.profileApplied ? "Keep the cylinder alive"
                    : (macpro.needsReboot ? "Applied — reboot when ready" : "Mac Pro 2013")
              meta: !macpro.profileApplied
                    ? "One Apply. Dual FirePro, sleep, Wi-Fi. This is the whole setup."
                    : (macpro.needsReboot
                       ? "Profile is in. Finish this job, then reboot (not logout)."
                       : (macpro.sleepSummary + (macpro.offloadCount > 0 ? (" · " + macpro.offloadCount + " on GPU 2") : " · 2013 Mac Pro")))
              foreground: root.foreground
              fontFamily: root.fontFamily
              iconComponent: Component {
                GpuIcon {
                  iconSize: Style.font.display
                  color: root.foreground
                  offloadActive: root.offloadBusy
                }
              }
            }
          }

          Text {
            textFormat: Text.PlainText
            visible: macpro.actionStatus !== "" || macpro.lastError !== ""
            width: parent.width
            leftPadding: Style.space(10)
            rightPadding: Style.space(10)
            text: macpro.actionStatus !== "" ? macpro.actionStatus : macpro.lastError
            color: macpro.lastError !== "" && macpro.actionStatus === "" ? (bar ? bar.urgent : Color.urgent) : root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
            wrapMode: Text.WordWrap
          }

          Column {
            visible: !macpro.profileApplied
            width: parent.width
            spacing: Style.space(6)

            Text {
              textFormat: Text.PlainText
              width: parent.width
              leftPadding: Style.space(10)
              rightPadding: Style.space(10)
              text: "Both GPUs. Sleep that can wake. Wi-Fi that comes back.\nNo DRM login loop. No manual ritual."
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
              wrapMode: Text.Wrap
            }

            CursorSurface {
              width: parent.width
              implicitHeight: Style.space(40)
              foreground: root.foreground
              hasCursor: false
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: macpro.applyProfile()
              }
              Text {
                textFormat: Text.PlainText
                anchors.verticalCenter: parent.verticalCenter
                leftPadding: Style.space(10)
                text: "Apply profile  ·  sudo in a terminal"
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
              }
            }
          }

          Text {
            visible: macpro.profileApplied && macpro.needsReboot
            textFormat: Text.PlainText
            width: parent.width
            leftPadding: Style.space(10)
            rightPadding: Style.space(10)
            text: "Do not log out now. Reboot later so the GPU names attach. Windows below already work on this session."
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
            wrapMode: Text.WordWrap
          }

          Text {
            visible: macpro.profileApplied && !macpro.needsReboot
            textFormat: Text.PlainText
            width: parent.width
            leftPadding: Style.space(10)
            rightPadding: Style.space(10)
            text: "Click a window to relaunch it on the other FirePro. Sleep is Hibernate. Super+Alt+M toggles 30/60 Hz."
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }

          CursorSurface {
            width: parent.width
            implicitHeight: Style.space(36)
            foreground: root.foreground
            hasCursor: false
            visible: macpro.profileApplied
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: macpro.removeProfile()
            }
            Text {
              anchors.verticalCenter: parent.verticalCenter
              leftPadding: Style.space(10)
              text: "Remove profile…"
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
            }
          }

          PanelSeparator { foreground: root.foreground }

          Column {
            id: appColumn
            width: parent.width
            spacing: 0

            Repeater {
              model: macpro.apps
              delegate: AppRow {
                required property var modelData
                required property int index
                width: appColumn.width
                app: modelData
                rowIndex: index
              }
            }
          }

          Text {
            visible: macpro.apps.length === 0
            width: parent.width
            leftPadding: Style.space(10)
            text: macpro.refreshing ? "Reading windows…" : "No movable windows"
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
          }
        }
      }
    }
  }

  component AppRow: CursorSurface {
    id: appRow
    property var app: null
    property int rowIndex: 0

    hasCursor: root.cursorActive && root.focusSection === "apps" && root.appIndex === rowIndex
    foreground: root.foreground
    implicitHeight: appContent.implicitHeight + Style.spacing.rowPaddingX

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onEntered: root.setAppCursor(appRow.rowIndex)
      onClicked: macpro.moveApp(appRow.app)
    }

    RowLayout {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: Style.space(10)
      anchors.rightMargin: Style.space(10)
      spacing: Style.space(8)

      GpuIcon {
        iconSize: Style.font.icon
        color: root.foreground
        offloadActive: appRow.app && appRow.app.gpu === "offload"
        Layout.alignment: Qt.AlignVCenter
      }

      ColumnLayout {
        id: appContent
        Layout.fillWidth: true
        spacing: Style.space(1)

        Text {
          textFormat: Text.PlainText
          Layout.fillWidth: true
          text: Model.appTitle(appRow.app)
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
          elide: Text.ElideRight
        }

        Text {
          textFormat: Text.PlainText
          Layout.fillWidth: true
          text: Model.appMeta(appRow.app)
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          elide: Text.ElideRight
        }
      }

      Text {
        text: "󰁔"
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.icon
        Layout.alignment: Qt.AlignVCenter
      }
    }
  }
}
