require("util/calculation")

script.on_init(function(event)
	global.stats = {}
	global.stats.playerPrefs = {}
	global.stats.tickRate = settings.global["production-monitor-update-seconds"].value * 60
	global.stats.perMinute = 3600 / global.stats.tickRate
end)

script.on_event(defines.events.on_tick, function(event)
	if (game.tick % global.stats.tickRate == 0) then
		local checkTickRate = settings.global["production-monitor-update-seconds"].value * 60
		if checkTickRate ~= global.stats.tickRate then
			global.stats.tickRate = checkTickRate
			global.stats.perMinute = 3600 / checkTickRate
		end

		for k, force in pairs(game.forces) do
			updateStats (force)
		end
	end
end)

script.on_configuration_changed(function(data)
   if data.mod_changes ~= nil and data.mod_changes["production-monitor"] ~= nil then 

		if (global.stats == nil) then
			global.stats = {}
		end

		global.stats.tickRate = settings.global["production-monitor-update-seconds"].value * 60
		global.stats.perMinute = 3600 / global.stats.tickRate

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

function playerModSettings (player)
	local mod_settings = {}
	
	mod_settings.modifier								= player.mod_settings["production-monitor-modifier"].value
	mod_settings["production-monitor-show-production"] 	= player.mod_settings["production-monitor-show-production"].value
	mod_settings["production-monitor-show-consumption"] = player.mod_settings["production-monitor-show-consumption"].value
	mod_settings["production-monitor-show-difference"] 	= player.mod_settings["production-monitor-show-difference"].value
	mod_settings["production-monitor-show-ratio"] 		= player.mod_settings["production-monitor-show-ratio"].value
	mod_settings["production-monitor-show-overall"] 		= player.mod_settings["production-monitor-show-overall"].value
	
	mod_settings["production-monitor-large"] 			= player.mod_settings["production-monitor-large"].value
	mod_settings["production-monitor-top"] 				= player.mod_settings["production-monitor-top"].value
	mod_settings.precision 								= player.mod_settings["production-monitor-precision"].value
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
	if mod_settings["production-monitor-show-overall"] then
		mod_settings.fieldCount = mod_settings.fieldCount + 1
		tableString = tableString .. "o"
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
	local isDisplayOnlyUpdate = false

	if (not stats) then 
		isDisplayOnlyUpdate = true
		stats = {}	
	end

	local player_settings = global.stats.playerPrefs[player.name]	
	if not player_settings then
		addPlayer(player)
		player_settings = global.stats.playerPrefs[player.name]
	end
	local isHidden = global.stats.playerPrefs[player.name].hide

	if player.controller_type == defines.controllers.cutscene then
		isHidden = true
	end

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

	local emptyItems = updateCalculations(player, forceName, mod_settings, player_settings.items, 
		stats.items, stats.itemsConsumed, 
		global.stats[forceName].items, global.stats[forceName].itemsConsumed,
		player_settings.itemStats, player_settings.itemStatsPrev,
		isDisplayOnlyUpdate, isHidden)

	local emptyfluids = updateCalculations(player, forceName, mod_settings, player_settings.fluids,
		stats.fluids, stats.fluidsConsumed, 
		global.stats[forceName].fluids, global.stats[forceName].fluidsConsumed,
		player_settings.fluidStats, player_settings.fluidStatsPrev,
		isDisplayOnlyUpdate, isHidden)


	if (emptyItems and emptyfluids) or isHidden then
		minDisplay(player, mod_settings)
	end
end

