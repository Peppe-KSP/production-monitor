require("util/display")

local zero = .059

function updateStats (force, statsOnly)

	local currentItemCount = {}
	local currentFluidCount =  {}
	local currentItemCountConsumed = {}
	local currentFluidCountConsumed = {}

	for k, surface in pairs(game.surfaces) do
		currentItemCount = merge_surface_stats(currentItemCount, force.get_item_production_statistics(surface).input_counts)
		currentFluidCount = merge_surface_stats(currentFluidCount, force.get_fluid_production_statistics(surface).input_counts)
		currentItemCountConsumed = merge_surface_stats(currentItemCountConsumed, force.get_item_production_statistics(surface).output_counts)
		currentFluidCountConsumed = merge_surface_stats(currentFluidCountConsumed, force.get_fluid_production_statistics(surface).output_counts)
	end

	local stats = {}
	stats.items =currentItemCount
	stats.fluids = currentFluidCount
	stats.itemsConsumed = currentItemCountConsumed
	stats.fluidsConsumed = currentFluidCountConsumed

	local forceName = force.name
	if (storage.stats == nil) then
		storage.stats = {}
	end

	if (storage.stats.playerPrefs == nil) then
		storage.stats.playerPrefs = {}
	end

	if (storage.stats[forceName] == nil) then
		storage.stats[forceName] = stats
	end

	if not statsOnly then
		updateDisplayForce (force, stats)
	end

	storage.stats[forceName].items = currentItemCount
	storage.stats[forceName].fluids = currentFluidCount
	
	storage.stats[forceName].itemsConsumed = currentItemCountConsumed
	storage.stats[forceName].fluidsConsumed = currentFluidCountConsumed
end

function merge_surface_stats (current, new)
	for key, name in pairs(new) do
		if current[key] ~= nil then
			current[key] = current[key] + new[key]
		else
			current[key] = new[key]
		end
	end

	return current
end

function updateDisplayForce (force, stats)
	for _, player in pairs(force.players) do
		if (player.valid and player.connected) then
			updateDisplayPlayer(player, force.name, stats, playerModSettings(player))
		end
	end
end

function updateCalculations (player, forceName, mod_settings, sourceList, 
	production, consumption, 
	forceProduction, forceconsumption, 
	playerStats, playerStatsPrev,
	isDisplayOnlyUpdate, isHidden)
	local empty = true
	for _, name in pairs (sourceList) do
		if not isDisplayOnlyUpdate then
			local calc = {}
			calc.rate = 			calcRate(production[name], forceProduction[name])
			calc.rateConsumed =  	calcRate(consumption[name], forceconsumption[name])
			calc = averageCalc(calc, playerStats[name], mod_settings.precision)
			calc.overall = production[name]

			playerStatsPrev[name] = playerStats[name]
			playerStats[name] = calc

			empty = false
		end
		if not isHidden then
			addUpdateDisplay(name, player, mod_settings, playerStats[name], playerStatsPrev[name])
		end
	end

	return empty
end

function averageCalc (newCalc, oldCalc, precision)
	if newCalc and oldCalc then
		precision = math.max(precision, 2)
		newCalc.rate = round (average ( newCalc.rate, oldCalc.rate), precision)
		newCalc.rateConsumed =  round (average ( newCalc.rateConsumed, oldCalc.rateConsumed), precision)
	end
	newCalc.ratio = calcRatio( newCalc.rate, newCalc.rateConsumed)
	newCalc.difference = calcDifference( newCalc.rate, newCalc.rateConsumed)
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
		return (new - old) * storage.stats.perMinute
	end
	return new
end

function calcDifference (production, consumption)
	if production and consumption then
		local diff = (production - consumption)
		if math.abs( diff ) > zero then
			return diff
		else
			return 0
		end
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

function round(val, precision)
	if val then
		if math.abs(val) < 1 then
			precision = math.max(precision, 1)
		end

		if precision then
			return math.floor( (val * 10^precision) + 0.5) / (10^precision)
		else
			return math.floor(val+0.5)
		end
	else
		return 0
	end
end