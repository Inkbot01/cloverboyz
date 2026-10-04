return table.freeze({
	Width = 256,
	Height = 253,
	Data = table.concat({
		require(script.Chunk1),
		require(script.Chunk2),
		require(script.Chunk3),
		require(script.Chunk4),
	}),
})
