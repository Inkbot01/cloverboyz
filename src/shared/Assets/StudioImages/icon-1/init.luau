return table.freeze({
	Width = 257,
	Height = 278,
	Data = table.concat({
		require(script.Chunk1),
		require(script.Chunk2),
	}),
})
