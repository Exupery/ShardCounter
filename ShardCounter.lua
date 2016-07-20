SLASH_SHARDCOUNTER1 = "/shardcounter"

local AFFLICTION = 265
local DEMONOLOGY = 266
local DESTRUCTION = 267

local shards = {}
local config = {}

local addon = CreateFrame("Frame", "ShardCounter", UIParent)
addon:SetClampedToScreen(true)
addon:SetMovable(true)

local events = CreateFrame("Frame", "EventFrame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("UNIT_POWER")

local function colorPrint(msg)
	print("|cff9382C9"..msg)
end

local function errorPrint(err)
	print("|cffFF0000"..err)
end

local function showInCombatOnly()
	return config["combatOnly"]
end

local function unlockFrame()
	addon:Show()
	addon:EnableMouse(true)
end

local function lockFrame()
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

local function drawMainFrame()
	if addon:GetHeight() == 0 then
		local height = 35
		local width = height * maxPower()
		addon:SetHeight(height)
		addon:SetWidth(width)

		addon:RegisterForDrag("LeftButton", "RightButton")
		addon:SetScript("OnDragStart", addon.StartMoving)
		addon:SetScript("OnDragStop", addon.StopMovingOrSizing)

		if addon:GetPoint(1) == nil then
			addon:SetPoint("TOP", UIParent, "TOP")
		end
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
	local size = addon:GetWidth() / 4
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

local function savedConfig()
	if not ShardCounterConfig then
		ShardCounterConfig = {["combatOnly"] = true}
	end
	return ShardCounterConfig
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
	if event == "UNIT_POWER" and unit == "player" and (powerType == "SOUL_SHARDS" or powerType == "BURNING_EMBERS") then
		update()
	elseif event == "PLAYER_REGEN_DISABLED" and showInCombatOnly() then
		addon:Show()
	elseif event == "PLAYER_REGEN_ENABLED" and showInCombatOnly() then
		addon:Hide()
	elseif event == "PLAYER_TALENT_UPDATE" or event == "ACTIVE_TALENT_GROUP_CHANGED" then
		load()
	elseif event == "ADDON_LOADED" and unit == "ShardCounter" then
		if (addon) then
			load()
			config = savedConfig()
			colorPrint("ShardCounter loaded, for help type /shardcounter ?")
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
		colorPrint("Click to move - type '/shardcounter lock' when done")
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
		print("/shardcounter unlock - Unlocks the frame for repositioning")
		print("/shardcounter lock - Locks the frame")
		print("/shardcounter center - Sets the position to center of screen")
		print("/shardcounter ? or /shardcounter help - Prints the command list")
	end
end

events:SetScript("OnEvent", eventHandler)
