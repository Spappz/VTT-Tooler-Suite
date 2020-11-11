<########################################################################################
#                                                                                       #
#                      R20EXPORTER TO 5ETOOLS MONSTER CONVERTER                         #
#                                                                                       #
#                                    Spappz 2020                                        #
#                                                                                       #
########################################################################################>

# SETTINGS
$source = "ToB2" # JSON source
$token = $true   # Adds tokenUrl (`$repo/$source/creature/token/<name>.png`)
$fluff = $true   # Extract fluff entries from each monster's 'bio.html'
$image = $true   # Adds fluff image (`$repo/$source/creature/<name>.webp`)
$repo = "https://raw.githubusercontent.com/TheGiddyLimit/homebrew/master/_img"

<#
# ABOUT
  This script converts monsters from Kakaroto's R20Exporter JSON to 5etools' homebrew
   schema. This script is designed to automate the *bulk* process, and it will almost
   certainly require manual correction afterwards (see below).

# HOW TO USE
   Place this file in the same directory as the 'characters' directory, which you should
    acquire by running R20Exporter. On Windows, right-click this script and select 'Run'.
    On Mac OS and Linux, you will probably have to install Powershell and run it via
    command line.

   A file named '# CONVERTED.json' will be created in this same directory. Make
    corrections as appropriate and you should be sorted!

   Knowledge of the 5etools' schema is strongly advised. Proficiency in basic regex is
    very helpful for clean-up!

# LIMITATIONS
  It is my personal opinion that Roll20's data format is, put simply, utter shit. I have
   experienced huge differences in data structure, and sometimes data just seems to be
   malformed or altogether absent. I have done my best to compensate.

  This script doesn't handle and will likely break with the following:
   - basically anything that isn't formatted remotely like WotC
   - 'special' type HPs (i.e. flat numbers without dice roll)
   - creatures with extra forms, specifically that alter AC or speed (e.g. werewolf|MM)
   - alignments that aren't either exact or in the form of 'any (non-)<alignment>'
   - `prefix` tags (e.g. 'Illuskan human')
   - swarms of nonstandard-type creatures (e.g. 'Medium swarm of Tiny aliens')
   - spell attack actions; all attack actions are presumed weapon attacks

  If something goes wrong, either an `XxX_ERROR_XxX` string will be put in the appropriate
   JSON attribute with a brief description of what's happening, or the script will crash.
   Good luck!

  Roll20 doesn't store everything that 5etools does. The following always requires
   manual entry:
   - page number (0 by default)
   - environments
   - `isNpc` flag
   - `familiar` flag
   - groups and search aliases
   - sound clips
   - dragon casting colour (lmao)
   - variant footers/insets (these will often be stored in the `fluff`)
   - the source on any `{@tag ...}` (will be left blank)

  Although this script tries to automatically match taggable strings, it is far from
   perfect. After addressing the errors, you should verify that filter arrays (e.g.
   `miscTags`, `conditionInflict`) are accurate, and tag anything relevant in `entries`
   arrays.

  Also this handles lists and tables terribly. If you see random italics or `<li>` tags
   everywhere, it's likely meant to be one of those.

# CONTACT
  - spap [hash] 9812
  - spappz [at] firemail [dot] cc

  pls no spam

# LICENSE
  MIT License

  Copyright © 2020 Spappz

  Permission is hereby granted, free of charge, to any person obtaining a copy of this
   software and associated documentation files (the "Software"), to deal in the Software
   without restriction, including without limitation the rights to use, copy, modify,
   merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
   permit persons to whom the Software is furnished to do so, subject to the following
   conditions:

  The above copyright notice and this permission notice shall be included in all copies
   or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
   INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
   PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
   HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
   CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
   OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#>

# INITIALISATION
Clear-Host
Write-Output "Initialising...`n"
if ((Test-Path ".\# BREW.json") -eq $true) {
    do {
        Write-Warning "'# BREW.json' already exists!"
        Write-Output "Please delete or rename it now.`n"
        pause
        Write-Output ""
    } while  (Test-Path ".\# BREW.json")
    Write-Output "Thank you. Beginning conversion.`n"
} else {
    Write-Output "Beginning conversion.`n"
}

$brew = @{
    "_meta" = [ordered]@{
        sources = @( [ordered]@{
            json = $source
            abbreviation = ""
            full = ""
            url = ""
            authors = @( "" )
            convertedBy = @( "" )
            color = ""
            version = "1.0.0"
        } )
        dateAdded = [int64](get-date -uformat %s)
        dateLastModified = [int64](get-date -uformat %s)
    }
    monster = @()
    legendaryGroup = @()
}
$progress = 0
$progmax = (Get-ChildItem -Path .\characters\).Count
$errcount = 0

