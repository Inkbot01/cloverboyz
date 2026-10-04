return table.freeze({
	Width = 162,
	Height = 235,
	Data = table.concat({
		require(script.Chunk1),
		require(script.Chunk2),
	}),
})
