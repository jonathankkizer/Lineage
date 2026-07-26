# Keyboard shortcuts

Linked from **Help → Keyboard Shortcuts** in the app.

## Files and projects

| Shortcut | Action |
|---|---|
| `⌘O` | Open a dbt project folder, a bare `target/`, or a `.lineagegh` connection |
| `⌘R` | Reload the project from disk (re-fetches the latest run for GitHub connections) |
| `⌘W` | Close window |
| `⌘P` | Print the graph |
| `⌘,` | Settings |

Dropping a project folder onto a Lineage window, the Welcome window, or the Dock
icon opens it. Other apps can hand Lineage a folder via **Services → Open in
Lineage**.

## Finding and selecting

| Shortcut | Action |
|---|---|
| `⌘F` | Focus the filter field |
| `⌘G` | Find next match |
| `⇧⌘G` | Find previous match |
| `⌘A` | Select every visible node (respects the active focus, search, and filter) |
| `⌘C` | Copy the selection — names as text, a table as TSV, source files as file URLs |
| Click | Select |
| `⌘`-click | Add or remove from the selection |
| Drag | Marquee-select |

The filter field accepts dbt selector syntax: `+name`, `name+`, `+name+`,
`N+name`, `name+N`.

## Moving around the graph

| Shortcut | Action |
|---|---|
| Arrow keys | Walk the DAG — up/down within a layer, left/right along dependencies |
| `Return` | Focus on the selection |
| `⌘Return` | Focus on the selection (works from anywhere) |
| `Esc` | Back to the overview |
| `⌘[` / `⌘]` | Focus history back / forward |
| Scroll / two-finger drag | Pan |
| Pinch | Zoom around the pointer |

## View

| Shortcut | Action |
|---|---|
| `⌘=` / `⌘-` | Zoom in / out |
| `⌘0` | Actual size |
| `⇧⌘0` | Zoom to fit |
| `⌘I` | Show or hide the inspector |
| `⇧⌘P` | Show the critical path |
| `⌃⌘F` | Full screen |

## Dragging out

Drag a node to Finder, an editor, or a Terminal window to get its source file.
Dragging an unselected node acts on that node; dragging a selected one takes the
whole selection.

## VoiceOver

The canvas exposes every on-screen node as an element. `VO`-arrow moves between
them, `VO`-Space enters focus mode on the current node, and selection changes —
including arrow-key DAG navigation — are announced along with focus, search, and
critical-path counts.
