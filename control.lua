require("mod-gui")
require("util/playerMgr")

function debugPrint(thing)
	for _, player in pairs(game.players) do
		player.print(serpent.block(thing))
	end
end

local logRoot = "[Production-Monitor] "
function logToPlayer(player, msg)
	player.print(logRoot .. msg)
end
