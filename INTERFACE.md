# Clover interface

The HUD, expandable menu, Stats, Grimoire, Equipment, and Customization screens use Fusion 0.3.0. `Client.Interface` starts through the existing client loader. Rojo includes the modules automatically. Artwork now uses imported image assets. No changes to the profile schema are required.

`StudioPreview.luau` mounts the same Fusion views in isolated CoreGui screens for Edit-mode review. All script changes now go to project files on disk, never through MCP source writes. The user controls their own Rojo session and Play testing.

## Controls

- **M** or the **Menu** button expands or collapses the flyout above the status HUD. Its top row has **Stats**, **Grimoire**, and **Items**; its utility row has **Customize** and the **Guide** compass toggle. Choosing a page closes the flyout. The old G and B page shortcuts are removed.
- **Guide** switches quest guidance on or off. When enabled, a world marker and a bearing indicator on the top compass point toward the active quest destination. Changing the quest updates the destination; clearing it hides the marker.
- **1–5** or a hotbar click selects an ability. Studio preview shows sample cooldowns.
- **+** stages an attribute point. **Undo** clears the staged allocation; **Apply** confirms it.
- **Gamepad Y** toggles the menu and **Gamepad B** closes the menu or current page. Buttons support GUI selection and activation.
- In Grimoire, select a spell, choose slot **2**, **3**, or **4**, and select **Assign Spell**. A spell can occupy one slot at a time. **Remove from Hotbar** clears its binding. Locked spells can be inspected but cannot be assigned.
- In Equipment, search and filter the inventory, inspect item bonuses against the same equipped slot, and use **Equip Item** or **Unequip**. Equipped items have an **E** marker. Materials and items above your level cannot be equipped.
- Inventory search, category filters, selected records, and pending stat points survive tab changes. The close button and a click outside the panel also close the window.

## Preview and live data

`Interface/Config.luau` enables preview data only in Studio. This supplies sample mana, stamina, XP, currency, attributes, spells, and inventory. Allocations and loadout changes in preview change local UI state and do not save. Set `PreviewInStudio` to `false` to review the unconfigured live state. Set `OpenStatsOnStart` to `true` to open the window immediately; `StartPage` chooses `"Stats"`, `"Grimoire"`, `"Equipment"`, or `"Customization"`.

Health always follows the character's Humanoid, including changes to maximum health and respawns. The portraits display clones of the actual player avatar. The compass follows the camera. The world, avatar clothing, and abilities shown in the concept artwork are not included as game assets.

Outside Studio, missing progression data and collections start at zero or empty. This module provides UI and local previews, not a persistent inventory, stat system, combat rules, or server remotes. Live allocation, spell binding, and equipment changes remain unavailable until their server-backed handlers are configured. Equipping an item in preview updates its UI slot and the weapon hotbar entry; it does not dress the avatar, grant a Tool, or recalculate combat stats.

## Integration

Other client modules can `require(script.Parent.Interface)` and use:

| Method | Purpose |
| --- | --- |
| `SetData(patch)` | Merge a snapshot from your authoritative client data adapter. Safe before the interface starts. |
| `Configure(handlers)` | Connect `AllocatePoints`, `ActivateSlot`, `BindSpell`, `EquipItem`, and `SaveAppearance` handlers. |
| `SetAppearance(patch)` | Merge an authoritative appearance snapshot, invalidate any older pending save, and refresh the editor. Safe before startup. |
| `SetCooldown(slot, seconds)` | Set or clear a slot cooldown; zero clears it. |
| `Open(page?)`, `Close()` | Open `"Stats"` (default), `"Grimoire"`, `"Equipment"`, or `"Customization"`, or close the window. |
| `Destroy()` | Disconnect listeners and destroy the Fusion scope. |

