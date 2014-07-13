SLASH_SHARDCOUNTER1 = "/shardcounter"

local addon = CreateFrame("Frame", "ShardCounter", UIParent)
local events = CreateFrame("Frame", "EventFrame")
events:RegisterEvent("ADDON_LOADED")

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

function eventHandler(self, event, unit, ...)
	if event == "TODO" then
		--TODO on shard count change
	elseif event == "ADDON_LOADED" and unit == "ShardCounter" then
		onLoad()
		events:UnregisterEvent("ADDON_LOADED")
	end
end

function onLoad()
	if (addon) then
		drawMainFrame()
		colorPrint("ShardCounter loaded, for help type /shardcounter ?")
	else
		errorPrint("Unable to load ShardCounter!")
	end
end

function drawMainFrame()
	local width = 100
	local height = 25
	addon:SetWidth(width)
	addon:SetHeight(height)

	addon:SetPoint("CENTER", UIParent, "CENTER")
	addon:SetMovable(true)
	addon:SetScript("OnDragStart", addon.StartMoving)
	addon:SetScript("OnDragStop", addon.StopMovingOrSizing)

	local bg = addon:CreateTexture("BACKGROUND", "ARTWORK")
	bg:SetTexture(0.58, 0.5, 0.79, 0.25)
	bg:SetWidth(width)
	bg:SetHeight(height)
	bg:SetPoint("CENTER", addon, "CENTER")
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