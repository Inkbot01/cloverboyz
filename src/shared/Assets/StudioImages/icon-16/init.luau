return table.freeze({
	Width = 258,
	Height = 261,
	Data = table.concat({
		require(script.Chunk1),
		require(script.Chunk2),
		require(script.Chunk3),
	}),
})
