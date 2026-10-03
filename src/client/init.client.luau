-- Client entry point. Data loads first — requiring it calls
-- ReplicaClient.RequestData(), which tells the server to start streaming this
-- player's replica. Loader then boots every other ModuleScript in this folder:
-- concurrent requires, error tracebacks, hang watchdog, and the optional
-- OnInit/OnStart lifecycle. Drop a ModuleScript into this folder and it loads
-- automatically; see Loader for the LoadPriority/LoadDisabled attributes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Loader = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Loader"))

require(script:WaitForChild("Data"))

Loader.LoadAll(script, { Exclude = { "Data" } })
