SLASH_SHARDCOUNTER1 = "/shardcounter"

local AFFLICTION = 265
local DESTRUCTION = 267

local addon = CreateFrame("Frame", "ShardCounter", UIParent)
local events = CreateFrame("Frame", "EventFrame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("UNIT_POWER")
events:RegisterEvent("PLAYER_TALENT_UPDATE")
--events:RegisterEvent("PLAYER_REGEN_DISABLED")
--events:RegisterEvent("PLAYER_REGEN_ENABLED")
local shards = {}

SlashCmdList["SHARDCOUNTER"] = function(cmd)
	if cmd=="unlock" then
		colorPrint("Right click to move - type '/shardcounter lock' when done")
		unlockFrame()
	elseif cmd=="lock" then
		lockFrame()
		colorPrint("ShardCounter locked")
	elseif cmd=="reset" then
		moveToCenter()
	else
		colorPrint("ShardCounter commands:")
		--print("/shardcounter always - Always show the frame")
		--print("/shardcounter combat - Show the frame only in combat")
		print("/shardcounter unlock - Unlocks the frame for repositioning")
		print("/shardcounter lock - Locks the frame")
		print("/shardcounter reset - Resets the position to center of screen")
		print("/shardcounter ? or /shardcounter help - Prints the command list")
	end
end

function eventHandler(self, event, unit, powerType, ...)
	if event == "UNIT_POWER" and unit == "player" and powerType == "SOUL_SHARDS" then
		update()
	-- elseif event == "PLAYER_REGEN_DISABLED" then
	-- 	addon:Show()
	-- elseif event == "PLAYER_REGEN_ENABLED" then
	-- 	addon:Hide()
	elseif event == "PLAYER_TALENT_UPDATE" then
		load()
	elseif event == "ADDON_LOADED" and unit == "ShardCounter" then
		if (addon) then
			load()
			colorPrint("ShardCounter loaded, for help type /shardcounter ?")
		else
			errorPrint("Unable to load ShardCounter!")
		end
		events:UnregisterEvent("ADDON_LOADED")
	end
end

function load()
	local spec = playerSpecialization()
	if (spec == AFFLICTION or spec == DESTRUCTION) then
		drawMainFrame()
		drawShards()
	end
end

function update()
	local available = UnitPower("player", powerType())
	for i, shard in ipairs(shards) do
		local alpha = 1.0
		if (tonumber(i) > available) then
			alpha = 0.15
		end
		shard:SetAlpha(alpha)
	end	
end

function drawMainFrame()
	local height = 35
	local width = height * maxPower()
	addon:SetHeight(height)
	addon:SetWidth(width)

	addon:SetPoint("CENTER", UIParent, "CENTER")
	addon:SetMovable(true)
	addon:SetScript("OnDragStart", addon.StartMoving)
	addon:SetScript("OnDragStop", addon.StopMovingOrSizing)
end

function drawShards()
	for i = 0, maxPower() - 1, 1 do
		local shard = shardTexture()
		shard:SetPoint("LEFT", shard:GetWidth() * i, 0)
		shards[i + 1] = shard
	end
	update()
end

function shardTexture()
	local size = addon:GetWidth() / 4
	local shard = addon:CreateTexture(nil, "ARTWORK")
	local icon = playerSpecialization() == AFFLICTION and "INV_Misc_Gem_Amethyst_02" or "ability_warlock_burningembers"
	shard:SetTexture("Interface\\ICONS\\" .. icon)
	shard:SetWidth(size)
	shard:SetHeight(size)
	return shard
end

function maxPower()
	return UnitPowerMax("player", powerType())
end

function powerType()
	local spec = playerSpecialization()
	if (spec == AFFLICTION) then
		return SPELL_POWER_SOUL_SHARDS
	elseif	(spec == DESTRUCTION) then
		return SPELL_POWER_BURNING_EMBERS
	else
		return nil
	end
end

function playerSpecialization()
	local spec = GetSpecialization()
	return spec and GetSpecializationInfo(spec) or nil
end

function colorPrint(msg)
	print("|cff9382C9"..msg)
end

function errorPrint(err)
	print("|cffFF0000"..err)
end

function unlockFrame()
	addon:Show()
	addon:EnableMouse(true)
	addon:RegisterForDrag("RightButton")
end

function lockFrame()
	addon:EnableMouse(false)
	--addon:Hide() --TODO check display out of combat setting
end

function moveToCenter()
	addon:SetPoint("CENTER")
end

events:SetScript("OnEvent", eventHandler)