`SetData` accepts `Name`, `Level`, `XP`, `XPToNext`, `Health`, `MaxHealth`, `Mana`, `MaxMana`, `Stamina`, `MaxStamina`, `Coins`, `Gems`, `UnspentPoints`, `MagicPower`, `Rank`, `Squad`, `Location`, `SafeZone`, `Attributes`, `Quest`, `Hotbar`, `Grimoire`, `Spells`, `SpellSlots`, `Inventory`, and `Equipped`. Humanoid events remain the normal owner of the two health fields. Only changed field values are published to Fusion so health changes do not reconstruct the inventory and spell lists.

`Attributes` is a partial table with `Vitality`, `Strength`, `Magic`, and `Defense`. An attribute or available-points update clears any pending allocation so the UI cannot apply a stale selection.

`Quest` is `{ Title = string, Objective = string, Distance = number?, TargetPosition = Vector3? }`. Supply the actual destination through `TargetPosition` to enable guidance. A new quest replaces the previous destination; pass `Quest = false` to clear it. Guidance calculates distance in studs from the player and bearing from the camera. There is no quest system in this repository supplying those destinations yet; Studio preview uses a sample position. The compass reports a missing destination instead of inventing one in live gameplay.

`Hotbar` contains up to five entries `{ Name = string, Icon = string, Color = string }`, indexed by slot number. Icon names come from `Assets.luau`; color names come from `Theme.luau`. Neither health nor other game resources are modified by activating a preview ability.

`AllocatePoints(allocation)` receives a table of attribute increments and can yield while requesting server validation. Return `true, snapshotPatch` on success, or `false, message` on failure. The production UI never awards attributes optimistically: it waits for the authoritative snapshot or later `SetData` call. The server must validate the request and own all persistent writes. An older response cannot replace attributes received during the request.

`ActivateSlot(slot)` receives a slot number. It is responsible for the game's ability or equipment action; call `SetCooldown` when gameplay accepts the action. The built-in Roblox backpack is left available until your gameplay integration replaces it.

`BindSpell(spellId, slot)` requests an assignment to slot 2–4. A slot value of `0` requests removal of that spell from the hotbar. `EquipItem(itemId, equipping)` requests equip when the boolean is true, and unequip when false. Both handlers can yield and return `true, snapshotPatch` or `false, message`, just like allocation. They must validate ownership, unlocks, level requirements, and slot rules on the server. Send only the changed authoritative fields in the response. A newer replicated collection update takes precedence over an older request response.

`SaveAppearance(draft)` receives a frozen appearance draft and returns `true, authoritativeAppearance` or `false, message`. It can yield. Live saving is disabled until this handler exists; the UI never writes profiles or changes the world avatar. [Customization integration](docs/ui/CUSTOMIZATION.md) documents the schema, available controls, preview behavior, and server responsibilities.

Collection payloads are:

| Field | Shape |
| --- | --- |
| `Grimoire` | Partial `{ Name, Affinity, Leaves, Mastery, XP, XPToNext }` |
| `Spells` | Complete array of `{ Id, Name, Description, Icon, Color, LevelRequired, Learned, ManaCost, Cooldown, Type }` |
| `SpellSlots` | Complete map of slot numbers 2–4 to spell IDs |
| `Inventory` | Complete array of `{ Id, Name, Description, Icon, Color, Category, Rarity, LevelRequired, Count, Bonuses }` |
| `Equipped` | Complete map `{ Weapon = itemId, Armor = itemId, Accessory = itemId }` |

Inventory categories are `Weapons`, `Armor`, `Accessories`, and `Materials`; the corresponding equipment slot is derived from the category. Rarities are `Common`, `Uncommon`, `Rare`, `Epic`, and `Legendary`. `Bonuses` is a table of numeric `Vitality`, `Strength`, `Magic`, and `Defense` values. Record IDs must be unique, nonempty strings of at most 64 bytes. Collections are capped at 300 records for this UI. Empty arrays/maps clear a collection. Update `Hotbar` with the corresponding `SpellSlots` or weapon changes so the authoritative HUD and loadout agree.

