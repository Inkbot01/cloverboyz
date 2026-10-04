return table.freeze({
	Width = 210,
	Height = 220,
	Data = table.concat({
		require(script.Chunk1),
		require(script.Chunk2),
		require(script.Chunk3),
	}),
})
