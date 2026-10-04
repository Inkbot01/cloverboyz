return table.freeze({
	Width = 213,
	Height = 219,
	Data = table.concat({
		require(script.Chunk1),
		require(script.Chunk2),
	}),
})
