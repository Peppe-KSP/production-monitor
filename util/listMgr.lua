function removeItem (player, itemToRemove)
	local items = global.stats.playerPrefs[player.name].items
    removeFromList(items, itemToRemove)
end

function removeFluid (player, fluidToRemove)
	local fluids = global.stats.playerPrefs[player.name].fluids
    removeFromList(fluids, fluidToRemove)
end

function removeFromList (list, target)
    for i, name in ipairs(list) do
    	if (name == target) then
			table.remove(list, i)
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