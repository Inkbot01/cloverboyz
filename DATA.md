# Data

Everything the game stores that outlives a server, and the rules that keep it
intact. Read this before touching `src/server/Data/`, before adding a field to a
profile, and before writing to any DataStore.

The stack is a **profile** per player, session-locked by ProfileStore and
replicated by Replica. Every other durable store you add inherits the same
rules. The profile is the one you cannot afford to lose.

---

## 1. The two rules

**Rule 1 — every profile write goes through the replica.**

```luau
local replica = PlayerData.GetReplica(player)
if replica == nil or not replica:IsActive() then return end
replica:Set({ "Coins" }, 10)
```

`profile.Data` and the replica's `Data` are **the same table**. Writing
`profile.Data.Coins = 10` directly does persist — and fires no replication
event, so the client's copy never moves. The value is there; it just never left
the server.

**Rule 2 — nothing a client sends is ever a path, an index, or a key.**

A client names *what it wants done*, never *where*. Every path in every
`replica:Set` in this repo is a literal written by the server. A client-supplied
path segment is a whole-profile overwrite primitive. If client input must end
up as a key, look it up in a server-owned table first, and refuse when it is not
there.

---

## 2. The model

```
┌───────────────────────────── SERVER ──────────────────────────────┐
│  ProfileStore ── session-locked DataStore wrapper                  │
│      │  profile.Data                                               │
│      │  profile.LastSavedData  ← what actually reached the store   │
│      ▼                                                             │
│  ReplicaServer.New({ Token, Data = profile.Data, Tags })           │
│      │  private, subscribed to its owner only                      │
│      ▼                                                             │
│  ReplicaWrapper ── .Changed signal, SafeSubscribe, destroy guards   │
│      │                                                             │
│      ├──► PeekableData replica ── PUBLIC, :Replicate()'d to all     │
│      │      mirrors only the paths in Data/Peekable.luau            │
│      ▼                                                             │
│  Owning modules (one writer per field)                             │
└────────────────────────────────────────────────────────────────────┘
```

**Two replicas per player.**

| Replica | Token | Audience | Contents |
|---|---|---|---|
| `PlayerData` | `"PlayerData"` | its owner only | the whole profile |
| `PeekableData` | `"PeekableData"` | **everyone in the server** | only the paths in `Peekable.luau` — currently none |

Anything you add to `Peekable.luau` becomes readable by every player in the
server, forever, including the parts of that sub-tree you were not thinking
about.

### Server API (`src/server/Data/init.luau`)

| | |
|---|---|
| `PlayerData.GetReplica(player \| userId)` | the private wrapped replica, or nil |
| `PlayerData.GetPeekable(player \| userId)` | the public wrapped replica, or nil |
| `PlayerData.GetProfile(player \| userId)` | the raw ProfileStore profile |
| `PlayerData.Await(player)` | yields until the replica exists; nil if the player left |
| `PlayerData.IsLoaded(player)` | boolean |
| `PlayerData.OnSessionStart` | `Signal<Player, WrappedReplica>` |
| `PlayerData.OnSessionEnd` | `Signal<Player>` |

### Client API (`src/client/Data/init.luau`)

| | |
|---|---|
| `PlayerData.Await()` | yields until our replica arrives |
| `PlayerData.Get(path)` | reads a path off our data, nil if absent |
| `PlayerData.OnSet(path, fn(new, old))` | returns a disconnect; safe before the replica arrives |
| `PlayerData.OnChange(fn(action, path, ...))` | returns a disconnect; safe before the replica arrives |
| `PlayerData.GetPeekable(userId)` | any player's public replica |
| `PlayerData.OnPeekableAdded` / `OnPeekableRemoved` | `Signal<userId, Replica>` / `Signal<userId>` |

### What `replica:Set` actually does

It walks `pointer = pointer[path[i]]` for `i = 1..#path-1`, then assigns.
**A missing intermediate table throws.** A new leaf key under an existing
parent is fine. This is why every field a `Set` path passes *through* must exist
in the template — see §4, invariant 1.

### What `Profile:Save()` actually does

`task.spawn(SaveProfileAsync, self)`. It **returns before the write is
attempted**, so a `pcall` around it can never observe a failure. To know a write
landed, wait for the value to appear in `profile.LastSavedData`. Do this before
acknowledging anything that cost real money.

### Session loss

`profile.OnSessionEnd` fires when the session is taken from under us: a steal, a
rejoin elsewhere, or ProfileStore giving up after ten minutes of failed updates.
From that moment writes are discarded. `Data/init.luau` connects it and
**kicks** the player, because the alternative is someone playing for an hour on
data that will never save.

`replica:IsActive()` does **not** tell you this. It reports whether the *wrapper*
was destroyed. Guard on it anyway — it is the right check for "has this player
left" — but never mistake it for a durability signal.

---

## 3. The profile

`src/server/Data/Default.luau` is the template. Every profile is reconciled
against it on load by `Global.FillTable`, which **fills missing keys and never
overwrites existing values**, recursing into sub-tables. So adding a field here
backfills every existing player; changing a default does not touch anyone who
already has a value.

| Field | Type | Owner | Bound |
|---|---|---|---|
| `FirstJoin` | boolean | `Data/OnFirstJoin` | — |
| `JoinDate` | number | `Data/OnFirstJoin` | — |
| `LastOnline` | number | `Data` | — |

Every field you add gets a row here: its type, the ONE module that writes it,
and the cap on it if it is a collection.

`src/server/Data/OnFirstJoin.luau` runs once per profile, after the reconcile.
One-time grants go there, and they are **raised to, never set to**, so a profile
whose `FirstJoin` flag is ever lost cannot have an earned balance replaced with
the starting one.

### Not in the profile: session state

