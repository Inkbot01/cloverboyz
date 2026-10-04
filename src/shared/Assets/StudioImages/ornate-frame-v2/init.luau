return table.freeze({
	Width = 512,
	Height = 509,
	Data = table.concat({
		require(script.Chunk1),
		require(script.Chunk2),
		require(script.Chunk3),
		require(script.Chunk4),
		require(script.Chunk5),
	}),
})
