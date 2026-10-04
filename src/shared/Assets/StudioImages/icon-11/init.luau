return table.freeze({
	Width = 204,
	Height = 183,
	Data = table.concat({
		require(script.Chunk1),
		require(script.Chunk2),
	}),
})
