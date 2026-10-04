# Interface memory

Updated October 4, 2026. Read this with `AGENTS.md` and `INTERFACE.md` before changing the UI.

## User's visual direction

The approved references are [HUD concept v1](../../output/ui-concepts/hud-concept-v1.png) and [Stats concept v1](../../output/ui-concepts/stats-concept-v1.png). They establish a pixel Black Clover RPG: readable parchment lettering, ink-dark panels, illustrated antique metal, clovers, and emerald accents. Pixel Piece supplied the initial compact RPG HUD reference. Later Histrovarius references asked for richer carved frame corners and metal edging.

Repeated feedback rejected oversized early HUDs, later undersized text, accidental centered positioning, cramped controls, synthetic thin borders, flat black-blue fills, and previews that differed from Roblox. The most recent direction enlarges resources and abilities, puts menus/currency above the left HUD, and places a larger quest card at middle-left. These revisions supersede menu placement in the first concept.

## Current decisions

- Keep Fusion 0.3 and native Roblox layout objects. Imported imagery supplies decoration; native instances supply dynamic text, bars, controls, and hierarchy. Do not recreate the UI as a flattened image or an offline web layout.
- HUD status is 520 × 250 at desktop design scale, abilities are 88 × 88, compass is 480 × 126, and quest card is 400 × 160. A single unscaled safe-area measurement drives canvas scale.
- **M** toggles the menu. Remove the old G/B shortcuts. Page choices are Stats, Grimoire, and Items. Customize and Guide sit in a separate utility row. Guide uses a compass and ON/OFF indicator.
- The cleaned menu uses a 480 × 236 footprint in the scaled HUD with one illustrated outer border, centered unboxed page buttons, 20-unit padding, a quiet divider, and a subdued charcoal material. It replaces four ornate cards jammed inside another ornate frame.
- Stats uses 70% × 80% screen bounds, a native 10:7 aspect constraint, and a center at 48% screen height. No fixed pixel screen dimensions. The user rejected the oversized top-docked trial. Preserve readable text while keeping the window close to the original footprint. Touch allows flexible height. Active tabs use filled selection, not underlines.
- Shared Fusion motion adds window/page entry and exit, hover/focus, and press/release feedback. Keep button geometry stable.
- Match the quest card's warm grimoire surface on HUD resources, ability slots, currency, compass and menu.
- Compact menu is 236 × 124. Short landscape screens move it beside the status column or above the ability row instead of moving health offscreen. Small portrait screens stack docks. Native lists perform the placement.
- Customization uses GPO's central-avatar/side-selector composition with the Clover art direction. It offers working choices for the current avatar, training clothes, palettes, size, camera orbit, and face/body framing. See [its contract and catalog](CUSTOMIZATION.md). Bespoke hairstyles/outfits and persistent saves are separate game systems.
- A server-backed handler must accept any live allocation, spell binding, equipment, or appearance save. Studio sample changes are explicitly local. Never label preview behavior as a persistent game feature.

## Assets and tools

Tungsten `3.1.1` is pinned through Rokit. `assets/interface/exports/` has the nine production PNGs; `manifest.json` records crop rectangles and slice margins. Original art and generation prompts are retained beside the exports. `src/shared/Assets/UI.luau` and `tungsten.lock.toml` contain the successful upload results.

Upload with `python3 tools/ui-art/upload_assets.py`. It runs Tungsten, checks completeness despite Tungsten's sometimes-successful exit status on failed uploads, and preserves previous IDs on failure. Staging lives under ignored `tmp/`. Credentials belong only in ignored `.env` and must never appear in the repository or terminal output.

The place is group `266869898`. Group-targeted uploads returned 403; the repository's original configured user `290622415` successfully uploaded all nine images. Keep that user in `tungsten.toml` unless the owner requests a migration. Upload success and visual/moderation approval are separate checks. An earlier thumbnail check had eight pending images. The later cloud-only native HUD/Stats preview loaded every visible image successfully.

For Studio without cloud access, 24 fallback images are bundled in 83 small modules. Large encoded payloads are split into chunks of at most 60,000 characters, which resolved native loading errors for the three largest textures. Regenerate with the two commands in `INTERFACE.md`. `Config.UseStudioArtwork` now defaults to false after the published images loaded in Studio. Set it to true only for local/offline checks. Published-game clients always use the uploaded IDs.

Figma exports and `tools/ui-preview/` are historical drafts. They cannot prove native alignment or image rendering. Do not publish their obsolete screenshots as the current UI. Approved concepts remain useful art direction, not implementation screenshots.

## Verification and current limits

- 521 local checks pass, including menu-open and menu-closed size cases, short touch screens, appearance validation, and existing progression/loadout rules.
- Native Edit-mode checks passed for draft color/face/scale changes, rotation, source-avatar preservation, reset/save/reopen, accepted and rejected save requests, and newer replication overriding stale responses.
- Desktop customization had no visible horizontal text-bound overflow during native inspection.
- Rojo build and StyLua checks are required before delivery. Do not run Play or start serve without a new request; the user runs those.
- MCP capture_screenshot returned the world without CoreGui. The user's latest screenshots show the corrected icons; full visual approval is still outstanding. Do not equate native property checks with matching the approved artwork.
- ModuleScript results are cached per Luau environment. Rojo source updates alone do not refresh a previously required Edit-mode view. A fresh user-run Play session loads the latest disk code. For Edit mode, `StudioPreviewSession` compiles the existing Rojo-synced view modules in an isolated require cache and remounts the preview; it never writes Source or clones scripts. Never work around caching by writing or cloning script sources through MCP.

## Collaboration and delivery

Write all scripts to disk. The user handles Rojo. MCP may inspect instances and invoke existing synced preview modules; no MCP Source writes. The Edit-mode CoreGui preview is isolated and removable, and production UI lives in PlayerGui.

GitHub must be **InkBot01**, never `isaacalazar`. Origin is `https://github.com/Inkbot01/cloverboyz.git`. Verify the active gh identity, author as `InkBot01 <68454447+Inkbot01@users.noreply.github.com>`, and push with the gh credential helper explicitly. Ignore secrets, temporary transfer buffers, Python caches, and obsolete generated preview screenshots.

## Icon crop incident

Roblox resized the 1254 × 1254 source atlas to 1024 × 1024 on delivery. Source-coordinate crops caused the cut-off/neighboring icons and empty cells shown in the user screenshots. `manifest.json` retains original crop rectangles and the verified published size. `build_icon_atlas.py` generates production coordinates; all sixteen crops are bounded and disjoint. Native icon holders center an aspect-constrained ImageLabel inside the padded frame. No reupload was needed. Do not silently assume a source PNG retains its dimensions after publishing.