# COMMON FUNCTIONS
function Process-Spell {
    [CmdletBinding()]
    PARAM (
        [Parameter(Mandatory, ValueFromPipeline)]
        [array]$str
    )
    PROCESS {
        Write-Output ($str -join "@#&" -split "@#&") | ForEach-Object {
            switch -regex ($_) {
                "(?<=\{@spell )arcane hand\}" { $_ -replace "arcane hand\}", "bigby's hand|phb|arcane hand}" }
                "(?<=\{@spell )instant summons\}" { $_ -replace "instant summons\}", "drawmij's instant summons|phb|instant summons}" }
                "black tentacles\}" {
                    $_ -replace "(?<=\{@spell )black tentacles", "evard's black tentacles|phb|black tentacles"
                    $5et.conditionInflictSpell += "restrained"
                }
                "(?<=\{@spell )secret chest\}" { $_ -replace "secret chest\}", "leomund's secret chest|phb|secret chest}" }
                "(?<=\{@spell )tiny hut\}" { $_ -replace "tiny hut\}", "leomund's tiny hut|phb|tiny hut}" }
                "(?<=\{@spell )acid arrow\}" { $_ -replace "acid arrow\}", "melf's acid arrow|phb|acid arrow}" }
                "(?<=\{@spell )faithful hound\}" { $_ -replace "faithful hound\}", "mordenkainen's faithful hound|phb|faithful hound}" }
                "(?<=\{@spell )magnificent mansion\}" { $_ -replace "magnificent mansion\}", "mordenkainen's magnificent mansion|phb|magnificent mansion}" }
                "(?<=\{@spell )private sanctum\}" { $_ -replace "private sanctum\}", "mordenkainen's private sanctum|phb|private sanctum}" }
                "(?<=\{@spell )arcanist's magic aura\}" { $_ -replace "arcanist's magic aura\}", "nystul's magic aura|phb|arcanist's magic aura}" }
                "(?<=\{@spell )freezing sphere\}" { $_ -replace "freezing sphere\}", "otiluke's freezing sphere|phb|freezing sphere}" }
                "(?<=\{@spell )resilient sphere\}" { $_ -replace "resilient sphere\}", "otiluke's resilient sphere|phb|resilient sphere}" }
                "(?<=\{@spell )irresistible dance\}" { $_ -replace "irresistible dance\}", "otto's irresistible dance|phb|irresistible dance}" }
                "(?<=\{@spell )telepathic bond\}" { $_ -replace "telepathic bond\}", "rary's tiny telepathic bondhut|phb|telepathic bond}" }
                "hideous laughter\}" {
                    $_ -replace "(?<=\{@spell )hideous laughter", "tasha's hideous laughter|phb|hideous laughter"
                    $5et.conditionInflictSpell += @( "prone", "incapacitated" )
                }
                "(?<=\{@spell )floating disk\}" { $_ -replace "hideous laughter\}", "tenser's floating disk|phb|floating disk}" }
                "(?<=\{@spell )blindness\/deafness\}" { $_; $5et.conditionInflictSpell += @( "blinded", "unconscious" ) }
                "(?<=\{@spell )color spray\}" { $_; $5et.conditionInflictSpell += "blinded" }
                "(?<=\{@spell )contagion\}" { $_; $5et.conditionInflictSpell += @( "poisoned", "blinded", "stunned" ) }
                "(?<=\{@spell )divine word\}" { $_; $5et.conditionInflictSpell += @( "deafened", "blinded", "stunned" ) }
                "(?<=\{@spell )holy aura\}" { $_; $5et.conditionInflictSpell += "blinded" }
                "(?<=\{@spell )mislead\}" { $_; $5et.conditionInflictSpell += @( "blinded", "invisible", "deafened" ) }
                "(?<=\{@spell )prismatic (spray|wall)\}" { $_; $5et.conditionInflictSpell += @( "blinded", "restrained", "petrified" ) }
                "(?<=\{@spell )project image\}" { $_; $5et.conditionInflictSpell += @( "blinded", "deafened" ) }
                "(?<=\{@spell )sunb(eam|urst)\}" { $_; $5et.conditionInflictSpell += "blinded" }
                "(?<=\{@spell )animal friendship\}" { $_; $5et.conditionInflictSpell += "charmed" }
                "(?<=\{@spell )awaken\}" { $_; $5et.conditionInflictSpell += "charmed" }
                "(?<=\{@spell )charm person\}" { $_; $5et.conditionInflictSpell += "charmed" }
                "(?<=\{@spell )dominate (beast|monster|person)\}" { $_; $5et.conditionInflictSpell += "charmed" }
                "(?<=\{@spell )geas\}" { $_; $5et.conditionInflictSpell += "charmed" }
                "(?<=\{@spell )hypnotic pattern\}" { $_; $5et.conditionInflictSpell += @( "charmed", "incapacitated" ) }
                "(?<=\{@spell )modify memory\}" { $_; $5et.conditionInflictSpell += @( "charmed", "incapacitated" ) }
                "(?<=\{@spell )silence\}" { $_; $5et.conditionInflictSpell += "deafened" }
                "(?<=\{@spell )storm of vengeance\}" { $_; $5et.conditionInflictSpell += "deafened" }
                "(?<=\{@spell )antipathy\/sympathy\}" { $_; $5et.conditionInflictSpell += "frightened" }
                "(?<=\{@spell )eyebite\}" { $_; $5et.conditionInflictSpell += @( "frightened", "unconscious" ) }
                "(?<=\{@spell )fear\}" { $_; $5et.conditionInflictSpell += "frightened" }
                "(?<=\{@spell )phantasmal killer\}" { $_; $5et.conditionInflictSpell += "frightened" }
                "(?<=\{@spell )symbol\}" { $_; $5et.conditionInflictSpell += @( "frightened", "unconscious", "incapacitated", "stunned" ) }
                "(?<=\{@spell )weird\}" { $_; $5et.conditionInflictSpell += "frightened" }
                "(?<=\{@spell )banishment\}" { $_; $5et.conditionInflictSpell += "incapacitated" }
                "(?<=\{@spell )wind walk\}" { $_; $5et.conditionInflictSpell += "incapacitated" }
                "(?<=\{@spell )(greater )?invisibility\}" { $_; $5et.conditionInflictSpell += "invisible" }
                "(?<=\{@spell )sequester\}" { $_; $5et.conditionInflictSpell += "invisible" }
                "(?<=\{@spell )hold (monster|person)\}" { $_; $5et.conditionInflictSpell += "paralyzed" }
                "(?<=\{@spell )flesh to stone\}" { $_; $5et.conditionInflictSpell += @( "restrained", "petrified" ) }
                "(?<=\{@spell )command\}" { $_; $5et.conditionInflictSpell += "prone" }
                "(?<=\{@spell )earthquake\}" { $_; $5et.conditionInflictSpell += "prone" }
                "(?<=\{@spell )grease\}" { $_; $5et.conditionInflictSpell += "prone" }
                "(?<=\{@spell )meld into stone\}" { $_; $5et.conditionInflictSpell += "prone" }
                "(?<=\{@spell )sleet storm\}" { $_; $5et.conditionInflictSpell += "prone" }
                "(?<=\{@spell )entangle\}" { $_; $5et.conditionInflictSpell += "restrained" }
                "(?<=\{@spell )imprisonment\}" { $_; $5et.conditionInflictSpell += "restrained" }
                "(?<=\{@spell )telekinesis\}" { $_; $5et.conditionInflictSpell += "restrained" }
                "(?<=\{@spell )web\}" { $_; $5et.conditionInflictSpell += "restrained" }
                "(?<=\{@spell )power word stun\}" { $_; $5et.conditionInflictSpell += "stunned" }
                "(?<=\{@spell )astral projection\}" { $_; $5et.conditionInflictSpell += "unconscious" }
                "(?<=\{@spell )sleep\}" { $_; $5et.conditionInflictSpell += "unconscious" }
                default { $_ }
            }
        }
    }
}
function Split-And-Tag-Spell-Lists {
    [CmdletBinding()]
    PARAM (
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$str
    )
    PROCESS {
        Write-Output ($str -split ", (?![^(]+\))") | ForEach-Object {
            switch -regex ($_) {
                '\w \(.+\)$' { ("{@spell " + ($_ -replace ' \(.*$') + "}" + ($_ -replace '^.+(?= \()')) | Process-Spell }
                "\w ?\*" { ("{@spell " + ($_ -replace '\*+[^\*]*$') + "}" + ($_ -replace '^.+(?= ?\*)')) | Process-Spell }
                default { ("{@spell " + $_ + "}") | Process-Spell }
            }
        }
    }
}
function Find-Damage-Types {
    [CmdletBinding()]
    PARAM (
        [Parameter(Mandatory, ValueFromPipeline)]
        $str
    )
    BEGIN {
        $finds = @()
        $confirms = @()
    }
    PROCESS {
        switch -regex ($str) {
            "\btak\w{1,3} [d \d\+\-\*×÷/\^\(\)]+? \w{4,} damage\b" { $finds += $str -replace '^.+\btak\w{1,3} [d \d\+\-\*×÷/\^\(\)\{@\}]+ (\w{4,}) damage\b.*$', '$1' }
            '\bdeal\w{0,3} [d \d\+\-\*×÷/\^\(\)]+? \w{4,} damage\b' { $finds += $str -replace '^.+\bdeal\w{0,3} [d \d\+\-\*×÷/\^\(\)\{@\}]+ (\w{4,}) damage\b.*$', '$1' }
            '\binflict\w{0,3} [d \d\+\-\*×÷/\^\(\)]+? \w{4,} damage\b' { $finds += $str -replace '^.+\binflict\w{0,3} [d \d\+\-\*×÷/\^\(\)\{@\}]+ (\w{4,}) damage\b.*$', '$1' }
            '\bsuffer\w{0,3} [d \d\+\-\*×÷/\^\(\)]+? \w{4,} damage\b' { $_;$finds += $str -replace '^.+\bsuffer\w{0,3} [d \d\+\-\*×÷/\^\(\)\{@\}]+ (\w{4,}) damage\b.*$', '$1' }
            '\bfor [d \d\+\-\*×÷/\^\(\)]+? \w{4,} damage\b' { $finds += $str -replace '^.+\bfor [d \d\+\-\*×÷/\^\(\)\{@\}]+ (\w{4,}) damage\b.*$', '$1' }
            '\bplus [d \d\+\-\*×÷/\^\(\)]+? \w{4,} damage\b' { $finds += $str -replace '^.+\bplus [d \d\+\-\*×÷/\^\(\)\{@\}]+ (\w{4,}) damage\b.*$', '$1' }
            '\band [d \d\+\-\*×÷/\^\(\)]+? \w{4,} damage\b' { $finds += $str -replace '^.+\band [d \d\+\-\*×÷/\^\(\)\{@\}]+ (\w{4,}) damage\b.*$', '$1' }
            '\bor \w{4,} damage' { $finds += $str -replace "^.+\bor (\w{4,}) damage.*$", '$1' }
        }
        switch -exact ($finds) {
            bludgeoning { $confirms += "B" }
            piercing { $confirms += "P" }
            slashing { $confirms += "S" }
            acid { $confirms += "A" }
            cold { $confirms += "C" }
            fire { $confirms += "F" }
            force { $confirms += "O" }
            lightning { $confirms += "L" }
            necrotic { $confirms += "N" }
            poison { $confirms += "I" }
            psychic { $confirms += "Y" }
            radiant { $confirms += "R" }
            thunder { $confirms += "T" }
        }
        Write-Output @($confirms)
    }
}
function Tag-Entries {
    [CmdletBinding()]
    PARAM (
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$str
    )
    PROCESS {
        Write-Output ($str `
            -replace '^\s+' -replace '\s+$' `
            -replace '(?<=\()([\dd \+\-×x\*÷\/\*]+\d)(?=\))', '{@damage $1}' `
            -replace '\b(\d+d[\dd \+\-×x\*÷\/]*\d)(?= (\w){4,9} damage\b)(?!\})', '{@damage $1}' `
            -replace '(?<=\brolls? a )(d\d+)\b(?!\})', '{@dice $1}' `
            -replace '(?<!@(damage|dice)) (\d+d[\dd \+\-×x\*÷\/]*\d)(?=( |\.|,))(?!\})', ' {@dice $2}' `
            -creplace '\bDC ?(\d+)\b', '{@dc $1}' `
            -creplace '(?<!\w)\+?(\-?\d)(?= (to hit|modifier|bonus))', '{@hit $1}' `
            -replace "(?<=\b(be(comes?)?|is|while|a(lso|nd)?|or) )(blinded|charmed|deafened|frightened|grappled|incapacitated|invisible|paralyzed|petrified|poisoned|restrained|stunned)\b", '{@condition $4}' `
            -replace "(?<=\b(knocked|pushed|shoved|becomes?|falls?|while|lands?) )(prone|unconscious)\b", '{@condition $2}' `
            -replace "(?<=levels? of )exhaustion\b", "{@condition exhaustion}" `
            -creplace '(?<=\b(Strength|Dexterity|Constitution|Intelligence|Wisdom|Charisma) \()(Athletics|Acrobatics|Sleight of Hand|Stealth|Arcana|History|Investigation|Nature|Religion|Animal Handling|Insight|Medicine|Perception|Survival|Deception|Intimidation|Performance|Persuasion)\b', '{@skill $2}' `
            -creplace '\b(Athletics|Acrobatics|Sleight of Hand|Stealth|Arcana|History|Investigation|Nature|Religion|Animal Handling|Insight|Medicine|Perception|Survival|Deception|Intimidation|Performance|Persuasion)(?= (check|modifier|bonus|roll|score))', '{@skill $1}' `
            -replace '(?<!cast (the )?)\b(darkvision|blindsight|tremorsense|truesight)\b(?! spell)', '{@sense $2}' `
            -replace "(?<=use )(.{,30}?)(?= statistics)", '{@creature $1}' `
            -creplace "\b(Attack(?! roll)|Cast a Spell|Dash|Disengage|Dodge|Help|Hide|Ready|Search|Use an Object)\b", '{@action $1}' `
            -replace '\bopportunity attack\b', '{@action opportunity attack}' `
            -replace '\b(\d{1,2}) percent chance\b', '{@chance $1} chance' `
            -replace '(<(strong|em)>)?<a href=".+?">(.+?)<\/a>(<\/(strong|em)>)?', '$3' `
            -replace "<strong>([^\r^\n]+?)<\/strong>", '{@b $1}' `
            -replace "<em>([^\r^\n]+?)<\/em>", '{@i $1}'
        )
    }
}
function Tag-Action-Name {
    [CmdletBinding()]
    PARAM (
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$str
    )
    PROCESS {
        Write-Output ($str `
            -replace '\(recharge (\d)(\-6)?\)', '{@recharge $1}'
        )
    }
}
function Find-Conditions { # TO DO
    [CmdletBinding()]
    PARAM (
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$str
    )
    BEGIN {
        $finds = @()
    }
    PROCESS {
        switch -regex ($str) {
            "(?<!(against( being)?|or|n('|o)t( be)?)) \{@condition bli" { $finds += "blinded" }
            "(?<!(against( being)?|or|n('|o)t( be)?)) \{@condition cha" { $finds += "charmed" }
            "(?<!(against( being)?|or|n('|o)t( be)?)) \{@condition dea" { $finds += "deafened" }
            "(?<!against( gaining)?) \{@condition exh" { $finds += "exhaustion" }
            "(?<!(against( being)?|or|n('|o)t( be)?)) \{@condition fri" { $finds += "frightened" }
            "(?<!(against( being)?|or|n('|o)t( be)?)) \{@condition gra" { $finds += "grappled" }
            "(?<!(against( being)?|or|n('|o)t( be)?)) \{@condition inc" { $finds += "incapacitated" }
            "(?<!(against( being)?|or|n('|o)t( be)?)) \{@condition inv" { $finds += "invisible" }
            "(?<!(against( being)?|or|n('|o)t( be)?)) \{@condition par" { $finds += "paralyzed" }
            "(?<!(against( being)?|or|n('|o)t( be)?)) \{@condition pet" { $finds += "petrified" }
            "(?<!(against( being)?|or|n('|o)t( be)?)) \{@condition poi" { $finds += "poisoned" }
            "(?<!(against( being)?|or|n('|o)t( be)?)) \{@condition res" { $finds += "restrained" }
            "(?<!(against( being)?|or|n('|o)t( be)?)) \{@condition stu" { $finds += "stunned" }
            "(?<!(against( being)?|or|n('|o)t( be)?)) (knocked|pushed|shoved|becomes|falls) \{@condition pro" { $finds += "prone" }
            "(?<!(against( being)?|or|n('|o)t( be)?)) (knocked|pushed|shoved|becomes|falls) \{@condition unc" { $finds += "unconscious" }
        }
        Write-Output $finds
    }
}
function Clean-Up-Tags {
    PARAM (
        [Parameter(Mandatory)]
        [object]$object,
        [Parameter(Mandatory)]
        [string]$member
    )
    PROCESS {
        if ($object.$member.Count) {
            $object.$member = [array]($object.$member | Sort -Unique)
        } else {
            $object.PSObject.Properties.Remove($member)
        }
    }
}

# TODO Multithreading?

Get-ChildItem -Path .\characters\ | ForEach-Object {
    $err = $false
    Write-Progress -Activity "Converting characters..." -Status "Progress:" -PercentComplete ($progress/$progmax*100) -Id 0
    Write-Progress -Activity "$($_.name -replace '\d+ - ')" -PercentComplete 0 -Id 1 -ParentId 0
    $5et = [PSCustomObject]@{}
    $r20 = (Get-Content -Path ".\characters\$($_.name)\character.json" -Encoding "UTF8") -replace "(‘|’)", "'" | ConvertFrom-Json

    # REFERENCE DATA
    Write-Progress -Activity "$($_.name -replace '\d+ - ')" -Status "Naming..." -PercentComplete 3.125 -Id 1 -ParentId 0
    $name = $r20.attributes | where { $_.name -eq "npc_name"} | Select -ExpandProperty current
    if ($name -eq $null) {
        $name = $r20.name
    }

    if ($name -match ", ") {
        Write-Output "`nThis creature's name might be jumbled. Enter the intended name or use a shortcut:"
        Write-Output "`tA  |  Accept name        >  $($name)"
        Write-Output "`tS  |  Switch order       >  $($name -replace '^(.+), (.+)$', '$2 $1')"
        Write-Output "`tD  |  Discard pre-comma  >  $($name -replace '^.+, (.+)$', '$1')"
        $5et | Add-Member -NotePropertyName name -NotePropertyValue "?"
        do {
            Write-Host "> " -NoNewLine
            switch -exact (Read-Host) {
                a { $5et.name = $name }
                s { $5et.name = $name -replace '^(.+), (.+)$', '$2 $1' }
                d { $5et.name = $name -replace '^.+, (.+)$', '$1' }
                default { $5et.name = $_ }
            }
        } until ($5et.name.length -gt 1)
    } else {
        $5et | Add-Member -NotePropertyName name -NotePropertyValue $name
    }
    $5et | Add-Member -NotePropertyName source -NotePropertyValue $source
    $5et | Add-Member -NotePropertyName page -NotePropertyValue 0

    # SIZE
    Write-Progress -Activity $name -Status "Weighing..." -PercentComplete 6.25 -Id 1 -ParentId 0
    $creaturetagline = $r20.attributes | where { $_.name -eq "npc_type" } | Select -ExpandProperty current
    switch -exact ($creaturetagline -replace '^([\w]+) [\w, \-\(\)]*$', '$1') {
        "tiny" { $5et | Add-Member -NotePropertyName size -NotePropertyValue "T" }
        "small" { $5et | Add-Member -NotePropertyName size -NotePropertyValue "S" }
        "medium" { $5et | Add-Member -NotePropertyName size -NotePropertyValue "M" }
        "large" { $5et | Add-Member -NotePropertyName size -NotePropertyValue "L" }
        "huge" { $5et | Add-Member -NotePropertyName size -NotePropertyValue "H" }
        "gargantuan" { $5et | Add-Member -NotePropertyName size -NotePropertyValue "G" }
        default {
            $5et | Add-Member -NotePropertyName size -NotePropertyValue "XxX_ERROR_XxX : Unknown size ///"
            $err = $true
        }
    }

    # TYPE
    Write-Progress -Activity $name -Status "Classifying..." -PercentComplete 9.375 -Id 1 -ParentId 0
    if ($creaturetagline -match '\(') {
        $5et | Add-Member -NotePropertyName type -NotePropertyValue @{
            type = $creaturetagline -replace '^[\w]+ ([\w \-]+) \([\w ,\-\)]+$', '$1'
            tags = @($creaturetagline -replace '^[\w ,\-]+\(([\w ,\-]+)\)[\w ,\-]+$', '$1' -split ", ")
        }
    } elseif ($creaturetagline -match 'swarm of') {
        switch -exact ($creaturetagline -replace '^[\w]+ swarm of ([\w]+) ([\w \-]+)[\w ,\-]*$', '$1') {
            "tiny" { $swarmSize = "T" }
            "small" { $swarmSize =  "S" }
            "medium" { $swarmSize =  "M" }
            "large" { $swarmSize =  "L" }
            "huge" { $swarmSize =  "H" }
            "gargantuan" { $swarmSize =  "G" }
            default {
                $swarmSize =  "XxX_ERROR_XxX : Unknown size ///"
                $err = $true
            }
        }
        $type = $creaturetagline -replace '^[\w]+ swarm of [\w]+ ([\w]+)[\w ,\-]*$', '$1'
        switch -exact ($type) {
            "fey" { }
            "monstrosities" { $type =  "monstrosity" }
            "undead" { }
            default { $type =  $type -replace 's$' }
        }
        $5et | Add-Member -NotePropertyName type -NotePropertyValue @{
            type = $type
            swarmSize = $swarmSize
        }
    } else {
        $5et | Add-Member -NotePropertyName type -NotePropertyValue ($creaturetagline -replace '^[\w]+ ([\w \-]+)[\w ,\-]*$', '$1')
    }

    # ALIGNMENT
    Write-Progress -Activity $name -Status "Aligning..." -PercentComplete 12.5 -Id 1 -ParentId 0
    switch -regex ($creaturetagline -replace '^[\w ,\-\(\)]+, ([\w \-]+)$', '$1') {
        "^unaligned$" { $5et | Add-Member -NotePropertyName alignment -NotePropertyValue @("U") }
        "^neutral$" { $5et | Add-Member -NotePropertyName alignment -NotePropertyValue @("N") }
        "^any( alignment)?$" { $5et | Add-Member -NotePropertyName alignment -NotePropertyValue @("A") }
        "^lawful good$" { $5et | Add-Member -NotePropertyName alignment -NotePropertyValue @("L", "G") }
        "^neutral good$" { $5et | Add-Member -NotePropertyName alignment -NotePropertyValue @("N", "G") }
        "^chaotic good$" { $5et | Add-Member -NotePropertyName alignment -NotePropertyValue @("C", "G") }
        "^chaotic neutral$" { $5et | Add-Member -NotePropertyName alignment -NotePropertyValue @("C", "N") }
        "^lawful evil$" { $5et | Add-Member -NotePropertyName alignment -NotePropertyValue @("L", "E") }
        "^lawful neutral$" { $5et | Add-Member -NotePropertyName alignment -NotePropertyValue @("L", "N") }
        "^neutral evil$" { $5et | Add-Member -NotePropertyName alignment -NotePropertyValue @("N", "E") }
        "^chaotic evil$" { $5et | Add-Member -NotePropertyName alignment -NotePropertyValue @("C", "E") }
        "^any non\-good( alignment)?$" { $5et | Add-Member -NotePropertyName alignment -NotePropertyValue @("L", "NX", "C", "NY", "E") }
        "^any non\-lawful( alignment)?$" { $5et | Add-Member -NotePropertyName alignment -NotePropertyValue @("NX", "C", "G", "NY", "E") }
        "^any non\-evil( alignment)?$" { $5et | Add-Member -NotePropertyName alignment -NotePropertyValue @("L", "NX", "C", "NY", "G") }
        "^any non\-chaotic( alignment)?$" { $5et | Add-Member -NotePropertyName alignment -NotePropertyValue @("NX", "L", "G", "NY", "E") }
        "^any chaotic( alignment)?$" { $5et | Add-Member -NotePropertyName alignment -NotePropertyValue @("C", "G", "NY", "E") }
        "^any evil( alignment)?$" { $5et | Add-Member -NotePropertyName alignment -NotePropertyValue @("L", "NX", "C", "E") }
        "^any lawful( alignment)?$" { $5et | Add-Member -NotePropertyName alignment -NotePropertyValue @("L", "G", "NY", "E") }
        "^any good( alignment)?$" { $5et | Add-Member -NotePropertyName alignment -NotePropertyValue @("L", "NX", "C", "G") }
        "^any neutral( alignment)?$" { $5et | Add-Member -NotePropertyName alignment -NotePropertyValue @("NX", "NY", "N") }
        "^good$" { $5et | Add-Member -NotePropertyName alignment -NotePropertyValue @("G") }
        "^lawful$" { $5et | Add-Member -NotePropertyName alignment -NotePropertyValue @("L") }
        "^chaotic$" { $5et | Add-Member -NotePropertyName alignment -NotePropertyValue @("C") }
        "^evil$" { $5et | Add-Member -NotePropertyName alignment -NotePropertyValue @("E") }
        default {
            $5et | Add-Member -NotePropertyName alignment -NotePropertyValue @("XxX_ERROR_XxX : Uninterpretable string ///")
            $err = $true
        }
    }

    # AC
    Write-Progress -Activity $name -Status "Armouring..." -PercentComplete 15.625 -Id 1 -ParentId 0
    if (($r20.attributes | where { $_.name -eq "npc_actype" } | Select -ExpandProperty current) -eq "") {
        $5et | Add-Member -NotePropertyName ac -NotePropertyValue @($r20.attributes | where { $_.name -eq "npc_ac" } | Select -ExpandProperty current)
    } elseif (($r20.attributes | where { $_.name -eq "npc_actype" } | Select -ExpandProperty current) -match '^[a-zA-Z ,\-]+$') {
        $5et | Add-Member -NotePropertyName ac -NotePropertyValue @( @{
            ac = $r20.attributes | where { $_.name -eq "npc_ac" } | Select -ExpandProperty current
            from = ($r20.attributes | where { $_.name -eq "npc_actype" } | Select -ExpandProperty current) -split ", "
        })
    } elseif (($r20.attributes | where { $_.name -eq "npc_actype" } | Select -ExpandProperty current) -match '^\d+ with .+$') {
        $5et | Add-Member -NotePropertyName ac -NotePropertyValue @(
            ($r20.attributes | where { $_.name -eq "npc_ac" } | Select -ExpandProperty current),
            [ordered]@{
                ac = ($r20.attributes | where { $_.name -eq "npc_actype" } | Select -ExpandProperty current) -replace '^([\d]+) with .+$', '$1'
                condition = ($r20.attributes | where { $_.name -eq "npc_actype" } | Select -ExpandProperty current) -replace '^[\d]+ (with .+)$', '$1'
                braces = $true
            }
        )
    } else {
        $5et | Add-Member -NotePropertyName ac -NotePropertyValue @("XxX_ERROR_XxX : Uninterpretable string ///")
        $err = $true
    }

    # HP
    Write-Progress -Activity $name -Status "Healing..." -PercentComplete 18.75 -Id 1 -ParentId 0
    $5et | Add-Member -NotePropertyName hp -NotePropertyValue @{
        average = $r20.attributes | where { $_.name -eq "hp"} | Select -ExpandProperty max
        formula = $r20.attributes | where { $_.name -eq "npc_hpformula"} | Select -ExpandProperty current
    }

    # SPEED (walk > burrow > climb > fly > swim)
    Write-Progress -Activity $name -Status "Speeding..." -PercentComplete 21.875 -Id 1 -ParentId 0
    if (($r20.attributes | where { $_.name -eq "npc_speed" } | Select -ExpandProperty "current") -match '^(?<walk>\d+ ?ft\.?(?<walkcond> \(.+\))?)(?<burrow>, burrow \d+ ?ft\.?(?<burrowcond> \(.+\))?)?(?<climb>, climb \d+ ?ft\.?(?<climbcond> \(.+\))?)?(?<fly>, fly \d+ ?ft\.?(?<flycond> \(.+\))?)?(?<swim>, swim \d+ ?ft\.?(?<swimcond> \(.+\))?)?$') {
        if ($matches.walkcond) {
            $5et | Add-Member -NotePropertyName speed -NotePropertyValue ([ordered]@{
                walk = @{
                    number = $matches.walk -replace '\D'
                    condition = ($matches.walk -replace '^[\w ,\.\-]* ([\(\w ,\.\-\)]+)$', '$1')
                }
            })
        } else {
            $5et | Add-Member -NotePropertyName speed -NotePropertyValue @{
                walk = $matches.walk -replace '\D'
            }
        }
        if ($matches.burrowcond) {
            $5et.speed.add("burrow", [ordered]@{
                number = $matches.burrow -replace '\D'
                condition = ($matches.burrow -replace '^[\w ,\.\-]* ([\(\w ,\.\-\)]+)$', '$1')
            })
        } elseif ($matches.burrow) {
            $5et.speed.add("burrow", $matches.burrow -replace '\D')
        }
        if ($matches.climbcond) {
            $5et.speed.add("climb", [ordered]@{
                number = $matches.climb -replace '\D'
                condition = ($matches.climb -replace '^[\w ,\.\-]* ([\(\w ,\.\-\)]+)$', '$1')
            })
        } elseif ($matches.climb) {
            $5et.speed.add("climb", $matches.climb -replace '\D')
        }
        if ($matches.flycond) {
            $5et.speed.add("fly", [ordered]@{
                number = $matches.fly -replace '\D'
                condition = ($matches.fly -replace '^[\w ,\.\-]* ([\(\w ,\.\-\)]+)$', '$1')
            })
            if ($5et.speed.fly.condition -match 'hover') {
                $5et.speed.add("canHover", $true)
            }
        } elseif ($matches.fly) {
            $5et.speed.add("fly", $matches.fly -replace '\D')
        }
        if ($matches.swimcond) {
            $5et.speed.add("swim", [ordered]@{
                number = $matches.swim -replace '\D'
                condition = ($matches.swim -replace '^[\w ,\.\-]* ([\(\w ,\.\-\)]+)$', '$1')
            })
        } elseif ($matches.swim) {
            $5et.speed.add("swim", $matches.swim -replace '\D')
        }
    } else {
        $5et | Add-Member -NotePropertyName speed -NotePropertyValue @{
            walk = "XxX_ERROR_XxX : Uninterpretable string ///"
        }
        $err = $true
    }

    # ABILITY SCORES
    Write-Progress -Activity $name -Status "Scoring..." -PercentComplete 25 -Id 1 -ParentId 0
    $5et | Add-Member -NotePropertyName str -NotePropertyValue ($r20.attributes | where { $_.name -eq "strength_base"} | Select -ExpandProperty current)
    $5et | Add-Member -NotePropertyName dex -NotePropertyValue ($r20.attributes | where { $_.name -eq "dexterity_base"} | Select -ExpandProperty current)
    $5et | Add-Member -NotePropertyName con -NotePropertyValue ($r20.attributes | where { $_.name -eq "constitution_base"} | Select -ExpandProperty current)
    $5et | Add-Member -NotePropertyName int -NotePropertyValue ($r20.attributes | where { $_.name -eq "intelligence_base"} | Select -ExpandProperty current)
    $5et | Add-Member -NotePropertyName wis -NotePropertyValue ($r20.attributes | where { $_.name -eq "wisdom_base"} | Select -ExpandProperty current)
    $5et | Add-Member -NotePropertyName cha -NotePropertyValue ($r20.attributes | where { $_.name -eq "charisma_base"} | Select -ExpandProperty current)

    # SAVES
    Write-Progress -Activity $name -Status "Saving..." -PercentComplete 28.125 -Id 1 -ParentId 0
    if ($r20.attributes | where { $_.name -eq "npc_saving_flag" } | Select -ExpandProperty current) {
        $saves = [PSCustomObject]@{}
        $r20.attributes | where {$_.name -match 'npc_..._save_base'} | ForEach-Object {
            if ($_.current -ne "") {
                $saves | Add-Member -NotePropertyName ($_.name -replace "npc_" -replace "_save_base") -NotePropertyValue $_.current
            }
        }
        $5et | Add-Member -NotePropertyName save -NotePropertyValue $saves
    }

    # SKILLS
    Write-Progress -Activity $name -Status "Training..." -PercentComplete 31.25 -Id 1 -ParentId 0
    if ($r20.attributes | where { $_.name -eq "npc_skills_flag" } | Select -ExpandProperty current) {
        $skills = [PSCustomObject]@{}
        if (($r20.attributes | where { $_.name -eq "npc_acrobatics" } | Select -ExpandProperty current) -ne "") {
            $skills | Add-Member `
                -NotePropertyName "acrobatics" `
                -NotePropertyValue ("+" + ($r20.attributes | where { $_.name -eq "npc_acrobatics" } | Select -ExpandProperty current))
        }
        if (($r20.attributes | where { $_.name -eq "npc_animal_handling" } | Select -ExpandProperty current) -ne "") {
            $skills | Add-Member `
                -NotePropertyName "animal handling" `
                -NotePropertyValue ("+" + ($r20.attributes | where { $_.name -eq "npc_animal_handling" } | Select -ExpandProperty current))
        }
        if (($r20.attributes | where { $_.name -eq "npc_arcana" } | Select -ExpandProperty current) -ne "") {
            $skills | Add-Member `
                -NotePropertyName "arcana" `
                -NotePropertyValue ("+" + ($r20.attributes | where { $_.name -eq "npc_arcana" } | Select -ExpandProperty current))
        }
        if (($r20.attributes | where { $_.name -eq "npc_athletics" } | Select -ExpandProperty current) -ne "") {
            $skills | Add-Member `
                -NotePropertyName "athletics" `
                -NotePropertyValue ("+" + ($r20.attributes | where { $_.name -eq "npc_athletics" } | Select -ExpandProperty current))
        }
        if (($r20.attributes | where { $_.name -eq "npc_deception" } | Select -ExpandProperty current) -ne "") {
            $skills | Add-Member `
                -NotePropertyName "deception" `
                -NotePropertyValue ("+" + ($r20.attributes | where { $_.name -eq "npc_deception" } | Select -ExpandProperty current))
        }
        if (($r20.attributes | where { $_.name -eq "npc_history" } | Select -ExpandProperty current) -ne "") {
            $skills | Add-Member `
                -NotePropertyName "history" `
                -NotePropertyValue ("+" + ($r20.attributes | where { $_.name -eq "npc_history" } | Select -ExpandProperty current))
        }
        if (($r20.attributes | where { $_.name -eq "npc_insight" } | Select -ExpandProperty current) -ne "") {
            $skills | Add-Member `
                -NotePropertyName "insight" `
                -NotePropertyValue ("+" + ($r20.attributes | where { $_.name -eq "npc_insight" } | Select -ExpandProperty current))
        }
        if (($r20.attributes | where { $_.name -eq "npc_intimidation" } | Select -ExpandProperty current) -ne "") {
            $skills | Add-Member `
                -NotePropertyName "intimidation" `
                -NotePropertyValue ("+" + ($r20.attributes | where { $_.name -eq "npc_intimidation" } | Select -ExpandProperty current))
        }
        if (($r20.attributes | where { $_.name -eq "npc_investigation" } | Select -ExpandProperty current) -ne "") {
            $skills | Add-Member `
                -NotePropertyName "investigation" `
                -NotePropertyValue ("+" + ($r20.attributes | where { $_.name -eq "npc_investigation" } | Select -ExpandProperty current))
        }
        if (($r20.attributes | where { $_.name -eq "npc_medicine" } | Select -ExpandProperty current) -ne "") {
            $skills | Add-Member `
                -NotePropertyName "medicine" `
                -NotePropertyValue ("+" + ($r20.attributes | where { $_.name -eq "npc_medicine" } | Select -ExpandProperty current))
        }
        if (($r20.attributes | where { $_.name -eq "npc_nature" } | Select -ExpandProperty current) -ne "") {
            $skills | Add-Member `
                -NotePropertyName "nature" `
                -NotePropertyValue ("+" + ($r20.attributes | where { $_.name -eq "npc_nature" } | Select -ExpandProperty current))
        }
        if (($r20.attributes | where { $_.name -eq "npc_perception" } | Select -ExpandProperty current) -ne "") {
            $skills | Add-Member `
                -NotePropertyName "perception" `
                -NotePropertyValue ("+" + ($r20.attributes | where { $_.name -eq "npc_perception" } | Select -ExpandProperty current))
        }
        if (($r20.attributes | where { $_.name -eq "npc_performance" } | Select -ExpandProperty current) -ne "") {
            $skills | Add-Member `
                -NotePropertyName "performance" `
                -NotePropertyValue ("+" + ($r20.attributes | where { $_.name -eq "npc_performance" } | Select -ExpandProperty current))
        }
        if (($r20.attributes | where { $_.name -eq "npc_persuasion" } | Select -ExpandProperty current) -ne "") {
            $skills | Add-Member `
                -NotePropertyName "persuasion" `
                -NotePropertyValue ("+" + ($r20.attributes | where { $_.name -eq "npc_persuasion" } | Select -ExpandProperty current))
        }
        if (($r20.attributes | where { $_.name -eq "npc_religion" } | Select -ExpandProperty current) -ne "") {
            $skills | Add-Member `
                -NotePropertyName "religion" `
                -NotePropertyValue ("+" + ($r20.attributes | where { $_.name -eq "npc_religion" } | Select -ExpandProperty current))
        }
        if (($r20.attributes | where { $_.name -eq "npc_sleight_of_hand" } | Select -ExpandProperty current) -ne "") {
            $skills | Add-Member `
                -NotePropertyName "sleight of hand" `
                -NotePropertyValue ("+" + ($r20.attributes | where { $_.name -eq "npc_sleight_of_hand" } | Select -ExpandProperty current))
        }
        if (($r20.attributes | where { $_.name -eq "npc_stealth" } | Select -ExpandProperty current) -ne "") {
            $skills | Add-Member `
                -NotePropertyName "stealth" `
                -NotePropertyValue ("+" + ($r20.attributes | where { $_.name -eq "npc_stealth" } | Select -ExpandProperty current))
        }
        if (($r20.attributes | where { $_.name -eq "npc_survival" } | Select -ExpandProperty current) -ne "") {
            $skills | Add-Member `
                -NotePropertyName "survival" `
                -NotePropertyValue ("+" + ($r20.attributes | where { $_.name -eq "npc_survival" } | Select -ExpandProperty current))
        }
        $5et | Add-Member -NotePropertyName skill -NotePropertyValue $skills
    }

    # SENSES
    Write-Progress -Activity $name -Status "Sensing..." -PercentComplete 34.375 -Id 1 -ParentId 0
    [System.Collections.ArrayList]$senses = ($r20.attributes | where { $_.name -eq "npc_senses"} | Select -ExpandProperty current) -replace "passive Perception " -split ", " -replace '^\s+' -replace '\s+$'
    $5et | Add-Member -NotePropertyName passive -NotePropertyValue ([int]$senses[-1])
    if ($senses.Count -gt 1) {
        $senses.RemoveAt($senses.Count - 1)
        $5et | Add-Member -NotePropertyName senses -NotePropertyValue $senses
        # SENSE TAGS
        $5et | Add-Member -NotePropertyName senseTags -NotePropertyValue @()
        foreach ($sense in $senses) {
            switch -regex ($sense) {
                "^blindsight" { $5et.senseTags += "B" }
                "^darkvision" {
                    if ([int]($_ -replace '^darkvision (\d+) ?f.*', '$1') -ge 100) {
                        $5et.senseTags += "SD"
                    } else {
                        $5et.senseTags += "D"
                    }
                }
                "^tremorsense" { $5et.senseTags += "T" }
                "^truesight" { $5et.senseTags += "U" }
            }
        }
    }

    # DAMAGE VULNERABILITIES
    Write-Progress -Activity $name -Status "Weakling..." -PercentComplete 37.5 -Id 1 -ParentId 0
    if (($r20.attributes | where { $_.name -eq "npc_vulnerabilities" } | Select -ExpandProperty current) -ne "") {
        [System.Collections.ArrayList]$vulns = ($r20.attributes | where { $_.name -eq "npc_vulnerabilities" } | Select -ExpandProperty current ) -split "; "
        if ($vulns.Count -eq 1) {
            $vulns = $vulns -replace ", and ", ", " -replace " and ", ", " -split ", "
            if ($vulns -match ' from ') {
                $vulncond = [PSCustomObject]@{}
                [System.Collections.ArrayList]$vulnX = $vulns -replace ", and ", ", " -replace " and ", ", " -split ", "
                $vulnX += $vulnX[-1] -replace "\w+ from ([.]*)", "from $1"
                $vulnX[-2] = $vulnX[-2] -replace $vulnX[-1] -replace " "
                $vulncond | Add-Member -NotePropertyName note -NotePropertyValue $vulnX[-1]
                $vulnX.RemoveAt($vulnX.Count - 1)
                $vulncond | Add-Member -NotePropertyName vulnerable -NotePropertyValue $vulnX
                $vulncond | Add-Member -NotePropertyName cond -NotePropertyValue $true
                $5et | Add-Member -NotePropertyName vulnerable -NotePropertyValue @( $vulncond )
            } else {
                $5et | Add-Member -NotePropertyName vulnerable -NotePropertyValue $vulns
            }
        } elseif ($vulns.Count -eq 2) {
            $vulncond = [PSCustomObject]@{}
            [System.Collections.ArrayList]$vulnX = $vulns[-1] -replace ", and ", ", " -replace " and ", ", " -split ", "
            $vulnX += $vulnX[-1] -replace "\w+ from ([.]*)", "from $1"
            $vulnX[-2] = $vulnX[-2] -replace $vulnX[-1] -replace " "
            $vulncond | Add-Member -NotePropertyName note -NotePropertyValue $vulnX[-1]
            $vulnX.RemoveAt($vulnX.Count - 1)
            $vulncond | Add-Member -NotePropertyName vulnerable -NotePropertyValue $vulnX
            $vulncond | Add-Member -NotePropertyName cond -NotePropertyValue $true
            $vulns = ($vulns[0] -split ", ") + $vulncond
            $5et | Add-Member -NotePropertyName vulnerable -NotePropertyValue @( $vulns )
        } else {
            $5et | Add-Member -NotePropertyName vulnerable -NotePropertyValue @( "XxX_ERROR_XxX : Uninterpretable string ///" )
            $err = $true
        }
    }

    # DAMAGE RESISTANCES
    Write-Progress -Activity $name -Status "Resisting..." -PercentComplete 40.625 -Id 1 -ParentId 0
    if (($r20.attributes | where { $_.name -eq "npc_resistances" } | Select -ExpandProperty current) -ne "") {
        [System.Collections.ArrayList]$resists = ($r20.attributes | where { $_.name -eq "npc_resistances" } | Select -ExpandProperty current ) -split "; "
        if ($resists.Count -eq 1) {
            $resists = $resists -replace ", and ", ", " -replace " and ", ", " -split ", "
            if ($resists -match ' from ') {
                $resistscond = [PSCustomObject]@{}
                [System.Collections.ArrayList]$resistsX = $resists -replace ", and ", ", " -replace " and ", ", " -split ", " -replace '^\s+' -replace '\s+$'
                $resistsX += $resistsX[-1] -replace "\w+ from ([.]*)", "from $1"
                $resistsX[-2] = $resistsX[-2] -replace $resistsX[-1] -replace " "
                $resistscond | Add-Member -NotePropertyName note -NotePropertyValue $resistsX[-1]
                $resistsX.RemoveAt($resistsX.Count - 1)
                $resistscond | Add-Member -NotePropertyName resist -NotePropertyValue $resistsX
                $resistscond | Add-Member -NotePropertyName cond -NotePropertyValue $true
                $5et | Add-Member -NotePropertyName resist -NotePropertyValue @( $resistscond )
            } else {
                $5et | Add-Member -NotePropertyName resist -NotePropertyValue $resists
            }
        } elseif ($resists.Count -eq 2) {
            $resistscond = [PSCustomObject]@{}
            [System.Collections.ArrayList]$resistsX = $resists[-1] -replace ", and ", ", " -replace " and ", ", " -split ", " -replace '^\s+' -replace '\s+$'
            $resistsX += $resistsX[-1] -replace "\w+ from ([.]*)", "from $1"
            $resistsX[-2] = $resistsX[-2] -replace $resistsX[-1] -replace " "
            $resistscond | Add-Member -NotePropertyName note -NotePropertyValue $resistsX[-1]
            $resistsX.RemoveAt($resistsX.Count - 1)
            $resistscond | Add-Member -NotePropertyName resist -NotePropertyValue $resistsX
            $resistscond | Add-Member -NotePropertyName cond -NotePropertyValue $true
            $resists = [array]@($resists[0] -split ", ") + $resistscond
            $5et | Add-Member -NotePropertyName resist -NotePropertyValue @( $resists )
        } else {
            $5et | Add-Member -NotePropertyName resist -NotePropertyValue @( "XxX_ERROR_XxX : Uninterpretable string ///" )
            $err = $true
        }
    }

    # DAMAGE IMMUNITIES
    Write-Progress -Activity $name -Status "Inoculating..." -PercentComplete 43.75 -Id 1 -ParentId 0
    if (($r20.attributes | where { $_.name -eq "npc_immunities" } | Select -ExpandProperty current) -ne "") {
        [System.Collections.ArrayList]$immunes = ($r20.attributes | where { $_.name -eq "npc_immunities" } | Select -ExpandProperty current ) -split "; "
        if ($immunes.Count -eq 1) {
            $immunes = $immunes -replace ", and ", ", " -replace " and ", ", " -split ", "
            if ($immunes -match ' from ') {
                $immunescond = [PSCustomObject]@{}
                [System.Collections.ArrayList]$immunesX = $immunes -replace ", and ", ", " -replace " and ", ", " -split ", " -replace '^\s+' -replace '\s+$'
                $immunesX += $immunesX[-1] -replace "\w+ from ([.]*)", "from $1"
                $immunesX[-2] = $immunesX[-2] -replace $immunesX[-1] -replace " "
                $immunescond | Add-Member -NotePropertyName note -NotePropertyValue $immunesX[-1]
                $immunesX.RemoveAt($immunesX.Count - 1)
                $immunescond | Add-Member -NotePropertyName immune -NotePropertyValue $immunesX
                $immunescond | Add-Member -NotePropertyName cond -NotePropertyValue $true
                $5et | Add-Member -NotePropertyName immune -NotePropertyValue @($immunescond)
            } else {
                $5et | Add-Member -NotePropertyName immune -NotePropertyValue $immunes
            }
        } elseif ($immunes.Count -eq 2) {
            $immunescond = [PSCustomObject]@{}
            [System.Collections.ArrayList]$immunesX = $immunes[-1] -replace ", and ", ", " -replace " and ", ", " -split ", " -replace '^\s+' -replace '\s+$'
            $immunesX += $immunesX[-1] -replace "\w+ from ([.]*)", "from $1"
            $immunesX[-2] = $immunesX[-2] -replace $immunesX[-1] -replace " "
            $immunescond | Add-Member -NotePropertyName note -NotePropertyValue $immunesX[-1]
            $immunesX.RemoveAt($immunesX.Count - 1)
            $immunescond | Add-Member -NotePropertyName immune -NotePropertyValue $immunesX
            $immunescond | Add-Member -NotePropertyName cond -NotePropertyValue $true
            $immunes = ($immunes[0] -split ", ") + $immunescond
            $5et | Add-Member -NotePropertyName immune -NotePropertyValue @( $immunes )
        } else {
            $5et | Add-Member -NotePropertyName immune -NotePropertyValue @("XxX_ERROR_XxX : Uninterpretable string ///")
            $err = $true
        }
    }

    # CONDITION IMMUNITIES
    Write-Progress -Activity $name -Status "Curing..." -PercentComplete 47.875 -Id 1 -ParentId 0
    if (($r20.attributes | where { $_.name -eq "npc_condition_immunities" } | Select -ExpandProperty current) -ne "") {
        $5et | Add-Member -NotePropertyName conditionImmune -NotePropertyValue (($r20.attributes | where { $_.name -eq "npc_condition_immunities"} | Select -ExpandProperty current) -replace ", and ", ", " -replace " and ", ", " -split ", " -replace '^\s+' -replace '\s+$')
    }

    # LANGUAGES
    Write-Progress -Activity $name -Status "Speaking..." -PercentComplete 50 -Id 1 -ParentId 0
    if (($r20.attributes | where { $_.name -eq "npc_languages" } | Select -ExpandProperty current) -ne "") {
        $5et | Add-Member -NotePropertyName languages -NotePropertyValue (($r20.attributes | where { $_.name -eq "npc_languages"} | Select -ExpandProperty current) -replace ", and ", ", " -replace " and ", ", " -split ", " -replace '^\s+' -replace '\s+$')
        # LANGUAGE TAGS
        $5et | Add-Member -NotePropertyName languageTags -NotePropertyValue @()
        switch -regex ($5et.languages) {
            "(^|^understands )Common\b" { $5et.languageTags += "C" }
            "(^|^understands )Abyssal\b" { $5et.languageTags += "AB" }
            "(^|^understands )Aquan\b" { $5et.languageTags += "AQ" }
            "(^|^understands )Auran\b" { $5et.languageTags += "AU" }
            "(^|^understands )Celestial\b" { $5et.languageTags += "CE" }
            "(^|^understands )Draconic\b" { $5et.languageTags += "DR" }
            "(^|^understands )Dwarvish\b" { $5et.languageTags += "D" }
            "(^|^understands )Elvish\b" { $5et.languageTags += "E" }
            "(^|^understands )Giant\b" { $5et.languageTags += "GI" }
            "(^|^understands )Gnomish\b" { $5et.languageTags += "G" }
            "(^|^understands )Goblin\b" { $5et.languageTags += "GO" }
            "(^|^understands )Halfling\b" { $5et.languageTags += "H" }
            "(^|^understands )Infernal\b" { $5et.languageTags += "I" }
            "(^|^understands )Orc\b" { $5et.languageTags += "O" }
            "(^|^understands )Primordial\b" { $5et.languageTags += "P" }
            "(^|^understands )Sylvan\b" { $5et.languageTags += "S" }
            "(^|^understands )Terran\b" { $5et.languageTags += "T" }
            "(^|^understands )Druidic\b" { $5et.languageTags += "DU" }
            "(^|^understands )Gith\b" { $5et.languageTags += "GTH" }
            "(^|^understands )thieves' cant\b" { $5et.languageTags += "TC" }
            "(^|^understands )Deep Speech\b" { $5et.languageTags += "DS" }
            "(^|^understands )Ignan\b" { $5et.languageTags += "IG" }
            "(^|^understands )Undercommon\b" { $5et.languageTags += "U" }
            "^telepathy" { $5et.languageTags += "TP" }
            "^all\b" { $5et.languageTags += "XX" }
            "\blanguages\b" { }
            "\byou speak" { }
            "\bcreator\b" { }
            default { $5et.languageTags += "OTH" }
        }
        if ($5et.languages -match "\bcan't speak\b") { $5et.languageTags += "CS" }
        if ($5et.languages -match '\bin life\b') { $5et.languageTags += "LF" }
        if ($5et.languages -match '((^(any|plus|pick|choose) )|((other|extra|additional|more) lang)| (choice|choosing))') { $5et.languageTags += "X" }
    }

    # CR
    Write-Progress -Activity $name -Status "Rating..." -PercentComplete 53.125 -Id 1 -ParentId 0
    $5et | Add-Member -NotePropertyName cr -NotePropertyValue ($r20.attributes | where { $_.name -eq "npc_challenge"} | Select -ExpandProperty current)

    # TRAITS
    Write-Progress -Activity $name -Status "Attributing..." -PercentComplete 56.25 -Id 1 -ParentId 0
    $5et | Add-Member -NotePropertyName trait -NotePropertyValue @()
    $5et | Add-Member -NotePropertyName damageInflict -NotePropertyValue @()
    $5et | Add-Member -NotePropertyName conditionInflict -NotePropertyValue @()
    foreach ($id in (($r20.attributes | where { $_.name -match '^repeating_npctrait_-[\w_\-]+_name$' } | Select -ExpandProperty name) -replace 'repeating_npctrait_-([\w_\-]+)_name', '$1')) {
        $atk = @( $r20.attributes | where { $_.name -eq "repeating_npctrait_-${id}_description" } | Select -ExpandProperty current | Tag-Entries) -split " ?\n" -replace '^\s+' -replace '\s+$'
        $5et.trait += [ordered]@{
            name = ($r20.attributes | where { $_.name -eq "repeating_npctrait_-${id}_name" } | Select -ExpandProperty current)
            entries = $atk
        }
        # DAMAGE INFLICT TAGS
        $5et.damageInflict += $atk | Find-Damage-Types
        # CONDITION INFLICT TAGS
        $5et.conditionInflict += $atk | Find-Conditions
        ###
    }
    if ($5et.trait.Count -eq 0) {
        $5et.PSObject.Properties.Remove('trait')
    }

    # TRAIT TAGS
    Write-Progress -Activity $name -Status "Attributing tags..." -PercentComplete 59.375 -Id 1 -ParentId 0
    $5et | Add-Member -NotePropertyName traitTags -NotePropertyValue @()
    switch -regex ($5et.trait.name) {
            "^turn immunity" { $5et.traitTags += "Turn Immunity" }
            "^brute" { $5et.traitTags += "Brute" }
            "^antimagic susceptibility" { $5et.traitTags += "Antimagic Susceptibility" }
            "^sneak attack" { $5et.traitTags += "Sneak Attack" }
            "^reckless" { $5et.traitTags += "Reckless" }
            "^web sense" { $5et.traitTags += "Web Sense" }
            "^flyby" { $5et.traitTags += "Flyby" }
            "^pounce" { $5et.traitTags += "Pounce" }
            "^water breathing" { $5et.traitTags += "Water Breathing" }
            "^turn(ing)? (defiance|resistance)" { $5et.traitTags += "Turn Resistance" }
            "^undead fortitude" { $5et.traitTags += "Undead Fortitude" }
            "^aggressive" { $5et.traitTags += "Aggressive" }
            "^illumination" { $5et.traitTags += "Illumination" }
            "^rampage" { $5et.traitTags += "Rampage" }
            "^rejuvenation" { $5et.traitTags += "Rejuvenation" }
            "^web walker" { $5et.traitTags += "Web Walker" }
            "^incorporeal movement" { $5et.traitTags += "Incorporeal Movement" }
            "^keen (sight|hearing|smell|senses)" { $5et.traitTags += "Keen Senses" }
            "^hold breath" { $5et.traitTags += "Hold Breath" }
            "^charge" { $5et.traitTags += "Charge" }
            "^fey ancestry" { $5et.traitTags += "Fey Ancestry" }
            "^siege monster" { $5et.traitTags += "Siege Monster" }
            "^pack tactics" { $5et.traitTags += "Pack Tactics" }
            "^regenerat" { $5et.traitTags += "Regeneration" }
            "^shapechange" { $5et.traitTags += "Shapechanger" }
            "^false appearance" { $5et.traitTags += "False Appearance" }
            "^spider climb" { $5et.traitTags += "Spider Climb" }
            "^sunlight (hyper)?sensitivity" { $5et.traitTags += "Sunlight Sensitivity" }
            "^light sensitivity" { $5et.traitTags += "Light Sensitivity" }
            "^amphibious" { $5et.traitTags += "Amphibious" }
            "^legendary resistance" { $5et.traitTags += "Legendary Resistances" }
            "^magic weapon" { $5et.traitTags += "Magic Weapons" }
            "^magic resistance" { $5et.traitTags += "Magic Resistance" }
            "^spell immunity" { $5et.traitTags += "Spell Immunity" }
            "^ambush" { $5et.traitTags += "Ambusher" }
            "^amorphous" { $5et.traitTags += "Amorphous" }
            "^death (burst|throes)" { $5et.traitTags += "Death Burst" }
            "^devil'?s? sight" { $5et.traitTags += "Devil's Sight" }
            "^immutable form" { $5et.traitTags += "Immutable Form" }
        }
    if ($5et.traitTags.Count -eq 0) {
        $5et.PSObject.Properties.Remove('traitTags')
    }

    # SPELLCASTING
    Write-Progress -Activity $name -Status "Spellcasting..." -PercentComplete 62.5 -Id 1 -ParentId 0
    if ($r20.attributes | where { $_.name -eq "npcspellcastingflag" } | Select -ExpandProperty current) {
        $5et | Add-Member -NotePropertyName spellcasting -NotePropertyValue @()
        $5et | Add-Member -NotePropertyName spellcastingTags -NotePropertyValue @()
        $5et | Add-Member -NotePropertyName conditionInflictSpell -NotePropertyValue @()
        foreach ($block in (@($5et.trait.name) -match "^((Innate|Shared) )?Spellcasting( \(.+\))?$")) {
            $spelldesc = ($5et.trait | where { $_.name -eq $block }).entries -join '#@&' -split '(?<!,) ?#@&' -replace '#@&', ' '
            $5et.trait = @( $5et.trait | Where-Object { $_.name -ne $block } )
            # SPELLCASTING TAGS
            switch -regex ($block) {
                "\bInnate\b" { $5et.spellcastingTags += "I" }
                "\bPsionics\b" { $5et.spellcastingTags += "P" }
                "\bForm\b" { $5et.spellcastingTags += "F" }
                "\bShared\b" { $5et.spellcastingTags += "S" }
            }
            switch -regex ($spelldesc) {
                "\bartificer\b" { $5et.spellcastingTags += "CA" }
                "\bbard\b" { $5et.spellcastingTags += "CB" }
                "\bcleric\b" { $5et.spellcastingTags += "CC" }
                "\bdruid\b" { $5et.spellcastingTags += "CD" }
                "\bpaladin\b" { $5et.spellcastingTags += "CP" }
                "\branger\b" { $5et.spellcastingTags += "CR" }
                "\bsorcerer\b" { $5et.spellcastingTags += "CS" }
                "\bwarlock\b" { $5et.spellcastingTags += "CL" }
                "\bwizard\b" { $5et.spellcastingTags += "CW" }
            }
            ###
            if ($spelldesc.Count -le 1) {
                $5et.spellcasting += [ordered]@{
                    name = $block
                    ability = ($spelldesc[0] -creplace '^.+(Intelligence|Wisdom|Charisma|Constitution|Strength|Dexterity).+$', '$1' -replace '^(...).+$', '$1').ToLower()
                    headerEntries = @($spelldesc[0] -replace '^\s+' -replace '\s+$')
                    footerEntries = "XxX_ERROR_XxX : Special spell list ///"
                }
                $err = $true
            } else {
                $spellheader = [ordered]@{
                    type = "spellcasting"
                    name = $block
                    ability = ($spelldesc[0] -creplace '^.+(Intelligence|Wisdom|Charisma|Constitution|Strength|Dexterity).+$', '$1' -replace '^(...).+$', '$1').ToLower()
                    headerEntries = @($spelldesc[0] -replace '^\s+' -replace '\s+$')
                }
                $spellcontent = [ordered]@{
                    spells = @{}
                    daily = @{}
                    rest = @{}
                    weekly = @{}
                }
                foreach ($line in $spelldesc | select -skip 1) {
                    switch -regex ($line) {
                        "^\d/day: " { $spellcontent.daily.add( ($_ -replace "/day: .*$"), @(($_ -replace "^\d/day: ") | Split-And-Tag-Spell-Lists) ) }
                        "^\d/day each: " { $spellcontent.daily.add( (($_ -replace "/day each: .*$") + "e"), @(($_ -replace "^\d/day each: ") | Split-And-Tag-Spell-Lists) ) }
                        "^at will: " { $spellheader += @{ will = @(($_ -replace "^at will: ") | Split-And-Tag-Spell-Lists) } }
                        "^cantrips( \((at will|0th( |-)level)\))?: " { $spellcontent.spells.add( "0", @{ spells = @(($_ -replace "^cantrips( \((at will|0th( |-)level)\))?: ") | Split-And-Tag-Spell-Lists) } ) }
                        "^\d\w\w( |-)level: " { $spellcontent.spells.add( ($_ -replace "\w\w( |-)level: .*$"), @{
                            spells = @(($_ -replace "^\d\w\w( |-)level: ") | Split-And-Tag-Spell-Lists)
                            slots = 0
                        } ) }
                        "^\d\w\w( |-)level \(\d slots?\): " { $spellcontent.spells.add( ($_ -replace "\w\w( |-)level \(\d slots?\): .*$"), @{
                            spells = @(($_ -replace "^\d\w\w( |-)level \(\d slots?\): ") | Split-And-Tag-Spell-Lists)
                            slots = [int]($_ -replace "^\d\w\w( |-)level \((\d) slots?\): .*$", '$2')
                        } ) }
                        "^\d\w\w-\d\w\w( |-)level: " { $spellcontent.spells.add( ($_ -replace "^\d\w\w-(\d)\w\w( |-)level: .*$", '$1'), @{
                            spells = @(($_ -replace "^\d\w\w( |-)level \(\d slots?\): ") | Split-And-Tag-Spell-Lists)
                            slots = 0
                            lower = [int]($_ -replace "^(\d)\w\w-\d\w\w( |-)level \(\d slots?\): .*$", '$1')
                        } ) }
                        "^\d\w\w-\d\w\w( |-)level \(\d slots?\): " { $spellcontent.spells.add( ($_ -replace "^\d\w\w-(\d)\w\w( |-)level \(\d slots?\): .*$", '$1'), @{
                            spells = @(($_ -replace "^\d\w\w( |-)level \(\d slots?\): ") | Split-And-Tag-Spell-Lists)
                            slots = [int]($_ -replace "^\d\w\w-\d\w\w( |-)level \((\d) slots?\): .*$", '$2')
                            lower = [int]($_ -replace "^(\d)\w\w-\d\w\w( |-)level \(\d slots?\): .*$", '$1')
                        } ) }
                        "^constant: " { $spellheader += @{ constant = @(($_ -replace "^constant: ") | Split-And-Tag-Spell-Lists) } }
                        "^\d/rest: " { $spellcontent.rest.add( ($_ -replace "/rest: .*$"), @{ spells = @(($_ -replace "^\d/rest: ") | Split-And-Tag-Spell-Lists) } ) }
                        "^\d/rest each: " { $spellcontent.rest.add( (($_ -replace "/rest each: .*$") + "e"), @(($_ -replace "^\d/rest each: ") | Split-And-Tag-Spell-Lists) ) }
                        "^\d/week: " { $spellcontent.weekly.add( ($_ -replace "/week: .*$"), @{ spells = @(($_ -replace "^\d/week: ") | Split-And-Tag-Spell-Lists) } ) }
                        "^\d/week each: " { $spellcontent.weekly.add( (($_ -replace "/week each: .*$") + "e"), @(($_ -replace "^\d/week each: ") | Split-And-Tag-Spell-Lists) ) }
                        "^\* ?\w+\b" { $spellheader += @{ footerEntries = @( $_ ) } }
                        # TODO check whether ritual has been added or removed in next update
                        default {
                            $spellheader += @{ footerEntries = @( "XxX_ERROR_XxX : Uninterpretable spell-list format ///" ) } 
                            $err = $true
                        }
                    }
                }
                ($spellcontent.GetEnumerator() | where { $_.Value.Count -eq 0 }) | ForEach-Object {
                    $spellcontent.Remove($_.Name)
                }
                $5et.spellcasting += $spellheader + $spellcontent
            }
        }
    }

    # ACTIONS
    Write-Progress -Activity $name -Status "Acting..." -PercentComplete 65.625 -Id 1 -ParentId 0
    $5et | Add-Member -NotePropertyName action -NotePropertyValue @()
    foreach ($id in (($r20.attributes | where { $_.name -match '^repeating_npcaction_-[\w_\-]+_name$' } | Select -ExpandProperty name) -replace 'repeating_npcaction_-([\w_\-]+)_name', '$1')) {
        if ($r20.attributes | where { $_.name -eq "repeating_npcaction_-${id}_attack_flag" }) {
            switch -regex ($r20.attributes | where { $_.name -eq "repeating_npcaction_-${id}_name" } | Select -ExpandProperty current) {
                '^.+ \(Ranged\)$' {
                    $atk = "XxX_ERROR_XxX : Ranged duplicate ///"
                    $err = $true
                }
					 '^.+ \(two\-handed\)$' {
                    $atk = "XxX_ERROR_XxX : Versatile duplicate ///"
                    $err = $true
                }
                '^.+ \(swarm has .*less.*\)$' {
                    $atk = "XxX_ERROR_XxX : Swarm HP-dependent duplicate ///"
                    $err = $true
                }
                default {
                    switch ($r20.attributes | where { $_.name -eq "repeating_npcaction_-${id}_attack_type" } | Select -ExpandProperty current) {
                        "Melee" { $atk = '{@atk mw}' }
                        "Ranged" { $atk = '{@atk rw}' }
                        default {
                            $atk = 'XxX_ERROR_XxX : Unknown attack type ///'
                            $err = $true
                        }
                    }
                    # TODO Check whteher rider effects are consistent in R20 vs book
                    $atk += " {@hit " + (($r20.attributes | where { $_.name -eq "repeating_npcaction_-${id}_attack_tohitrange" } | Select -ExpandProperty current) -replace '^([\d\+\-]+)(, .+)?$', '$1') + "} to hit"
                    $atk += (($r20.attributes | where { $_.name -eq "repeating_npcaction_-${id}_attack_tohitrange" } | Select -ExpandProperty current) -replace '^([\d\+\-]+)(.*)$', '$2' -creplace '\bR(?=(each|ange)\b)', 'r') + "."
                    if ($r20.attributes | where { $_.name -eq "repeating_npcaction_-${id}_attack_onhit" } | Select -ExpandProperty current) {
                        $atk += " {@h}" + ($r20.attributes | where { $_.name -eq "repeating_npcaction_-${id}_attack_onhit" } | Select -ExpandProperty current)
                        if (($r20.attributes | where { $_.name -eq "repeating_npcaction_-${id}_description" } | Select -ExpandProperty current) -match "^If") {
                            $atk += ". " + ($r20.attributes | where { $_.name -eq "repeating_npcaction_-${id}_description" } | Select -ExpandProperty current)
                        } elseif ($r20.attributes | where { $_.name -eq "repeating_npcaction_-${id}_description" } | Select -ExpandProperty current) {
                            $atk += ", and " + (($r20.attributes | where { $_.name -eq "repeating_npcaction_-${id}_description" } | Select -ExpandProperty current) -creplace "^T", "t")
                        } else {
                            $atk += "."
                        }
                    } else {
                        if ($r20.attributes | where { $_.name -eq "repeating_npcaction_-${id}_description" } | Select -ExpandProperty current) {
                            $atk += " {@h}" + ($r20.attributes | where { $_.name -eq "repeating_npcaction_-${id}_description" } | Select -ExpandProperty current)
                        } else {
                            $atk += "XxX_ERROR_XxX : Missing attack effects ///"
                        }
                    }
                }
            }
            $atk = $atk | Tag-Entries
            $5et.action += @( [ordered]@{
                name =  $r20.attributes | where { $_.name -eq "repeating_npcaction_-${id}_name" } | Select -ExpandProperty current | Tag-Action-Name
                entries = $atk -split ' ?\n' -replace '^\s+' -replace '\s+$'
            } )
            # DAMAGE INFLICT TAGS
            switch -exact ($r20.attributes | where { $_.name -eq "repeating_npcaction_-${id}_attack_damagetype" } | Select -ExpandProperty current) {
                bludgeoning { $5et.damageInflict += "B" }
                piercing { $5et.damageInflict += "P" }
                slashing { $5et.damageInflict += "S" }
                acid { $5et.damageInflict += "A" }
                cold { $5et.damageInflict += "C" }
                fire { $5et.damageInflict += "F" }
                force { $5et.damageInflict += "O" }
                lightning { $5et.damageInflict += "L" }
                necrotic { $5et.damageInflict += "N" }
                poison { $5et.damageInflict += "I" }
                psychic { $5et.damageInflict += "Y" }
                radiant { $5et.damageInflict += "R" }
                thunder { $5et.damageInflict += "T" }
            }
            switch -exact ($r20.attributes | where { $_.name -eq "repeating_npcaction_-${id}_attack_damagetype2" } | Select -ExpandProperty current) {
                bludgeoning { $5et.damageInflict += "B" }
                piercing { $5et.damageInflict += "P" }
                slashing { $5et.damageInflict += "S" }
                acid { $5et.damageInflict += "A" }
                cold { $5et.damageInflict += "C" }
                fire { $5et.damageInflict += "F" }
                force { $5et.damageInflict += "O" }
                lightning { $5et.damageInflict += "L" }
                necrotic { $5et.damageInflict += "N" }
                poison { $5et.damageInflict += "I" }
                psychic { $5et.damageInflict += "Y" }
                radiant { $5et.damageInflict += "R" }
                thunder { $5et.damageInflict += "T" }
            }
            # CONDITION INFLICT TAGS
            $5et.conditionInflict += $atk | Find-Conditions
            ###
        } else {
            $atk = @( $r20.attributes | where { $_.name -eq "repeating_npcaction_-${id}_description" } | Select -ExpandProperty current | Tag-Entries ) -split ' ?\n'
            $5et.action += @( [ordered]@{
                name = $r20.attributes | where { $_.name -eq "repeating_npcaction_-${id}_name" } | Select -ExpandProperty current | Tag-Action-Name
                entries = $atk -replace '^\s+' -replace '\s+$'
            } )
            # DAMAGE INFLICT TAGS
            $5et.damageInflict += $atk | Find-Damage-Types
            # CONDITION INFLICT TAGS
            $5et.conditionInflict += $atk | Find-Conditions
            ###
        }
    }
    if ($5et.action.Count -eq 0) {
        $5et.PSObject.Properties.Remove('action')
    }

    # REACTIONS
    Write-Progress -Activity $name -Status "Reacting..." -PercentComplete 68.75 -Id 1 -ParentId 0
    if ($r20.attributes | where { $_.name -eq "npcreactionsflag" } | Select -ExpandProperty current) {
        $5et | Add-Member -NotePropertyName reaction -NotePropertyValue @()
        foreach ($id in (($r20.attributes | where { $_.name -match '^repeating_npcreaction_-[\w_\-]+_name$' } | Select -ExpandProperty name) -replace 'repeating_npcreaction_-([\w_\-]+)_name', '$1')) {
            $atk = @( $r20.attributes | where { $_.name -eq "repeating_npcreaction_-${id}_description" } | Select -ExpandProperty current | Tag-Entries ) -split ' ?\n'
            $5et.reaction += [ordered]@{
                name = $r20.attributes | where { $_.name -eq "repeating_npcreaction_-${id}_name" } | Select -ExpandProperty current | Tag-Action-Name
                entries = $atk -replace '^\s+' -replace '\s+$'
            }
            # DAMAGE INFLICT TAGS
            $5et.damageInflict += $atk | Find-Damage-Types
            # CONDITION INFLICT TAGS
            $5et.conditionInflict += $atk | Find-Conditions
        }
    }

    # ACTION TAGS
    Write-Progress -Activity $name -Status "Actively tagging..." -PercentComplete 71.875 -Id 1 -ParentId 0
    $5et | Add-Member -NotePropertyName actionTags -NotePropertyValue @()
    switch -regex ($5et.action.name) {
        "^Multiattack" { $5et.actionTags += "Multiattack" }
        "^Frightful Presence" { $5et.actionTags += "Frightful Presence" }
        "^Teleport" { $5et.actionTags += "Teleport" }
        "^Swallow" { $5et.actionTags += "Swallow" }
        "^Tentacle" { $5et.actionTags += "Tentacles" }
    }
    if ($5et.action.entries -match '\bswallowed\b') {
        $5et.actionTags += "Swallow"
    }
    switch -regex ($5et.reaction.name) {
        "^Parry" { $5et.actionTags += "Parry" }
    }

    # LEGENDARY ACIONS
    Write-Progress -Activity $name -Status "Frightening..." -PercentComplete 75 -Id 1 -ParentId 0
    $5et | Add-Member -NotePropertyName conditionInflictLegendary -NotePropertyValue @()
    if (($r20.attributes | where { $_.name -eq "npc_legendary_actions" } | Select -ExpandProperty current) -ne "") {
        if (($r20.attributes | where { $_.name -eq "npc_legendary_actions" } | Select -ExpandProperty current) -ne 3) {
            $5et | Add-Member -NotePropertyName legendaryActions -NotePropertyValue ($r20.attributes | where { $_.name -eq "npc_legendary_actions" } | Select -ExpandProperty current)
        }
        if (($r20.attributes | where { $_.name -eq "npc_legendary_actions_desc" } | Select -ExpandProperty current) -ne "The $name can take 3, choosing from the options below. Only one legendary option can be used at a time and only at the end of another creature's turn. The $name regains spent legendary actions at the start of its turn." ) {
            $5et | Add-Member -NotePropertyName legendaryHeader -NotePropertyValue @($r20.attributes | where { $_.name -eq "npc_legendary_actions_desc" } | Select -ExpandProperty current)
        } elseif (($r20.attributes | where { $_.name -eq "npc_legendary_actions_desc" } | Select -ExpandProperty current) -eq "$name can take 3, choosing from the options below. Only one legendary option can be used at a time and only at the end of another creature's turn. $name regains spent legendary actions at the start of its turn." ) {
            $5et | Add-Member -NotePropertyName isNamedCreature -NotePropertyValue $true
        }
        $5et | Add-Member -NotePropertyName legendary -NotePropertyValue @()
        foreach ($id in (($r20.attributes | where { $_.name -match '^repeating_npcaction-l_-[\w_\-]+_name$' } | Select -ExpandProperty name) -replace 'repeating_npcaction-l_-([\w_\-]+)_name', '$1')) {
            $atk = @( $r20.attributes | where { $_.name -eq "repeating_npcaction-l_-${id}_description" } | Select -ExpandProperty current | Tag-Entries ) -split ' ?\n'
            $5et.legendary += [ordered]@{
                name = $r20.attributes | where { $_.name -eq "repeating_npcaction-l_-${id}_name" } | Select -ExpandProperty current
                entries = $atk -replace '^\s+' -replace '\s+$'
            }
            # DAMAGE INFLICT TAGS
            $5et.damageInflict += $atk | Find-Damage-Types
            # CONDITION INFLICT TAGS
            $5et.conditionInflictLegendary += $atk | Find-Conditions
				# TAG ACTIONS
				switch -regex ($5et.legendary.name) {
                "^Multiattack" { $5et.actionTags += "Multiattack" }
                "^Frightful Presence" { $5et.actionTags += "Frightful Presence" }
                "^Teleport" { $5et.actionTags += "Teleport" }
                "^Swallow" { $5et.actionTags += "Swallow" }
                "^Tentacle" { $5et.actionTags += "Tentacles" }
				}
				if ($5et.action.entries -match '\bswallowed\b') {
                $5et.actionTags += "Swallow"
				}
        }
    }

    # MYTHIC ACTIONS
    # TODO

    # MISC TAGS
    Write-Progress -Activity $name -Status "Miscellaneously tagging..." -PercentComplete 78.125 -Id 1 -ParentId 0
    # TODO Find THW by assumption when a '* (Ranged)' attack action is found? Check SRD for examples
    $5et | Add-Member -NotePropertyName miscTags -NotePropertyValue @()
    switch -regex ($5et.action.entries) {
        '^\{@atk mw' { $5et.miscTags += "MW" }
        '^\{@atk rw' { $5et.miscTags += "RW" }
        '\breach \d{2,} ft\.' { $5et.miscTags += "RCH" }
        '\b(sphere|line|cone|cube)\b' { $5et.miscTags += "AOE" }
        '\b(each (target|creature)|(targets|creatures)) (with)?in (a )?\d+( |-)f(oo|ee)?t\b' { $5et.miscTags += "AOE" }
    }
    switch -regex ($5et.action.name) {
		 '\b((short|long|cross)bow|sling|dart|net|(shot|blow)gun|rifle|pistol|musket|revolver)\b' { $5et.miscTags += "RNG" }
		 '\(Ranged\)$' { $5et.miscTags += "THW" }
    }

    # TOKEN
    Write-Progress -Activity $name -Status "Portraiting..." -PercentComplete 81.25 -Id 1 -ParentId 0
    if ($token) {
        $5et | Add-Member -NotePropertyName tokenUrl -NotePropertyValue ("https://raw.githubusercontent.com/TheGiddyLimit/homebrew/master/_img/" + $source + "/creature/token/" + $5et.name + " (Token).png")
    }

    # FLUFF + LAIR ACTIONS + REGIONAL EFFECTS
    Write-Progress -Activity $name -Status "Biographing..." -PercentComplete 84.375 -Id 1 -ParentId 0
    [System.Collections.ArrayList]$bio = $r20.bio -split "</?h\d>"
    [System.Collections.ArrayList]$LARE = $bio[1..($bio.Count - 1)] -split ' ?\n'
    if ($fluff -or $image) {
        $5et | Add-Member -NotePropertyName fluff -NotePropertyValue @{}
    }
    if ($fluff) {
        $bio = (($bio[0] -replace '</?p>' -replace '\t' -replace '<br>') | Tag-Entries) -split ' ?\n' 
        for ($i = 0; $i -lt $bio.Count; $i++) {
            if ($bio[$i] -match "^\s*$") { # Remove empty lines
                $bio.RemoveAt($i)
                $i--
            } elseif ($bio[$i] -match "^<img .+>.?$") { # Remove images
                $bio.RemoveAt($i)
                $i--
            }
        }
        for ($i = 0; $i -lt $bio.Count; $i++) {
            if ($bio[$i] -match "^\{@b .+?(\.|!|\?)\}") {
                for ($j = 1; $j -le $bio.Count - $i; $j++) { # Count number of lines until next header or EoF
                    if (($bio[$i+$j] -match "^\{@b .+?(\.|!|\?)\}") -or ($bio[$i+$j] -eq "<blockquote>") -or ($bio[$i+1+$j] -eq $null)) {
                        $bio[$i] = [ordered]@{
                            type = "entries"
                            name = $bio[$i] -replace "^\{@b (.+?)\.?\} .+$", '$1'
                            entries = $bio[$i..($i + $j - 1)] -replace "^\{@b .+?\.?\} (.+)$", '$1'
                        } # Add lines after beginning but before next header/EoF
                        if ($j -gt 1) {
                            $bio.RemoveRange($i + 1, $j)
                        }
                        break
                    }
                }
            } elseif ($bio[$i] -eq "<blockquote>") { # Reformat quotes
                for ($j = 1; $j -le $bio.Count - $i; $j++) { # Count number of lines until hit end of quote
                    if ($bio[$i+1+$j] -eq "</blockquote>") {
                        $bio[$i] = [ordered]@{
                            type = "quote"
                            entries = $bio[($i + 1)..($i + $j)] -replace "\{@i (.+?)\}", '$1'
                        } # Add lines between beginning and end to quote block
                        $bio.RemoveRange($i + 1, $j + 1)
                        break
                    }
                }
            }
        }
        $5et.fluff += @{ entries = @( [ordered]@{
            type = "entries"
            entries = @( [ordered]@{
                type = "entries"
                entries = $bio
            } )
        } ) }
    }
    Write-Progress -Activity $name -Status "Haunting..." -PercentComplete 87.5 -Id 1 -ParentId 0
    if ($LARE) {
        $LARE = $LARE -replace '</?p>' -replace '\t' -replace '<br>' -split ' ?\n' -replace '^\s+' -replace '\s+$'
        $LG = [ordered]@{
            name = $5et.name
            source = $source
        }
        for ($i = 0; $i -lt $LARE.Count; $i++) {
            if (($LARE[$i] -match "^\s*$") -or ($LARE[$i] -match "^<img .+>$") -or ($LARE[$i] -ceq "Traits") -or ($LARE[$i] -ceq "Actions")) { # Remove images
                continue
            } elseif ($LARE[$i] -cmatch "'s? Lair$") {
                for ($j = 3; $j -lt $LARE.Count - $i; $j++) {
                    if (($LARE[$i+$j] -match "^\s*$") -or ($LARE[$i+$j] -eq $null)) {
                        if ($fluff) {
                            $5et.fluff.entries += [ordered]@{
                                type = "entries"
                                name = $LARE[$i]
                                entries = @($LARE[($i + 2)..($i + $j - 1)] | Tag-Entries)
                            }
                        } elseif ($image) {
                            $5et.fluff += @{ entries = @(
                                [ordered]@{
                                    type = "entries"
                                    name = $LARE[$i]
                                    entries = @($LARE[($i + 2)..($i + $j - 1)] | Tag-Entries)
                                }
                            ) }
                        } else {
                            $5et | Add-Member -NotePropertyName fluff -NotePropertyValue @{ entries = @(
                                [ordered]@{
                                    type = "entries"
                                    name = $LARE[$i]
                                    entries = @($LARE[($i + 2)..($i + $j - 1)] | Tag-Entries)
                                }
                            ) }
                        }
                        $i = $i + $j
                        break
                    }
                }
            } elseif ($LARE[$i] -ceq "Lair Actions") {
                for ($j = 3; $j -lt $LARE.Count - $i; $j++) {
                    if (($LARE[$i+$j] -match "^\s*$") -or ($LARE[$i+$j] -eq $null)) {
                        $LG += @{
                            lairActions = [System.Collections.ArrayList]@(
                                $LARE[($i + 2)..($i + $j - 1)] | Tag-Entries
                            )
                        }
                        $i = $i + $j
                        break
                    }
                }
            } elseif ($LARE[$i] -ceq "Regional Effects") {
                for ($j = 3; $j -lt $LARE.Count - $i; $j++) {
                    if (($LARE[$i+$j] -match "^\s*$") -or ($LARE[$i+$j] -eq $null)) {
                        $LG += @{
                            regionalEffects = [System.Collections.ArrayList]@(
                                $LARE[($i + 2)..($i + $j - 1)] | Tag-Entries
                            )
                        }
                        $i = $i + $j
                        break
                    }
                }
            } else {
                for ($j = 3; $j -lt $LARE.Count - $i; $j++) {
                    if (($LARE[$i+$j] -match "^\s*$") -or ($LARE[$i+$j] -eq $null)) {
                        if ($fluff) {
                            $5et.fluff.entries += [ordered]@{
                                type = "inset"
                                name = $LARE[$i]
                                entries = @($LARE[($i + 2)..($i + $j - 1)] | ForEach-Object { $_ | Tag-Entries } )
                            }
                        } elseif ($image) {
                            $5et.fluff += @{ entries = @(
                                [ordered]@{
                                    type = "inset"
                                    name = $LARE[$i]
                                    entries = @($LARE[($i + 2)..($i + $j - 1)] | Tag-Entries)
                                }
                            ) }
                        } else {
                            $5et | Add-Member -NotePropertyName fluff -NotePropertyValue @{ entries = @(
                                [ordered]@{
                                    type = "inset"
                                    name = $LARE[$i]
                                    entries = @($LARE[($i + 2)..($i + $j - 1)] | ForEach-Object { $_ | Tag-Entries } )
                                }
                            ) }
                        }
                        $i = $i + $j
                        break
                    }
                }
            }
        }
        if ($LG.lairActions -or $LG.regionalEffects) {
            if ($LG.regionalEffects.Count -gt 1) { # Convert lists
                for ($i = 0; $i -lt $LG.regionalEffects.Count; $i++) {
                    if ($LG.regionalEffects[$i] -eq "<ul>") {
                        $LG.regionalEffects[$i] = [ordered]@{
                            type = "list"
                            items = @()
                        }
                        while ($LG.regionalEffects[$i + 1] -ne "</ul>") {
                            $LG.regionalEffects[$i].items += $LG.regionalEffects[$i + 1] -replace "<\/?li>"
                            $LG.regionalEffects.RemoveAt($i + 1)
                        }
                        $LG.regionalEffects.RemoveAt($i + 1)
                    }
                }
            }
            if ($LG.lairActions.Count -gt 1) { # Convert lists
                for ($i = 0; $i -lt $LG.lairActions.Count; $i++) {
                    if ($LG.lairActions[$i] -eq "<ul>") {
                        $LG.lairActions[$i] = [ordered]@{
                            type = "list"
                            items = @()
                        }
                        while ($LG.lairActions[$i + 1] -ne "</ul>") {
                            $LG.lairActions[$i].items += $LG.lairActions[$i + 1] -replace "<\/?li>"
                            $LG.lairActions.RemoveAt($i + 1)
                        }
                        $LG.lairActions.RemoveAt($i + 1)
                    }
                }
            }

            # TODO Fix the markdown-list screw-ups that result in {@i } tags everywhere

            $5et | Add-Member -NotePropertyName legendaryGroup -NotePropertyValue @{
                name = $LG.name
                source = $source
            }
            $brew.legendaryGroup += $LG
        }
    }

    # IMAGE
    Write-Progress -Activity $name -Status "Landscaping..." -PercentComplete 90.625 -Id 1 -ParentId 0
    if ($image) {
        $5et.fluff += @{ images = @(
            [ordered]@{
                type = "image"
                href = @{
                    type = "external"
                    url = $repo + "/" + $source + "/creature/" + $5et.name + ".webp"
                }
            }
        ) }
    }

    # TAG CLEANUP
    Write-Progress -Activity $name -Status "Cleaning..." -PercentComplete 93.75 -Id 1 -ParentId 0
    Clean-Up-Tags $5et "senseTags"
    Clean-Up-Tags $5et "damageInflict"
    Clean-Up-Tags $5et "conditionInflict"
    Clean-Up-Tags $5et "languageTags"
    Clean-Up-Tags $5et "spellcastingTags"
    Clean-Up-Tags $5et "conditionInflictSpell"
    Clean-Up-Tags $5et "actionTags"
    Clean-Up-Tags $5et "conditionInflictLegendary"
    Clean-Up-Tags $5et "miscTags"

    # CLEAN UP SPECIAL CHARACTERS
    # TODO
    # bullets bring up pseudo-error code to tell user to manually convert to list
    # check how R20 exports tables
    # SEE 'VAMPIRE, PSYCHIC' TO CHECK HOW TABLES ARE FORMATTED

    # TODO Optimise by changing PSCustomObjects to hash tables or whatever???
    # probably easiest to just build at random then reorganise during cleanup
    #
    # Change '* (Ranged)' attacks to thrown by default?
    # 
    # Minify then reformat json because powershell sucks
    
    $5et.PSObject.Members | Where {$_.Value -eq $null } | ForEach-Object {
        $_.Value = "XxX_ERROR_XxX : Missing data ///"
    }

    Write-Progress -Activity $name -Status "Submitting..." -PercentComplete 96.875 -Id 1 -ParentId 0
    $brew.monster += $5et
    $progress++
    Write-Progress -Activity $name -Status "Done!" -PercentComplete 100 -Id 1 -ParentId 0
    if ($err) {
        Write-Warning "Converted '$($5et.name)' with errors."
        $errcount++
    } else {
        Write-Output "Successfully converted '$($5et.name)'."
    }
}

if ($brew.legendaryGroup.Count -eq 0) {
    $brew.Remove("legendaryGroup")
}

(($brew | ConvertTo-Json -Depth 15 -Compress | ForEach-Object {
    [Regex]::Replace($_, "\\u(?<Value>\w{4})", { param($matches) ([char]([int]::Parse($matches.Groups['Value'].Value, [System.Globalization.NumberStyles]::HexNumber))).ToString() })
}) -replace '(“|”)', '\"' -replace '—', '\u2014' -replace '–', '\u2013') | Out-File -FilePath ".\# BREW.json" -Encoding UTF8

Write-Output "`nConversion complete.`n"
if ($errcount) {
    Write-Warning "$errcount creatures with errors."
    Write-Output ""
}
pause