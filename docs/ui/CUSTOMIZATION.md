# Character customization

Open **M → Customize** (the compact button reads **Edit**), or call `Interface.Open("Customization")`. The editor uses Fusion and native Roblox instances. It shares the HUD's imported brass frame, parchment type, charcoal surfaces, and clover artwork.

## Composition

The reference is GPO's character-centered editor: selectors at the left, an avatar in the middle, and appearance colors at the right. [The reference image](https://devforum-uploads.s3.dualstack.us-east-2.amazonaws.com/uploads/original/4X/4/4/3/443a3bce3d789bdedf25cc7111cd3e2da2859517.jpeg) informed the arrangement, not the game's branding or monetization.

The desktop window has a maximum size of 1280 × 760 canvas units. Side columns are 276 units each; a native flex item gives the remaining width to the character. Body/Face views and 45-degree rotation buttons stay with the preview. Labels and selector values have separate rows; color choices use a four-column `UIGridLayout`. One illustrated outer border contains the window. Controls use restrained hover and selection states rather than repeated ornamental boxes.

Under 1000 canvas units, appearance and color panels share tabs. Under 600, the avatar sits above the scrollable controls. Native constraints, lists, padding, and scrolling own placement. The global interface scale is inherited from the same safe-area measurement as the HUD.

## Available options

The editor starts with a complete game character. It does not offer account-avatar placeholders, Roblox smile/blank faces, training primitives, or Base color swatches.

| Field | Accepted values | Behavior |
| --- | --- | --- |
| `Gender` | `male`, `female` | Apply the inspected custom torso shape and matching outfit fit. |
| `Hair` | `iron_spikes`, `wind_swept`, `ember_ponytail` | Published v2 hairstyles fitted to the custom heads. |
| `Face` | `determined` | Emerald Resolve pixel face. Arrows are disabled until another real face is available. |
| `Outfit` | `ink_knight`, `forest_initiate` | Black Bulls and Golden Dawn squad outfits respectively. Stable internal IDs are retained. |
| `Accessories` | `hidden`, `headband`, `grimoire`, `knight_set` | None, headband, grimoire, or headband plus grimoire. The old mantle is not included; squad robes are part of the outfit. |
| `SkinTone` | `porcelain`, `sand`, `warm`, `amber`, `copper`, `umber`, `ebony` | Explicit body colors. |
| `HairColor` | `ink`, `chestnut`, `auburn`, `wheat`, `silver`, `sage`, `plum` | Explicit hair colors. |
| `Scale` | Finite number from `0.9` to `1.1` | Absolute model scale; UI steps by 5%. |

Defaults are Male, Iron Spikes, Emerald Resolve, Black Bulls, no extra accessories, warm skin, silver hair, and 100% size. Removed option IDs are rejected by validation. The removed `OutfitColor` field is ignored; authored squad fabrics and trim keep their intended palette. Changing gender preserves all other choices. No persistent save or race-roll system is supplied.

## Imported starter pack ? October 8, 2026

The pack is published and selectable. `ReplicatedStorage.Shared.Assets.CustomizationTemplates` contains ten models and 26 MeshParts; `CustomizationImages` contains the face ID. `published.json` records genuine Studio import results and `fitting.json` records body-relative fitting data. `CharacterCosmetics` clones and welds each piece to the appropriate body part, removes conflicting original clothing, and hides covered torso/legs. Hair uses the selected explicit color. Outfit fabrics and trim retain their authored squad palette.

The measured rigs have a 2 ? 2 ? 1 torso, 1 ? 2 ? 1 limbs, and a 1.25 ? 1 ? 1.05 head. Female fitting recognizes torso CharacterMesh 48112070 or `CosmeticBodyFit = "female"`. Other rig types have not been fitted. Always apply the renderer to a fresh disposable clone, as it removes source appearance instances.

`CustomizationShowcase` is an Edit-mode-only helper that builds four dressed copies under `Workspace.CloverCustomizationShowcase`, leaving the original rigs untouched. Its source is synced through Rojo. Invoke it from Studio with the two original rigs present to rebuild the display.

## Preview and save behavior

- Every appearance edit affects a scoped clone in a `WorldModel`, never the actual character.
- **Reset** returns the draft to the last accepted appearance. Closing without saving discards the draft when the editor is reopened.
- In Studio preview, **Use preview** remembers the selection for this UI session and closes the editor. It does not change the world avatar, HUD portrait, or player profile. Reopening restores the selection.
- In live mode, **Save appearance** is disabled until a `SaveAppearance` handler is configured. The other controls remain available for preview.
- During a save, edits and repeated saves are blocked. A failed request leaves the draft editable, displays a message, and emits a notification. An accepted response replaces the draft with the server's returned appearance.
- `SetAppearance` invalidates any older in-flight save. A response after interface cleanup is ignored.

## Gameplay integration

The UI supplies a client contract, not a persistence or entitlement system. No profile fields, remotes, paid rolls, or server cosmetic grants were added.

```luau
local Interface = require(script.Parent.Interface)

Interface.SetAppearance({
    Gender = "female",
    Hair = "ember_ponytail",
    Face = "determined",
    Outfit = "ink_knight",
    SkinTone = "warm",
    HairColor = "silver",
    Accessories = "hidden",
    Scale = 1,
})

Interface.Configure({
    SaveAppearance = function(draft)
        return AppearanceClient.RequestSave(draft)
    end,
})
```

