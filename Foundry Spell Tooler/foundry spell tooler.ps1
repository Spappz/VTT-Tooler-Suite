<########################################################################################
#                                                                                       #
#                         FOUNDRY TO 5ETOOLS SPELL CONVERTER                            #
#                                                                                       #
#                                    Spappz 2021                                        #
#                                                                                       #
########################################################################################>

# SETTINGS
$overrideSource = "" # Set to an empty string to copy the Foundry source.
$extractPageNumbers = $false <# Set to $false if page numbers aren't included in the
                                Foundry source, or to otherwise ignore page numbers.
                                Note that the source must include 'page 15' or 'p.15' or 
                                some such. #>

<# ABOUT
  This script converts spells from a Foundry VTT `dnd5e` compendium file to 5etools'
   homebrew schema. This script is designed to automate the *bulk* process, and it will
   almost certainly require manual correction afterwards (see below).

# HOW TO USE
  Place this file in the same directory as your compendium file (e.g. `spells.db`). On
   Windows, right-click this script and select 'Run with PowerShell'. On macOS and Linux,
   you will probably have to install PowerShell and run it via command line.

  A file named '# BREW.json' will be created in this same directory. Make corrections as
   appropriate and you should be sorted!

  Knowledge of 5etools' schema is strongly advised. Proficiency in basic regex is very
   helpful for clean-up!

# LIMITATIONS
  You should be aware of the following limitations with this automated conversion.
  - Spell lists (class, subclass, race, eldritch invocation, etc.) are not populated as
     this data is not stored in Foundry VTT dnd5e compendia.
  - Spells with multiple area-of-effect shapes (`areaTags`), spell attack options
     (`spellAttacks`), or saving throws (`savingThrows`) aren't recognised. One tag at
     most from each will be applied.
  - Spells with permanent or multiple durations might be missing data, especially the
     `upTo` and `ends` keys.
  - Spells with variable damage types may suffer dice and `damageInflict` mistagging.
  - Non-trivial spell descriptions (`entries`), especially knowing how homebrew tends to
     be, will likely be misformatted. It should still be readable, but not 100% accurate
     or complete. Most significantly, `table`s are handled by an obscene and fickle hack,
     and `inset` blocks are entirely unaccounted for. This thing parses HTML with regex!
  - 5etools filter metadata (especially `miscTags`) relies largely on pattern-matching
     and so might miss tags. False negatives are far more likely than false positives.
  - The following 5etools metadata is completely ignored: `damageResist`, `damageImmune`,
     `damageVulnerable`, and `conditionImmune`. You'll have to fill these out manually.

  If something goes wrong, either an `xxxERRORxxx : <error message>` string will be put
   in the appropriate JSON attribute, or the script will crash. Good luck!
   
  Last tested under Foundry VTT 5th Edition (`dnd5e`) version 1.5.3. Support outside this
   version is not guaranteed.

