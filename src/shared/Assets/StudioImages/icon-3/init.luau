return table.freeze({
	Width = 248,
	Height = 258,
	Data = table.concat({
		require(script.Chunk1),
		require(script.Chunk2),
		require(script.Chunk3),
	}),
})
