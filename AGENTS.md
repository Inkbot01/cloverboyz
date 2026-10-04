# Cloverboyz interface work

Read `CLAUDE.md` for the repository's Luau standards. These instructions apply to interface work in this project.

## Visual authority

- Open `output/ui-concepts/hud-concept-v1.png` and `output/ui-concepts/stats-concept-v1.png` before changing the interface. They are the approved art direction. Later Figma frames and offline previews are implementation drafts, not replacement references.
- The game is a pixel Black Clover RPG: dark ink, warm parchment type, antique brass and blackened steel frames, clover and Black Bulls motifs, emerald interaction states. The latest border references call for illustrated carved corners and layered metal edges; use the imported v2 frame textures rather than thin flat outlines. Use the original concepts' hierarchy and proportions. The current revision replaces flat black-blue interiors with subtle grimoire-cover material and warm olive-charcoal shading. Keep text off decorative endcaps, pair resource values with their labels above the bars, and give location text an opaque backing instead of heavy text outlines.
- HUD: enlarged portrait and resources at bottom left, an M menu toggle and currency immediately above them, and five abilities along the bottom beside that column. The flyout has one illustrated outer frame: three centered, unboxed page buttons (Stats, Grimoire, Items), then a quiet divider and separate Customize and Guide controls. Do not restore nested ornate tiles. Guide uses the compass icon and an explicit ON/OFF state. The current user revision takes precedence over the original menu position. Use a larger top-center compass and a readable quest card at middle-left. Keep the center of the world unobstructed.
- Customization: use GPO's central character preview and side selectors as the composition reference, retaining the approved Clover palette and artwork. Appearance choices belong left, color palettes right, with a large avatar between them. Use a single outer frame and quiet internal controls. See `docs/ui/CUSTOMIZATION.md` for the current catalog and save contract; do not invent unavailable cosmetic assets, race rolls, or persistent saves.
- Stats: modestly above-center character window, full-body avatar and identity at left, attribute rows and combat overview at right. Screen size and position use UDim2 scale values with native aspect constraints, never fixed pixel modal dimensions. Keep the expanded body text while avoiding a giant or top-docked window. Active tabs use a filled state, not an underline. Use quiet separators between rows. Gold borders belong to the outer window, portrait, icon wells and controls; do not box every row in gold.
- Pixel art needs intentional silhouettes and shading. Use imported image assets for illustrated icons and decorative frames. Do not approximate detailed artwork with hundreds of tiny GUI Frames.
- Native TextLabels own all dynamic text. Do not bake labels, values, bars, or interaction states into a screenshot.

## Roblox construction

- Fusion creates the production UI. Keep reusable view components shared between runtime and Studio previews.
- Use `UIListLayout`, `UIGridLayout`, `LayoutOrder`, `UIPadding`, and purposefully applied `UIFlexItem`. Do not compute child positions from array indices, text-length estimates, or a custom layout solver.
- Use `AnchorPoint` and screen-relative Scale sizes/positions for screen docks and modal windows. Use `UIAspectRatioConstraint` for desktop window proportions and centered icon artwork; allow flexible height for narrow touch screens. Constraints belong to the object they constrain. Avoid competing layout and size constraints.
- HUD resource panels, ability slots, currency, compass and menu reuse the quest card's warm grimoire material, including its gradient and texture.
- Imported pixel frames use `ImageLabel`/`ImageButton`, `ScaleType.Slice`, an explicit `SliceCenter`, and `ResampleMode.Pixelated`. Atlas icons use documented image rectangles. Keep aspect ratio intact.
- Use the shared Fusion motion primitives for window/page entry, hover/focus and press/release feedback. Keep hit targets stable during interaction; do not resize list-managed buttons to create hover effects.
- Separate decoration from content containers so list layouts never rearrange borders, shadows, or corner ornaments.
- Use explicit screen layers and sibling Z ordering. Production screens live in PlayerGui. An isolated, removable CoreGui preview is permitted only in Studio Edit mode.
- Use one source of viewport measurements outside scaled content. Never create a UIScale/AbsoluteSize feedback loop. Validate wide, narrow, and high-density Studio viewports in the engine.
- A ViewportFrame owns its Camera and WorldModel. Clone characters safely, strip scripts, disable physics, and clean up scoped connections and instances.
- Preserve allocation validation, server authority, keyboard/gamepad input, and cleanup. Never present a preview reset button as an implemented server respec.

## Assets and verification

- Keep original and export assets under `assets/interface/`, with an asset manifest documenting atlas rectangles and slice margins. Do not use invented Roblox asset IDs.
- The source icon atlas is 1254 square, but the verified published texture is 1024 square. Runtime crops come from generated `Shared.Assets.IconAtlas`; run `python3 tools/ui-art/build_icon_atlas.py` after changing manifest rectangles or published size. Never use source-image coordinates against the resized Roblox texture.
- Check import results and image loading in Studio. Missing artwork is a blocker to final visual sign-off, not a reason to silently substitute crude geometry.
- Read current official Creator Hub docs for unfamiliar properties and record the links in `INTERFACE.md`.
- Prefer actual edit-mode Studio inspection and screenshots. Offline renderers are approximate diagnostics, never evidence of engine rendering.
- Write scripts only to project files on disk. The user syncs them with Rojo. Do not create or replace script sources through MCP or copy source directly into Studio.
- Do not run Play or start Rojo serve unless the user requests it. Existing Edit-mode previews are for inspection; project files are the source of truth.
- Never claim the design matches the concepts based only on compilation or property checks. Inspect the visible result, text, border thickness, avatar framing, spacing, clipping and layering.
- Upload with `python3 tools/ui-art/upload_assets.py`, which uses Tungsten and validates all nine IDs before replacing the runtime map. The configured uploader is Roblox user `290622415`; the place is group-owned, but group-targeted uploads returned 403. Do not change the creator solely to match the place. Credentials stay in ignored `.env`, never code, docs, logs, or commits.
- Push this project as **InkBot01**, never `isaacalazar`. Verify `gh api user` before pushing; use the gh credential helper explicitly and author commits with `InkBot01 <68454447+Inkbot01@users.noreply.github.com>`. The remote is `Inkbot01/cloverboyz`.
- Update `INTERFACE.md` and `docs/ui/DECISIONS.md` when behavior or the asset pipeline changes. Preserve honest limitations and verification results so later sessions do not confuse concept art with engine screenshots.

## Official references

- https://create.roblox.com/docs/ui/positioning-and-sizing
- https://create.roblox.com/docs/ui/list-flex-layouts
- https://create.roblox.com/docs/ui/size-modifiers
- https://create.roblox.com/docs/ui/9-slice
- https://create.roblox.com/docs/reference/engine/classes/ScreenGui
- https://create.roblox.com/docs/reference/engine/classes/CoreGui
- https://create.roblox.com/docs/reference/engine/classes/ViewportFrame
