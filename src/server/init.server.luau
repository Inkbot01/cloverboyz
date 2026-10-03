-- Server entry point. Data loads first: it starts ProfileStore sessions on
-- PlayerAdded and creates each player's replica. Loader then boots every
-- other ModuleScript — concurrent requires, error tracebacks, hang watchdog,
-- optional OnInit/OnStart lifecycle — walking descendants (not just
-- children) so nested side-effect modules get picked up too; anything a
-- parent already required just resolves from the module cache.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Loader = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Loader"))

require(script:WaitForChild("Data"))

Loader.LoadAll(script, { Descendants = true, Exclude = { "Data" } })
