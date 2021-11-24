# Foundry Spell Tooler

### About
This script converts spells from [Foundry VTT](https://foundryvtt.com/) [`dnd5e`](https://gitlab.com/foundrynet/dnd5e) compendia to the [5etools' homebrew](https://github.com/TheGiddyLimit/homebrew) schema. This script is designed to automate the *bulk* process, and it will almost certainly require manual correction afterwards (see below).

### How to use
Place this file in the same directory as your compendium file (e.g. `spells.db`). On Windows, right-click this script and select 'Run'. On Mac OS and Linux, you will probably have to install [Powershell](https://github.com/powershell/powershell) and run it via command line.

A file named `# BREW.json` will be created in this same directory. Make corrections as appropriate and you should be sorted!

Knowledge of the [5etools' schema](https://github.com/TheGiddyLimit/TheGiddyLimit.github.io/tree/master/test/schema) is strongly advised. Proficiency in basic regex is very helpful for clean-up!

### Settings
The following settings can (and should) be set by editing the script. They're found at the top.
- `$overrideSource` (string) sets the JSON source for all spells in the compendium; an empty string tells the script to copy it from the compendium
- `$extractPageNumbers` (bool), when `$true`, tells the script to make an attempt at extracting page numbers from the spell's `source` in the compendium

### Limitations
You should be aware of the following limitations with this automated conversion.
- Spell lists (class, subclass, race, eldritch invocation, etc.) are not populated as this data is not stored in Foundry VTT dnd5e compendia.
- Spells with multiple area-of-effect shapes (`areaTags`), spell attack options (`spellAttacks`), or saving throws (`savingThrows`) aren't recognised. One tag at most from each will be applied.
- Spells with permanent or multiple durations might be missing data, especially the `upTo` and `ends` keys.
- Spells with variable damage types may suffer dice and `damageInflict` mistagging.
- Non-trivial spell descriptions (`entries`), especially knowing how homebrew tends to be, will likely be misformatted. It should still be readable, but not 100% accurate or complete. Most significantly, `table`s are handled by an obscene and fickle hack, and `inset` blocks are entirely unaccounted for. This thing parses HTML with regex!
- 5etools filter metadata (especially `miscTags`) relies largely on pattern-matching and so might miss tags. False negatives are far more likely than false positives.
- The following 5etools metadata is completely ignored: `damageResist`, `damageImmune`, `damageVulnerable`, and `conditionImmune`. You'll have to fill these out manually.

If something goes wrong, either an `xxxERRORxxx : <error message>` string will be put in the appropriate JSON attribute, or the script will crash. Good luck!
   
Last tested under Foundry VTT [`dnd5e` system](https://gitlab.com/foundrynet/dnd5e) version 1.5.3. Support outside this version is not guaranteed.

### Longevity

Please [create an issue](https://github.com/Spappz/VTT-Tooler-Suite/issues/new) if you'd like some extra work on this: bugs to fix, changes to the `dnd5e` system, features to develop, etc.