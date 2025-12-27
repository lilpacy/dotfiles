-- AeroSpace auto-enable based on external monitor connection
-- When external monitor is connected: AeroSpace ON (tiling enabled)
-- When only built-in display: AeroSpace OFF (normal macOS window management)

local AEROSPACE = "/opt/homebrew/bin/aerospace"

local function checkMonitors()
  local screens = hs.screen.allScreens()
  local hasExternalMonitor = false
  local builtInOnly = false

  -- Check if we have only the built-in display
  if #screens == 1 then
    local screenName = screens[1]:name()
    -- Built-in display names typically contain "Built-in" or similar
    if screenName:find("Built%-in") or screenName:find("Color LCD") then
      builtInOnly = true
    else
      -- Single external monitor (clamshell mode)
      hasExternalMonitor = true
    end
  elseif #screens > 1 then
    -- Multiple displays = external monitor connected
    hasExternalMonitor = true
  end

  if hasExternalMonitor or not builtInOnly then
    -- External monitor or clamshell mode → Enable AeroSpace
    hs.execute(AEROSPACE .. " enable on", true)
    hs.notify.new({
      title = "AeroSpace",
      informativeText = "Enabled (External monitor/Clamshell mode)"
    }):send()
  else
    -- Built-in display only → Disable AeroSpace
    hs.execute(AEROSPACE .. " enable off", true)
    hs.notify.new({
      title = "AeroSpace",
      informativeText = "Disabled (Laptop mode)"
    }):send()
  end
end

-- Watch for monitor changes
local screenWatcher = hs.screen.watcher.new(function()
  -- Small delay to let macOS settle after monitor connect/disconnect
  hs.timer.doAfter(0.5, checkMonitors)
end)
screenWatcher:start()

-- Watch for sleep/wake events
local caffeinateWatcher = hs.caffeinate.watcher.new(function(event)
  if event == hs.caffeinate.watcher.systemDidWake or
     event == hs.caffeinate.watcher.screensDidWake then
    -- Longer delay after wake to ensure displays are fully initialized
    hs.timer.doAfter(2.0, checkMonitors)
  end
end)
caffeinateWatcher:start()

-- Run on Hammerspoon startup
hs.timer.doAfter(1.0, checkMonitors)

-- Show notification when Hammerspoon config is loaded
hs.notify.new({
  title = "Hammerspoon",
  informativeText = "Config loaded successfully"
}):send()