Existing `Notifications.OnNotification` events appear as styled notifications. Component colors, fonts, and timings are centralized in `Theme.luau`. Icons are native ImageLabels using an illustrated atlas. Frames use imported nine-slice fills and trims. Published asset IDs and Roblox moderation are required for the live game.

## Construction and review

`UIListLayout` owns the HUD docks, menu row, resources, attribute rows and footer. `UIGridLayout` owns collection grids and the combat overview. `UIPadding` owns content insets, and `UIFlexItem` distributes available space. Artwork remains outside content layout containers.

The unscaled safe-area frame measures the viewport. Its child canvas uses one native `UIScale` against a 1440-unit desktop design width. This avoids a measurement feedback loop on high-density displays. The current user revision enlarges the status block to 520 × 250 and ability buttons to 88 × 88, moves menus and currency above the left status block, enlarges the compass to 480 × 126, and moves the 400 × 160 quest card to middle-left. Native layout separates the larger status and ability areas. A half-height quest dock with a UISizeConstraint reserves a 24-unit gap above the bottom dock, including the expanded menu; on very short viewports it hides the card. Resource labels and values share a row above each full-width meter. Currency uses 144 × 42 and 120 × 42 plaques with separate icon and amount cells. The expanded desktop menu uses a 480 × 236 design footprint within the scaled HUD: one outer frame, a centered three-button page row, a divider, and a utility row. Icons and labels have their own space; idle page buttons have no nested trim. Its compact version is 236 × 124. On short landscape touch screens, the flyout moves beside the status column or above the abilities, using native lists, so health and the menu remain visible. The village name and safe-zone status sit on a dedicated backing. Touch layouts retain targets of at least 44 units and stack the docks at narrow widths.

Stats follows the original `output/ui-concepts/stats-concept-v1.png`: full-body profile, quiet row separators, illustrated attribute icons, and emerald focus states. The desktop window uses `Size = UDim2.fromScale(0.70, 0.80)`, a native `UIAspectRatioConstraint` of `10/7`, and a centered anchor at 48% screen height. There is no fixed pixel modal size or maximum. The constraint fits the whole window within those proportions. Touch uses a flexible 94% × 90% safe-area window and scrolls the body. Header, tabs, body and footer flow through native lists and flex items; larger 20–24 point body text uses SourceSansSemibold/Bold, with Arcade reserved for headings. Selected tabs use a filled state instead of an underline. Customization similarly uses proportional screen bounds and a desktop `32/19` aspect constraint. Reset Points clears only staged points, not saved attributes.

The HUD now shares the quest card's warm brown grimoire cover, tiled material and vertical shading across resources, slots, currency, compass and menu. Button surfaces tween on hover/focus and press/release using the shared `Motion.Button`; mouse, touch and gamepad activation share the same enabled guard. `Motion.Presence` drives short Fusion window/page fades and a small relative slide. Main windows remain visible until their closing tween ends, and tab changes fade the page without reopening the outer window. Buttons retain stable hit-target geometry.

A ViewportFrame owns its Camera and WorldModel. Its scoped clone strips executable code and effects, disables physics, and resolves accessory welds in Edit mode before framing the complete character. The avatar is the player's actual model, not the illustrated character from the concept.

Production hierarchy: `PlayerGui > CloverInterface > SafeArea > Canvas > HUD / CharacterOverlay / CustomizationOverlay`. The character and customization overlays are mutually exclusive. Navigation uses a separate `CloverNavigation` screen. Both use sibling Z ordering and device-safe clipping. Quest guidance uses a scoped BillboardGui in PlayerGui adorning a scoped Attachment under Terrain. The preview uses the same screen hierarchy under CoreGui with names ending in `Preview` and cleans up when Play starts. Close a character page with its X button; the menu buttons reopen it. The preview's Control BindableFunction supports `HUD`, `Menu`, `Navigation`, `Page`, `Stage`, `Undo`, `Apply`, and `Destroy` for inspection.

