-- AeroSpace auto-enable based on external monitor connection
-- When external monitor is connected: AeroSpace ON (tiling enabled)
-- When only built-in display: AeroSpace OFF (normal macOS window management)

local log = hs.logger.new("aerospace", "debug")
local lastHasExternal = nil

local function hasExternalMonitorNow()
  local screens = hs.screen.allScreens()
  log.d("Screen count: " .. #screens)

  if #screens == 1 then
    local screenName = screens[1]:name()
    log.d("Single screen name: " .. screenName)
    -- Built-in display names typically contain "Built-in" or similar
    if screenName:find("Built%-in") or screenName:find("Color LCD") then
      return false
    else
      -- Single external monitor (clamshell mode)
      return true
    end
  else
    -- Multiple displays = external monitor connected
    return true
  end
end

local function quitAeroSpace()
  -- Try hs.application first
  local app = hs.application.get("AeroSpace")
  if app then
    log.d("Quitting AeroSpace via hs.application")
    app:kill()
    return
  end

  -- Fallback to killall
  log.d("Quitting AeroSpace via killall")
  hs.execute("/usr/bin/killall AeroSpace", true)
end

local function launchAeroSpace()
  log.d("Launching AeroSpace")
  hs.application.launchOrFocusByBundleID("bobko.aerospace")
end

local function updateAeroSpace()
  local hasExternal = hasExternalMonitorNow()
  log.d("hasExternal: " .. tostring(hasExternal) .. ", lastHasExternal: " .. tostring(lastHasExternal))

  -- Skip if state hasn't changed
  if hasExternal == lastHasExternal then
    log.d("No state change, skipping")
    return
  end
  lastHasExternal = hasExternal

  if hasExternal then
    launchAeroSpace()
    hs.notify.new({
      title = "AeroSpace",
      informativeText = "Launched (External monitor/Clamshell mode)"
    }):send()
  else
    quitAeroSpace()
    hs.notify.new({
      title = "AeroSpace",
      informativeText = "Quit (Laptop mode)"
    }):send()
  end
end

-- Watch for monitor changes
local screenWatcher = hs.screen.watcher.new(function()
  log.d("Screen watcher fired")
  hs.alert.show("Screen changed")
  -- Increased delay to let macOS settle after monitor connect/disconnect
  hs.timer.doAfter(1.5, updateAeroSpace)
end)
screenWatcher:start()

-- Watch for sleep/wake events
local caffeinateWatcher = hs.caffeinate.watcher.new(function(event)
  if event == hs.caffeinate.watcher.systemDidWake or
     event == hs.caffeinate.watcher.screensDidWake then
    log.d("Wake event detected")
    -- Longer delay after wake to ensure displays are fully initialized
    hs.timer.doAfter(2.0, updateAeroSpace)
  end
end)
caffeinateWatcher:start()

-- Run on Hammerspoon startup
hs.timer.doAfter(1.0, updateAeroSpace)

-- Show notification when Hammerspoon config is loaded
hs.notify.new({
  title = "Hammerspoon",
  informativeText = "Config loaded successfully"
}):send()
