# Ace3v (dh-harald)

Consolidated home for all of dh-harald's own Ace3-style libraries written for
vanilla WoW 1.12.1 / Unreal Azeroth. Each library currently lives in its own
GitHub repo under `github.com/dh-harald/`; this repo merges them into one,
mirroring the layout `github.com/laytya/Ace3v` uses for the upstream Ace3
backport (one repo, one subfolder per library, each externaled by its own
subpath).

Goal: stop maintaining N separate repos with N separate issue trackers and
release cadences for libraries that are all "Lua 5.0/5.1 dual-client Ace3
component, written or patched by the same author for the same project" — keep
one changelog, one place to open a PR, one place a future library lands.

Consuming addons (ElvUI, Bagzen, ZygorGuidesViewerNG, ...) keep pulling each
library via its own `.pkgmeta` external subpath, unchanged in effect — only
the upstream URL moves from the per-library repo to this repo's subfolder.
