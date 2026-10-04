return table.freeze({
	Width = 272,
	Height = 206,
	Data = table.concat({
		require(script.Chunk1),
		require(script.Chunk2),
		require(script.Chunk3),
	}),
})
