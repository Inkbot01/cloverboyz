-- Server entry point. The network comes up first: requiring Blink's server
-- half creates the two remotes every client waits on, so a fast joiner never
-- sits on WaitForChild. Data loads next: it starts ProfileStore sessions on
-- PlayerAdded and creates each player's replica. Loader then boots every
-- other ModuleScript — concurrent requires, error tracebacks, hang watchdog,
-- optional OnInit/OnStart lifecycle — walking descendants (not just
-- children) so nested side-effect modules get picked up too; anything a
-- parent already required just resolves from the module cache.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Loader = require(Shared:WaitForChild("Loader"))

require(Shared:WaitForChild("Network"):WaitForChild("Server"))
require(script:WaitForChild("Data"))

Loader.LoadAll(script, { Descendants = true, Exclude = { "Data" } })
