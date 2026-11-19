-- ~/.hammerspoon/init.lua
-- F12 from anywhere: a maximized Ghostty terminal comes to the front.
--   * Ghostty not running        -> starts it
--   * running, no window open    -> opens a fresh terminal
--   * running, in the background -> brings it to the front
--   * already in front           -> hides it (press again to bring it back)

require("hs.ipc")                 -- lets the `hs` command line talk to Hammerspoon
hs.autoLaunch(true)              -- start Hammerspoon at login
hs.dockIcon(false)               -- menu-bar icon only
hs.window.animationDuration = 0  -- resize instantly

local GHOSTTY = "com.mitchellh.ghostty"

-- Needs the Accessibility permission; without it this quietly does nothing
-- (Ghostty's own `maximize = true` still maximizes every new window).
local function maximizeFrontWindow()
  pcall(function()
    local app = hs.application.get(GHOSTTY)
    if not app then return end
    local win = app:focusedWindow() or app:mainWindow()
    if not win or not win:isStandard() or win:isFullScreen() then return end
    local f, s = win:frame(), win:screen():frame()
    if math.abs(f.w - s.w) > 8 or math.abs(f.h - s.h) > 8 then win:maximize() end
  end)
end

-- Does the app have a normal window on screen? Asked of the window server,
-- so it works without the Accessibility permission. If the question fails,
-- assume yes (F12 then hides, the long-standing behaviour).
local function hasWindows(app)
  local ok, result = pcall(function()
    local pid = app:pid()
    for _, w in ipairs(hs.window.list() or {}) do
      if w.kCGWindowOwnerPID == pid and w.kCGWindowLayer == 0
         and (w.kCGWindowBounds or {}).Height and w.kCGWindowBounds.Height > 100 then
        return true
      end
    end
    return false
  end)
  if not ok then return true end
  return result
end

local function showTerminal()
  -- `open -a` starts Ghostty, or activates it; Ghostty opens a new window
  -- itself when it is running with none.
  hs.task.new("/usr/bin/open", function()
    hs.timer.doAfter(0.35, maximizeFrontWindow)
  end, { "-b", GHOSTTY }):start()
end

-- Small log of what F12 decided: ~/.hammerspoon/f12.log
local LOG = os.getenv("HOME") .. "/.hammerspoon/f12.log"
local function note(msg)
  local f = io.open(LOG, "a")
  if f then f:write(os.date("%F %T "), msg, "\n"); f:close() end
end

hs.hotkey.bind({}, "f12", function()
  local front = hs.application.frontmostApplication()
  local isGhostty = front ~= nil and front:bundleID() == GHOSTTY
  local wins = isGhostty and hasWindows(front)
  if isGhostty and wins then
    note("F12: Ghostty in front with a window -> hide")
    front:hide()
  else
    note("F12: front=" .. tostring(front and front:bundleID()) .. " windows=" .. tostring(wins) .. " -> show")
    showTerminal()
  end
end)

note("config loaded, accessibility=" .. tostring(hs.accessibilityState()))
