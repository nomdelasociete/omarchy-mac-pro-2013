.pragma library

function gpuLabel(gpu) {
  if (gpu === "offload") return "GPU 2 · offload"
  return "GPU 1 · display"
}

function otherLabel(gpu) {
  if (gpu === "offload") return "Relaunch on display GPU"
  return "Relaunch on offload GPU"
}

function appMeta(app) {
  if (!app) return ""
  var bits = []
  bits.push(gpuLabel(app.gpu))
  if (app.class) bits.push(String(app.class))
  if (app.pid) bits.push("pid " + app.pid)
  return bits.join("  ·  ")
}

function appTitle(app) {
  if (!app) return "Untitled"
  var t = String(app.title || app.class || "Untitled")
  return t.length ? t : "Untitled"
}
