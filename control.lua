require("mod-gui")

local tickRate = settings.global["production-monitor-update-seconds"].value * 60
local perMinute = 3600 / tickRate
local noValue = "-"
local displayUoM = "/m"
local minValue = .01
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
		tickRate = settings.global["production-monitor-update-seconds"].value * 60
		for k, force in pairs(game.forces) do
			updateStats (force)
		end
	end
end)

script.on_configuration_changed(function(data)
   if data.mod_changes ~= nil and data.mod_changes["production-monitor"] ~= nil then  		
     	for k, force in pairs(game.forces) do
			updateStats (force, true)
			for _, player in pairs(force.players) do
				local showProduction = player.mod_settings["production-monitor-show-production"].value
				local showConsumption = player.mod_settings["production-monitor-show-consumption"].value

				local itemFlowTop = player.gui.top.stats_item_flow
				local itemFlowLeft = player.gui.left.stats_item_flow
				
				if (itemFlowTop) then
					itemFlowTop.destroy()
				end

				if (itemFlowLeft) then
					itemFlowLeft.destroy()
				end				
			end
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
	return getIndex(items, itemToFind)
end

function getFluidIndex (player, fluidToFind)
	local fluids = global.stats.playerPrefs[player.name].fluids
	return getIndex(fluids, fluidToFind)
end

function getIndex (list, target)
	for i, name in ipairs(list) do
    	if (name == target) then
			return i
		end
	end
	return 1
end

function addItem (player, itemToAdd, index)
	addMonitor(global.stats.playerPrefs[player.name].items, itemToAdd, index)
end

function addFluid (player, fluidToAdd, index)
	addMonitor(global.stats.playerPrefs[player.name].fluids, fluidToAdd, index)
end

function addMonitor (list, target, index)
	local size = 1
	for i, name in ipairs(list) do
    	if (name == target) then
			return
		end
		size = size + 1
	end
	if (index) then
		index = math.max( 1,index)
		index = math.min(size,index)
		--debugPrint(index)
		table.insert(list, index, target)
	else
		table.insert(list, target)
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

function updateStats (force, statsOnly)
	local currentItemCount = force.item_production_statistics.input_counts
	local currentFluidCount = force.fluid_production_statistics.input_counts

	local currentItemCountConsumed = force.item_production_statistics.output_counts
	local currentFluidCountConsumed = force.fluid_production_statistics.output_counts

	local stats = {}
	stats.items =currentItemCount
	stats.fluids = currentFluidCount
	stats.itemsConsumed = currentItemCountConsumed
	stats.fluidsConsumed = currentFluidCountConsumed

	local forceName = force.name
	if (global.stats == nil) then
		global.stats = {}
	end

	if (global.stats.playerPrefs == nil) then
		global.stats.playerPrefs = {}
	end

	if (global.stats[forceName] == nil) then
		global.stats[forceName] = stats
	end
	
	if not statsOnly then
		updateDisplayForce (force, stats)
	end

	global.stats[forceName].items = currentItemCount
	global.stats[forceName].fluids = currentFluidCount
	
	global.stats[forceName].itemsConsumed = currentItemCountConsumed
	global.stats[forceName].fluidsConsumed = currentFluidCountConsumed
end

function updateDisplayForce (force, stats)
	for _, player in pairs(force.players) do
		if (player.valid and player.connected) then
			updateDisplayPlayer(player, force.name, stats)
		end
	end
end

function updateDisplayPlayer (player, forceName, stats)
	if (not stats) then 
		stats = {}
		stats.items = global.stats[forceName].items
		stats.fluids = global.stats[forceName].fluids
		stats.itemsConsumed = global.stats[forceName].itemsConsumed
		stats.fluidsConsumed = global.stats[forceName].fluidsConsumed
	end

	local player_settings = global.stats.playerPrefs[player.name]	
	if not player_settings then
		addPlayer(player)
		player_settings = global.stats.playerPrefs[player.name]
	end

	local empty = true

	for _, itemName in pairs (player_settings.items) do
		local rate = 			calcRate(stats.items[itemName], global.stats[forceName].items[itemName])
		local rateConsumed =  	calcRate(stats.itemsConsumed[itemName], global.stats[forceName].itemsConsumed[itemName])
		addUpdateDisplay(itemName, player, rate, rateConsumed)
		empty = false
	end

	for _, fluidName in pairs (player_settings.fluids) do
		local rate = 			calcRate(stats.fluids[fluidName], global.stats[forceName].fluids[fluidName])
		local rateConsumed =  	calcRate(stats.fluidsConsumed[fluidName], global.stats[forceName].fluidsConsumed[fluidName])
		addUpdateDisplay(fluidName, player, rate, rateConsumed)
		empty = false
	end

	if (empty) then
		local showProduction = player.mod_settings["production-monitor-show-production"].value
		local showConsumption = player.mod_settings["production-monitor-show-consumption"].value
		minDisplay(player, showProduction, showConsumption)
	end
end

function calcRate (new, old)
	if old then
		return (new - old) * perMinute
	end
	return noValue
end

function getAttachLocation (player)
	local location = "left"
	if (player.mod_settings["production-monitor-top"].value) then
		location = "top"
	end
	return location
end

function getButtonStyle (large)
	local style = "small_slot_button_style"
	if large then
		style = "slot_button_style"
	end
	return style
end

function getLabelStyle (large)
	local style = "bold_label_style"
	if (large) then
		style = "bold_label_style_large"
	end
	return style
end

function getTableStyle (large)
	local style = "stats_table_style"
	if (large) then
		style = "stats_table_style_large"
	end
	return style
end

function minDisplay (player, showProduction, showConsumption)
	local large = player.mod_settings["production-monitor-large"].value

	local attachLocation = getAttachLocation(player)
	local buttonStyle = getButtonStyle(large)
	local labelStyle = getLabelStyle(large)
	local tableStyle = getTableStyle(large)

	local fieldCount = 1
	if player.mod_settings["production-monitor-show-production"].value then
		fieldCount = fieldCount + 1
	end
	if player.mod_settings["production-monitor-show-consumption"].value then
		fieldCount = fieldCount + 1
	end
	local playerColspan =  player.mod_settings["production-monitor-columns"].value * fieldCount
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
		local item_table = item_flow.add{type = "table", colspan = playerColspan, name = "stats_item_table", style=tableStyle}

		item_table.add{type = "sprite-button", name = "stats_show_settings", tooltip={"stats_show_settings_tip"}, 
			sprite=settingsIcon, style = buttonStyle}
		if showProduction then
			item_table.add{type = "label", name = "stats_item_label_settings_created", caption = "+"..displayUoM, 
				style= labelStyle, tooltip={"stats_created"} }
		end
		if showConsumption then
			item_table.add{type = "label", name = "stats_item_label_settings_consumed", caption = "-"..displayUoM, 
				style= labelStyle, tooltip={"stats_consumed"} }
		end
	end	
end

function addUpdateDisplay(itemName, player, rate, rateConsumed)

	local showProduction = player.mod_settings["production-monitor-show-production"].value
	local showConsumption = player.mod_settings["production-monitor-show-consumption"].value
	local precision = player.mod_settings["production-monitor-precision"].value

	minDisplay(player, showProduction, showConsumption)

	local sprite
	local btnName
	local localised_name = {itemName}
	local attachLocation = getAttachLocation(player)

	local large = player.mod_settings["production-monitor-large"].value
	local buttonStyle = getButtonStyle(large)
	local labelStyle = getLabelStyle(large)

	if game.item_prototypes[itemName] then
		sprite = "item/"..itemName
		localised_name = game.item_prototypes[itemName].localised_name
		btnName = "stats_item_button_".. itemName
	elseif game.fluid_prototypes[itemName] then		
		sprite = "fluid/"..itemName
		localised_name = game.fluid_prototypes[itemName].localised_name
		btnName = "stats_fluid_button_".. itemName
	end

	local table = player.gui[attachLocation].stats_item_flow.stats_item_table	
	if btnName and not table[btnName] then
		table.add{type = "sprite-button", name = btnName, tooltip=localised_name, sprite = sprite, style = buttonStyle}

		if (showProduction) then
			local labelName = "stats_item_label_created_" .. itemName
			if not table[labelName] then
				table.add{type = "label", name = labelName,  tooltip=localised_name, caption = rate, style=labelStyle}
			end
		end

		if (showConsumption) then
			local labelName = "stats_item_label_consumed_" .. itemName
			if not table[labelName] then
				table.add{type = "label", name = labelName,  tooltip=localised_name, caption = rateConsumed, style=labelStyle}
			end
		end


	else
		if (sprite == nil) then

			if btnName and table[btnName] then
				table[btnName].destroy()
			else
				btnName = "stats_item_button_".. itemName
				if table[btnName] then
					table[btnName].destroy()
				end

				btnName = "stats_fluid_button_".. itemName
				if table[btnName] then
					table[btnName].destroy()
				end
			end

			local labelName = "stats_item_label_created_" .. itemName
			if table[labelName] then
				table[labelName].destroy()
			end

			labelName = "stats_item_label_consumed_" .. itemName
			if table[labelName] then
				table[labelName].destroy()
			end

			removeItem(player, itemName)
			removeFluid(player, itemName)
		else
			if (showProduction) then
				updateDisplayLabel(table["stats_item_label_created_" .. itemName], rate, precision)
			end

			if (showConsumption) then
				updateDisplayLabel(table["stats_item_label_consumed_" .. itemName], rateConsumed, precision)
			end
			
		end
	end
end

function updateDisplayLabel (label, value, precision)
	if label then
		local currentCaption = label.caption
		if (currentCaption ~= noValue and currentCaption:sub(1) ~= displayUoM) then
			local rawCaption = tonumber( removeComma(currentCaption) )
			local smoothValue =  (rawCaption + value) / 2 
			if (smoothValue > minValue) then
				if (smoothValue > rawCaption) then
					label.style.font_color = upTrend
				elseif (smoothValue < rawCaption) then
					label.style.font_color = downTrend
				else
					label.style.font_color = flatTrend
				end
					label.caption = fmtNumber( round(smoothValue, precision) )
			else
				label.caption = 0
			end
		else
			label.caption = fmtNumber(value)
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
			local index = getFluidIndex(player, name)
			removeFluid(player, name)
			if (button == defines.mouse_button_type.left) then
				-- to the top
				addFluid (player, name, index-1)
			elseif (button == defines.mouse_button_type.right) then
				-- to the bottom
				addFluid (player, name, index+1)
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
	if not amount then
		return
	end
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