`AppearanceClient` in the example represents your game's server-backed adapter, not a module included here. Its handler returns `true, authoritativeAppearance` on success or `false, playerFacingMessage` on failure. Return the complete accepted appearance so normalization or rejected individual choices are reflected accurately. The frozen draft is an untrusted request: the server must validate the catalog, ownership, scale, unlocks, and request rate, persist the accepted state, and apply the resulting appearance to the character. Feed replicated changes back through `Interface.SetAppearance`.

`SetAppearance` can run before `OnStart`. Later calls merge validated partial snapshots and reset the local draft. Other data continues through `Interface.SetData`.

## Implementation map

| File under `src/client/Interface/` | Responsibility |
| --- | --- |
| `AppearanceModel.luau` | Frozen option definitions, defaults, immutable validation and cycling. |
| `AvatarAppearance.luau` | Apply a validated selection to a disposable character clone. |
| `CharacterRig.luau` | Apply the inspected custom male/female torso definition to the disposable clone. |
| `CharacterCosmetics.luau` | Fit and weld published hair, segmented outfits, and accessories. |
| `CustomizationShowcase.luau` | Rebuild the four Edit-mode display rigs. |
| `CustomizationSession.luau` | Draft/saved state, reset, saves, busy state, stale responses, cleanup. |
| `Customization.luau` | Window, selectors, palettes, avatar controls, responsive composition. |
| `Components.luau` | ViewportFrame, camera, WorldModel, framing, orbit, clone cleanup. |
| `CharacterWindow.luau` | Select the customization overlay or existing character pages. |
| `MenuFlyout.luau` | Entry point and quest guidance toggle. |
| `init.luau` / `StudioPreview.luau` | Runtime and Edit-mode controllers using the same views. |

The current preview clone removes scripts, Tools, particle effects, lights, and highlights; all parts are anchored and non-colliding. Camera framing follows the original character's bounds so changing size remains visible. `ViewportFrame.CurrentCamera`, Camera, and WorldModel share one scoped owner.

## Verification

Run `lune run tools/check_interface`, StyLua, and a Rojo build. The local checks include malformed appearance payloads, immutable saved state, selector wrapping, and layouts with the menu open and closed. Native Edit-mode checks verified skin/clothing color, classic face, scale, rotation, unchanged source avatar, reset/save/reopen, authoritative saves, stale-response rejection, and failed-save recovery. Native text bounds showed no visible horizontal overflow in the desktop customization window.

MCP screenshot capture timed out during this revision. Mobile visual review, dynamic-head appearance behavior, and persistent server integration still require game-side review; do not treat the checks as a visual sign-off.

October 8 integration: all 68 content fetch callbacks for the four dressed mannequins succeeded. Actual Studio front/back views and a desktop Customize preview were inspected; uploaded outfits, hair, face, palette and accessories rendered. The female Ember Knight selection appeared in the UI WorldModel. Template checks, 521 interface checks, StyLua and Rojo build passed. Walking/combat animation fit, mobile review and persistent saves remain unverified/unimplemented; no Play session was started.

## Hair fit and gender correction ? October 8, 2026

The user rejected the first hair fit. Earlier wide Studio views did not reveal exposed square-head corners; they were insufficient for fit approval. All three hair meshes were rebuilt with a continuous cap around the measured 1.25 ? 1 ? 1.05 head, shorter spikes, connected fringe and temple coverage. `assets/interface/customization/v2/` contains the Blender source, FBX, exact fitting data and three replacement published IDs. Stable catalog IDs now resolve to these new meshes.

Gender is the first appearance selector. Current rig preserves the supplied source; Male and Female apply the inspected torso definition while preserving hair, colors, clothing and accessories. The two source rigs have identical body dimensions and differ by torso CharacterMesh. The existing draft/reset/save contract now includes Gender; this does not implement server persistence or alter the actual player character.

Checks: 30 Blender corner-coverage rays, 12 native combinations of gender/hair/outfit, 526 interface checks, template validation, StyLua and Rojo build passed. All 52 template content-fetch callbacks succeeded. Close desktop views of all three hairstyles were inspected; male Iron Spikes and female Wind Swept screenshot evidence is under `output/ui-previews/hair-v2/`. Original Workspace rigs remain unchanged. Animation and mobile visual review remain outstanding.

## Squad uniforms and catalog cleanup ? October 8, 2026

This supersedes the earlier original/current-rig and training-clothes options. The user rejected the generic tunics and placeholder choices. The Black Bulls set now has an asymmetric short black robe, gold edging, bull skull insignia, layered undershirt/vest, broad leather belt and taller boots. Golden Dawn has a wine-red uniform, white panels/trousers, cream-and-blue long cape, raised collar, gold buttons, shoulder badge, diagonal strap and boot trim. Both use five rigid body segments and separate male/female torso fits.

Official visual reference: [Sword of the Wizard King character art](https://bclover-movie.jp/character/). Sources and URLs are recorded in `assets/interface/customization/v3/references.json`; the meshes are blocky adaptations, not exact replicas of the illustrations. Source Blender, combined FBX, palette, fitting metadata and 20 genuine published mesh IDs are in v3. Runtime template building applies v2 hair followed by v3 outfits over the starter pack.

Verification: 561 interface checks, 10-template/26-part checks, native 12 gender/hair/outfit combinations, 52 successful content fetch callbacks and no placeholder labels or selector overflow. Wide desktop and a native 700x1000 safe-area preview were inspected; screenshots are under `output/ui-previews/squad-v3/`. The display rigs were rebuilt with the new outfits. No Play session was started. Cape deformation and combat animation fit remain unverified; the capes are rigid.
