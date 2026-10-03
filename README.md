# cloverboyz

A Roblox game. Rojo project with the ProfileStore + Replica data stack.

## Docs

| | |
| --- | --- |
| [DATA.md](DATA.md) | player data — ProfileStore, Replica, the profile template and its invariants |

## Working on it

```
rokit install      # rojo, wally, lune at the pinned versions
wally install      # packages into Packages/
rojo serve         # then connect from the Rojo plugin in Studio
```

Checks, all runnable without Studio:

```
rojo build -o build.rbxl          # the project tree assembles
python3 tools/check_schema.py     # every profile write lands on a field the template declares
```

## Layout

```
src/
  shared/      ReplicatedStorage.Shared — Loader, Global helpers, Game_Settings
  server/      ServerScriptService.Server — Data service + every server module
  client/      StarterPlayerScripts.Client — Data view + every client module
  replicatedfirst/
tools/         scripts that run outside Studio
Packages/      wally output (gitignored)
```

Any ModuleScript dropped into `src/server` or `src/client` is booted by
`Shared/Loader` automatically. Return a table with optional `OnInit(self)` and
`OnStart(self)` to hook the lifecycle.