## Artwork import

The nine PNG files in `assets/interface/exports/` have been uploaded through Tungsten. `assets/interface/manifest.json` records the actual atlas rectangles and nine-slice margins. The rectangles follow visible artwork bounds so icons remain centered; the generated sheet is not assumed to be a perfectly uniform grid. The v2 frame and meter textures use carved clover ornaments, layered metal rails, and preserved corner regions. Native nine-slice scaling stretches only the middle bands. Trim renders above its contents; its interior margins protect text, icons and resource fills. The built-in image generation prompts and provenance are in `assets/interface/ornate-v2-prompts.json`. The original renders remain beside the exported assets; obsolete border exports are archived. The grimoire-cover material uses a tiled ImageLabel with a subdued theme tint and native vertical UIGradient. Its source and built-in imagegen prompt are in `grimoire-leather-v1-source.png` and `surface-v1-prompt.json`. The compass icon has its own transparent export and `compass-v1-prompt.json` records its generation prompt. Decoration and content remain separate siblings so trim sits above icons and meter fills. Small controls use smaller corner scales to preserve their content area.

`src/shared/Assets/UI.luau` maps all nine export stems to published `rbxassetid://...` image URIs. Tungsten uploaded them on October 4, 2026, using the original configured Roblox user `290622415`. The connected place is owned by group `266869898`; attempting group-targeted uploads with this credential returned 403. The user-targeted uploads succeeded. Keep the configured creator unless a deliberate asset-ownership migration is requested, and verify fetch/moderation results in the target place. The earlier public thumbnail check showed eight assets pending. A later native cloud-only preview successfully loaded every visible image in Stats and the HUD; the published atlas was also opened as an EditableImage and measured at 1024 × 1024. Keep API credentials local.

Publish with `python3 tools/ui-art/upload_assets.py`. The wrapper invokes `tungsten sync cloud`, redacts credentials from process output, validates all nine expected IDs in `tmp/tungsten/UI.luau`, and atomically replaces the runtime map only when complete. Tungsten can exit successfully after individual upload errors, so use the wrapper for publishing. Commit the map and `tungsten.lock.toml` together. `.env`, transfer buffers, and upload staging stay ignored.

For Studio testing, `src/shared/Assets/StudioImages/` contains 24 compressed images in 83 modules, including the atlas's 16 cropped icons. Rojo includes these automatically. Its loader reconstructs native EditableImages only in Studio. `Config.UseStudioArtwork = false` now defaults to the verified published assets in Studio. Set it to `true` only for an offline/local artwork check. Outside Studio, the interface always uses the published IDs. This supports user-run Play tests without cloud upload credentials. The temporary Edit-mode image store under `CoreGui.CloverDesignPreviewKit.EditorImages` remains an optional preview source. Neither route replaces asset publishing for release. Tungsten is a development CLI; the game does not require it. Large fallback payloads are split into source modules of at most 60,000 encoded characters; this repaired the three large modules that failed native loading in the previous bundle. Roblox caches required modules per Luau environment, so Rojo Source updates alone do not refresh an already required view. `StudioPreviewSession.luau`, invoked from plugin/command-bar context after Rojo sync, reads and evaluates the synced view modules in an isolated module cache, refreshes the asset maps, and cleans up the previous preview. It performs no Source writes or Script/ModuleScript cloning and never runs in a published game. Packages and the local image pool remain shared. All edits still originate on disk.

Regenerate the Studio bundle after changing an export:

```sh
python3 tools/ui-art/prepare_preview_buffers.py
python3 tools/ui-art/build_studio_images.py
```

