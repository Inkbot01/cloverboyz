local Layout = {}
Layout.Window = table.freeze({ WidthScale = 0.70, HeightScale = 0.80, AspectRatio = 10 / 7, CenterY = 0.48 })
local desktopMenu = table.freeze({
	Width = 480,
	Height = 236,
	Padding = 20,
	RowGap = 14,
	PagesHeight = 110,
	UtilitiesHeight = 56,
	PageGap = 12,
	DockGap = 12,
	ToolbarHeight = 54,
})
local compactMenu = table.freeze({
	Width = 236,
	Height = 124,
	Padding = 8,
	RowGap = 4,
	PagesHeight = 54,
	UtilitiesHeight = 44,
	PageGap = 6,
	DockGap = 8,
	ToolbarHeight = 48,
})

function Layout.Menu(compact)
	return if compact then compactMenu else desktopMenu
end

function Layout.Resolve(width, height, touch, menuOpen)
	width = if width > 0 then width else 1440
	height = if height > 0 then height else 860
	local touchControls = touch and width < 1100
	local scale = if touchControls then 1 else math.min(width / 1440, 1.25)
	width /= scale
	height /= scale
	local margin = if touchControls then 16 else 24
	local slot = if touchControls then 44 else 88
	local slotGap = if touchControls then 5 else 10
	local statusWidth = if touchControls then 236 else 520
	local statusHeight = if touchControls then 146 else 250
	local hotbarWidth = slot * 5 + slotGap * 4
	local stackHUD = touchControls and width < statusWidth + hotbarWidth + 20 + margin * 2
	local menu = Layout.Menu(touchControls)
	local moveMenu = touchControls
		and not stackHUD
		and menuOpen == true
		and statusHeight + menu.ToolbarHeight + menu.Height + menu.DockGap + 12 > height - margin * 2
	local menuBeside = moveMenu and width >= statusWidth + hotbarWidth + menu.Width + 40 + margin * 2
	local menuAboveAbilities = moveMenu and not menuBeside
	local menuHeight = menu.ToolbarHeight + (if menuOpen and not moveMenu then menu.Height + menu.DockGap else 0)
	local hotbarHeight = slot + 64
	local abilityHeight = hotbarHeight + (if menuAboveAbilities then menu.Height + menu.DockGap else 0)
	local columnHeight = statusHeight + menuHeight + 12
	local dockHeight = if stackHUD then columnHeight + abilityHeight + 12 else math.max(columnHeight, abilityHeight)
	local bottom = if touchControls
		then math.min(if stackHUD then 164 else 140, math.max(margin, height - dockHeight - margin))
		else margin
	local panelWidth = width * (if touchControls then 0.94 else Layout.Window.WidthScale)
	local panelHeight = height * (if touchControls then 0.90 else Layout.Window.HeightScale)
	if not touchControls then
		panelWidth = math.min(panelWidth, panelHeight * Layout.Window.AspectRatio)
		panelHeight = panelWidth / Layout.Window.AspectRatio
	end
	local panelTop = height * Layout.Window.CenterY - panelHeight / 2
	return {
		Scale = scale,
		CanvasWidth = width,
		CanvasHeight = height,
		Margin = margin,
		Status = { Width = statusWidth, Height = statusHeight },
		StatusBottom = bottom,
		StatusColumnHeight = columnHeight,
		HUDHeight = dockHeight,
		HUDGap = if stackHUD then 12 elseif touchControls then 20 else 40,
		StackHUD = stackHUD,
		CompactHUD = touchControls,
		Hotbar = { Width = hotbarWidth, Height = hotbarHeight },
		SlotSize = slot,
		SlotGap = slotGap,
		AbilityArt = if touchControls then 34 else 70,
		MenuHeight = menuHeight,
		MenuBeside = menuBeside,
		MenuAboveAbilities = menuAboveAbilities,
		MenuButton = if touchControls then 44 else 64,
		MenuGap = if touchControls then 8 else 12,
		Navigation = { Width = if touchControls then 250 else 480, Height = 126 },
		ShowCompass = width >= 700 and not touchControls,
		Quest = { Width = 400, Height = 160 },
		ShowQuest = width >= 1100 and height >= 680 and height - dockHeight - bottom - 24 >= 160 + margin,
		Panel = {
			X = (width - panelWidth) / 2,
			Y = panelTop,
			Width = panelWidth,
			Height = panelHeight,
		},
		Compact = panelWidth < 760 or panelHeight < 540,
		Tight = panelWidth < 540,
		ShortPanel = panelHeight < 540,
		PanelPadding = if panelWidth < 540 then 16 else 24,
		TouchControls = touchControls,
	}
end

return table.freeze(Layout)
