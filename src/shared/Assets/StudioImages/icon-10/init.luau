return table.freeze({
	Width = 227,
	Height = 219,
	Data = table.concat({
		require(script.Chunk1),
		require(script.Chunk2),
		require(script.Chunk3),
	}),
})