The atlas source is 1254 × 1254 while Roblox serves the uploaded texture at 1024 × 1024, verified through `CreateEditableImageAsync().Size`. The manifest keeps source rectangles for the local crops and `publishedSize` separately. Generate the production rectangle table with `python3 tools/ui-art/build_icon_atlas.py`; do not hand-edit `src/shared/Assets/IconAtlas.luau`. Each sprite is a stable holder with a centered ImageLabel and native `UIAspectRatioConstraint`. Only the published route uses atlas rectangles; local cropped EditableImages use their own dimensions. This prevents adjacent sprites or empty corners from leaking into a slot. Recheck delivered dimensions after replacing the atlas.

The preparation tool uses Pillow and the local Homebrew libzstd library.

## Verification

```sh
stylua --check src/client/Interface src/shared/Assets/StudioImages/init.luau tools/check_interface.luau
lune run tools/check_interface
rojo build -o /tmp/cloverboyz-ui.rbxlx
```

Lune runs local Luau checks; it is not the game's UI framework or a visual renderer. The 521 checks cover published-atlas bounds and disjoint crops, allocation bounds, immutable data, invalid values, sparse slots, spell binding, level gates, equipment, search, normalization, appearance choices, and responsive dimensions with the menu both open and closed. The matrix includes narrow portrait, short landscape touch, and high-density Studio viewports. Native controller checks also verified preview reset/save/reopen, authoritative saves, stale-response rejection, and failed-save recovery. Native Studio inspection is required for actual text bounds, image loading, parenting and rendering.

The old `tools/ui-preview` renderer and its Figma exports are historical drafts. They do not support the current imported artwork and are not visual evidence for this implementation. MCP capture_screenshot again returned only the world, omitting the visible CoreGui preview. The user's Studio captures remain the visual review evidence. Native text-bound and avatar checks passed for the desktop customization preview, but they are not a screenshot review. Do not claim visual sign-off from geometry checks alone.

## Roblox references

