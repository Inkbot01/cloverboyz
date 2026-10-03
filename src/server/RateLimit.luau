--!strict

-- Per-player token buckets for anything a client can trigger. Blink validates
-- the SHAPE of what arrives; this bounds HOW OFTEN. Build one limiter per verb
-- at module scope and make the check the first line of the handler — before
-- any work, before any yield.
--
--   local limiter = RateLimit.new(perSecond, burst)
--   if not limiter:Allow(player) then
--       return
--   end
--
-- Buckets are strong-keyed by Player and dropped on PlayerRemoving. A weak key
-- on an Instance tracks the Lua wrapper, not the instance (DATA.md §7).

local Players = game:GetService("Players")

local RateLimit = {}
RateLimit.__index = RateLimit

type Bucket = {
	Tokens: number,
	Updated: number,
}

export type Limiter = typeof(setmetatable(
	{} :: {
		Rate: number,
		Burst: number,
		Buckets: { [Player]: Bucket },
	},
	RateLimit
))

local limiters: { [Limiter]: boolean } = {}

function RateLimit.new(perSecond: number, burst: number?): Limiter
	if perSecond <= 0 then
		error("[RateLimit] perSecond must be positive", 2)
	end
	local self = setmetatable({
		Rate = perSecond,
		Burst = math.max(burst or perSecond, 1),
		Buckets = {},
	}, RateLimit)
	limiters[self] = true
	return self
end

function RateLimit.Allow(self: Limiter, player: Player): boolean
	local now = os.clock()
	local bucket = self.Buckets[player]
	if bucket == nil then
		bucket = { Tokens = self.Burst, Updated = now }
		self.Buckets[player] = bucket
	end

	local tokens = math.min(self.Burst, bucket.Tokens + (now - bucket.Updated) * self.Rate)
	bucket.Updated = now

	if tokens < 1 then
		bucket.Tokens = tokens
		return false
	end
	bucket.Tokens = tokens - 1
	return true
end

function RateLimit.Forget(self: Limiter, player: Player)
	self.Buckets[player] = nil
end

Players.PlayerRemoving:Connect(function(player)
	for limiter in limiters do
		limiter.Buckets[player] = nil
	end
end)

return RateLimit