# CONTACT
  - spap [has#] 9812
  - spappz [@t] fire mail [d.t] cc

  pls no spam

# LICENSE
  MIT License

  Copyright © 2021 Spappz

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

# FUNCTIONS
function Tag-Entries {
    PROCESS {
        Write-Output (
            $input -replace '^\s+' -replace '\s+$' `
            -replace '\b(\d+d[\dd \+\-×x\*÷/]*\d)(?=( (\w){4,9})? damage\b)(?!\})', '{@damage $1}' `
            -replace '(?<=\brolls? (a )?)(d\d+)\b(?!\})', '{@dice $2}' `
            -replace '(?<!@d(amage|ice)) (\d+d[\dd \+\-×x\*÷/]*\d)\b(?!\})', ' {@dice $2}' `
            -creplace '(?<!\w)\+?(\-?\d)(?= (to hit|modifier))', '{@hit $1}' `
            -replace "(?<=\b(be(comes?)?|is( ?n['o]t)?|while|a(lso|nd|( ?n['o]t))?|or|th(e|at)) )(blinded|charmed|deafened|frightened|grappled|incapacitated|invisible|paralyzed|petrified|poisoned|restrained|stunned)\b", '{@condition $7}' `
            -replace "(?<=\b(knocked|pushed|shoved|becomes?|falls?|while|lands?) )(prone|unconscious)\b", '{@condition $2}' `
            -replace "(?<=levels? of )exhaustion\b", "{@condition exhaustion}" `
            -creplace '(?<=\()(Athletics|Acrobatics|Sleight of Hand|Stealth|Arcana|History|Investigation|Nature|Religion|Animal Handling|Insight|Medicine|Perception|Survival|Deception|Intimidation|Performance|Persuasion)(?=\))', '{@skill $1}' `
            -creplace '\b(Athletics|Acrobatics|Sleight of Hand|Stealth|Arcana|History|Investigation|Nature|Religion|Animal Handling|Insight|Medicine|Perception|Survival|Deception|Intimidation|Performance|Persuasion)(?= (check|modifier|bonus|roll|score))', '{@skill $1}' `
            -replace '(?<!cast (the )?)\b(darkvision|blindsight|tremorsense|truesight)\b(?! spell)', '{@sense $2}' `
            -creplace "\b(Attack(?! roll)|Cast a Spell|Dash|Disengage|Dodge|Help|Hide|Ready|Search|Use an Object)\b", '{@action $1}' `
            -replace '\bopportunity attack\b', '{@action opportunity attack}' `
            -replace '\b(\d{1,2}) percent chance\b', '{@chance $1} chance' `
            -creplace '(<em>)?@Compendium\[dnd5e\.spells\.\w+?\]\{(.+?)\}(</em>)?', '{@spell $2}' `
            -creplace '@Compendium\[dnd5e\.rules\.\w+?\]\{(blinded|charmed|deafened|frightened|grappled|incapacitated|invisible|paralyzed|petrified|poisoned|prone|restrained|stunned|exhaustion)\}', '{@condition $1}' `
            -creplace '(<em>)?@Compendium\[dnd5e\.monsters\.\w+?\]\{(.+?)\}(</em>)?', '{@creature $2}' `
            -replace '\[\[/r (.+?)( # .+?)?\]\]', '{@dice $1}' `
            -replace '(<em>)?\[\[(\[)?srd-spell:(.+?)\]\](\])?(</em>)?', '{@spell $3}' `
            -replace '\[\[(\[)?' -replace '\]\](\])?' `
            -replace "<strong>([^\r^\n]+?)<\/strong>", '{@b $1}' `
            -replace "<em>([^\r^\n]+?)<\/em>", '{@i $1}' `
            -replace ' {2,}', ' ' 
        )
    }
}
function HtmlTo-Entries {
    [CmdletBinding()]
    PARAM (
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$html
    )
    BEGIN {
        $status = $false
    }
    PROCESS {
        $entries = $html -replace "`n" -replace "`r" -replace "`t" -split '(<p\b.*?>.*?</p>)' -split '(<ul\b.*?>.*?</ul>)' -split '(<ol\b.*?>.*?</ol>)' -split '(<table\b.*?>.*?</table>)' -split '(?=<br ?/?>)' -ne ""
        $entries = switch -Regex ($entries) {
            '^<(p|br)\b.*?>\s*(<(em|i|strong|b)>)+(.+?)([\. ]|</(em|i|strong|b)>){2,}' {
                [PSCustomObject]@{
                    type = "entries"
                    name = $_ -replace '^<(p|br)\b.*?>\s*(<(em|i|strong|b)>)+(.+?)([\. ]|</(em|i|strong|b)>){2,}.*$', '$4'
                    entries = @($_ -replace '^<(p|br)\b.*?>\s*(<(em|i|strong|b)>)+(.+?)([\. ]|</(em|i|strong|b)>){2,}')
                }
                continue
            }
            '^<(p|br)\b' {
                $_ -replace '</?(p|br) ?(style=".*?")?/?>' | Tag-Entries
                continue
            }
            '^<ul\b' {
                [PSCustomObject]@{
                    type = "list"
                    items = @($_ -replace '</?ul\b.*?>' -split '</?li\b.*?>' -notmatch '\s*' | Tag-Entries)
                }
                continue
            }
            '^<ol\b' {
                [PSCustomObject]@{
                    type = "list"
                    style = "list-decimal"
                    items = @($_ -replace '</?ol\b.*?>' -split '</?li\b.*?>' -notmatch '\s*' | Tag-Entries)
                }
                continue
            }
            '^<table\b' {
                $obj = [PSCustomObject]@{type = "table"}
                $widths = $aligns = $null
                if ($_ -match '<td style=".*?width:.*?">') {
                    $widths = ($_ -replace '^.*?<tr\b.*?>' -split '</tr>')[0] -split '</td>' -replace '^.*?width:\s*([\d\.]+).*?$', '$1' -match '^\d'
                    $widths = ($widths | ForEach-Object { [decimal]::Round($_ / ($widths | Measure-Object -sum).sum * 24) / 2 }) -replace '\.', '-'
                    if ($widths.Count -eq 2 -and ($widths[0] -eq 1 -or $widths[0] -eq "1-5")) {
                        $widths = @(
                            "col-2",
                            "col-10"
                        )
                    } else {
                        $widths = $widths | ForEach-Object { "col-" + $_ }
                    }
                }
                if ($_ -match '<td style=".*?width:.*?">') {
                    $aligns = ($_ -replace '^.*?<tbody\b.*?>' -replace '^.*</th></tr>' -replace '^.*?<tr\b.*?>' -split '</tr>')[0] -split '</td>' -replace '^.*?text-align:(\w+).*?$', '$1' -notmatch '^\W'
                    $aligns = $aligns | ForEach-Object {
                        if ($_ -eq "center" -or $_ -eq "right" -or $_ -eq "justify") {
                            "text-" + $_
                        } else {
                            ""
                        }
                    }
                }
                if ($widths) {
                    if ($aligns) {
                        $obj | Add-Member -MemberType NoteProperty -Name colStyles -Value $(
                            for ($i = 0; $i -lt $widths.Count; $i++) {
                                $widths[$i] + $(if ($aligns[$i]) { " " + $aligns[$i] } else { $null })
                            }
                        )
                    } else {
                        $obj | Add-Member -MemberType NoteProperty -Name colStyles -Value $widths
                    }
                } elseif ($aligns) {
                    $obj | Add-Member -MemberType NoteProperty -Name colStyles -Value $aligns
                }
                if ($_ -match '<thead( style=".*?")?>') {
                    $obj | Add-Member -MemberType NoteProperty -Name colLabels -Value @(
                        $_ -replace '^.*<thead\b.*?>\s*<tr\b.*?>\s*(.*)\s*</td>\s*</tr>\s*</thead>.*$', '$3' -replace '<td\b.*?>' -replace '</?(strong|em|b)\b.*?>' -split '</td>'
                    )
                } elseif ($_ -match '<th\b') {
                    $obj | Add-Member -MemberType NoteProperty -Name colLabels -Value @(
                        $_ -replace '^.*?<th\b.*?>' -replace '</th></tr>.*?$' -replace '</?(strong|em|b)\b.*?>' -split '</th>\s*<th\b.*?>'
                    )
                } else {
                    $status = $true
                }
                $rows = [System.Collections.ArrayList]::new()
                $_ -replace '^.*?<tbody\b.*?>' -replace '^.*</th></tr>' -replace '</td>\s*</tr>\s*(</tbody>)?\s*</table>' -split '</tr>' | ForEach-Object {
                    $rows += , (($_ -split '</td>').Trim() -replace '^.*?<td\b.*?>' -ne "" | Tag-Entries)
                }
                $obj | Add-Member -MemberType NoteProperty -Name rows -Value $rows
                $obj
                continue
            }
            default {
                "$_" | Tag-Entries
                $status = $true
            }
        }
        Write-Output @{
            entries = @($entries)
            status = $status
        }
    }
}
function Find-DamageType {
    [CmdletBinding()]
    PARAM (
        [Parameter(Mandatory, ValueFromPipeline)]
        $str
    )
    BEGIN {
        $finds = [System.Collections.ArrayList]::new()
        $confirms = [System.Collections.ArrayList]::new()
    }
    PROCESS {
        switch -regex ($str) {
            "\btak\w{1,3} [\{\}@diceamg \d\+\-\*×÷/\^\(\)]+? (?<type>\w{4,}) damage\b" { $finds += $Matches.type }
            '\bdeal\w{0,3} [\{\}@diceamg \d\+\-\*×÷/\^\(\)]+? (?<type>\w{4,}) damage\b' { $finds += $Matches.type }
            '\binflict\w{0,3} [\{\}@diceamg \d\+\-\*×÷/\^\(\)]+? (?<type>\w{4,}) damage\b' { $finds += $Matches.type }
            '\bsuffer\w{0,3} [\{\}@diceamg \d\+\-\*×÷/\^\(\)]+? (?<type>\w{4,}) damage\b' { $finds += $Matches.type }
            '\bfor [\{\}@diceamg \d\+\-\*×÷/\^\(\)]+? (?<type>\w{4,}) damage\b' { $finds += $Matches.type }
            '\bplus [\{\}@diceamg \d\+\-\*×÷/\^\(\)]+? (?<type>\w{4,}) damage\b' { $finds += $Matches.type }
            '\band [\{\}@diceamg \d\+\-\*×÷/\^\(\)]+? (?<type>\w{4,}) damage\b' { $finds += $Matches.type }
            '\bor \w{4,} damage' { $finds += $Matches.type }
        }
        switch -exact ($finds) {
            acid { $confirms += "A" }
            bludgeoning { $confirms += "B" }
            cold { $confirms += "C" }
            fire { $confirms += "F" }
            force { $confirms += "O" }
            lightning { $confirms += "L" }
            necrotic { $confirms += "N" }
            piercing { $confirms += "P" }
            poison { $confirms += "I" }
            psychic { $confirms += "Y" }
            radiant { $confirms += "R" }
            slashing { $confirms += "S" }
            thunder { $confirms += "T" }
        }
        Write-Output @($confirms | Sort -Unique)
    }
}
function Find-Condition {
    [CmdletBinding()]
    PARAM (
        [Parameter(Mandatory, ValueFromPipeline)]
        $str
    )
    BEGIN {
        $finds = [System.Collections.ArrayList]::new()
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
        Write-Output @($finds | Sort-Object -Unique)
    }
}
function Find-AbilityCheck {
    [CmdletBinding()]
    PARAM (
        [Parameter(Mandatory, ValueFromPipeline)]
        $str
    )
    BEGIN {
        $finds = [System.Collections.ArrayList]::new()
    }
    PROCESS {
        switch -Regex ($str) {
            'Strength (\((\{@skill )?\w+\}?\) )?((ability|skill) )?check' { $finds += "strength" }
            'Dexterity (\((\{@skill )?\w+\}?\) )?((ability|skill) )?check' { $finds += "dexterity" }
            'Constitution (\((\{@skill )?\w+\}?\) )?((ability|skill) )?check' { $finds += "constitution" }
            'Intelligence (\((\{@skill )?\w+\}?\) )?((ability|skill) )?check' { $finds += "intelligence" }
            'Wisdom (\((\{@skill )?\w+\}?\) )?((ability|skill) )?check' { $finds += "wisdom" }
            'Charisma (\((\{@skill )?\w+\}?\) )?((ability|skill) )?check' { $finds += "charisma" }
        }
        Write-Output @($finds | Sort-Object -Unique)
    }
}

# INITIALISATION
Clear-Host
Write-Output "FOUNDRY TO 5ETOOLS SPELL CONVERTER`n`nInitialising...`n`n"
if (Test-Path ".\# BREW.json") {
    do {
        Write-Warning "``# BREW.json`` already exists!"
        Write-Output "Please delete or rename it now.`n"
        pause
        Write-Output ""
    } while (Test-Path "# BREW.json")
    Write-Host "Thank you.`n`n"
}
if (-not (Test-Path '*.db')) {
    do {
        Write-Warning "No compendium files found!"
        Write-Output "Please add one to this directory now.`n"
        pause
        Write-Output ""
    } until (Test-Path '*.db')
    Write-Host "Thank you.`n`n"
}
if ((Get-ChildItem | Where-Object {$_.name -match '\.db$'}).Count -gt 1) {
    Write-Warning "Multiple compendium files found:"
    (Get-ChildItem | Where-Object {$_.name -match '\.db$'}).name | ForEach-Object {"  " + $_}
    do {
        $sourceFileName = Read-Host "`nEnter compendium filename"
    } until ($sourceFileName)
    if (Test-Path ($sourceFileName + ".db")) {
        $sourceFileName = $sourceFileName + ".db"
    } elseif (-not (Test-Path $sourceFileName)) {
        do {
            Write-Output ""
            Write-Warning "File does not exist!"
            (Get-ChildItem | Where-Object {$_.name -match '\.db$'}).name | ForEach-Object {"  " + $_}
            $sourceFileName = Read-Host "`nEnter compendium filename"
        } until ((Test-Path $sourceFileName) -or (Test-Path ($sourceFileName + ".db")))
        if ($sourceFileName -notmatch '\.db$') {
            $sourceFileName = $sourceFileName + ".db"
        }
    }
    Write-Host "Thank you.`n`n"
} else {
    $sourceFileName = (Get-ChildItem | Where-Object {$_.name -match '\.db$'}).name
}
Write-Output "`n`nBeginning conversion...`n"

$brew = [PSCustomObject]@{
    "_meta" = [ordered]@{
        sources = @([ordered]@{
            json = $overrideSource
            abbreviation = ""
            full = ""
            url = ""
            authors = @("")
            convertedBy = @("")
            color = ""
            version = "1.0.0"
        })
        dateAdded = [int64](get-date -uformat %s)
        dateLastModified = [int64](get-date -uformat %s)
    }
    "spell" = [System.Collections.ArrayList]::new()
}
$foundry = "[" + ((Get-Content $sourceFileName -Raw -Encoding 'utf8') -replace "&nbsp;", " " -replace "’|‘", "'" -replace "\}`n\{", "},{") + "]" | ConvertFrom-Json

$foundry | ForEach-Object -Begin {
    $progress = 0
    $progmax = $foundry.Count
    $errors = 0
    $warnings = 0
} -Process {
    Write-Progress -Activity "Converting spells..." -Status $_.name -PercentComplete ($progress/$progmax*100) -Id 0

    $status = ""
    $5et = [PSCustomObject]::new()

    if ($overrideSource) {
        $5et | Add-Member -MemberType NoteProperty -Name source -Value $overrideSource
    } else {
        $5et | Add-Member -MemberType NoteProperty -Name source -Value ($_.data.source -replace '\bp[pa]?(ge?)?(\. ?|\-)?(\d+)(?!\d)')
    }

    if ($extractPageNumbers) {
        $5et | Add-Member -MemberType NoteProperty -Name page -Value ($_.data.source -replace '^.*\bp[pa]?(ge?)?(\. ?|\-)?(\d+)(?!\d).*$', '$3')
    } else {
        $5et | Add-Member -MemberType NoteProperty -Name page -Value 0
    }

    $5et | Add-Member -MemberType NoteProperty -Name name -Value $_.name

    $5et | Add-Member -MemberType NoteProperty -Name level -Value $_.data.level

    $5et | Add-Member -MemberType NoteProperty -Name school -Value $(
        switch ($_.data.school) {
            abj { "A" }
            enc { "E" }
            evo { "V" }
            con { "C" }
            div { "D" }
            ill { "I" }
            nec { "N" }
            trs { "T" }
            psi { "P" }
            default { $_ }
        }
    )

    if ($_.data.components.ritual) {
        $5et | Add-Member -MemberType NoteProperty -Name meta -Value @{
            ritual = $true
        }
    }

    $5et | Add-Member -MemberType NoteProperty -Name time -Value @(
        [PSCustomObject]@{
            number = [UInt16]$_.data.activation.cost
            unit = $_.data.activation.type
        }
    )
    if ($_.data.activation.condition) {
        $5et.time[0] | Add-Member -MemberType NoteProperty -Name condition -Value $_.data.activation.condition
        if ($5et.time[0].unit -ne "reaction") {
            $status = "w"
        }
    }

    if ($_.data.range.units -eq "self") {
        if ($_.data.target.units -notin "radius", "line", "sphere", "cone", "cube", "cylinder") {
            $5et | Add-Member -MemberType NoteProperty -Name range -Value ([PSCustomObject]@{
                type = "point"
                distance = @{
                    type = "self"
                }
            })
        } else {
            $5et | Add-Member -MemberType NoteProperty -Name range -Value ([PSCustomObject]@{
                type = $(
                    switch ($_.data.target.type) {
                        radius { "radius" }
                        line { "line" }
                        sphere { "sphere" }
                        cone { "cone" }
                        cube { "cube" }
                        cylinder { "cylinder" }
                        default {
                            "xxxERRORxxx : Unknown range = ``" + "$_" + "``"
                            $status += "e"
                        }
                    }
                )
                distance = @{
                    amount = $_.data.target.value
                    type = $_.data.target.units
                }
            })
        }
    } else {
        $range = $_.data.range
        $5et | Add-Member -MemberType NoteProperty -Name range -Value ([PSCustomObject]@{
            type = "point"
            distance = $(
                switch ($range.units) {
                    ft {
                        [PSCustomObject]@{
                            amount = $range.value
                            type = "feet"
                        }
                    }
                    touch {
                        @{
                            type = "touch"
                        }
                    }
                    spec {
                        @{
                            type = "sight"
                        }
                    }
                    mi {
                        [PSCustomObject]@{
                            amount = $range.value
                            type = "miles"
                        }
                    }
                    any {
                        @{
                            type = "unlimited"
                        }
                    }
                    default {
                        [PSCustomObject]@{
                            amount = $range.value
                            type = "xxxERRORxxx : Unknown range = ``" + "$_" + "``"
                        }
                        $status += "e"
                    }
                }
            )
        })
    }

    $5et | Add-Member -MemberType NoteProperty -Name components -Value ([PSCustomObject]::new())
    if ($_.data.components.vocal) {
        $5et.components | Add-Member -MemberType NoteProperty -Name v -Value $true
    }
    if ($_.data.components.somatic) {
        $5et.components | Add-Member -MemberType NoteProperty -Name s -Value $true
    }
    if ($_.data.components.material) {
        if ($_.data.materials.cost) {
            $5et.components | Add-Member -MemberType NoteProperty -Name m -Value ([PSCustomObject]@{
                text = ($_.data.materials.value -replace '\.$').Trim()
                cost = $_.data.materials.cost * 100
                consume = $_.data.materials.consumed
            })
        } elseif ($_.data.materials.value) {
            $5et.components | Add-Member -MemberType NoteProperty -Name m -Value ($_.data.materials.value -replace '\.$').Trim()
        } else {
            $5et.components | Add-Member -MemberType NoteProperty -Name m -Value $true
        }
    }

    if ($_.data.duration.value) {
        $5et | Add-Member -MemberType NoteProperty -Name duration -Value @(
            [PSCustomObject]@{
                type = "timed"
                duration = [PSCustomObject]@{
                    amount = $_.data.duration.value
                    type = $(
                        switch ($_.data.duration.units) {
                            minute { "minute" }
                            hour { "hour" }
                            round { "round" }
                            day { "day" }
                            week { "week" }
                            year { "year" }
                            turn { "turn" }
                            default {
                                "xxxERRORxxx : Unknown duration = ``" + "$_" + "``"
                                $status += "e"
                            }
                        }
                    )
                }
            }
        )
        if ($_.data.components.concentration) {
            $5et.duration[0] | Add-Member -MemberType NoteProperty -Name concentration -Value $true
        }
    } else {
        $5et | Add-Member -MemberType NoteProperty -Name duration -Value @(
            switch -Regex ($_.data.duration.units) {
                'inst(ant(aneous)?)?' {
                    [PSCustomObject]@{type = "instant"}
                }
                'perm(anent)?' {
                    [PSCustomObject]@{type = "permanent"}
                    $status += "w"
                }
                'until [\w, ]+' {
                    [PSCustomObject]@{
                        type = "permanent"
                        ends = @($_ -replace 'dispelled', 'dispel' -replace 'triggered', 'trigger' -replace 'discharged', 'discharge' -replace ' |\b(until|or)\b', ',' -split ',' -ne "")    
                    }
                }
                'spec(ial .*)?' {
                    [PSCustomObject]@{type = "special"}
                }
                default {
                    [PSCustomObject]@{type = "xxxERRORxxx : Unknown duration = ``" + $_ + "``"}
                    $status += "e"
                }
            }
        )
    }
    
    ($entries, $entriesHigherLevel) = $_.data.description.value -split '\s*<(p|br) ?(style=".*?")?/?>\s*(<(em|i|strong|b)>)*(\s*(At )?Higher Levels)([\.: ]|</(em|i|strong|b)>)*', 0, "ExplicitCapture"
    $entries = $entries | HtmlTo-Entries
    $5et | Add-Member -MemberType NoteProperty -Name entries -Value $entries.entries
    if ($entries.status) {
        $status += "w"
    }
    if ($entriesHigherLevel) {
        $entriesHigherLevel = ("<p>" + $entriesHigherLevel) | HtmlTo-Entries
        if ($_.data.scaling.mode -eq "level" -and $_.data.scaling.formula) {
            $entriesHigherLevel.entries = $entriesHigherLevel.entries -replace $('\{@dice ' + $_.data.scaling.formula + '}'), $('{@scaledice ' + $_.data.damage.parts[0][0] + '|' + $_.data.level + '-9|' + $_.data.scaling.formula + '}')
        }
        $5et | Add-Member -MemberType NoteProperty -Name entriesHigherLevel -Value @(
            [PSCustomObject]@{
                type = "entries"
                name = "At Higher Levels"
                entries = $entriesHigherLevel.entries
            }
        )
        if ($entriesHigherLevel.status) {
            $status += "w"
        }
    }

    $damageInflict = ($_.data.damage.parts | ForEach-Object {$_}) -notmatch '\d' -ne "healing" -ne "temphp"
    if ($damageInflict.Count) {
        if (($damageInflict -eq "").Count) {
            $damageInflict = ($damageInflict -ne "") + (,$entries.entries | Find-DamageType)
            if ($damageInflict.Count -eq 0) {
                $status += "w"
            } else {
                $5et | Add-Member -MemberType NoteProperty -Name damageInflict -Value @($damageInflict)
            }
        } else {
            $5et | Add-Member -MemberType NoteProperty -Name damageInflict -Value @($damageInflict)
        }
    }

    $conditionInflict = ,$entries.entries | Find-Condition
    if ($conditionInflict) {
        $5et | Add-Member -MemberType NoteProperty -Name conditionInflict -Value @($conditionInflict)
    }

    $areaTags = switch ($_.data.target.type) {
        cone { "N" }
        creature { "ST" }
        cube { "C" }
        cylinder { "Y" }
        line { "L" }
        object { "ST" }
        radius { "S" }
        sphere { "S" }
        square { "Q" }
        wall { "W" }
        default { $null }
    }
    if ($areaTags -eq "ST" -and $_.data.target.value -gt 1) {
        $areaTags = "MT"
    }
    if ($areaTags) {
        $5et | Add-Member -MemberType NoteProperty -Name areaTags -Value @($areaTags)
    }
    
    if ($_.data.actionType -eq "msak") {
        $5et | Add-Member -MemberType NoteProperty -Name spellAttack -Value @("M")
    }
    if ($_.data.actionType -eq "rsak") {
        $5et | Add-Member -MemberType NoteProperty -Name spellAttack -Value @("R")
    }

    if ($_.data.save.ability) {
        $5et | Add-Member -MemberType NoteProperty -Name savingThrow -Value @($(
            switch ($_.data.save.ability) {
                str { "strength" }
                dex { "dexterity" }
                con { "constitution" }
                int { "intelligence" }
                wis { "wisdom" }
                cha { "charisma" }
                default {
                    "xxxERRORxxx : Unknown saving throw = ``" + "$_" + "``"
                    $status += "e"
                }
            }
        ))
    }

    $abilityCheck = ,$entries.entries | Find-AbilityCheck
    if ($abilityCheck) {
        $5et | Add-Member -MemberType NoteProperty -Name abilityCheck -Value @($abilityCheck)
    }

    foreach ($entry in $entries.entries) {
        if (
            $entry -match '(?<=(choose|touch|each) ((an?|((up to )?(\d+|one|t(wo|hree)|f(our|ive)|six))) )?)(?<creatures>((aberration|beast|celestial|construct|dragon|elemental|fiend|giant|humanoid|ooze|plant)s?\b|fey\b|undead\b|monstrosit(y|ies)\b|, | ?\b(and|or) (an? )?)+)'
        ) {
            $5et | Add-Member -MemberType NoteProperty -Name affectsCreatureType -Value @(
                $Matches.creatures -split ', ' -split ' ?(a(nd?)?|or) ', 0, "ExplicitCapture" -ne "" -replace 's$' -replace 'ie$', 'y'
            )
            break
        } elseif (
            $entry -match '\b(?<creatures>((aberration|beast|celestial|construct|dragon|elemental|fiend|giant|humanoid|ooze|plant)s?\b|fey\b|undead\b|monstrosit(y|ies)\b|, | ?\b(and|or) (an? )?)+)(?=( creatures?)? (is|are) ?((n[o'']t |un)affected|immune))' `
            -or $entry -match '(?<=spell (ha|doe)s ?n[o''t]{1,2} [ae]ffect (on )?)(?<creatures>((aberration|beast|celestial|construct|dragon|elemental|fiend|giant|humanoid|ooze|plant)s?\b|fey\b|undead\b|monstrosit(y|ies)\b|, | ?\b(and|or) (an? )?)+)\b'
        ) {
            $affectsCreatureType = @(
                "aberration",
                "beast",
                "celestial",
                "construct",
                "dragon",
                "elemental",
                "fey",
                "fiend",
                "giant",
                "humanoid",
                "monstrosity",
                "ooze",
                "plant",
                "undead"
            ) | Where-Object {
                $_ -notin ($Matches.creatures -split ', ' -split ' ?(a(nd?)?|or) ', 0, "ExplicitCapture" -ne "" -replace 's$' -replace 'ie$', 'y')
            }
            if ($affectsCreatureType.Count -lt 14) {
                $5et | Add-Member -MemberType NoteProperty -Name affectsCreatureType -Value @($affectsCreatureType)
            }
            break
        }
    }

    $miscTags = [System.Collections.ArrayList]::new()
    if ($entries.entries -match '\bpu(sh|ll)(ed)? (it |the (creature|object)s? )?(a number of |(up to )?\d+ )feet') {
        $miscTags += "FMV"
    }
    if ($_.data.damage.parts -match "healing" -or $entries.entries -match '\b((re)?gain|restore|heal|grant)s? ([d\d\+-×÷ ]+|a number of) h(it )?p(oints?)' -or $entries.entries -match '\b((re)?gain|restore|heal|grant)s? h(it )?p(oints?) (equal|up) to') {
        $miscTags += "HL"
    }
    if ($entries.entries -match '\d (bonus|penalty) to AC\b' -or $entries.entries -match '\bAC (is|becomes) \d') {
        $miscTags += "MAC"
    }
    if ($entries.entries -match '\bpermanent(ly)?\b') {
        $miscTags += "PRM"
    }
    if (-not $entriesHigherLevel -and $_.data.scaling.mode -eq "cantrip") {
        $miscTags += "SCL"
    }
    if ($entries.entries -match '\byou can see\b(?! in)') {
        $miscTags += "SGT"
    }
    if ($_.name -match '^summon\b' -or $_.name -match '^conjure\b') {
        $miscTags += "SMN"
    }
    if ($_.data.damage.parts -match "temphp" -or $entries.entries -match '\b((re)?gain|restore|heal|grant)s? ([d\d\+-×÷ ]+|a number of) temp(orary|\.)? h(it )?p(oints?)' -or $entries.entries -match '\b((re)?gain|restore|heal|grant)s? temp(orary|\.)? h(it )?p(oints?) (equal|up) to') {
        $miscTags += "THP"
    }
    if ($entries.entries -match 'teleports? ((up to )?(\d|a)|a number of (feet|miles) equal to|to a(n unoccupied)? space|(your|it|them)sel(f|ves))') {
        $miscTags += "TP"
    }
    if ($miscTags) {
        $5et | Add-Member -MemberType NoteProperty -Name miscTags -Value @($miscTags)
    }

    #damageResist
    #damageImmune
    #damageVulnerable
    #conditionImmune
    # I cba to do the above since they're hard to distinguish with simple pattern-matching
    # and they're not even used in the filters anyway lmao
     
    $brew.spell += $5et
    
    if ($status -match 'e') {
        [Console]::ForegroundColor = 'red'
        [Console]::BackgroundColor = 'black'
        Write-Host $("`nERROR: Converted ``" + $5et.name + "`` with errors.") -NoNewline
        $errors++
        [Console]::ResetColor()
    } elseif ($status -match 'w') {
        [Console]::ForegroundColor = 'yellow'
        [Console]::BackgroundColor = 'black'
        Write-Host $("`nWARNING: Converted ``" + $5et.name + "`` with potential mistakes.") -NoNewline
        $warnings++
        [Console]::ResetColor()
    } else {
        Write-Host $("`nSuccessfully converted ``" + $5et.name + "``.") -NoNewline
    } 

    $progress++
}

Write-Output $("`n`n`nCompleted conversion of " + $progmax + " spells with " + $errors + " errors (" + [math]::Round($errors/$progmax*100) + "%) and " + $warnings + " warnings (" + [math]::Round($warnings/$progmax*100) + "%).`n")

Write-Host "`nExporting file..." -NoNewLine 
(($brew | ConvertTo-Json -Depth 15 -Compress | ForEach-Object {
    [Regex]::Replace($_, "\\u(?<Value>\w{4})", {
        param($Matches)
        ([char]([int]::Parse($Matches.Groups['Value'].Value, [System.Globalization.NumberStyles]::HexNumber))).ToString()
    })
}) -replace '(“|”)', '\"' -replace '—', '\u2014' -replace '–', '\u2013') | Out-File -FilePath ".\# BREW.json" -Encoding UTF8
Write-Host " Done.`n`n"

Read-Host "Press Enter to exit"