- [Native lists and flex layouts](https://create.roblox.com/docs/ui/list-flex-layouts)
- [Nine-slice image borders](https://create.roblox.com/docs/ui/9-slice)
- [Size modifiers](https://create.roblox.com/docs/ui/size-modifiers)
- [ScreenGui safe areas](https://create.roblox.com/docs/reference/engine/classes/ScreenGui)
- [ViewportFrame](https://create.roblox.com/docs/reference/engine/classes/ViewportFrame)
- [EditableImage](https://create.roblox.com/docs/reference/engine/classes/EditableImage)

- [ImageLabel tiling and slices](https://create.roblox.com/docs/reference/engine/classes/ImageLabel)
- [UIGradient](https://create.roblox.com/docs/reference/engine/classes/UIGradient)

- [Roblox module caching](https://create.roblox.com/docs/reference/engine/classes/ModuleScript)
- [Open Cloud asset uploads](https://create.roblox.com/docs/cloud/guides/usage-assets)
- [Tungsten](https://github.com/pwnwrkz/tungsten)

Latest native checks (October 4): published atlas delivery is 1024 × 1024; all five hotbar icons are centered and contained; Stats and menu had no visible text overflow at the connected viewport; all visible published images loaded. Opening/closing transitions produced intermediate opacity values and completed; input handlers passed mouse/touch press-release and disabled-activation checks. The larger initial 1080 × 820 top-docked trial was explicitly rejected and replaced by the proportional, aspect-constrained window above.

- [Aspect constraints](https://create.roblox.com/docs/reference/engine/classes/UIAspectRatioConstraint)
- [CanvasGroup](https://create.roblox.com/docs/reference/engine/classes/CanvasGroup)
- [Fusion tweens](https://elttob.uk/Fusion/0.3/api-reference/animation/types/tween/)

## Local character asset pack — October 4, 2026

`assets/interface/customization/v1/` contains editable Blender geometry, FBX and glTF exports, a shared palette, and a transparent pixel face. The pack has three hairstyles, two outfit designs with separate straight and tapered torso variants, a clover headband, a short mantle, and a grimoire satchel. The user's Workspace screenshot of `Male` and `Female` supplied the silhouette reference. The source rigs were not available: dimensions and female waist taper are estimates, not measured rig data.

Each outfit exports five rigid body segments. These are local game cosmetic meshes, not skinned/caged layered clothing. Hair and accessory exports have no attachment instances. Import, fit, attach, and inspect them against the actual rigs before adding them to `AppearanceModel`. The existing catalog and save contract remain unchanged. No cloud IDs or Studio verification are claimed.

Rebuild with Blender 4.4 in background mode using `tools/ui-art/build_customization_assets.py`; use `--factory-startup --python-exit-code 1 --python` before the script path. Verify with the same command and `tools/ui-art/check_customization_assets.py`. Keep each `.gltf` beside its `.bin` and palette PNG, or use the matching FBX with embedded texture. `exports/manifest.json` records categories, source coordinates, body segments, palette rectangles, triangle counts and fitting limits. `face-prompt.json` preserves the built-in image-generation prompt. The Blender source packs its images.

The separate mesh pack does not change the existing nine-image Tungsten uploader. Publishing and runtime integration remain separate work. Front/back PNGs are Blender geometry previews, not Studio screenshots. See `verification.json` for export checks and `IMPORT.txt` for fitting notes.

Local verification passed for all 20 FBX/glTF reimports, including part/triangle counts, finite vertices, nondegenerate faces, UV bounds, material presence, referenced files and preserved bounds. The face PNG is RGBA with transparent surroundings. Front/back Blender renders were visually inspected. Rojo build passed. The default StyLua check flagged existing CRLF line endings; `stylua --check --line-endings Windows --output-format summary src` passed without changing runtime files.

Official mesh references consulted for this pack:

- [Custom 3D assets and Studio import behavior](https://create.roblox.com/docs/art/modeling)
- [Importing FBX and glTF assets](https://create.roblox.com/docs/art/accessories/creating-rigid/importing)
- [Rigid accessory meshes and attachments](https://create.roblox.com/docs/avatar/rigid-accessories)


## Character pack imported ? October 8, 2026

This supersedes the October 4 local-only status above. The full pack is uploaded, synced into `ReplicatedStorage.Shared.Assets.CustomizationTemplates`, and registered in Customize. Four dressed copies of the actual Male/Female rigs are present under `Workspace.CloverCustomizationShowcase`. The originals were preserved. Appearance saving still uses the existing disabled-until-configured server adapter contract.

Studio's native FBX importer uploaded the combined `clover-customization-import.fbx` using its current `clova boyz` creator selection; the face used Studio MCP image upload. No Open Cloud key was needed. The nine-image Tungsten uploader and its configured creator were not changed. `published.json` records 26 mesh IDs, the shared palette ID and face ID. `AssetService:CreateAssetAsync` was unavailable in this Studio build, so it was not used.

Pipeline: Blender 4.4 runs `package_customization_import.py` to produce the combined import file and `export_customization_transfer.py` to derive `fitting.json`. Unhide collections and update Blender's dependency graph before reading transforms. After a native import, record its IDs/sizes in `published.json`; run `lune run tools/ui-art/build_customization_templates` to regenerate the Rojo model and image map. The importer used 100x geometry units. Templates retain native mesh dimensions as serialized `InitialSize` while normalizing visible `Size` to studs. Omitting that field caused huge rendered meshes even though `Size` was correct. Native `MeshSize` now matches the uploaded geometry. The FBX basis maps source coordinates to (-X, Z, Y), and attachment offsets account for it.

Measured custom rigs: torso 2x2x1, limbs 1x2x1, head 1.25x1x1.05. `CharacterCosmetics` fits relative to each body part and adds noncolliding, massless welded geometry. Female torso variants recognize CharacterMesh 48112070 or the explicit `CosmeticBodyFit` attribute. R15 and arbitrary custom rigs were not fitted. Preview application expects fresh clones.

Verification: 10 templates / 26 meshes validated; 521 interface checks and Rojo build passed. Studio content preloading completed 68 callbacks with no failures. Front/back mannequin views and the desktop customization WorldModel were visually inspected in Edit mode. Animation fit and mobile rendering remain unverified; no Play session was started. The raw 100x import is archived in ServerStorage, not rendered in Workspace.

References consulted during import:
- [AssetService](https://create.roblox.com/docs/reference/engine/classes/AssetService)
- [EditableMesh](https://create.roblox.com/docs/reference/engine/classes/EditableMesh)
- [MeshPart and MeshSize](https://create.roblox.com/docs/reference/engine/classes/MeshPart)
- [Blender export and import](https://create.roblox.com/docs/art/blender)


## Hair fit and gender correction ? October 8, 2026

The user rejected the first hair silhouettes and exposed head corners. Wide mannequin screenshots were inadequate fit evidence. Rebuilt all three hair meshes around the measured 1.25x1x1.05 head with continuous square-corner caps, shorter spikes and connected fringe/temples. The v2 Blender/FBX sources, fitting metadata and genuine replacement mesh IDs live in `assets/interface/customization/v2/`. `rebuild_customization_hair.py` includes 30 head-corner ray checks. `build_customization_templates.luau` overlays v2 meshes/fittings onto the unchanged outfit/accessory pack, preserving catalog IDs and native InitialSize metadata.

Added the first Customize selector, Gender: Current rig / Male / Female. Inspection confirmed the custom rigs have identical part sizes/offsets and differ by torso CharacterMesh 48112070. `CharacterRig` changes that definition only on disposable preview clones, sets the fitting attribute and automatically selects the corresponding outfit variant. Other appearance choices remain selected. Gender participates in draft validation, reset and the existing save adapter contract; persistent saving remains unimplemented.

Native verification exercised all 12 gender/hair/outfit combinations and confirmed the torso, cosmetic welds, outfit variant and unchanged originals. All 52 template fetch callbacks succeeded. Close desktop hair views were inspected; evidence is in `output/ui-previews/hair-v2/`. 526 interface checks, template checks, StyLua and Rojo build passed. No Play session or game publication occurred. Animation and mobile visual review remain outstanding.


## Squad uniforms and real catalog choices ? October 8, 2026

Removed Current rig, Your hairstyle/expression/outfit, Original/Base colors, built-in smile/blank face, training clothes and source-avatar accessory toggles from the production catalog. Male/Female, actual imported assets and explicit colors now define every default. None remains a deliberate accessory choice. Single-choice expressions disable their arrows. The ineffective clothing color palette was removed; squad palettes remain authored. Existing internal outfit IDs map to Black Bulls (`ink_knight`) and Golden Dawn (`forest_initiate`). Old IDs/fields are rejected rather than revived in the interface.

Replaced all 20 outfit MeshParts with v3 squad designs informed by the official [film character artwork](https://bclover-movie.jp/character/). Black Bulls uses an asymmetric black/gold short robe and horned skull badge. Golden Dawn uses red/white tailoring, a long cream/blue cape, raised collar, shoulder insignia and diagonal strap. Both have separate female fits. These are blocky adaptations rather than exact illustration replicas. The capes are rigid torso geometry; walking/combat deformation is unverified.

`build_squad_outfits.py` produces the v3 Blender/FBX, 16-color palette and fitting data. Studio's regular importer published 20 meshes and palette 103727090592936; actual IDs are in v3/published.json. The template builder applies revisions in order (v2 hair, v3 outfits), preserving InitialSize. The existing Tungsten UI uploader is unchanged. Optional mantle geometry is retained in the library but removed from the menu and accessory combination to avoid duplicating the squad robes.

Verified 561 interface checks, the 10-template/26-mesh model, all 12 native gender/hair/outfit combinations, and 52 content fetch callbacks with no failures. Desktop and native 700x1000 safe-area inspection found no removed placeholder labels or selector text overflow. Screenshots are under `output/ui-previews/squad-v3/`. StyLua and Rojo build passed. No Play session, persistence implementation or place publication occurred.
