return table.freeze({
	Width = 234,
	Height = 247,
	Data = table.concat({
		require(script.Chunk1),
		require(script.Chunk2),
	}),
})
