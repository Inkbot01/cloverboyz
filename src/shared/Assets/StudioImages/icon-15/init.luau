return table.freeze({
	Width = 211,
	Height = 229,
	Data = table.concat({
		require(script.Chunk1),
		require(script.Chunk2),
	}),
})
