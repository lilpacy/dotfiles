-- AeroSpace auto-enable based on external monitor connection
-- When external monitor is connected: AeroSpace ON (tiling enabled)
-- When only built-in display: AeroSpace OFF (normal macOS window management)

local AEROSPACE = "/opt/homebrew/bin/aerospace"

local function checkMonitors()
  local screens = hs.screen.allScreens()
  local monitorCount = #screens

  if monitorCount > 1 then
    -- External monitor connected → Enable AeroSpace
    hs.execute(AEROSPACE .. " enable on", true)
    hs.notify.new({
      title = "AeroSpace",
      informativeText = "Enabled (External monitor detected)"
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

-- Run on Hammerspoon startup
hs.timer.doAfter(1.0, checkMonitors)

-- Show notification when Hammerspoon config is loaded
hs.notify.new({
  title = "Hammerspoon",
  informativeText = "Config loaded successfully"
}):send()
