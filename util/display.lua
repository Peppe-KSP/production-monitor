require("util/listMgr")

local noValue = "-"
local displayUoM = "/m"
local settingsIcon = "add"
local downTrend = {r=1, g=.8, b=.8}
local upTrend = {r=.8, g=1, b=.8}
local flatTrend = {r=1, g=1, b=1}
local warning = {r=.7, g=.7, b=0}
local redLight = {r=1, g=.2, b=.2}
local mouseButtonFilter = {"left", "right","middle"}

function getAttachLocation (isTop)
	local location = "left"
	if isTop then
		location = "top"
	end
	return location
end

function getButtonStyle (large)
	local style = "tool_button"
	if large then
		style = "slot_button"
	end
	return style
end

function getLabelStyle (large)
	local style = "bold_label"
	if (large) then
		style = "stats_label_style_large"
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

function applyTrend (label, smoothValue, rawCaption)
	if (smoothValue > rawCaption) then
		label.style.font_color = upTrend
	elseif (smoothValue < rawCaption) then
		label.style.font_color = downTrend
	else
		label.style.font_color = flatTrend
	end
end

function applyStopLight (label, smoothValue, minValue)
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

function applyPosNeg (label, smoothValue, minValue)
	if smoothValue > minValue then
		label.style.font_color = upTrend
	elseif smoothValue < -minValue then
		label.style.font_color = downTrend
	else
		label.style.font_color = flatTrend
	end
end

function sortItems (a, b)
    if a.itemtype == b.itemtype then
        return a.name < b.name 
    else
        return a.itemtype < b.itemtype  
    end
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
		
        center = player.gui.center.stats_center

		if event.element.name == "stats_show_settings" then
			if player.cursor_stack ~= nil and player.cursor_stack.valid_for_read then
				addItem(player, player.cursor_stack.name)
				productionMonitorEvent=true
			else
                if (not center) then
                    center = player.gui.center.add({type = "frame",name = "stats_center",direction = "vertical"})
                    center.style.maximal_height=800 
                end
                centeri = center.stats_center_item_frame
                centerf = center.stats_center_fluid_frame
                
                if (button == defines.mouse_button_type.left and applyModifer) or (button == defines.mouse_button_type.middle) then   
                    if centerf then 
                        centerf.destroy()
                    end
                    if (not centeri) then
						centeri = center.add{type = "scroll-pane", name = "stats_center_item_frame", direction = "vertical"}
					end
					if centeri.items_table then 
						center.destroy()
					else
						local items_table = centeri.add{type = "table", column_count = 16, name = "items_table", style = "slot_table"}


                        sortedItems = {}
                        for _, item in pairs(game.item_prototypes) do
                            table.insert(sortedItems, {type = "sprite-button", name = "stats_item_selector_" .. item.name, sprite = "item/"..item.name, style = "slot_button", tooltip = item.localised_name, itemtype=item.type})
                        end

                        table.sort(sortedItems, sortItems )
                        
						for _, item in pairs(sortedItems) do
							items_table.add(item)
						end
					end
                elseif button == defines.mouse_button_type.left then
                    if centeri then 
                        centeri.destroy()
                    end
                    
					if (not centerf) then
						centerf = center.add{type = "scroll-pane", name = "stats_center_fluid_frame", direction = "vertical"}
            
					end
					if centerf.fluids_table then 
						center.destroy()
					else
						local fluids_table = centerf.add{type = "table", column_count = 16, name = "fluids_table", style = "slot_table"}
						for _, fluid in pairs(game.fluid_prototypes) do
							fluids_table.add{type = "sprite-button", name = "stats_fluid_selector_" .. fluid.name, sprite = "fluid/"..fluid.name, style = "slot_button", tooltip = fluid.localised_name}
						end
					end
				elseif (button == defines.mouse_button_type.right) then
                    center.destroy()
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
        elseif event.element.name:find("stats_item_selector_") then
			addItem (player, event.element.name:sub(21))
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
	local showOverall = mod_settings["production-monitor-show-overall"]
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
		local item_table = item_flow.add{type = "table", column_count = colSpan, name = mod_settings.tableId, style=tableStyle}

		item_table.add{type = "sprite-button", name = "stats_show_settings", tooltip={"stats_show_settings_tip"},
			sprite = settingsIcon, style = buttonStyle, mouse_button_filter = mouseButtonFilter}

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

			if showOverall then
				item_table.add{type = "label", name = "stats_item_label_settings_overall", caption = "Ov", 
				style= labelStyle, tooltip={"stats_produced"} }
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
	local showOverall = mod_settings["production-monitor-show-overall"]
	
	local precision = mod_settings.precision

	minDisplay(player, mod_settings)

	local sprite
	local btnName
	local localised_name = {itemName}
	local attachLocation = getAttachLocation(mod_settings["production-monitor-top"])

	local large = mod_settings["production-monitor-large"]
	local buttonStyle = getButtonStyle(large)
	local labelStyle = getLabelStyle(large)
	local labelName
	
	if game.fluid_prototypes[itemName] then		
		sprite = "fluid/"..itemName
		localised_name = game.fluid_prototypes[itemName].localised_name
		btnName = "stats_fluid_button_".. itemName
	elseif game.item_prototypes[itemName] then
		sprite = "item/"..itemName
		localised_name = game.item_prototypes[itemName].localised_name
		btnName = "stats_item_button_".. itemName
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

		labelName = "stats_item_label_overall_" .. itemName
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
			table.add{type = "sprite-button", name = btnName, tooltip=localised_name, sprite = sprite, style = buttonStyle, mouse_button_filter = mouseButtonFilter}
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

		if (showOverall) then
			labelName = "stats_item_label_overall_" .. itemName
			if not table[labelName] then
				table.add{type = "label", name = labelName,  tooltip=localised_name, style=labelStyle}
			end
			updateDisplayLabel(table[labelName], calc.overall, calcPrev.overall, precision)
		end
	end
