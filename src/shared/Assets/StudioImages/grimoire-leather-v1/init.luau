return table.freeze({
	Width = 512,
	Height = 512,
	Data = table.concat({
		require(script.Chunk1),
		require(script.Chunk2),
		require(script.Chunk3),
		require(script.Chunk4),
		require(script.Chunk5),
		require(script.Chunk6),
		require(script.Chunk7),
		require(script.Chunk8),
		require(script.Chunk9),
	}),
})
