return table.freeze({
	Width = 155,
	Height = 192,
	Data = table.concat({
		require(script.Chunk1),
		require(script.Chunk2),
	}),
})
