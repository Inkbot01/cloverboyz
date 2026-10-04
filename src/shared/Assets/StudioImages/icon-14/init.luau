return table.freeze({
	Width = 182,
	Height = 244,
	Data = table.concat({
		require(script.Chunk1),
		require(script.Chunk2),
	}),
})
