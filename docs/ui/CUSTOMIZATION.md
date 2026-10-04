# Character customization

Open **M → Customize** (the compact button reads **Edit**), or call `Interface.Open("Customization")`. The editor uses Fusion and native Roblox instances. It shares the HUD's imported brass frame, parchment type, charcoal surfaces, and clover artwork.

## Composition

The reference is GPO's character-centered editor: selectors at the left, an avatar in the middle, and appearance colors at the right. [The reference image](https://devforum-uploads.s3.dualstack.us-east-2.amazonaws.com/uploads/original/4X/4/4/3/443a3bce3d789bdedf25cc7111cd3e2da2859517.jpeg) informed the arrangement, not the game's branding or monetization.

The desktop window has a maximum size of 1280 × 760 canvas units. Side columns are 276 units each; a native flex item gives the remaining width to the character. Body/Face views and 45-degree rotation buttons stay with the preview. Labels and selector values have separate rows; color choices use a four-column `UIGridLayout`. One illustrated outer border contains the window. Controls use restrained hover and selection states rather than repeated ornamental boxes.

Under 1000 canvas units, appearance and color panels share tabs. Under 600, the avatar sits above the scrollable controls. Native constraints, lists, padding, and scrolling own placement. The global interface scale is inherited from the same safe-area measurement as the HUD.

## Available options

The current catalog provides working controls using the actual avatar and built-in Roblox primitives. It does not include a licensed or bespoke catalog of anime hairstyles, faces, outfits, or races.

| Field | Accepted values | Behavior |
| --- | --- | --- |
| `Hair` | `original`, `none` | Keep the avatar's hairstyle or remove hair accessories from the preview. |
| `Face` | `original`, `classic`, `blank` | Keep the face, use Roblox's built-in smile decal, or remove front decals. |
| `Outfit` | `original`, `training` | Keep the outfit or show a simple colored torso with dark trousers. |
| `Accessories` | `visible`, `hidden` | Show or hide non-hair accessories. Training clothes also remove these accessories. |
| `SkinTone` | `original`, `porcelain`, `sand`, `warm`, `amber`, `copper`, `umber`, `ebony` | Recolor body parts and BodyColors on the clone. |
| `HairColor` | `original`, `ink`, `chestnut`, `auburn`, `wheat`, `silver`, `sage`, `plum` | Recolor hair; chosen colors remove mesh textures from the clone. |
| `OutfitColor` | `onyx`, `ivory`, `forest`, `wine`, `ocean`, `ochre`, `slate`, `violet` | Color the training torso. The UI explains this dependency. |
| `Scale` | Finite number from `0.9` to `1.1` | Absolute model scale. UI steps by 5%; received values round to 1%. |

Defaults preserve the avatar, use `onyx` for training clothes, and use scale `1`. Unknown fields and unknown option IDs are ignored. Invalid scale values, including NaN and infinity, are rejected. `original` means the source character supplied to the editor; restoring an account's original avatar after gameplay modifications requires the game's avatar service to provide that baseline. Decal face choices target classic heads; dynamic-head expressions need a dedicated catalog/renderer.

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
    Hair = "original",
    Face = "classic",
    Outfit = "training",
    SkinTone = "warm",
    HairColor = "silver",
    OutfitColor = "forest",
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
