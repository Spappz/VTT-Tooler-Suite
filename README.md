# R20 Monster Tooler

### About
This script converts monsters from [Kakaroto's R20Exporter](https://github.com/kakaroto/R20Exporter/) JSON to [5etools' homebrew](https://github.com/TheGiddyLimit/homebrew) schema. This script is designed to automate the *bulk* process, and it will almost certainly require manual correction afterwards (see below).

### How to use
Place this file in the same directory as the 'characters' directory, which you should acquire by running [R20Exporter](https://github.com/kakaroto/R20Exporter/). On Windows, right-click this script and select 'Run'. On Mac OS and Linux, you will probably have to install [Powershell](https://github.com/powershell/powershell) and run it via command line.

A file named `# CONVERTED.json` will be created in this same directory. Make corrections as appropriate and you should be sorted!

Knowledge of the [5etools' schema](https://github.com/TheGiddyLimit/TheGiddyLimit.github.io/tree/master/test/schema) is strongly advised. Proficiency in basic regex is very helpful for clean-up!

### Settings
The following settings can (and should) be set by editing the script. They're found at the top.
- `$source` (string) sets the JSON source
- `$token` (bool) to add a `tokenUrl` (pointing to `$repo/$source/creature/token/<name>.png`)
- `$fluff` (bool) to extract fluff entries from each monster's `bio.html`
- `$image` (bool) to add a fluff image (pointing to `$repo/$source/creature/<name>.webp`)
- `$repo` (string) is used for the first part of the above URLs

### Limitations
This script doesn't handle and will likely break with the following:
- basically anything that isn't formatted remotely like WotC
- 'special' type HPs (i.e. flat numbers without dice roll)
- creatures with extra forms, specifically that alter AC or speed (e.g. werewolf|MM)
- alignments that aren't either exact or in the form of 'any (non-)<alignment>'
- `prefix` tags (e.g. '**Illuskan** human')
- swarms of nonstandard-type creatures (e.g. 'Medium swarm of Tiny **aliens**')
- spell attack actions; all attack actions are presumed weapon attacks

If something goes wrong, either an `XxX_ERROR_XxX` string will be put in the appropriate JSON attribute with a brief description of what's happening, or the script will crash. Good luck!

Roll20 doesn't store everything that 5etools does. The following always requires manual entry:
- page number (0 by default)
- environments
- `isNpc` flag
- `familiar` flag
- groups and search aliases
- sound clips
- dragon casting colour (lmao)
- variant footers/insets (these will often be stored in the `fluff`)
- the source on any `{@tag ...}` (will be left blank)

Although this script tries to automatically match taggable strings, it is far from perfect. After addressing the errors, you should verify that filter arrays (e.g. `miscTags`, `conditionInflict`) are accurate, and tag anything relevant in `entries` arrays.

Also this handles lists and tables terribly. If you see random italics or `<li>` tags everywhere, it's likely meant to be one of those.
