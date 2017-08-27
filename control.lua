require("mod-gui")

local tickRate = settings.global["production-monitor-update-seconds"].value * 60
local perMinute = 3600 / tickRate
local noValue = "-"
local displayUoM = "/m"
local minValue = .01
local precision = 2
local settingsIcon = "add"
local downTrend = {r=1, g=.8, b=.8}
local upTrend = {r=.8, g=1, b=.8}
local flatTrend = {r=1, g=1, b=1}

script.on_init(function(event)
	global.stats = {}
	global.stats.playerPrefs = {}
end)

script.on_event(defines.events.on_tick, function(event)
	if (game.tick % tickRate == 0) then
		for k, force in pairs(game.forces) do
			updateStats (force)
		end
	end
end)

function addPlayer(player)	
	global.stats.playerPrefs[player.name] = {}
	
	local defaultItems = {
		"science-pack-1",
		"science-pack-2",
		"science-pack-3",
		"military-science-pack",
		"production-science-pack",
		"high-tech-science-pack",
		"space-science-pack",
		}

	if (game.active_mods["bobtech"]) then
		table.insert(defaultItems, 4, "logistic-science-pack")
	end
		
	global.stats.playerPrefs[player.name].items = defaultItems

	local defaultFluids = {
		"crude-oil",
		"petroleum-gas",
		}

	if (game.active_mods["angelspetrochem"]) then
		table.insert(defaultFluids, "liquid-multi-phase-oil")
	end

	global.stats.playerPrefs[player.name].fluids = defaultFluids

end

function removeItem (player, itemToRemove)
	local items = global.stats.playerPrefs[player.name].items
	for i, name in ipairs(items) do
    	if (name == itemToRemove) then
			-- debugPrint("Stats Removed: " .. name)
			table.remove(items, i)
			break
		end
	end
end

function removeFluid (player, fluidToRemove)
	local fluids = global.stats.playerPrefs[player.name].fluids
	for i, name in ipairs(fluids) do
    	if (name == fluidToRemove) then
			-- debugPrint("Stats Removed: " .. name)
			table.remove(fluids, i)
			break
		end
	end
end

function getItemIndex (player, itemToFind)
	local items = global.stats.playerPrefs[player.name].items
	for i, name in ipairs(items) do
    	if (name == itemToFind) then
			return i
		end
	end
end

function addItem (player, itemToAdd, index)
	local items = global.stats.playerPrefs[player.name].items
	local size = 1
	for i, name in ipairs(items) do
    	if (name == itemToAdd) then
			return
		end
		size = size + 1
	end
	if (index) then
		index = math.max( 1,index)
		index = math.min(size,index)
		--debugPrint(index)
		table.insert(items, index, itemToAdd)
	else
		table.insert(items, itemToAdd)
	end
end


function replaceItem (player, itemToAdd, existingItem)
	local items = global.stats.playerPrefs[player.name].items
	for i, name in ipairs(items) do
    	if (name == itemToAdd) then
			return
		end
	end
	for i, name in ipairs(items) do
    	if (name == existingItem) then
			table.remove(items, i)
			table.insert(items, i, itemToAdd)
		end
	end
end

function addFluid (player, fluidToAdd, addToStart)
	local fluids = global.stats.playerPrefs[player.name].fluids
	for i, name in ipairs(fluids) do
    	if (name == fluidToAdd) then
			return
		end
	end
	if (addToStart) then
		table.insert(fluids, 1, fluidToAdd)
	else
		table.insert(fluids, fluidToAdd)
	end
end

function updateStats (force)
	local currentItemCount = force.item_production_statistics.input_counts
	local currentFluidCount = force.fluid_production_statistics.input_counts
	local forceName = force.name
	if (global.stats == nil) then
		global.stats = {}
	end

	if (global.stats.playerPrefs == nil) then
		global.stats.playerPrefs = {}
	end

	if (global.stats[forceName] == nil) then
		global.stats[forceName] = {}
	end
	
	updateDisplayForce (force, currentItemCount, currentFluidCount)

	global.stats[forceName].items = currentItemCount
	global.stats[forceName].fluids = currentFluidCount
end

function updateDisplayForce (force, currentItemCount, currentFluidCount)
	if (global.stats ~= nil and global.stats[force.name] ~= nil) then
		for _, player in pairs(force.players) do
			updateDisplayPlayer(player, force.name, currentItemCount, currentFluidCount)
		end
	end