What should not survive a respawn or a rejoin is never put on the profile. It
lives in a table in the server module that owns it, keyed by Player, cleared on
`PlayerRemoving`.

---

## 4. Invariants

These are the rules that, if broken, lose data.

**1. Every path a `Set` passes through must exist in `Default.luau`.**
`replica:Set({"Inventory", "Items", id}, n)` throws for anyone whose profile has
no `Inventory.Items` table — unless both are in the template so `FillTable` can
put empty tables there. `python3 tools/check_schema.py` checks every literal
path in `src/server` against the template.

**2. Every collection on the profile has a hard cap.**
A profile that exceeds 4 MB can never be saved again — silently, permanently.
Every list has a ceiling it may not pass, and the cap is enforced in the writer.

**3. Strings that reach a store are cut on character boundaries, and invalid
UTF-8 is refused, not truncated.**
A DataStore rejects a non-UTF-8 value outright. `string.sub(name, 1, 48)` on a
CJK display name cuts mid-sequence, and the resulting profile never saves again.
Use `utf8.len` / `utf8.offset`; return `""` when `utf8.len` is nil.

```luau
-- by characters
local stop = utf8.offset(text, maxChars + 1)
text = if stop ~= nil then string.sub(text, 1, stop - 1) else ""
```

**4. Non-finite numbers never reach a store.**
`math.clamp(0/0, 0, 1)` returns **NaN**. `math.floor(math.huge)` is
`math.huge`. Neither has a JSON form. Test `value ~= value` explicitly, and
`math.abs(v) ~= math.huge`.

**5. An `UpdateAsync` transform is pure, non-yielding, and safe to run twice.**
Roblox may invoke it repeatedly under contention. Return `nil` to abort.

**6. A failed READ is never treated as "empty".**
Retry the read; if it never succeeds, disable saving for that key for the
session's whole life. Writing memory over a store you failed to read is how
everything disappears at once.

**7. Client-named ids are rate-limited before they become requests.**
The DataStore budget is roughly `60 + 10×players` per minute, **shared with
ProfileStore** — starving it breaks everybody's saves. Cache misses as well as
hits.

**8. Anything added to `Peekable.luau` is public forever.**
The mirror deep-copies rather than aliasing, so an in-place mutation of the
private profile cannot leak — but the path itself, and everything under it, is
readable by every player in the server.

---

## 5. Migrations

Two mechanisms, in ascending order of violence.

**`Revisions.luau`** — mechanical, per-load, keyed by dot-path.
`Redactions` drop a key; `Renames` move one. Deleting a key during the
`pairs()` walk is legal; **inserting one is not**, so renames are collected
during the traversal and applied after it.

**`Game_Settings.DataStore.StoreVersion`** — a clean break. The key becomes
`PlayerData<version>`, so **every account in the game starts from nothing** and
the old data sits at the old key. There is no guard and no migration path.

Adding a field: put it in `Default.luau` with a safe zero value and it
backfills. That is all. Do not write a migration for a new field.

---

## 6. When a store fails

| Failure | What the player sees | What the code does |
|---|---|---|
| Profile fails to load | kicked, "Data failed to load. Please rejoin." | `StartSessionAsync` returns nil |
| Anything throws mid-load | kicked, same message | one `xpcall` releases the session lock first |
| Session taken elsewhere | kicked, "opened elsewhere" | `OnSessionEnd` |
| Profile save fails | **nothing** | `ProfileStore.OnError` warns; ending-session saves retry forever, ordinary ones drop |
| Key corrupted | profile resets to template | `ProfileStore.OnOverwrite` warns — this is your only signal |
| Store-wide outage | features degrade one at a time | `OnCriticalToggle` warns |

Shutdown: `game:BindToClose` releases every live session up front — `EndSession`
saves with the ending-session flag, which is what makes ProfileStore retry until
the write lands — then waits for the drain. Roblox caps the total at 30 seconds.

### In Studio

With "Enable Studio Access to API Services" **off**, ProfileStore runs against
an in-memory mock: every playtest starts from the template and nothing is
written anywhere. With it **on**, a playtest reads and writes the real
`PlayerData<StoreVersion>` store, the same one the live game uses.

Wiping your own profile: from the command bar in EDIT mode, with API access on,
`RemoveAsync` the key `Player_<userId>` from the `PlayerData<StoreVersion>`
DataStore.

---

## 7. Pitfalls

- **`math.clamp` does not stop NaN.** Nor does `< 0`, `> 0` or `math.max`.
- **`string.sub` counts bytes.** Every user-facing cap is in *characters*.
- **`__mode = "k"` on an Instance key tracks the Lua wrapper, not the
  instance.** Use strong keys and clear them on `PlayerRemoving`.
- **The `.Changed` signal and the wrapper's methods do not share an argument
  order.** `TableRemove` *fires* `(path, removedValue, index)` and *takes*
  `(path, index)`. The peekable mirror dispatches by name for this reason.
- **A check before a yield and a spend after it is not a gate.** Hold a
  one-in-flight guard across the yield.
- **A `pcall` around `Profile:Save()` proves nothing.** See §2.

---

## 8. Adding a field — the checklist

1. Add it to `Default.luau` with a zero value, and a comment saying **who owns
   the writes**.
2. If it is a collection, give it a cap in `Game_Settings` and enforce the cap
   in the writer. State the cap in the table in §3.
3. Give it exactly one writing module. Two writers is a race you will not
   reproduce.
4. Write through `replica:Set`, never `profile.Data`.
5. If a client can influence its size or its keys, rate-limit the verb and
   bound the input **before** the work, not after.
6. If any string in it is player-authored and another player can see it, run it
   through `TextService:FilterStringAsync` and fail **closed**.
7. Decide whether it belongs in `Peekable.luau`. The default is no.
