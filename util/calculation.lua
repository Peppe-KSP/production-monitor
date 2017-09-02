require("util/display")

local zero = .059

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

function updateCalculations (player, forceName, mod_settings, sourceList, 
	production, consumption, 
	forceProduction, forceconsumption, 
	playerStats, playerStatsPrev,
	isDisplayOnlyUpdate, isHidden)
	for _, name in pairs (sourceList) do
		if not isDisplayOnlyUpdate then
			local calc = {}
			calc.rate = 			calcRate(production[name], forceProduction[name])
			calc.rateConsumed =  	calcRate(consumption[name], forceconsumption[name])
			calc = averageCalc(calc, playerStats[name], mod_settings.precision)

			playerStatsPrev[name] = playerStats[name]
			playerStats[name] = calc

			empty = false
		end
		if not isHidden then
			addUpdateDisplay(name, player, mod_settings, playerStats[name], playerStatsPrev[name])
		end
	end
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
		return (new - old) * global.stats.perMinute
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