end



function updateDisplayLabel (label, value, oldValue, precision, style)
	if label then
		if value and oldValue then
			local smoothValue = value
			local minValue = .5 / (math.pow(10, precision))			

			if not style then
				applyTrend (label, smoothValue, oldValue)
			elseif style == "stopLight" then
				applyStopLight (label, smoothValue, minValue)
			elseif style == "posNeg" then
				applyPosNeg (label, smoothValue, minValue)
			end

			if style == "stopLight" and smoothValue >= 100 then
				label.caption = "∞"
			else
				label.caption = fmtNumber( smoothValue, precision)
			end

			if label.caption == "0" and not style == "stopLight" then
				label.style.font_color = flatTrend
			end

		else
			label.style.font_color = flatTrend
			label.caption = fmtNumber(noValue, precision, 0)
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

function resetGuiEvent (player, mod_settings)
	local attachLocation = getAttachLocation(mod_settings["production-monitor-top"])
	local flow = player.gui[attachLocation].stats_item_flow

	if flow then
		flow.destroy()
	end
	updateDisplayPlayer(player, player.force.name, nil, mod_settings)
end

function fmtNumber(amount, precision)

	if not amount or amount == noValue then
		return amount
	end
	
	local trillion
	local billion
	local million
	local thousand

	local absAmount = math.abs(amount) 

	if absAmount >= 1000000000000 then
		trillion = true
		amount = amount / 1000000000000
		precision = precision + 4
	elseif absAmount >= 1000000000 then
		billion = true
		amount = amount / 1000000000
		precision = precision + 3
	elseif absAmount >= 1000000 then
		million = true
		amount = amount / 1000000
		precision = precision + 2
	elseif  absAmount >= 1000 then
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

	if trillion then
		return formatted.."T"
	end

	if billion then
		return formatted.."G"
	end  
	
	if million then
		return formatted.."M"
	end

	if thousand then
		return formatted.."k"
	end
	return formatted
end