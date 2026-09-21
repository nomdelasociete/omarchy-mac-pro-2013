import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Item {
  id: root

  property var settings: ({})
  property string pluginDir: ""

  property var apps: []
  property var savedApps: []
  property bool refreshing: false
  property bool moving: false
  property string lastError: ""
  property string actionStatus: ""
  property int offloadCount: 0
  property int displayCount: 0
  property bool profileApplied: false
  property bool needsReboot: false
  property bool wifiWatch: false
  property bool udevNames: false
  property string suspend: ""
  property string hibernate: ""
  property bool isMacPro: false
  property string product: ""
  property string sleepSummary: ""
  property bool screensaverOff: false
  property bool suspendOff: false
  property bool stayAwake: false

  readonly property int refreshIntervalSec: {
    var n = parseInt(String(settings && settings.refreshIntervalSec != null ? settings.refreshIntervalSec : 4), 10)
    if (!isFinite(n)) n = 4
    if (n < 2) n = 2
    if (n > 30) n = 30
    return n
  }

  readonly property string listBin: pluginDir + "/bin/list-apps"
  readonly property string moveBin: pluginDir + "/bin/move-gpu"
  readonly property string prefBin: pluginDir + "/bin/gpu-pref"
  readonly property string statusBin: pluginDir + "/bin/status"
  readonly property string applyBin: pluginDir + "/bin/user-apply"
  readonly property string removeBin: pluginDir + "/bin/user-remove"

  function refresh() {
    if (listProc.running) return
    lastError = ""
    refreshing = true
    listProc.command = ["/usr/bin/timeout", "8", listBin]
    listProc.running = true
    if (!statusProc.running) {
      statusProc.command = ["/usr/bin/timeout", "5", statusBin]
      statusProc.running = true
    }
    if (!prefListProc.running) {
      prefListProc.command = ["/usr/bin/timeout", "5", prefBin, "list"]
      prefListProc.running = true
    }
  }

  function applyProfile() {
    actionStatus = "Apply: sudo in the terminal…"
    Quickshell.execDetached(["/usr/bin/omarchy-launch-floating-terminal-with-presentation", applyBin])
  }

  function removeProfile() {
    actionStatus = "Remove: sudo in the terminal…"
    Quickshell.execDetached(["/usr/bin/omarchy-launch-floating-terminal-with-presentation", removeBin])
  }

  function toggleWifiWatch() {
    var on = !wifiWatch
    wifiWatch = on
    wifiProc.command = ["/usr/bin/systemctl", "--user", on ? "enable" : "disable", "--now", "nomdelasociete.macpro-wifi-watch.service"]
    wifiProc.running = true
  }

  function moveApp(app) {
    if (!app || moving) return
    var target = app.other === "offload" ? "offload" : "display"
    setGpuPref(app.key || app.class, target, app.title || app.class, app.pid)
  }

  function setGpuPref(key, gpu, name, pid) {
    if (!key || (gpu !== "display" && gpu !== "offload")) return
    lastError = ""
    actionStatus = (pid ? "Relaunching on " : "Next launch: ") + gpu + "…"
    prefSetProc.command = ["/usr/bin/timeout", "8", prefBin, "set", String(key), gpu, String(name || key)]
    prefSetProc.pendingPid = pid ? Number(pid) : 0
    prefSetProc.pendingGpu = gpu
    prefSetProc.running = true
  }

  function toggleSaved(app) {
    if (!app) return
    var next = app.gpu === "offload" ? "display" : "offload"
    var running = null
    for (var i = 0; i < apps.length; i++) {
      if (String(apps[i].key || apps[i].class || "").toLowerCase() === String(app.key || "").toLowerCase()) {
        running = apps[i]
        break
      }
    }
    setGpuPref(app.key, next, app.name || app.key, running ? running.pid : 0)
  }

  Process {
    id: listProc
    stdout: StdioCollector { id: listOut }
    stderr: StdioCollector { id: listErr }
    onExited: function() {
      refreshing = false
      var raw = String(listOut.text || "")
      try {
        var parsed = JSON.parse(raw)
      } catch (e) {
        lastError = String(listErr.text || e)
        return
      }
      if (!parsed.ok) {
        lastError = String(parsed.error || "Failed to list apps")
        apps = []
        return
      }
      apps = parsed.apps || []
      var off = 0
      var disp = 0
      for (var i = 0; i < apps.length; i++) {
        if (apps[i].gpu === "offload") off++
        else disp++
      }
      offloadCount = off
      displayCount = disp
    }
  }

  Process {
    id: statusProc
    stdout: StdioCollector { id: statusOut }
    stderr: StdioCollector {}
    onExited: function() {
      try {
        var s = JSON.parse(String(statusOut.text || "{}"))
      } catch (e) {
        return
      }
      profileApplied = s.applied === true
      needsReboot = s.needsReboot === true
      wifiWatch = s.wifiWatch === true
      udevNames = s.udevNames === true
      suspend = String(s.suspend || "")
      hibernate = String(s.hibernate || "")
      isMacPro = s.isMacPro61 === true
      product = String(s.product || "")
      screensaverOff = s.screensaverOff === true
      suspendOff = s.suspendOff === true
      stayAwake = s.stayAwake === true
      var bits = []
      if (s.needsReboot) bits.push("fix DRM before next login")
      else bits.push("live")
      if (s.wifiWatch) bits.push("Wi-Fi watch on")
      if (s.suspend === "masked") bits.push("Sleep blocked")
      sleepSummary = bits.join(" · ")
    }
  }

  Process {
    id: wifiProc
    stdout: StdioCollector {}
    stderr: StdioCollector {}
    onExited: function() { Qt.callLater(root.refresh) }
  }

  Process {
    id: prefListProc
    stdout: StdioCollector { id: prefListOut }
    stderr: StdioCollector {}
    onExited: function() {
      try {
        var p = JSON.parse(String(prefListOut.text || "{}"))
        savedApps = p.ok ? (p.apps || []) : []
      } catch (e) {
        savedApps = []
      }
    }
  }

  Process {
    id: prefSetProc
    property int pendingPid: 0
    property string pendingGpu: ""
    stdout: StdioCollector { id: prefSetOut }
    stderr: StdioCollector { id: prefSetErr }
    onExited: function(code) {
      if (code !== 0) {
        lastError = String(prefSetErr.text || prefSetOut.text || "Could not save GPU preference").trim()
        actionStatus = ""
        Qt.callLater(root.refresh)
        return
      }
      if (pendingPid > 0) {
        moving = true
        actionStatus = "Relaunching on " + pendingGpu + "…"
        moveProc.command = ["/usr/bin/timeout", "15", moveBin, String(pendingPid), pendingGpu]
        moveProc.running = true
      } else {
        actionStatus = "Saved for next launch"
        Qt.callLater(root.refresh)
      }
    }
  }

  Process {
    id: moveProc
    stdout: StdioCollector {}
    stderr: StdioCollector { id: moveErr }
    onExited: function(code) {
      moving = false
      if (code !== 0) {
        lastError = String(moveErr.text || "Relaunch failed").trim()
        actionStatus = ""
      } else {
        actionStatus = "Relaunched"
      }
      Qt.callLater(root.refresh)
    }
  }

  Timer {
    interval: root.refreshIntervalSec * 1000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  Component.onCompleted: refresh()
}
