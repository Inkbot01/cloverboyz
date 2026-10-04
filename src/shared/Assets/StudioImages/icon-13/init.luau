return table.freeze({
	Width = 197,
	Height = 220,
	Data = table.concat({
		require(script.Chunk1),
		require(script.Chunk2),
	}),
})