end

function updateDisplayPlayer (player, forceName, currentItemCount, currentFluidCount)
	local player_settings = global.stats.playerPrefs[player.name]
	if (not currentItemCount) then 
		currentItemCount = global.stats[forceName].items
	end

	if (not currentFluidCount) then
		currentFluidCount = global.stats[forceName].fluids
	end
	
	if not player_settings then
		addPlayer(player)
		player_settings = global.stats.playerPrefs[player.name]
	end

	local empty = true

	for _, item in pairs (player_settings.items) do
		loadItem(forceName, item, currentItemCount, player)
		empty = false
	end

	for _, fluid in pairs (player_settings.fluids) do
		loadFluid(forceName, fluid, currentFluidCount, player)
		empty = false
	end

	if (empty) then
		minDisplay(player)
	end
end

function loadItem (forceName, itemName, current, player)
	if (global.stats[forceName].items ~= nil and global.stats[forceName].items[itemName] ~= nil and current[itemName] ~= nil) then
		local rate = (current[itemName] - global.stats[forceName].items[itemName]) * perMinute
		addUpdateDisplay(itemName, player, rate)
	else
		addUpdateDisplay(itemName, player, noValue)
	end
end

function loadFluid (forceName, fluidName, current, player)
	if (global.stats[forceName].fluids ~= nil and global.stats[forceName].fluids[fluidName] ~= nil and current[fluidName] ~= nil) then
		local rate = (current[fluidName] - global.stats[forceName].fluids[fluidName]) * perMinute
		addUpdateDisplay(fluidName, player, rate)
	else
		addUpdateDisplay(fluidName, player, noValue)
	end
end

function getAttachLocation (player)
	local location = "left"
	if (player.mod_settings["production-monitor-top"].value) then
		location = "top"
	end
	return location
end

function getButtonStyle (player)
	local style = "small_slot_button_style"
	if (player.mod_settings["production-monitor-large"].value) then
		style = "slot_button_style"
	end
	return style
end

function getLabelStyle (player)
	local style = "bold_label_style"
	if (player.mod_settings["production-monitor-large"].value) then
		style = "bold_label_style_large"
	end
	return style
end

function minDisplay (player)
	
	local attachLocation = getAttachLocation(player)
	local buttonStyle = getButtonStyle(player)
	local labelStyle = getLabelStyle(player)

	local playerColspan = player.mod_settings["production-monitor-columns"].value * 2
	local itemFlowTop = player.gui.top.stats_item_flow
	local itemFlowLeft = player.gui.left.stats_item_flow
	local item_flow

	if (attachLocation == "left") then
		item_flow = itemFlowLeft
		if (itemFlowTop) then
			itemFlowTop.destroy()
		end
	else
		item_flow = itemFlowTop
		if (itemFlowLeft) then
			itemFlowLeft.destroy()
		end
	end

	if not item_flow then
		item_flow = player.gui[attachLocation].add{type = "scroll-pane", name = "stats_item_flow"}
		local item_table = item_flow.add{type = "table", colspan = playerColspan, name = "stats_item_table"}

		item_table.add{type = "sprite-button", name = "stats_show_settings", tooltip={"stats_show_settings_tip"}, 
			sprite=settingsIcon, style = buttonStyle}
		item_table.add{type = "label", name = "stats_item_label_settings", caption = displayUoM, style= labelStyle }
	end	
end

