# FG Monster Tooler

### About
This script converts spells from a [Fantasy Grounds](https://www.fantasygrounds.com/home/home.php) (FG) `.mod` file to [5etools' homebrew](https://github.com/TheGiddyLimit/homebrew) schema. This script is designed to automate the *bulk* process, and it will almost certainly require manual correction afterwards (see below).

### How to use
Place this script in the same directory as your `.mod` file. On Windows, right-click this script and select 'Run with PowerShell'. On Mac OS and Linux, you will probably have to install [PowerShell](https://github.com/powershell/powershell) and run it via command line.

A file following 5etools' homebrew filename convention (`Author; Homebrew Title.json`) will be created in this same directory. Make corrections as appropriate and you should be sorted!

Knowledge of [5etools' schema](https://github.com/TheGiddyLimit/TheGiddyLimit.github.io/tree/master/test/schema) is strongly advised. Proficiency in basic regex is very helpful for clean-up!

### Settings
The following settings can (and should) be set by editing the script. They're found at the top.
- `$source` (string) sets the JSON source; an empty string tells the script to set one itself
- `$abbreviation` (string) sets the source's display abbreviation; an empty string tells the script to set one itself
- `$url` (string) sets the link to the homebrew's official store or place of publication; an empty string leaves the property undefined
- `$colour` (string; standard 6-digit RGB hexadecimal code) sets the source's display colour; an empty string leaves the property undefined
- `$addFluff` (bool), when `$true`, tells the script to extract the monsters' fluff.
- `$addTokens` (bool), when `$true`, tells the script to extract the monsters' tokens, place them in a folder in the current directory called `$source`, and set appropriate monsters' tokens to point to `$repo/$source/creature/token/<filename>`
- `$addImages` (bool), when `$true`, tells the script to extract the monsters' image, place them in a folder in the current directory called `$source`, and set appropriate monsters' images to point to `$repo/$source/creature/<filename>`
- `$repo` (string) is used to define the token/image repository URL if either of the above two flags are `$true`
- `$addLegendary` (bool), when `$true`, tells the script to extract `legendaryGroup` data (i.e. lair actions and regional effects) from the creature's fluff (this may fail catastrophically at times)
- `$bonusActions` (bool) is an experimental setting that, when `$true` but FG's data lacks a separate field for bonus actions, tells the script to try to find bonus actions and convert them to match 5etools' `bonus` schema
- `$spellcastingActions` (bool), when `$true`, tells the script to look for "Spellcasting" (and related) actions as well as traits, and to treat them all as actions

### Limitations
**Forewarning:** I have seen a number of `.mod`s that flat-out ignore data fields and inconsistently format things as raw text, which almost undoubtedly produces errors. Nothing I can do here; take it up with the author(s).

You should be aware of the following limitations with this automated conversion; there's a lot of edge cases and variation that's hard to foresee.
- Alignment descriptions that aren't either exact or in the form of "any (non-)**alignment**" (e.g. "50% Lawful Good, 50% Chaotic Evil"). `alignmentPrefix`es that aren't `typically ` will also be missed.
- `prefix` tags (e.g. "**Illuskan** human") are not handled.
- `special` HP maxima, which lack an average or formula, are not handled.
- Certain complex, conditional ACs may be malformed.
- Certain complex, non-standard damage vulnerability/resistance/immunity formats
- Condition immunities with embedded conditions (e.g. "poisoned (while in Angry Form)")
- `languageTags` will not be populated with `OTH`
- Invalid CRs may be accepted, but this script won't warn you about them (I don't know how FG handles, for example, lair CRs).
- Lair actions and regional effects are assumed to follow standard formatting and will not tolerate any real deviation from the norm.
- Lair actions and regional effects are always formatted in the old bulleted-list style rather than the new `list-hang-notitle` style. Feel free to [raise an issue](https://github.com/Spappz/VTT-Tooler-Suite/issues/new) if this matters for you.
- Spellcasting actions are messy; see **Settings** above for more information.
- Bonus actions may appear (with slightly modified text) as normal actions; see above for more information.

If something goes wrong, either an `xxxERRORxxx : <error message>` string will be put in the appropriate JSON attribute, or the script will crash. Good luck!

Fantasy Grounds doesn't store everything that 5etools does. The following will always require manual entry:
   - `page` number (set to `0` by default)
   - `environment`s
   - `isNpc` flag
   - `familiar` flag
   - `group`s and search `alias`es
   - `soundClip`
   - `dragonCastingColor` (lmao)
   - `dragonAge` (feel free to [raise an issue](https://github.com/Spappz/VTT-Tooler-Suite/issues/new) if this matters for you)
   - `variant` footers or inserts (these will often be stored in the `fluff`)

Although this script tries to automatically match taggable strings, it is far from perfect. After addressing the errors, you should verify that filter arrays (e.g. `miscTags`, `conditionInflict`) are accurate, and then tag anything relevant in the `entries` arrays.

If something goes wrong, either an `xxxERRORxxx : <error message>` string will be put in the appropriate JSON attribute, or the script will crash. Good luck!
   
### Longevity
Please [create an issue](https://github.com/Spappz/VTT-Tooler-Suite/issues/new) if you'd like some extra work on this: bugs to fix, changes to FG's schema, features to develop, etc.
