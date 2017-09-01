require("mod-gui")

local tickRate = settings.global["production-monitor-update-seconds"].value * 60
local perMinute = 3600 / tickRate
local zero = .01
local noValue = "-"
local displayUoM = "/m"
local settingsIcon = "add"
local downTrend = {r=1, g=.8, b=.8}
local upTrend = {r=.8, g=1, b=.8}
local flatTrend = {r=1, g=1, b=1}
local warning = {r=.7, g=.7, b=0}
local redLight = {r=1, g=.2, b=.2}

script.on_init(function(event)
	global.stats = {}
	global.stats.playerPrefs = {}
end)

script.on_event(defines.events.on_tick, function(event)
	if (game.tick % tickRate == 0) then
		local checkTickRate = settings.global["production-monitor-update-seconds"].value * 60
		if checkTickRate ~= tickRate then
			tickRate = checkTickRate
			perMinute = 3600 / tickRate
		end

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

function strSplit(inputstr, sep)
        if sep == nil then
                sep = "%s"
        end
        local t={} ; i=1
        for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
                t[i] = trim(str)
                i = i + 1
        end
        return t
end

function trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function addPlayer(player)	
	global.stats.playerPrefs[player.name] = {}

	local playerItems = player.mod_settings["production-monitor-default-items"].value
	local defaultItems = strSplit(playerItems, ",")		
	global.stats.playerPrefs[player.name].items = defaultItems


	local playerFluids = player.mod_settings["production-monitor-default-fluids"].value
	local defaultFluids = strSplit(playerFluids, ",")
	global.stats.playerPrefs[player.name].fluids = defaultFluids

	global.stats.playerPrefs[player.name].itemStats = {}
	global.stats.playerPrefs[player.name].fluidStats = {}
	global.stats.playerPrefs[player.name].hide = false
end

function removeItem (player, itemToRemove)
	local items = global.stats.playerPrefs[player.name].items
	for i, name in ipairs(items) do
    	if (name == itemToRemove) then
			table.remove(items, i)
			break
		end
	end
end

function removeFluid (player, fluidToRemove)
	local fluids = global.stats.playerPrefs[player.name].fluids
	for i, name in ipairs(fluids) do
    	if (name == fluidToRemove) then
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
		index = math.max(1, index)
		index = math.min(size, index)
		table.insert(list, index, target)
	else
		table.insert(list, target)
	end
end

function replaceItem (player, itemToAdd, existingItem)
	local items = global.stats.playerPrefs[player.name].items
	for i, name in ipairs(items) do
    	if (name == itemToAdd) then
			table.remove(items, i)
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
			updateDisplayPlayer(player, force.name, stats, playerModSettings(player))
		end
	end
end

function playerModSettings (player)
	local mod_settings = {}
	
	mod_settings.modifier								= player.mod_settings["production-monitor-modifier"].value
	mod_settings["production-monitor-show-production"] 	= player.mod_settings["production-monitor-show-production"].value
	mod_settings["production-monitor-show-consumption"] = player.mod_settings["production-monitor-show-consumption"].value
	mod_settings["production-monitor-show-difference"] 	= player.mod_settings["production-monitor-show-difference"].value
	mod_settings["production-monitor-show-ratio"] 		= player.mod_settings["production-monitor-show-ratio"].value
	
	mod_settings["production-monitor-large"] 			= player.mod_settings["production-monitor-large"].value
	mod_settings["production-monitor-top"] 				= player.mod_settings["production-monitor-top"].value
	mod_settings["production-monitor-precision"] 		= player.mod_settings["production-monitor-precision"].value
	mod_settings["production-monitor-columns"] 			= player.mod_settings["production-monitor-columns"].value

	

	mod_settings.fieldCount = 1
	local tableString = "stats_item_table_"
	if mod_settings["production-monitor-show-production"] then
		mod_settings.fieldCount = mod_settings.fieldCount + 1
		tableString = tableString .. "p"
	end
	if mod_settings["production-monitor-show-consumption"] then
		mod_settings.fieldCount = mod_settings.fieldCount + 1
		tableString = tableString .. "c"
	end
	if mod_settings["production-monitor-show-difference"] then
		mod_settings.fieldCount = mod_settings.fieldCount + 1
		tableString = tableString .. "d"
	end
	if mod_settings["production-monitor-show-ratio"] then
		mod_settings.fieldCount = mod_settings.fieldCount + 1
		tableString = tableString .. "r"
	end

	if mod_settings["production-monitor-large"] then
		tableString = tableString .. "_large_"
	else
		tableString = tableString .. "_small_"
	end

	mod_settings.playerColspan = mod_settings["production-monitor-columns"] * mod_settings.fieldCount

	mod_settings.tableId = tableString .. mod_settings.playerColspan

	return mod_settings
end

function updateDisplayPlayer (player, forceName, stats, mod_settings)
	local wasReset = false

	if (not stats) then 
		wasReset = true
	end

	local player_settings = global.stats.playerPrefs[player.name]	
	if not player_settings then
		addPlayer(player)
		player_settings = global.stats.playerPrefs[player.name]
	end
	local isHidden = global.stats.playerPrefs[player.name].hide

	if not player_settings.itemStats then
		player_settings.itemStats = {}
	end

	if not player_settings.itemStatsPrev then
		player_settings.itemStatsPrev = {}
	end

	if not player_settings.fluidStats then
		player_settings.fluidStats = {}
	end

	if not player_settings.fluidStatsPrev then
		player_settings.fluidStatsPrev = {}
	end

	local empty = true

	for _, itemName in pairs (player_settings.items) do
		if not wasReset then
			local calc = {}
			calc.rate = 			calcRate(stats.items[itemName], global.stats[forceName].items[itemName])
			calc.rateConsumed =  	calcRate(stats.itemsConsumed[itemName], global.stats[forceName].itemsConsumed[itemName])
			calc = averageCalc(calc, player_settings.itemStats[itemName])

			player_settings.itemStatsPrev[itemName] = player_settings.itemStats[itemName]
			player_settings.itemStats[itemName] = calc

			empty = false
		end
		if not isHidden then
			addUpdateDisplay(itemName, player, mod_settings, player_settings.itemStats[itemName], player_settings.itemStatsPrev[itemName])
		end
	end

	for _, fluidName in pairs (player_settings.fluids) do
		if not wasReset then
			local calc = {}
			calc.rate = 			calcRate(stats.fluids[fluidName], global.stats[forceName].fluids[fluidName])
			calc.rateConsumed =  	calcRate(stats.fluidsConsumed[fluidName], global.stats[forceName].fluidsConsumed[fluidName])
			calc = averageCalc(calc, player_settings.fluidStats[itemName])

			player_settings.fluidStatsPrev[fluidName] = player_settings.fluidStats[fluidName]
			player_settings.fluidStats[fluidName] = calc

			empty = false
		end
		if not isHidden then
			addUpdateDisplay(fluidName, player, mod_settings, player_settings.fluidStats[fluidName], player_settings.fluidStatsPrev[fluidName])
		end
	end

	if empty or isHidden then
		minDisplay(player, mod_settings)
	end
end

function averageCalc (newCalc, oldCalc)
	if newCalc and oldCalc then
		newCalc.rate = average (newCalc.rate, oldCalc.rate)
		newCalc.rateConsumed = average (newCalc.rateConsumed, oldCalc.rateConsumed)
	end
	newCalc.ratio = calcRatio(newCalc.rate, newCalc.rateConsumed)
	newCalc.difference = calcDifference(newCalc.rate, newCalc.rateConsumed)
	return newCalc
end

function average (new, old)
	if old and new then
		local rate = (new*(.1) + old*(.9)  )
		if rate > zero then
			return rate
		else
			return 0
		end
	end
	return new
end

function calcRate (new, old)
	if old and new then
		return (new - old) * perMinute
	end
	return new
end

function calcDifference (production, consumption)
	if production and consumption then
		return (production - consumption)
	end
	return nil
end

function calcRatio (production, consumption)
	if production and consumption then
		if consumption > zero then
			return (production / consumption)
		end
		if production > 0 and consumption == 0 then
			return 100
		end
	end

	return nil
end

function getAttachLocation (isTop)
	local location = "left"
	if isTop then
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

function minDisplay (player, mod_settings)
	local attachLocation = getAttachLocation(mod_settings["production-monitor-top"])
	local isHidden = global.stats.playerPrefs[player.name].hide

	local large = mod_settings["production-monitor-large"]
	local buttonStyle = getButtonStyle(large)
	local labelStyle = getLabelStyle(large)
	local tableStyle = getTableStyle(large)
	local showProduction = mod_settings["production-monitor-show-production"]
	local showConsumption = mod_settings["production-monitor-show-consumption"]
	local showDiff = mod_settings["production-monitor-show-difference"]
	local showRatio = mod_settings["production-monitor-show-ratio"]
	local colSpan = mod_settings.playerColspan
	if isHidden then
		colSpan = 1
	end

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
		local item_table = item_flow.add{type = "table", colspan = colSpan, name = mod_settings.tableId, style=tableStyle}

		item_table.add{type = "sprite-button", name = "stats_show_settings", tooltip={"stats_show_settings_tip"}, 
			sprite=settingsIcon, style = buttonStyle}

		if not isHidden then
			if showProduction then
				item_table.add{type = "label", name = "stats_item_label_settings_created", caption = "+"..displayUoM, 
					style= labelStyle, tooltip={"stats_created"} }
			end
			if showConsumption then
				item_table.add{type = "label", name = "stats_item_label_settings_consumed", caption = "-"..displayUoM, 
					style= labelStyle, tooltip={"stats_consumed"} }
			end

			if showDiff then
				item_table.add{type = "label", name = "stats_item_label_settings_diff", caption = "Sum", 
					style= labelStyle, tooltip={"stats_diff"} }
			end

			if showRatio then
				item_table.add{type = "label", name = "stats_item_label_settings_ratio", caption = "P/C", 
				style= labelStyle, tooltip={"stats_ratio"} }
			end
		end
	else
		if not item_flow[mod_settings.tableId] then			
			item_flow.destroy()
			updateDisplayPlayer(player, player.force.name, nil, mod_settings)
		end
	end
end

function addUpdateDisplay(itemName, player, mod_settings, calc, calcPrev)

	local showProduction = mod_settings["production-monitor-show-production"]
	local showConsumption = mod_settings["production-monitor-show-consumption"]
	local showDiff = mod_settings["production-monitor-show-difference"]
	local showRatio = mod_settings["production-monitor-show-ratio"]
	
	local precision = mod_settings["production-monitor-precision"]

	minDisplay(player, mod_settings)

	local sprite
	local btnName
	local localised_name = {itemName}
	local attachLocation = getAttachLocation(mod_settings["production-monitor-top"])

	local large = mod_settings["production-monitor-large"]
	local buttonStyle = getButtonStyle(large)
	local labelStyle = getLabelStyle(large)
	local labelName

	if game.item_prototypes[itemName] then
		sprite = "item/"..itemName
		localised_name = game.item_prototypes[itemName].localised_name
		btnName = "stats_item_button_".. itemName
	elseif game.fluid_prototypes[itemName] then		
		sprite = "fluid/"..itemName
		localised_name = game.fluid_prototypes[itemName].localised_name
		btnName = "stats_fluid_button_".. itemName
	end

	local table = player.gui[attachLocation].stats_item_flow[mod_settings.tableId]
	
	if (sprite == nil) then
		logToPlayer(player, "Invalid Item/Fluid Removed : " .. itemName)
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

		labelName = "stats_item_label_created_" .. itemName
		if table[labelName] then
			table[labelName].destroy()
		end

		labelName = "stats_item_label_consumed_" .. itemName
		if table[labelName] then
			table[labelName].destroy()
		end

		labelName = "stats_item_label_diff_" .. itemName
		if table[labelName] then
			table[labelName].destroy()
		end

		labelName = "stats_item_label_ratio_" .. itemName
		if table[labelName] then
			table[labelName].destroy()
		end

		removeItem(player, itemName)
		removeFluid(player, itemName)
	else

		if not calc then
			calc = {}
		end

		if not calcPrev then
			calcPrev = calc
		end

		if btnName and not table[btnName] then
			table.add{type = "sprite-button", name = btnName, tooltip=localised_name, sprite = sprite, style = buttonStyle}
		end

		if (showProduction) then
			labelName = "stats_item_label_created_" .. itemName
			if not table[labelName] then
				table.add{type = "label", name = labelName,  tooltip=localised_name, style=labelStyle}
			end
			updateDisplayLabel(table[labelName], calc.rate, calcPrev.rate, precision)
		end

		if (showConsumption) then
			labelName = "stats_item_label_consumed_" .. itemName
			if not table[labelName] then
				table.add{type = "label", name = labelName,  tooltip=localised_name, style=labelStyle}
			end
			updateDisplayLabel(table[labelName], calc.rateConsumed, calcPrev.rateConsumed, precision)
		end

		if (showDiff) then
			labelName = "stats_item_label_diff_" .. itemName
			if not table[labelName] then
				table.add{type = "label", name = labelName,  tooltip=localised_name, style=labelStyle}
			end
			updateDisplayLabel(table[labelName], calc.difference, calcPrev.difference, precision, "posNeg")
		end
		
		if (showRatio) then
			labelName = "stats_item_label_ratio_" .. itemName
			if not table[labelName] then
				table.add{type = "label", name = labelName,  tooltip=localised_name, style=labelStyle}
			end
			updateDisplayLabel(table[labelName], calc.ratio, calcPrev.ratio, math.max(1, precision), "stopLight")
		end
	end
end

function applyTrend (label, smoothValue, rawCaption)
	if (smoothValue > rawCaption) then
		label.style.font_color = upTrend
	elseif (smoothValue < rawCaption) then
		label.style.font_color = downTrend
	else
		label.style.font_color = flatTrend
	end
end

function applyStopLight  (label, smoothValue, minValue)
	if smoothValue >= (1 + minValue) then
		label.style.font_color = upTrend
	elseif smoothValue < .35 then
		label.style.font_color = redLight
	elseif smoothValue < .65 then
		label.style.font_color = downTrend
	elseif smoothValue < (1 - minValue) then
		label.style.font_color = warning
	else
		label.style.font_color = flatTrend
	end
end

function applyPosNeg  (label, smoothValue)
	if smoothValue > 0 then
		label.style.font_color = upTrend
	elseif smoothValue < 0 then
		label.style.font_color = downTrend
	else
		label.style.font_color = flatTrend
	end
end

function updateDisplayLabel (label, value, oldValue, precision, style)
	if label then
		if value and oldValue then
			local smoothValue =  value
			local minValue = .5 / (math.pow(10, precision))			
			if (smoothValue > minValue) or style == "posNeg" then
				if not style then
					applyTrend (label, smoothValue, oldValue)
				elseif style == "stopLight" then
					applyStopLight (label, smoothValue, minValue)
				elseif style == "posNeg" then
					applyPosNeg (label, smoothValue)
				end

				if style == "stopLight" and smoothValue >= 100 then
					label.caption = "∞"
				else
					label.caption = fmtNumber( smoothValue, precision )
				end
				
			else
				if style == "stopLight" then
					label.style.font_color = redLight
				else
					label.style.font_color = flatTrend
				end
				label.caption = 0
			end
		else
			label.style.font_color = flatTrend
			label.caption = fmtNumber(noValue, precision)
		end
	end
end

function checkModifier (modifierType, ctr, alt, shift)
	if modifierType == "control" then
		return ctr
	end
	if modifierType == "alt" then
		return alt
	end
	if modifierType == "shift" then
		return shift
	end
	return false
end



script.on_event(defines.events.on_gui_click, function(event)
	local player = game.players[event.player_index]
	
	local center = player.gui.center.stats_center_frame
	local button = event.button
	local alt = event.alt
	local ctr = event.control
	local shift = event.shift

	if event.element.valid then
		local mod_settings
		local applyModifer
		local productionMonitorEvent
		if event.element.name == "stats_show_settings" or event.element.name:find("stats_") then
			mod_settings = playerModSettings(player)
			productionMonitorEvent = true
			applyModifer = checkModifier(mod_settings.modifier, ctr, alt, shift)
		end

		if event.element.name == "stats_show_settings" then
			if player.cursor_stack.valid_for_read then
				addItem(player, player.cursor_stack.name)
				productionMonitorEvent=true
			else
				if button == defines.mouse_button_type.left then
					if (not center) then
						center = player.gui.center.add{type = "frame", name = "stats_center_frame", direction = "vertical"}
					end
					if center.fluids_table then 
						center.destroy()
					else
						local fluids_table = center.add{type = "table", colspan = 12, name = "fluids_table", style = "slot_table_style"}
						for _, fluid in pairs(game.fluid_prototypes) do
							fluids_table.add{type = "sprite-button", name = "stats_fluid_selector_" .. fluid.name, sprite = "fluid/"..fluid.name, style = "slot_button_style", tooltip = fluid.localised_name}
						end
					end
				elseif (button == defines.mouse_button_type.right) then
					local hide = global.stats.playerPrefs[player.name].hide
					if hide then
						global.stats.playerPrefs[player.name].hide = false
					else
						global.stats.playerPrefs[player.name].hide = true
					end
					productionMonitorEvent=true
				end
			end
		elseif event.element.name:find("stats_fluid_selector_") then
			addFluid (player, event.element.name:sub(22))
			center.destroy()
			productionMonitorEvent=true
		elseif event.element.name:find("stats_fluid_button_") then
			local name = event.element.name:sub(20)
			-- middle click removes
			local index = getFluidIndex(player, name)
			removeFluid(player, name)
			if button == defines.mouse_button_type.middle or applyModifer then
				-- do nothing
			elseif button == defines.mouse_button_type.left  then
				-- to the top
				addFluid (player, name, index-1)
			elseif button == defines.mouse_button_type.right then
				-- to the bottom
				addFluid (player, name, index+1)
			end
			productionMonitorEvent=true
		elseif event.element.name:find("stats_item_button_") then
			local name = event.element.name:sub(19)
			-- middle click removes
			if player.cursor_stack.valid_for_read then
				replaceItem(player, player.cursor_stack.name, name)
			else
				local index = getItemIndex(player, name)
				removeItem(player, name)
				if button == defines.mouse_button_type.middle or applyModifer then
					-- do nothing
				elseif button == defines.mouse_button_type.left then
					-- to the top
					addItem (player, name, index-1)
				elseif button == defines.mouse_button_type.right then
					-- to the bottom
					addItem (player, name, index+1)
				end
			end
			productionMonitorEvent=true
		end

		if productionMonitorEvent then
			resetGuiEvent (player, mod_settings)
		end
	end


end)

function resetGuiEvent (player, mod_settings)
	local attachLocation = getAttachLocation(mod_settings["production-monitor-top"])
	local flow = player.gui[attachLocation].stats_item_flow

	if flow then
		flow.destroy()
	end
	updateDisplayPlayer(player, player.force.name, nil, mod_settings)
end

function debugPrint(thing)
	for _, player in pairs(game.players) do
		player.print(serpent.block(thing))
	end
end

local logRoot = "[Production-Monitor] "
function logToPlayer(player, msg)
	player.print(logRoot .. msg)
end

function fmtNumber(amount, precision)

	if not amount or amount == noValue then
		return amount
	end
	
	local million
	local thousand

	if math.abs(amount) >= 1000000 then
		million = true
		amount = amount / 1000000
		precision = precision + 2
	elseif  math.abs(amount) >= 1000 then
		thousand = true
		amount = amount / 1000
		precision = precision + 1
	end
	
	local formatted = round(amount, precision)
	while true do  
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		if (k==0) then
		break
		end
	end

	if million then
		return formatted.."M"
	end

	if thousand then
		return formatted.."k"
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