function addUpdateDisplay(itemName, player, rate)
	minDisplay(player)
	
	local sprite
	local btnName = "stats_item_button_".. itemName
	local localised_name = {itemName}
	local attachLocation = getAttachLocation(player)
	local buttonStyle = getButtonStyle(player)
	local labelStyle = getLabelStyle(player)

	if game.item_prototypes[itemName] then
		sprite = "item/"..itemName
		localised_name = game.item_prototypes[itemName].localised_name
	elseif game.fluid_prototypes[itemName] then		
		sprite = "fluid/"..itemName
		localised_name = game.fluid_prototypes[itemName].localised_name
		btnName = "stats_fluid_button_".. itemName
	end

	local table = player.gui[attachLocation].stats_item_flow.stats_item_table	
	if not table[btnName] then
		table.add{type = "sprite-button", name = btnName, tooltip=localised_name, sprite = sprite, style = buttonStyle}
		table.add{type = "label", name = "stats_item_label_" .. itemName,  tooltip=localised_name, caption = rate, style=labelStyle}
	else
		local currentRowLabel = table["stats_item_label_" .. itemName]
		local currentCaption = currentRowLabel.caption
		if (sprite == nil) then
			table[btnName].destroy()
			currentRowLabel.destroy()
			removeItem(player, itemName)
			removeFluid(player, itemName)
		else	
			if (currentCaption ~= noValue and currentCaption ~= displayUoM) then
				local rawCaption = tonumber( removeComma(currentCaption) )
				local smoothValue =  (rawCaption + rate) / 2 
				if (smoothValue > minValue) then
					if (smoothValue > rawCaption) then
						currentRowLabel.style.font_color = upTrend
					elseif (smoothValue < rawCaption) then
						currentRowLabel.style.font_color = downTrend
					else
						currentRowLabel.style.font_color = flatTrend
					end
						currentRowLabel.caption = fmtNumber( round(smoothValue, precision) )
				else
					currentRowLabel.caption = 0
				end
			else
				currentRowLabel.caption = fmtNumber(rate)
			end
		end
	end
end

script.on_event(defines.events.on_gui_click, function(event)
	local player = game.players[event.player_index]

	local attachLocation = getAttachLocation(player)
	local flow = player.gui[attachLocation].stats_item_flow
	if (not flow) then
		updateDisplayPlayer(player, player.force.name)
	end
	local center = player.gui.center.stats_center_frame
	local button = event.button
	if event.element.valid then 
		if event.element.name == "stats_show_settings" then
			if player.cursor_stack.valid_for_read then
				addItem(player, player.cursor_stack.name)
				flow.destroy()
				updateDisplayPlayer(player, player.force.name)
			else
				if (not center) then
					center = player.gui.center.add{type = "frame", name = "stats_center_frame", direction = "vertical"}
				end
				if center.fluids_table then center.destroy()
				else
					local fluids_table = center.add{type = "table", colspan = 12, name = "fluids_table", style = "slot_table_style"}
					for _, fluid in pairs(game.fluid_prototypes) do
						fluids_table.add{type = "sprite-button", name = "stats_fluid_selector_" .. fluid.name, sprite = "fluid/"..fluid.name, style = "slot_button_style", tooltip = fluid.localised_name}
					end
				end
			end
		elseif event.element.name:find("stats_fluid_selector_") then
			addFluid (player, event.element.name:sub(22))
			center.destroy()
			flow.destroy()
			updateDisplayPlayer(player, player.force.name)
		elseif event.element.name:find("stats_fluid_button_") then
			local name = event.element.name:sub(20)
			-- middle click removes
			removeFluid(player, name)
			if (button == defines.mouse_button_type.left) then
				-- to the top
				addFluid (player, name, true)
			elseif (button == defines.mouse_button_type.right) then
				-- to the bottom
				addFluid (player, name)
			end
			flow.destroy()
			updateDisplayPlayer(player, player.force.name)
		elseif event.element.name:find("stats_item_button_") then
			local name = event.element.name:sub(19)
			-- middle click removes
			if player.cursor_stack.valid_for_read then
				replaceItem(player, player.cursor_stack.name, name)
			else
				local index = getItemIndex(player, name)
				removeItem(player, name)
				if (button == defines.mouse_button_type.left) then
					-- to the top
					addItem (player, name, index-1)
				elseif (button == defines.mouse_button_type.right) then
					-- to the bottom
					addItem (player, name, index+1)
				end
			end

			flow.destroy()
			updateDisplayPlayer(player, player.force.name)
		end
	end
end)

function debugPrint(thing)
	for _, player in pairs(game.players) do
		player.print(serpent.block(thing))
	end
end


function fmtNumber(amount)
  local formatted = amount
  while true do  
    formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
    if (k==0) then
      break
    end
  end
  return formatted
end

function round(val, decimal)
  if (decimal) then
    return math.floor( (val * 10^decimal) + 0.5) / (10^decimal)
  else
    return math.floor(val+0.5)
  end
end

function removeComma(amount)
  local formatted = amount
  while true do  
    formatted, k = string.gsub(formatted, ",", "")
    if (k==0) then
      break
    end
  end
  return formatted
end
