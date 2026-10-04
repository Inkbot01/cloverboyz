return table.freeze({
	Width = 183,
	Height = 208,
	Data = table.concat({
		require(script.Chunk1),
		require(script.Chunk2),
	}),
})
