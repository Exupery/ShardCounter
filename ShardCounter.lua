SLASH_SHARDCOUNTER1 = "/shardcounter"

local AFFLICTION = 265
local DEMONOLOGY = 266
local DESTRUCTION = 267

local SPELL_POWER_SOUL_SHARDS = 7

local shards = {}
local config = {}
local resizeButton = nil

local addon = CreateFrame("Frame", "ShardCounter", UIParent)
addon:SetClampedToScreen(true)
addon:SetMovable(true)

local events = CreateFrame("Frame", "ShardCounterEventFrame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("UNIT_POWER_UPDATE")

local function colorPrint(msg)
  print("|cff9382C9"..msg)
end

local function errorPrint(err)
  print("|cffFF0000"..err)
end

local function savedConfig()
  if not ShardCounterConfig then
    ShardCounterConfig = {
      ["combatOnly"] = true,
      ["height"] = 36,
    }
  end
  return ShardCounterConfig
end

local function showInCombatOnly()
  return config["combatOnly"]
end

local function unlockFrame()
  addon:Show()
  resizeButton:Show()
  addon:EnableMouse(true)
end

local function lockFrame()
  resizeButton:Hide()
  addon:EnableMouse(false)
  if showInCombatOnly() then
    addon:Hide()
  end
end

local function moveToCenter()
  addon:ClearAllPoints()
  addon:SetPoint("CENTER", UIParent, "CENTER")
end

local function playerSpecialization()
  local spec = GetSpecialization()
  return spec and GetSpecializationInfo(spec) or nil
end

local function maxPower()
  return UnitPowerMax("player", SPELL_POWER_SOUL_SHARDS)
end

local function stopMoving()
  addon:StopMovingOrSizing()
  local left, bottom = addon:GetRect()
  local _, _, parentWidth, parentHeight = addon:GetParent():GetRect()
  ShardCounterConfig["left"] = left / parentWidth
  ShardCounterConfig["bottom"] = bottom / parentHeight
  config = savedConfig()
end

local function resized(frame, width, height)
  local size = width / maxPower()
  for i, shard in ipairs(shards) do
    shard:SetWidth(size)
    shard:SetHeight(size)
    shard:SetPoint("LEFT", shard:GetWidth() * (i - 1), 0)
  end
  addon:SetWidth(width)
  addon:SetHeight(size)
  resizeButton:SetPoint("BOTTOMRIGHT")
  ShardCounterConfig["height"] = size
  config = savedConfig()
end

local function drawMainFrame()
  if addon:GetHeight() == 0 then
    local numPower = maxPower()
    local height = config["height"] or 36
    local width = height * numPower
    addon:SetHeight(height)
    addon:SetWidth(width)
    addon:SetResizable(true)
    addon:SetMinResize(12 * numPower, 12)
    addon:SetMaxResize(64 * numPower, 64)
    addon:SetScript("OnSizeChanged", resized)

    resizeButton = CreateFrame("Button", "ShardCounterResizeFrame", addon)
    resizeButton:SetSize(16, 16)
    resizeButton:SetPoint("BOTTOMRIGHT")
    resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeButton:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    resizeButton:Hide()

    resizeButton:SetScript("OnMouseDown", function()
      addon:StartSizing("BOTTOMRIGHT")
    end)
    resizeButton:SetScript("OnMouseUp", function()
      addon:StopMovingOrSizing()
    end)

    addon:RegisterForDrag("LeftButton", "RightButton")
    addon:SetScript("OnDragStart", addon.StartMoving)
    addon:SetScript("OnDragStop", stopMoving)

    local left = config["left"] or 0
    local bottom = config["bottom"] or 0
    local _, _, parentWidth, parentHeight = addon:GetParent():GetRect()
    local xOffset = parentWidth * left
    local yOffset = parentHeight * bottom
  end

  if showInCombatOnly() then
    addon:Hide()
  else
    addon:Show()
  end
end

local function update()
  local available = UnitPower("player", SPELL_POWER_SOUL_SHARDS)
  for i, shard in ipairs(shards) do
    local alpha = tonumber(i) > available and 0.15 or 1.0
    shard:SetAlpha(alpha)
  end
end

local function getIcon()
  return "Interface\\ICONS\\INV_Misc_Gem_Amethyst_02"
end

local function shardTexture()
  local size = addon:GetWidth() / maxPower()
  local shard = addon:CreateTexture(nil, "ARTWORK")
  shard:SetTexture(getIcon())
  shard:SetWidth(size)
  shard:SetHeight(size)
  return shard
end

local function drawShards()
  if next(shards) == nil then
    for i = 0, maxPower() - 1, 1 do
      local shard = shardTexture()
      shard:SetPoint("LEFT", shard:GetWidth() * i, 0)
      shards[i + 1] = shard
    end
  else
    local icon = getIcon()
    for i, shard in ipairs(shards) do
      shard:SetTexture(icon)
    end
  end
  update()
end

local function toggleCombatOnly(combatOnly)
  ShardCounterConfig["combatOnly"] = combatOnly
  config = savedConfig()
  if combatOnly then
    addon:Hide()
  else
    addon:Show()
  end
end

local function load()
  local spec = playerSpecialization()
  if spec == AFFLICTION or spec == DESTRUCTION or spec == DEMONOLOGY then
    drawMainFrame()
    drawShards()
    events:RegisterEvent("PLAYER_REGEN_DISABLED")
    events:RegisterEvent("PLAYER_REGEN_ENABLED")
  else
    addon:Hide()
  end
end

local function eventHandler(self, event, unit, powerType, ...)
  if event == "UNIT_POWER_UPDATE" and unit == "player" then
    update()
  elseif event == "PLAYER_REGEN_DISABLED" and showInCombatOnly() then
    addon:Show()
  elseif event == "PLAYER_REGEN_ENABLED" and showInCombatOnly() then
    addon:Hide()
  elseif event == "PLAYER_TALENT_UPDATE" or event == "ACTIVE_TALENT_GROUP_CHANGED" then
    load()
  elseif event == "ADDON_LOADED" and unit == "ShardCounter" then
    if (addon) then
      config = savedConfig()
      load()
    else
      errorPrint("Unable to load ShardCounter!")
    end
    events:UnregisterEvent("ADDON_LOADED")
    events:RegisterEvent("PLAYER_TALENT_UPDATE")
    events:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
  end
end

SlashCmdList["SHARDCOUNTER"] = function(cmd)
  if cmd == "unlock" then
    colorPrint("Click to move, use lower-right corner to resize - type '/shardcounter lock' when done")
    unlockFrame()
  elseif cmd == "lock" then
    lockFrame()
    colorPrint("ShardCounter locked")
  elseif cmd == "center" then
    moveToCenter()
  elseif cmd == "always" then
    toggleCombatOnly(false)
  elseif cmd == "combat" then
    toggleCombatOnly(true)
  else
    colorPrint("ShardCounter commands:")
    print("/shardcounter always - Always show the frame")
    print("/shardcounter combat - Show the frame only in combat")
    print("/shardcounter unlock - Unlocks the frame for repositioning and resizing")
    print("/shardcounter lock - Locks the frame")
    print("/shardcounter center - Sets the position to center of screen")
    print("/shardcounter ? or /shardcounter help - Prints the command list")
  end
end

events:SetScript("OnEvent", eventHandler)
