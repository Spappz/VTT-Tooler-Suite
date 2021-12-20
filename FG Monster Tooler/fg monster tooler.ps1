<########################################################################################
#                                                                                       #
#                    FANTASY GROUNDS TO 5ETOOLS MONSTER CONVERTER                       #
#                                                                                       #
#                                    Spappz 2021                                        #
#                                                                                       #
########################################################################################>

# BREW SETTINGS
$source = "MonsterManualExpanded3"
    <# JSON source string. Set to "" or $false to instead generate a source string from
        the brew's name. #>
$abbreviation = "MME3"
    <# Abbreviation string. Set to "" or $false instead generate an abbreviation string
        from the brew's name. #>
$url = "https://www.dmsguild.com/product/365853/Monster-Manual-Expanded-III-5E"
    <# Link to one of the brew's official stores or place or publication. Set to "" or
        $false to ignore. #>
$colour = "BD7044"
    <# Colour the brew can be identified as on 5etools, as a standard 6-digit RGB hexa-
        decimal code. Set to "" or $false to use the 5etools default. #>

# CONVERSION SETTINGS
$addTokens = $true
    <# If $true, each monster's token will be extracted and placed in a folder in the
        current directory called $source. Where possible, a `tokenUrl` key is added to
        each monster, pointing to `$repo/$source/creature/<name> (Token).png`. #>
$addImages = $true
    <# If $true, each monster's image will be extracted and placed in a folder in the
        current directory called $source. Where possible, a `tokenUrl` key is added to
        each monster, pointing to `$repo/$source/creature/<name>.png`. If either
        $addTokens or $addImages are set to $true, the brew's cover image is also
        extracted and placed in the same folder. #>
$repo = "https://raw.githubusercontent.com/TheGiddyLimit/homebrew/master/_img"
    <# See above for context. #>
$bonusActions = $true
    <# Set to $true if the brew uses the modern Bonus Actions block and you want to try
        automating that. (Warning: highly experimental.) #>
$spellcastingActions = $true
    <# Regardless of how the FG `.mod` displays it, if the brew source treats
    spellcasting as a trait (legacy styling), set to $false. If it treats spellcasting
    as an action (modern styling), set to $true.
    
    At time of writing, to my knowledge, FG doesn't support the modern-style spellcasting
    actions, and forces everything into traits. If this changes, see code comments below
    (search for 'SPELLCASTING'). A bunch of extra processing stuff is currently commented
    out for efficiency. #>

<#limitations
- complex alignments (e.g. with chances)
- prefix tags (e.g. 'Illuskan human')
- certain complex AC conditionals
- special HPs without averages/formulae
- certain complex, non-standard damage vulnerability/resistance/immunity formats
- condition immunities with conditionals
- won't match many OTH languageTags
- will accept invalid CRs but won't warn you about them (don't know how FG handles e.g. lair CRs)
- spellcasting in FG appaers to be always in traits, contrary to new style
- assumes standard formatting in lair actions and regional effects

- bonus actions don't exist; recognising them is iffy
- environments don't exist
- page numbers don't exist
- no mythic actions
#>

# INITIALISATION
Clear-Host
Write-Output "FANTASY GROUNDS TO 5ETOOLS MONSTER CONVERTER`n`nInitialising...`n`n"
if (Test-Path ".\# BREW.json") {
    do {
        Write-Warning "``# BREW.json`` already exists!"
        Write-Output "Please delete or rename it now.`n"
        pause
        Write-Output ""
    } while (Test-Path "# BREW.json")
    Write-Host "Thank you.`n`n"
}
if (-not (Test-Path '*.mod')) {
    do {
        Write-Warning "No module files found!"
        Write-Output "Please add one to this directory now.`n"
        pause
        Write-Output ""
    } until (Test-Path '*.mod')
    Write-Host "Thank you.`n`n"
}
if ((Get-ChildItem | Where-Object {$_.name -match '\.mod$'}).Count -gt 1) {
    Write-Warning "Multiple module files found:"
    (Get-ChildItem | Where-Object {$_.name -match '\.mod$'}).name | ForEach-Object {"  " + $_}
    do {
        $sourceFileName = (Read-Host "`nEnter module filename") -replace '\.mod$'
    } until ($sourceFileName)
    if (-not (Test-Path ($sourceFileName + '.mod'))) {
        do {
            Write-Output ""
            Write-Warning "File does not exist!"
            (Get-ChildItem | Where-Object {$_.name -match '\.mod$'}).name | ForEach-Object {"  " + $_}
            $sourceFileName = (Read-Host "`nEnter module filename") -replace '\.mod$'
        } until (Test-Path ($sourceFileName + ".mod"))
    }
    Write-Host "Thank you.`n`n"
} else {
    $sourceFileName = (Get-ChildItem | Where-Object {$_.name -match '\.mod$'}).name -replace '\.mod$'
}

do {
    $path = 'temp-' + (-join (97..122 | Get-Random -Count 8 | ForEach-Object {[char]$_}))
} while (Test-Path $path)
$null = New-Item $path -ItemType Directory
Copy-Item ($sourceFileName + '.mod') $path\_zipzip.zip
Expand-Archive $path\_zipzip.zip $path
[xml]$definition = Get-Content $path\definition.xml
[xml]$db = (Get-Content $path\db.xml -ReadCount 0 -Encoding UTF8) -replace "[‘’]|&#821(6|7);", "'" -replace '[“”]|&#822(0|1);', '"'

if ($definition.root.ruleset -ne '5E') {
    Read-Host "`n`nno`n`n`n"
    exit
}

if (-not $source) {
    $source = -join ($definition.root.name -split '\W' -ne "" | ForEach-Object {$_[0..2]})
}
if (-not $abbreviation) {
    $abbreviation = -join ($definition.root.name -split '\W' | ForEach-Object {
        if ($_ -cmatch '^I+$') {
            $_.Length
        } else {
            $_[0]
        }
    })
}

if ($addTokens -or $addImages) {
    $null = New-Item ($source + "\creature") -ItemType Directory
    Copy-Item ($path + "\thumbnail.png") ($source + "\cover.png")
}

$5et = [PSCustomObject]@{
    _meta = [ordered]@{
        sources = @(
            [ordered]@{
                json = $source
                abbreviation = $abbreviation
                full = $definition.root.name
                url = $url
                authors = @($definition.root.author)
                convertedBy = @($env:USERNAME)
                color = $colour
                version = "1.0.0"
            }
        )
        dateAdded = [uInt32](get-date -uformat %s)
        dateLastModified = [uInt32](get-date -uformat %s)
    }
    monster = [System.Collections.ArrayList]::new()
    legendaryGroup = [System.Collections.ArrayList]::new()
}
if (-not $url) {
    $5et.PSObject.Properties.Remove('url')
}
if (-not $colour) {
    $5et.PSObject.Properties.Remove('color')
}

# SHORTHAND
$c = 'category'
$t = '#text'

# FUNCTIONS
function Format-Entries { # haha this sucks
    PARAM(
        [Parameter(Mandatory, ValueFromPipeline)]$block
    )
    PROCESS {
        Write-Output @(
            for ($i = 0; $i -lt $block.Count; $i++) {
                switch -Exact ($block[$i].LocalName) {
                    desc {
                        Tag-Entries ($block[$i].$t -split '\\n')
                        break
                    }
                    p {
                        if ($block[$i].b) { # bold => innermost entries header => 3rd-degree nesting
                            [PSCustomObject]@{ 
                                type = "entries"
                                entries = @(
                                    [PSCustomObject]@{
                                        type = "entries"
                                        entries = @(
                                            [PSCustomObject]@{
                                                type = "entries"
                                                name = $block[$i].b -replace '\.? ?$'
                                                entries = @(Tag-Entries $block[$i].$t)
                                            }
                                        )
                                    }
                                )
                            }
                        } else {
                            Tag-Entries ($block[$i].$t -split '\\n')
                        }
                        break
                    }
                    h {
                        [PSCustomObject]@{
                            type = "entries"
                            name = $block[$i++].$t
                            entries = @(Tag-Entries ($block[$i].$t -split '\\n'))
                        }
                        break
                    }
                    list {
                        [PSCustomObject]@{
                            type = "list"
                            items = @(Tag-Entries $block[$i].li)
                        }
                    }
                }
            }
        )
    }
}
function Tag-Entries { # Be careful editing; this catches almost everything I've tried,
    PARAM(             # so almost any change inevitably breaks it somehow.
        [Parameter(Mandatory, ValueFromPipeline)]$text
    )
    PROCESS {
        Write-Output (
            $text -replace '^\s+' -replace '\s+$' `
                -replace '(?<=\()([\dd \+\-×x\*÷\/\*]+\d)(?=\))', '{@damage $1}' `
                -replace '\b(\d+d[\dd \+\-×x\*÷/]*\d)(?=( (\w){4,11})? damage\b)', '{@damage $1}' `
                -replace '(?<=\brolls? (a )?)(d\d+)\b(?!\})', '{@dice $2}' `
                -replace '(?<!@d(amage|ice)) (\d+d[\dd \+\-×x\*÷/]*\d)\b(?!\})', ' {@dice $2}' `
                -creplace '(?<!\w)\+?(\-?\d)(?= (to hit|modifier|bonus))', '{@hit $1}' `
                -creplace '\bDC ?(\d+)\b', '{@dc $1}' `
                -replace "(?<=\b(be(comes?)?|is( ?n[o']t)?|while|a(lso|nd)?|or|th(e|at)) )(blinded|charmed|deafened|frightened|grappled|incapacitated|invisible|paralyzed|petrified|poisoned|restrained|stunned)\b", '{@condition $6}' `
                -replace "(?<=\b(knocked|pushed|shoved|becomes?|falls?|while|lands?) )(prone|unconscious)\b", '{@condition $2}' `
                -replace "(?<=levels? of )exhaustion\b", "{@condition exhaustion}" `
                -creplace '(?<=\()(Athletics|Acrobatics|Sleight of Hand|Stealth|Arcana|History|Investigation|Nature|Religion|Animal Handling|Insight|Medicine|Perception|Survival|Deception|Intimidation|Performance|Persuasion)(?=\))', '{@skill $1}' `
                -creplace '\b(Athletics|Acrobatics|Sleight of Hand|Stealth|Arcana|History|Investigation|Nature|Religion|Animal Handling|Insight|Medicine|Perception|Survival|Deception|Intimidation|Performance|Persuasion)(?= (check|modifier|bonus|roll|score))', '{@skill $1}' `
                -replace '(?<!cast (the )?)\b(darkvision|blindsight|tremorsense|truesight)\b(?! spell)', '{@sense $2}' `
                -creplace "\b(Attack(?! roll)|Cast a Spell|Dash|Disengage|Dodge|Help|Hide|Ready|Search|Use an Object)\b", '{@action $1}' `
                -replace '\bopportunity attack\b', '{@action opportunity attack}' `
                -replace '\b(\d{1,2}) percent chance\b', '{@chance $1} chance' `
                -replace ' {2,}', ' '
        )
    }
}
function Process-SpellList {
    PARAM (
        [Parameter(Mandatory, ValueFromPipeline)]$text
    )
    PROCESS {
        Write-Output @(
            switch -Regex (
                $text -split ', (?![^(]+\))' | ForEach-Object {
                    switch -Regex ($_) {
                        '\w \(.+\)$' { "{@spell " + ($_ -replace ' \(.*$') + "} " + (Tag-Entries ($_ -replace '^.+?(?=\()')) }
                        "\w ?\*" { "{@spell " + ($_ -replace '\*+[^\*]*$') + "}" + ($_ -replace '^.+?(?= ?\*)') }
                        default { "{@spell " + $_ + "}" }
                    }
                }
            ) { # Yes, this is a giant list of every (relevant) SRD spell.
                "\barcane hand\}" {
                    $_ -replace "\barcane hand\}", "bigby's hand|phb|arcane hand}"
                    continue
                }
                "(?<!s )\binstant summons\}" {
                    $_ -replace "\binstant summons\}", "drawmij's instant summons|phb|instant summons}"
                    continue
                }
                "\bblack tentacles\}" {
                    $_ -replace "(?<!s )\bblack tentacles\}", "evard's black tentacles|phb|black tentacles}"
                    $null = $monster.conditionInflictSpell.Add("restrained")
                    continue
                }
                "(?<!s )\bsecret chest\}" {
                    $_ -replace "\bsecret chest\}", "leomund's secret chest|phb|secret chest}"
                    continue
                }
                "(?<!s )\btiny hut\}" {
                    $_ -replace "\btiny hut\}", "leomund's tiny hut|phb|tiny hut}"
                    continue
                }
                "(?<!s )\bacid arrow\}" {
                    $_ -replace "\bacid arrow\}", "melf's acid arrow|phb|acid arrow}"
                    continue
                }
                "(?<!s )\bfaithful hound\}" {
                    $_ -replace "\bfaithful hound\}", "mordenkainen's faithful hound|phb|faithful hound}"
                    continue
                }
                "(?<!s )\bmagnificent mansion\}" {
                    $_ -replace "\bmagnificent mansion\}", "mordenkainen's magnificent mansion|phb|magnificent mansion}"
                    continue
                }
                "(?<!s )\bprivate sanctum\}" {
                    $_ -replace "\bprivate sanctum\}", "mordenkainen's private sanctum|phb|private sanctum}"
                    continue
                }
                "(?<!s )\barcanist's magic aura\}" {
                    $_ -replace "\barcanist's magic aura\}", "nystul's magic aura|phb|arcanist's magic aura}"
                    continue
                }
                "(?<!s )\bfreezing sphere\}" {
                    $_ -replace "\bfreezing sphere\}", "otiluke's freezing sphere|phb|freezing sphere}"
                    continue
                }
                "(?<!s )\bresilient sphere\}" {
                    $_ -replace "\bresilient sphere\}", "otiluke's resilient sphere|phb|resilient sphere}"
                    continue
                }
                "(?<!s )\birresistible dance\}" {
                    $_ -replace "\birresistible dance\}", "otto's irresistible dance|phb|irresistible dance}"
                    continue
                }
                "(?<!s )\btelepathic bond\}" {
                    $_ -replace "\btelepathic bond\}", "rary's telepathic bond|phb|telepathic bond}"
                    continue
                }
                "\bhideous laughter\}" {
                    $_ -replace "(?<!s )\bhideous laughter\}", "tasha's hideous laughter|phb|hideous laughter"
                    $null = $monster.conditionInflictSpell.AddRange(@("prone", "incapacitated"))
                    continue
                }
                "(?<!s )\bfloating disk\}" {
                    $_ -replace "\bfloating disk\}", "tenser's floating disk|phb|floating disk}"
                    continue
                }
                "\bblindness\/deafness\}" {
                    $_
                    $null = $monster.conditionInflictSpell.Add("blinded")
                    continue
                }
                "\bcolor spray\}" {
                    $_
                    $null = $monster.conditionInflictSpell.Add("blinded")
                    continue
                }
                "\bcontagion\}" {
                    $_
                    $null = $monster.conditionInflictSpell.AddRange(@("poisoned", "blinded", "stunned"))
                    continue
                }
                "\bdivine word\}" {
                    $_
                    $null = $monster.conditionInflictSpell.AddRange(@("deafened", "blinded", "stunned"))
                    continue
                }
                "\bholy aura\}" {
                    $_
                    $null = $monster.conditionInflictSpell.Add("blinded")
                    continue
                }
                "\bmislead\}" {
                    $_
                    $null = $monster.conditionInflictSpell.AddRange(@("blinded", "invisible", "deafened"))
                    continue
                }
                "\bprismatic (spray|wall)\}" {
                    $_
                    $null = $monster.conditionInflictSpell.AddRange(@("blinded", "restrained", "petrified"))
                    continue
                }
                "\bproject image\}" {
                    $_
                    $null = $monster.conditionInflictSpell.AddRange(@("blinded", "deafened"))
                    continue
                }
                "\bsunb(eam|urst)\}" {
                    $_
                    $null = $monster.conditionInflictSpell.Add("blinded")
                    continue
                }
                "\ba(nimal friendship|waken)\}" {
                    $_
                    $null = $monster.conditionInflictSpell.Add("charmed")
                    continue
                }
                "\bcharm person\}" {
                    $_
                    $null = $monster.conditionInflictSpell.Add("charmed")
                    continue
                }
                "\bdominate (beast|monster|person)\}" {
                    $_
                    $null = $monster.conditionInflictSpell.Add("charmed")
                    continue
                }
                "\bgeas\}" {
                    $_
                    $null = $monster.conditionInflictSpell.Add("charmed")
                    continue
                }
                "\bhypnotic pattern\}" {
                    $_
                    $null = $monster.conditionInflictSpell.AddRange(@("charmed", "incapacitated"))
                    continue
                }
                "\bmodify memory\}" {
                    $_
                    $null = $monster.conditionInflictSpell.AddRange(@("charmed", "incapacitated"))
                    continue
                }
                "\bs(ilence|torm of vengeance)\}" {
                    $_
                    $null = $monster.conditionInflictSpell.Add("deafened")
                    continue
                }
                "\bantipathy\/sympathy\}" {
                    $_
                    $null = $monster.conditionInflictSpell.Add("frightened")
                    continue
                }
                "\beyebite\}" {
                    $_
                    $null = $monster.conditionInflictSpell.AddRange(@("frightened", "unconscious"))
                    continue
                }
                "\bfear\}" {
                    $_
                    $null = $monster.conditionInflictSpell.Add("frightened")
                    continue
                }
                "\bphantasmal killer\}" {
                    $_
                    $null = $monster.conditionInflictSpell.Add("frightened")
                    continue
                }
                "\bsymbol\}" {
                    $_
                    $null = $monster.conditionInflictSpell.AddRange(@("frightened", "unconscious", "incapacitated", "stunned"))
                    continue
                }
                "\bweird\}" {
                    $_
                    $null = $monster.conditionInflictSpell.Add("frightened")
                    continue
                }
                "\bbanishment\}" {
                    $_
                    $null = $monster.conditionInflictSpell.Add("incapacitated")
                    continue
                }
                "\bwind walk\}" {
                    $_
                    $null = $monster.conditionInflictSpell.Add("incapacitated")
                    continue
                }
                "\b(greater )?invisibility\}" {
                    $_
                    $null = $monster.conditionInflictSpell.Add("invisible")
                    continue
                }
                "\bsequester\}" {
                    $_
                    $null = $monster.conditionInflictSpell.Add("invisible")
                    continue
                }
                "\bhold (monster|person)\}" {
                    $_
                    $null = $monster.conditionInflictSpell.Add("paralyzed")
                    continue
                }
                "\bflesh to stone\}" {
                    $_
                    $null = $monster.conditionInflictSpell.AddRange(@("restrained", "petrified"))
                    continue
                }
                "\bcommand\}" {
                    $_
                    $null = $monster.conditionInflictSpell.Add("prone")
                    continue
                }
                "\bearthquake\}" {
                    $_
                    $null = $monster.conditionInflictSpell.Add("prone")
                    continue
                }
                "\bgrease\}" {
                    $_
                    $null = $monster.conditionInflictSpell.Add("prone")
                    continue
                }
                "\bmeld into stone\}" {
                    $_
                    $null = $monster.conditionInflictSpell.Add("prone")
                    continue
                }
                "\bsleet storm\}" {
                    $_
                    $null = $monster.conditionInflictSpell.Add("prone")
                    continue
                }
                "\bentangle\}" {
                    $_
                    $null = $monster.conditionInflictSpell.Add("restrained")
                    continue
                }
                "\bimprisonment\}" {
                    $_
                    $null = $monster.conditionInflictSpell.Add("restrained")
                    continue
                }
                "\btelekinesis\}" {
                    $_
                    $null = $monster.conditionInflictSpell.Add("restrained")
                    continue
                }
                "\bweb\}" {
                    $_
                    $null = $monster.conditionInflictSpell.Add("restrained")
                    continue
                }
                "\bpower word stun\}" {
                    $_
                    $null = $monster.conditionInflictSpell.Add("stunned")
                    continue
                }
                "\bastral projection\}" {
                    $_
                    $null = $monster.conditionInflictSpell.Add("unconscious")
                    continue
                }
                "\bsleep\}" {
                    $_
                    $null = $monster.conditionInflictSpell.Add("unconscious")
                    continue
                }
                default { $_ }
            }
        )
    }
}
function Enumerate-DamageTypes {
    PARAM(
        [Parameter(Mandatory, ValueFromPipeline)]$text
    )
    PROCESS {
        Write-Output @(
            switch -Exact (($text | Select-String '(?<=\b(Hit:\s*|(tak|deal|inflict|suffer)\w{0,3}|f?or|plus|and) [\dd \+\-\(\)×x\*÷\/\*]+? )\w{4,11}(?= damage)' -AllMatches).Matches.Value) {
                bludgeoning {
                    "B"
                    continue
                }
                piercing {
                    "P"
                    continue
                }
                slashing {
                    "S"
                    continue
                }
                acid {
                    "A"
                    continue
                }
                cold {
                    "C"
                    continue
                }
                fire {
                    "F"
                    continue
                }
                force {
                    "O"
                    continue
                }
                lightning {
                    "L"
                    continue
                }
                necrotic {
                    "N"
                    continue
                }
                poison {
                    "I"
                    continue
                }
                psychic {
                    "Y"
                    continue
                }
                radiant {
                    "R"
                    continue
                }
                thunder {
                    "T"
                }
            }
        )
    }
}
function Enumerate-Conditions {
    PARAM(
        [Parameter(Mandatory, ValueFromPipeline)]$text
    )
    PROCESS{
        Write-Output @(
            switch -Regex ($text) {
                "(?<!against( being| the)?|or|n['o]t( be)?) blinded\b" { "blinded" }
                "(?<!against( being| the)?|or|n['o]t( be)?) charmed\b" { "charmed" }
                "(?<!against( being| the)?|or|n['o]t( be)?) deafened\b" { "deafened" }
                "(?<!against( gaining)?) exhaustion\b" { "exhaustion" }
                "(?<!against( being| the)?|or|n['o]t( be)?) frightened\b" { "frightened" }
                "(?<!against( being| the)?|or|n['o]t( be)?) grappled\b" { "grappled" }
                "(?<!against( being| the)?|or|n['o]t( be)?) incapacitated\b" { "incapacitated" }
                "(?<!against( being| the)?|or|n['o]t( be)?) invisible\b" { "invisible" }
                "(?<!against( being| the)?|or|n['o]t( be)?) paraly[sz]ed\b" { "paralyzed" }
                "(?<!against( being| the)?|or|n['o]t( be)?) petrified\b" { "petrified" }
                "(?<!against( being| the)?|or|n['o]t( be)?) poisoned\b" { "poisoned" }
                "(?<!against( being)?|or|n['o]t( be)?) (knocked|pushed|shoved|becomes|falls) prone\b" { "prone" }
                "(?<!against( being| the)?|or|n['o]t( be)?) restrained\b" { "restrained" }
                "(?<!against( being| the)?|or|n['o]t( be)?) stunned\b" { "stunned" }
                "(?<!against( being)?|or|n['o]t( be)?) (knocked|pushed|shoved|becomes|falls) unconscious\b" { "unconscious" }
            }
        )
    }
}

###

Write-Output "`n`nBeginning conversion...`n"

# PROCESS
$db.root.npc.$c.ChildNodes | ForEach-Object -Begin {
    $progress = 0
    $progmax = $db.root.npc.$c.ChildNodes.Count
    $errors = 0
    $warnings = 0
} -Process {
    Write-Progress -Activity "Converting monsters..." -Status $_.name.$t -PercentComplete ($progress/$progmax*100)
    $status = ""
    $monster = [PSCustomObject]::new()

    # GENERAL DATA
    $monster | Add-Member -NotePropertyMembers ([ordered]@{
        source = $source
        page = 0
    })

    # NAME
    $monster | Add-Member -MemberType NoteProperty -Name name -Value $_.name.$t
    if ($_.name.$t -match ", ") {
        switch -Exact ($nameQueryDefault) {
            a { break }
            s {
                $monster.name = $_.name.$t -replace '^(.+), (.+)$', '$2 $1'
                break
            }
            d { $monster.name = $_.name.$t -replace '^.+, (.+)$', '$1' }
            default {
                Write-Host "`n`nThis creature's name might be jumbled. Enter the intended name or use a shortcut:"
                Write-Host "`ta  |  Accept name        >  $($monster.name)"
                Write-Host "`ts  |  Switch order       >  $($monster.name -replace '^(.+), (.+)$', '$2 $1')"
                Write-Host "`td  |  Discard pre-comma  >  $($monster.name -replace '^.+, (.+)$', '$1')"
                Write-Host "(Capitalise shortcut to apply for all.)"
                :promptUser do {
                    Write-Host "> " -NoNewLine
                    switch -Exact -CaseSensitive (Read-Host) {
                        a { break promptUser }
                        s {
                            $monster.name = $monster.name -replace '^(.+), (.+)$', '$2 $1'
                            break promptUser
                        }
                        d {
                            $monster.name = $monster.name -replace '^.+, (.+)$', '$1'
                            break promptUser
                        }
                        A {
                            $nameQueryDefault = "a"
                            break promptUser
                        }
                        S {
                            $monster.name = $monster.name -replace '^(.+), (.+)$', '$2 $1'
                            $nameQueryDefault = "s"
                            break promptUser
                        }
                        D {
                            $monster.name = $monster.name -replace '^.+, (.+)$', '$1'
                            $nameQueryDefault = "d"
                            break promptUser
                        }
                        default { 
                            if ($_.Length -gt 1) {
                                $monster.name = $_
                                break promptUser
                            }
                        }
                    }
                } until ($false)
            }
        }
    }

    # SIZE
    switch ($_.size.$t) {
        tiny {
            $monster | Add-Member -MemberType NoteProperty -Name size -Value "T"
            break
        }
        small {
            $monster | Add-Member -MemberType NoteProperty -Name size -Value "S"
            break
        }
        medium {
            $monster | Add-Member -MemberType NoteProperty -Name size -Value "M"
            break
        }
        large {
            $monster | Add-Member -MemberType NoteProperty -Name size -Value "L"
            break
        }
        huge {
            $monster | Add-Member -MemberType NoteProperty -Name size -Value "H"
            break
        }
        gargantuan { $monster | Add-Member -MemberType NoteProperty -Name size -Value "G" }
        default {
            $monster | Add-Member -MemberType NoteProperty -Name size -Value "xxxERRORxxx : Unknown size = ``$_``"
            $status += "e"
        }
    }

    # TYPE
    if ($_.type.$t -match 'swarm of|\(') {
        $monster | Add-Member -MemberType NoteProperty -Name type -Value ([PSCustomObject]@{type = $_.type.$t -replace '^(swarm of \w+ )?(\w+)\b.*$', '$2'})
        if ($_.type.$t -match 'swarm of') {
            $monster.type | Add-Member -MemberType NoteProperty -Name swarmSize -Value $(
                switch ($_.type.$t -replace '^swarm of (\w+) \w+\b.*$', '$1') {
                    tiny {
                        "T"
                        break
                    }
                    small {
                        "S"
                        break
                    }
                    medium {
                        "M"
                        break
                    }
                    large {
                        "L"
                        break
                    }
                    huge {
                        "H"
                        break
                    }
                    gargantuan { "G" }
                    default {
                        "xxxERRRORxxx : Unknown swarmSize = ``" + $_ + "``"
                        $status += "e"
                    }
                }
            )
            $monster.type.type = switch ($monster.type.type) {
                fey { break }
                monstrosities {
                    "monstrosity"
                    break
                }
                undead { break }
                default { $monster.type.type -replace 's$' }
            }
        }
        if ($_.type.$t -match '\(') {
            $monster.type | Add-Member -MemberType NoteProperty -Name tags -Value @($_.type.$t -replace '^.*\(([\w ,\-]+)\).*$', '$1' -split ', ')
        }
    } else {
        $monster | Add-Member -MemberType NoteProperty -Name type -Value $_.type.$t
    }

    # ALIGNMENT
    switch -regex ($_.alignment.$t) {
        '^typically ' {
            $monster | Add-Member -MemberType NoteProperty -Name alignmentPrefix -Value "typically "
        }
        '\bunaligned$' {
            $monster | Add-Member -MemberType NoteProperty -Name alignment -Value @("U")
            continue
        }
        '\bneutral$' {
            $monster | Add-Member -MemberType NoteProperty -Name alignment -Value @("N")
            continue
        }
        '^any( alignment)?$' {
            $monster | Add-Member -MemberType NoteProperty -Name alignment -Value @("A")
            continue
        }
        '\blawful good$' {
            $monster | Add-Member -MemberType NoteProperty -Name alignment -Value @("L", "G")
            continue
        }
        '\bneutral good$' {
            $monster | Add-Member -MemberType NoteProperty -Name alignment -Value @("N", "G")
            continue
        }
        '\bchaotic good$' {
            $monster | Add-Member -MemberType NoteProperty -Name alignment -Value @("C", "G")
            continue
        }
        '\bchaotic neutral$' {
            $monster | Add-Member -MemberType NoteProperty -Name alignment -Value @("C", "N")
            continue
        }
        '\blawful evil$' {
            $monster | Add-Member -MemberType NoteProperty -Name alignment -Value @("L", "E")
            continue
        }
        '\blawful neutral$' {
            $monster | Add-Member -MemberType NoteProperty -Name alignment -Value @("L", "N")
            continue
        }
        '\bneutral evil$' {
             $monster | Add-Member -MemberType NoteProperty -Name alignment -Value @("N", "E")
            continue
        }
        '\bchaotic evil$' {
             $monster | Add-Member -MemberType NoteProperty -Name alignment -Value @("C", "E")
            continue
        }
        '\bany non\-good( alignment)?$' {
            $monster | Add-Member -MemberType NoteProperty -Name alignment -Value @("L", "NX", "C", "NY", "E")
            continue
        }
        '\bany non\-lawful( alignment)?$' {
            $monster | Add-Member -MemberType NoteProperty -Name alignment -Value @("NX", "C", "G", "NY", "E")
            continue
        }
        '\bany non\-evil( alignment)?$' {
            $monster | Add-Member -MemberType NoteProperty -Name alignment -Value @("L", "NX", "C", "NY", "G")
            continue
        }
        '\bany non\-chaotic( alignment)?$' {
            $monster | Add-Member -MemberType NoteProperty -Name alignment -Value @("NX", "L", "G", "NY", "E")
            continue
        }
        '\bany chaotic( alignment)?$' {
            $monster | Add-Member -MemberType NoteProperty -Name alignment -Value @("C", "G", "NY", "E")
            continue
        }
        '\bany evil( alignment)?$' {
            $monster | Add-Member -MemberType NoteProperty -Name alignment -Value @("L", "NX", "C", "E")
            continue
        }
        '\bany lawful( alignment)?$' {
            $monster | Add-Member -MemberType NoteProperty -Name alignment -Value @("L", "G", "NY", "E")
            continue
        }
        '\bany good( alignment)?$' {
            $monster | Add-Member -MemberType NoteProperty -Name alignment -Value @("L", "NX", "C", "G")
            continue
        }
        '\bany neutral( alignment)?$' {
            $monster | Add-Member -MemberType NoteProperty -Name alignment -Value @("NX", "NY", "N")
            continue
        }
        '\bgood$' {
            $monster | Add-Member -MemberType NoteProperty -Name alignment -Value @("G")
            continue
        }
        '\blawful$' {
            $monster | Add-Member -MemberType NoteProperty -Name alignment -Value @("L")
            continue
        }
        '\bchaotic$' {
            $monster | Add-Member -MemberType NoteProperty -Name alignment -Value @("C")
            continue
        }
        '\bevil$' { $monster | Add-Member -MemberType NoteProperty -Name alignment -Value @("E") }
        default {
            $monster | Add-Member -MemberType NoteProperty -Name alignment -Value @("xxxERRORxxx : Unknown alignment = ``" + $_ + "``")
            $status += "e"
        }
    }

    # AC
    if ($_.actext) {
        $monster | Add-Member -MemberType NoteProperty -Name ac -Value @(
            ($_.ac.$t + " " + $_.actext.$t) -split '(?<!\([^\)]+), (?![^\(]+\))' -split '(?<=\d.+) (\(\d+ .+\))' -ne "" | ForEach-Object {
                if ($_ -match '^\d+$') {
                    [int]$_
                } else {
                    $ac = [PSCustomObject]@{
                        ac = [int]($_ -replace '^\(?(\d+)\b.*$', '$1')
                    }
                    if ($_ -match '\(\D+\)') {
                        $ac | Add-Member -MemberType NoteProperty -Name from -Value @(
                            switch -Regex ($_ -replace '^.*\(([\D]+)\).*$', '$1' -split ', ') {
                                'natural armou?r' {
                                    $_
                                    continue
                                }
                                '^padded' {
                                    if ($_ -eq 'padded armor') {
                                        "{@item padded armor|phb}"
                                    } else {
                                        "{@item padded armor|phb|$_}"
                                    }
                                    continue
                                }
                                '^leather' {
                                    if ($_ -eq 'leather armor') {
                                        "{@item leather armor|phb}"
                                    } else {
                                        "{@item leather armor|phb|$_}"
                                    }
                                    continue
                                }
                                '^studded' {
                                    if ($_ -eq 'studded leather armor') {
                                        "{@item studded leather armor|phb}"
                                    } else {
                                        "{@item studded leather armor|phb|$_}"
                                    }
                                    continue
                                }
                                '^hide' {
                                    if ($_ -eq 'hide armor') {
                                        "{@item hide armor|phb}"
                                    } else {
                                        "{@item hide armor|phb|$_}"
                                    }
                                    continue
                                }
                                '^chain ?shirt$' {
                                    if ($_ -eq 'chain shirt') {
                                        "{@item chain shirt|phb}"
                                    } else {
                                        "{@item chain shirt|phb|$_}"
                                    }
                                    continue
                                }
                                '^scale' {
                                    if ($_ -eq 'scale mail') {
                                        "{@item scale mail|phb}"
                                    } else {
                                        "{@item scale mail|phb|$_}"
                                    }
                                    continue
                                }
                                '^breast' {
                                    if ($_ -eq 'breastplate') {
                                        "{@item breastplate|phb}"
                                    } else {
                                        "{@item breatplate|phb|$_}"
                                    }
                                    continue
                                }
                                '^half' {
                                    if ($_ -eq 'half plate armor') {
                                        "{@item half plate armor|phb}"
                                    } else {
                                        "{@item half plate armor|phb|$_}"
                                    }
                                    continue
                                }
                                '^ring' {
                                    if ($_ -eq 'ring mail') {
                                        "{@item ring mail|phb}"
                                    } else {
                                        "{@item ring mail|phb|$_}"
                                    }
                                    continue
                                }
                                '^chain ?mail' {
                                    if ($_ -eq 'chain mail') {
                                        "{@item chain mail|phb}"
                                    } else {
                                        "{@item chain mail|phb|$_}"
                                    }
                                    continue
                                }
                                '^splint' {
                                    if ($_ -eq 'splint armor') {
                                        "{@item splint armor|phb}"
                                    } else {
                                        "{@item splint armor|phb|$_}"
                                    }
                                    continue
                                }
                                '^plate' {
                                    if ($_ -eq 'plate armor') {
                                        "{@item plate armor|phb}"
                                    } else {
                                        "{@item plate armor|phb|$_}"
                                    }
                                    continue
                                }
                                '^shield$' { "{@item shield|phb}" }
                                default {
                                    $_
                                    $status += "w"
                                }
                            }
                        )
                    }
                    if ($_ -match '\b(in|with)\b') {
                        $ac | Add-Member -MemberType NoteProperty -Name condition -Value ($_ -replace '^\(?\d+( \(.*\))? \(?((in|with) [^\)]+)\)?.*$', '$2' -replace 'mage armou?r', '{@spell mage armor}')
                    }
                    if ($_ -match '^\(') {
                        $ac | Add-Member -MemberType NoteProperty -Name braces -Value $true
                    }
                    $ac
                }
            }
        )
    } else {
        $monster | Add-Member -MemberType NoteProperty -Name ac -Value @($_.ac.$t)
    }

    # HP
    $monster | Add-Member -MemberType NoteProperty -Name hp -Value @{
        average = [int]$_.hp.$t
        formula = $_.hd.$t -replace '^\(' -replace '\)$'
    }

    # SPEED   //   walk, burrow, climb, fly (hover), swim
    $monster | Add-Member -MemberType NoteProperty -Name speed -Value ([PSCustomObject]::new())
    switch -Regex ($_.speed.$t) {
        '^(?<walk>\d+) ?ft\.?( (?<condition>\(?.+\)?))?' {
            if ($Matches.condition) {
                $monster.speed | Add-Member -MemberType NoteProperty -Name walk -Value ([PSCustomObject]@{
                    number = [int]$Matches.walk
                    condition = $Matches.condition
                })
            } else {
                $monster.speed | Add-Member -MemberType NoteProperty -Name walk -Value ([int]$Matches.walk)
            }
        }
        '(?<!\([^\)]+)\bburrow (?<burrow>\d+) ?ft\.?( (?<condition>\(?.+\)?))?' {
            if ($Matches.condition) {
                $monster.speed | Add-Member -MemberType NoteProperty -Name burrow -Value ([PSCustomObject]@{
                    number = [int]$Matches.burrow
                    condition = $Matches.condition
                })
            } else {
                $monster.speed | Add-Member -MemberType NoteProperty -Name burrow -Value ([int]$Matches.burrow)
            }
        }
        '(?<!\([^\)]+)\bclimb (?<climb>\d+) ?ft\.?( (?<condition>\(?.+\)?))?' {
            if ($Matches.condition) {
                $monster.speed | Add-Member -MemberType NoteProperty -Name climb -Value ([PSCustomObject]@{
                    number = [int]$Matches.climb
                    condition = $Matches.condition
                })
            } else {
                $monster.speed | Add-Member -MemberType NoteProperty -Name climb -Value ([int]$Matches.climb)
            }
        }
        '(?<!\([^\)]+)\bfly (?<fly>\d+) ?ft\.?( (?<condition>\(?.+\)?))?' {
            if ($Matches.condition) {
                $monster.speed | Add-Member -MemberType NoteProperty -Name fly -Value ([PSCustomObject]@{
                    number = [int]$Matches.fly
                    condition = $Matches.condition
                })
                if ($Matches.condition -match '\bhover\b') {
                    $monster.speed | Add-Member -MemberType NoteProperty -Name canHover -Value $true
                }
            } else {
                $monster.speed | Add-Member -MemberType NoteProperty -Name fly -Value ([int]$Matches.fly)
            }
        }
        '(?<!\([^\)]+)\bswim (?<swim>\d+) ?ft\.?( (?<condition>\(?.+\)?))?' {
            if ($Matches.condition) {
                $monster.speed | Add-Member -MemberType NoteProperty -Name swim -Value ([PSCustomObject]@{
                    number = [int]$Matches.swim
                    condition = $Matches.condition
                })
            } else {
                $monster.speed | Add-Member -MemberType NoteProperty -Name swim -Value ([int]$Matches.swim)
            }
        }
        default {
            $monster.speed | Add-Member -MemberType NoteProperty -Name walk -Value "xxxERRORxxx : Unknown speed = ``$_``"
            $status += "e"
        }
    }

    # ABILITY SCORES
    $monster | Add-Member -NotePropertyMembers ([ordered]@{
        str = [int]$_.abilities.strength.score.$t
        dex = [int]$_.abilities.dexterity.score.$t
        con = [int]$_.abilities.constitution.score.$t
        int = [int]$_.abilities.intelligence.score.$t
        wis = [int]$_.abilities.wisdom.score.$t
        cha = [int]$_.abilities.charisma.score.$t
    })

    # SAVING THROWS
    if ($_.savingthrows) {
        $monster | Add-Member -MemberType NoteProperty -Name save -Value ([PSCustomObject]::new())
        switch -Regex ($_.savingthrows.$t) {
            '\bstr (?<mod>[+-]\d+)' { $monster.save | Add-Member -MemberType NoteProperty -Name str -Value $Matches.mod }
            '\bdex (?<mod>[+-]\d+)' { $monster.save | Add-Member -MemberType NoteProperty -Name dex -Value $Matches.mod }
            '\bcon (?<mod>[+-]\d+)' { $monster.save | Add-Member -MemberType NoteProperty -Name con -Value $Matches.mod }
            '\bint (?<mod>[+-]\d+)' { $monster.save | Add-Member -MemberType NoteProperty -Name int -Value $Matches.mod }
            '\bwis (?<mod>[+-]\d+)' { $monster.save | Add-Member -MemberType NoteProperty -Name wis -Value $Matches.mod }
            '\bcha (?<mod>[+-]\d+)' { $monster.save | Add-Member -MemberType NoteProperty -Name cha -Value $Matches.mod }
            default {
                $monster.save | Add-Member -MemberType NoteProperty -Name str -Value "xxxERRORxxx : Unknown saving throw = ``$_``"
                $status += "e"
            }
        }
    }

    # SKILLS
    if ($_.skills) {
        $monster | Add-Member -MemberType NoteProperty -Name skill -Value ([PSCustomObject]::new())
        switch -Regex ($_.skills.$t) {
            '\bacrobatics (?<mod>[+-]\d+)' { $monster.skill | Add-Member -MemberType NoteProperty -Name acrobatics -Value $Matches.mod }
            '\banimal handling (?<mod>[+-]\d+)' { $monster.skill | Add-Member -MemberType NoteProperty -Name "animal handling" -Value $Matches.mod }
            '\barcana (?<mod>[+-]\d+)' { $monster.skill | Add-Member -MemberType NoteProperty -Name arcana -Value $Matches.mod }
            '\bathletics (?<mod>[+-]\d+)' { $monster.skill | Add-Member -MemberType NoteProperty -Name athletics -Value $Matches.mod }
            '\bdeception (?<mod>[+-]\d+)' { $monster.skill | Add-Member -MemberType NoteProperty -Name deception -Value $Matches.mod }
            '\bhistory (?<mod>[+-]\d+)' { $monster.skill | Add-Member -MemberType NoteProperty -Name history -Value $Matches.mod }
            '\binsight (?<mod>[+-]\d+)' { $monster.skill | Add-Member -MemberType NoteProperty -Name insight -Value $Matches.mod }
            '\bintimidation (?<mod>[+-]\d+)' { $monster.skill | Add-Member -MemberType NoteProperty -Name intimidation -Value $Matches.mod }
            '\binvestigation (?<mod>[+-]\d+)' { $monster.skill | Add-Member -MemberType NoteProperty -Name investigation -Value $Matches.mod }
            '\bmedicine (?<mod>[+-]\d+)' { $monster.skill | Add-Member -MemberType NoteProperty -Name medicine -Value $Matches.mod }
            '\bnature (?<mod>[+-]\d+)' { $monster.skill | Add-Member -MemberType NoteProperty -Name nature -Value $Matches.mod }
            '\bperception (?<mod>[+-]\d+)' { $monster.skill | Add-Member -MemberType NoteProperty -Name perception -Value $Matches.mod }
            '\bperformance (?<mod>[+-]\d+)' { $monster.skill | Add-Member -MemberType NoteProperty -Name performance -Value $Matches.mod }
            '\bpersuasion (?<mod>[+-]\d+)' { $monster.skill | Add-Member -MemberType NoteProperty -Name persuasion -Value $Matches.mod }
            '\breligion (?<mod>[+-]\d+)' { $monster.skill | Add-Member -MemberType NoteProperty -Name religion -Value $Matches.mod }
            '\bsleight of hand (?<mod>[+-]\d+)' { $monster.skill | Add-Member -MemberType NoteProperty -Name "sleight of hand" -Value $Matches.mod }
            '\bstealth (?<mod>[+-]\d+)' { $monster.skill | Add-Member -MemberType NoteProperty -Name stealth -Value $Matches.mod }
            '\bsurvival (?<mod>[+-]\d+)' { $monster.skill | Add-Member -MemberType NoteProperty -Name survival -Value $Matches.mod }
            default {
                $monster.skill | Add-Member -MemberType NoteProperty -Name perception -Value "xxxERRORxxx : Unknown skill = ``$_``"
                $status += "e"
            }
        }
    }

    # DAMAGE VULNERABILITIES
    if ($_.damagevulnerabilities) {
        $monster | Add-Member -MemberType NoteProperty -Name vulnerable -Value @(
            $_.damagevulnerabilities.$t -split '; ' | ForEach-Object {
                if ($_ -notmatch '\sfrom \w+') {
                    $_ -split ', ' -split ' ?and ' -ne ""
                } else {
                    [PSCustomObject]@{
                        vulnerable = @($_ -replace '^(.+)\sfrom .*$', '$1' -split ', ' -split ' ?and ' -ne "")
                        note = $_ -replace '^.+\s(from .*)$', '$1'
                        cond = $true
                    }
                }
            }
        )
    }

    # DAMAGE RESISTANCES
    if ($_.damageresistances) {
        $monster | Add-Member -MemberType NoteProperty -Name resist -Value @(
            $_.damageresistances.$t -split '; ' | ForEach-Object {
                if ($_ -notmatch '\sfrom \w+') {
                    $_ -split ', ' -split ' ?and ' -ne ""
                } else {
                    [PSCustomObject]@{
                        resist = @($_ -replace '^(.+)\sfrom .*$', '$1' -split ', ' -split ' ?and ' -ne "")
                        note = $_ -replace '^.+\s(from .*)$', '$1'
                        cond = $true
                    }
                }
            }
        )
    }

    # DAMAGE IMMUNITIES
    if ($_.damageimmunities) {
        $monster | Add-Member -MemberType NoteProperty -Name immune -Value @(
            $_.damageimmunities.$t -split '; ' | ForEach-Object {
                if ($_ -notmatch '\sfrom \w+') {
                    $_ -split ', ' -split ' ?and ' -ne ""
                } else {
                    [PSCustomObject]@{
                        immune = @($_ -replace '^(.+)\sfrom .*$', '$1' -split ', ' -split ' ?and ' -ne "")
                        note = $_ -replace '^.+\s(from .*)$', '$1'
                        cond = $true
                    }
                }
            }
        )
    }

    # CONDITION IMMUNITIES
    if ($_.conditionimmunities) {
        $monster | Add-Member -MemberType NoteProperty -Name conditionImmune -Value @($_.conditionimmunities.$t -split ', ')
    }

    # SENSES & PASSIVE PERCEPTION
    $null = $_.senses.$t -match '^(?<senses>.*)passive perception (?<passive>\d+)$'
    if ($Matches.senses) {
        $monster | Add-Member -NotePropertyMembers ([ordered]@{
            senses = @($Matches.senses -split ', ' -ne "")
            passive = [int]$Matches.passive
        })

        # SENSE TAGS
        $monster | Add-Member -MemberType NoteProperty -Name senseTags -Value @(
            switch -Regex ($Matches.senses) {
                '\bblindsight\b' { "B" }
                '\bdarkvision \d{1,2}(?!\d)' { "D" }
                '\bdarkvision \d{3,}(?!\d)' { "SD" }
                '\btremorsense\b' { "T" }
                '\btruesight\b' { "U" }
            }
        )
    } else {
        $monster | Add-Member -MemberType NoteProperty -Name passive -Value ([int]$Matches.passive)
    }

    # LANGUAGES
    if ($_.languages -and $_.languages.$t -match '\w') {
        $monster | Add-Member -MemberType NoteProperty -Name languages -Value @($_.languages.$t -split ', ')

        # LANGUAGE TAGS
        $monster | Add-Member -MemberType NoteProperty -Name languageTags -Value @(
            @(
                switch -Regex ($_.languages.$t) {
                    '\bCommon\b' { "C" }
                    '\bAbyssal\b' { "AB" }
                    '\bAquan\b' { "AQ" }
                    '\bAuran\b' { "AU" }
                    '\bCelestial\b' { "CE" }
                    '\bDraconic\b' { "DR" }
                    '\bDwarvish\b' { "D" }
                    '\bElvish\b' { "E" }
                    '\bGiant\b' { "GI" }
                    '\bGnomish\b' { "G" }
                    '\bGoblin\b' { "GO" }
                    '\bHalfling\b' { "H" }
                    '\bInfernal\b' { "I" }
                    '\bOrc\b' { "O" }
                    '\bPrimordial\b' { "P" }
                    '\bSylvan\b' { "S" }
                    '\bTerran\b' { "T" }
                    '\bDruidic\b' { "DU" }
                    '\bGith\b' { "GTH" }
                    '\bthieve[s'']{1,2} cant\b' { "TC" }
                    '\bDeep Speech\b' { "DS" }
                    '\bIgnan\b' { "IG" }
                    '\bUndercommon\b' { "U" }
                    '\btelepathy\b' { "TP" }
                    '\ball\b' { "XX" }
                    '\bcan(''| ?no)t speak\b' { "CS" }
                    ' in life\b' { "LF" }
                    '(\b(any|choose|p(lus|ick)) |\b(other|extra|additional|more) language| cho(ice|osing)\b)' { "X" }
                    default { "OTH" }
                }
            ) | Sort-Object -Unique
        )
    }

    # CR
    $monster | Add-Member -MemberType NoteProperty -Name cr -Value $_.cr.$t

    # TRAITS
    $spellcastingFlag = $false # It's a surprise tool that'll help us later! 😏
    $damageTags = [System.Collections.ArrayList]::new()
    $conditionInflict = [System.Collections.ArrayList]::new()
    if ($_.traits) {
        $monster | Add-Member -MemberType NoteProperty -Name trait -Value ([System.Collections.ArrayList]::new())
        $_.traits.ChildNodes | ForEach-Object {
            <# SPELLCASTING
                Use commented-out conditional opening below instead of the uncommented one if FG starts
                allowing spellcasting in actions. At time of writing, even brews with spellcasting actions
                displayed as the legacy spellcasting traits on FG.
            #>
#           if (-not $spellcastingActions -and $_.name.$t -match '^(innate |shared )?spellcasting( \(.+\))?$') {
            if ($_.name.$t -match '^(innate |shared )?spellcasting( \(.+\))?$') {
                $spellcastingFlag = $true
            } else {
                $null = $monster.trait.Add([PSCustomObject]@{
                    name = $_.name.$t
                    entries = @(Format-Entries @($_.desc))
                })
                $null = $damageTags.AddRange(@(Enumerate-DamageTypes $_.desc.$t))
                $null = $conditionInflict.AddRange(@(Enumerate-Conditions $_.desc.$t))
            }
        }
        if (-not $monster.trait) {
            $monster.PSObject.Properties.Remove('trait')
        } else {
            # TRAIT TAGS
            $monster | Add-Member -MemberType NoteProperty -Name traitTags -Value @(
                switch -regex ($monster.trait.name) {
                    "^aggressive\b" {
                        "Aggressive"
                        break
                   }
                    "^ambush\b" {
                        "Ambusher"
                        break
                    }
                    "^amorphous\b" {
                        "Amorphous"
                        break
                    }
                    "^amphibious\b" {
                        "Amphibious"
                        break
                    }
                    "^antimagic susceptibility\b" {
                        "Antimagic Susceptibility"
                        break
                    }
                    "^brute\b" {
                        "Brute"
                        break
                    }
                    "^charge\b" {
                        "Charge"
                        break
                    }
                    "^damage absorption\b" {
                        "Damage Absorption"
                        break
                    }
                    "^death (burst|throes)\b" {
                        "Death Burst"
                        break
                    }
                    "^devil['s]{0,2} sight\b" {
                        "Devil's Sight"
                        break
                    }
                    "^false appearance\b" {
                        "False Appearance"
                        break
                    }
                    "^fey ancestry\b" {
                        "Fey Ancestry"
                        break
                    }
                    "^flyby\b" {
                        "Flyby"
                        break
                    }
                    "^hold breath\b" {
                        "Hold Breath"
                        break
                    }
                    "^illumination\b" {
                        "Illumination"
                        break
                    }
                    "^immutable form\b" {
                        "Immutable Form"
                        break
                    }
                    "^incorporeal movement\b" {
                        "Incorporeal Movement"
                        break
                    }
                    "^keen (sight|hearing|smell|senses)\b" {
                        "Keen Senses"
                        break
                    }
                    "^legendary resistance\b" {
                        "Legendary Resistances"
                        break
                    }
                    "^light sensitivity\b" {
                        "Light Sensitivity"
                        break
                    }
                    "^magic resistance\b" {
                        "Magic Resistance"
                        break
                    }
                    "^magic weapon\b" {
                        "Magic Weapons"
                        break
                    }
                    "^pack tactics\b" {
                        "Pack Tactics"
                        break
                    }
                    "^pounce\b" {
                        "Pounce"
                        break
                    }
                    "^rampage\b" {
                        "Rampage"
                        break
                    }
                    "^reckless\b" {
                        "Reckless"
                        break
                    }
                    "^regenerat(e|ion)\b" {
                        "Regeneration"
                        break
                    }
                    "^rejuvenat(e|ion)\b" {
                        "Rejuvenation"
                        break
                    }
                    "^shapechange\b" {
                        "Shapechanger"
                        break
                    }
                    "^siege monster\b" {
                        "Siege Monster"
                        break
                    }
                    "^sneak attack\b" {
                        "Sneak Attack"
                        break
                    }
                    "^spell immunity\b" {
                        "Spell Immunity"
                        break
                    }
                    "^spider climb\b" {
                        "Spider Climb"
                        break
                    }
                    "^sunlight (hyper)?sensitivity\b" {
                        "Sunlight Sensitivity"
                        break
                    }
                    "^turn(ing)? immunity\b" {
                        "Turn Immunity"
                        break
                    }
                    "^turn(ing)? (defiance|resistance)\b" {
                        "Turn Resistance"
                        break
                    }
                    "^undead fortitude\b" {
                        "Undead Fortitude"
                        break
                    }
                    "^water breathing\b" {
                        "Water Breathing"
                        break
                    }
                    "^web sense\b" {
                        "Web Sense"
                        break
                    }
                    "^web walker\b" { "Web Walker" }
                }
            )
            if (-not $monster.traitTags) {
                $monster.PSObject.Properties.Remove('traitTags')
            }
        }
    }

    # ACTIONS & BONUS ACTIONS + MISCELLANEOUS TAG DISCOVERY
    $miscTags = [System.Collections.ArrayList]::new()
    if ($_.actions) {
        $monster | Add-Member -MemberType NoteProperty -Name action -Value ([System.Collections.ArrayList]::new())
        if ($bonusActions) {
            $monster | Add-Member -MemberType NoteProperty -Name bonus -Value ([System.Collections.ArrayList]::new())
        }
        $_.actions.ChildNodes | ForEach-Object {
            <# SPELLCASTING
                Use commented-out conditional block below, replacing the single-line conditional opener
                if FG starts allowing spellcasting in actions. At time of writing, even brews with
                spellcasting actions displayed as the legacy spellcasting traits on FG.
            #>
#           if ($spellcastingActions -and $_.name.$t -match '^(innate |shared )?spellcasting( \(.+\))?$') {
#               $spellcastingFlag = $true
#           } elseif ($_.desc.$t -cmatch '^As a bonus action, (?<firstletter>\w)') {
            if ($_.desc.$t -cmatch '^As a bonus action, (?<firstLetter>\w)') {
                $null = $monster.bonus.Add(([PSCustomObject]@{
                    name = $_.name.$t -replace '\(recharges? (\d)([-–—−]6)?\)', '{@recharge $1}'
                    entries = @(Tag-Entries ($_.desc.$t -creplace '^As a bonus action, \w', $Matches.firstLetter.ToUpper())) # See comment below
                }))
            } else {
                $null = $monster.action.Add(([PSCustomObject]@{
                    name = $_.name.$t -replace '\(recharges? (\d)([-–—−]6)?\)', '{@recharge $1}'
                    entries = @(Tag-Entries @( # No `entries` object matching because I'm lazy and this would become a mess
                        switch -Regex ($_.desc.$t) {
                            '^Melee Weapon Attack:' {
                                $_ -replace '^Melee Weapon Attack:', '{@atk mw}' -creplace '\bHit:\s*', '{@h}'
                                $null = $miscTags.Add("MW")
                                if ($_ -match ', reach \d{2,}\b') {
                                    $null = $miscTags.Add("RCH")
                                }
                                break
                            }
                            '^Ranged Weapon Attack:' {
                                $_ -replace '^Ranged Weapon Attack:', '{@atk rw}' -creplace '\bHit:\s*', '{@h}'
                                $null = $miscTags.Add("RW")
                                break
                            }
                            '^Melee or Ranged Weapon Attack:' {
                                $_ -replace '^Melee or Ranged Weapon Attack:', '{@atk mw,rw}' -creplace '\bHit:\s*', '{@h}'
                                $null = $miscTags.AddRange(@("MW", "RW", "THW"))
                                if ($_ -match ', reach \d{2,}\b') {
                                    $null = $miscTags.Add("RCH")
                                }
                                break
                            }
                            '^Melee Spell Attack:' {
                                $_ -replace '^Melee Spell Attack:', '{@atk ms}' -creplace '\bHit:\s*', '{@h}'
                                if ($_ -match ', reach \d{2,}\b') {
                                    $null = $miscTags.Add("RCH")
                                }
                                break
                            }
                            '^Ranged Spell Attack:' {
                                $_ -replace '^Ranged Spell Attack:', '{@atk rs}' -creplace '\bHit:\s*', '{@h}'
                                break
                            }
                            '^Melee or Ranged Spell Attack:' {
                                $_ -replace '^Melee or Ranged Spell Attack:', '{@atk ms,rs}' -creplace '\bHit:\s*', '{@h}'
                                break
                            }
                            default {
                                $_
                                if ($_ -match '\b(sphere|line|cone|cube)\b' -or $_ -match '\b(target|creature)s? (with)?in (a )?\d+[ -]f[oe]{2}t\b') {
                                    $null = $miscTags.Add("AOE")
                                }
                            }
                        }
                    ))
                }))
            }
            $null = $damageTags.AddRange(@(Enumerate-DamageTypes $_.desc.$t))
            $null = $conditionInflict.AddRange(@(Enumerate-Conditions $_.desc.$t))
        }
        if (-not $monster.action) {
            $monster.PSObject.Properties.Remove('action')
        }
        if (-not $monster.bonus) {
            $monster.PSObject.Properties.Remove('bonus')
        }
    }
   
    # REACTIONS
    if ($_.reactions) {
        $monster | Add-Member -MemberType NoteProperty -Name reaction -Value ([System.Collections.ArrayList]::new())
        $_.reactions.ChildNodes | ForEach-Object {
            $null = $monster.reaction.Add(([PSCustomObject]@{
                name = $_.name.$t -replace '\(recharge (\d)([-–—−]6)?\)', '{@recharge $1}'
                entries = @(Format-Entries @($_.desc))
            }))
            $null = $damageTags.AddRange(@(Enumerate-DamageTypes $_.desc.$t))
            $null = $conditionInflict.AddRange(@(Enumerate-Conditions $_.desc.$t))
        }
    }

    # ACTION TAGS
    $monster | Add-Member -MemberType NoteProperty -Name actionTags -Value @(
        switch -regex ($monster.action.name + $monster.bonus.name + $monster.reaction.name) {
            "^(Breath (Weapon|of [\w\-' ]+?)|[\w\-' ]+? Breath)\b" {
                "Breath Weapon"
                continue
            }
            "^Frightful Presence\b" {
                "Frightful Presence"
                continue
            }
            "^Multiattack\b" {
                "Multiattack"
                continue
            }
            "^(change| |shape){2,3}\b" {
                "Shapechanger"
                continue
            }
            "^Parry\b" {
                "Parry"
                continue
            }
            "^Swallow\b" {
                "Swallow"
                continue
            }
            "^Teleport\b" {
                "Teleport"
                continue
            }
            "^Tentacles?\b" { "Tentacles" }
        }
    )
    if (-not $monster.actionTags) {
        $monster.PSObject.Properties.Remove('actionTags')
    }

    # SPELLCASTING
    if ($spellcastingFlag) {
        $monster | Add-Member -NotePropertyMembers ([ordered]@{
            spellcasting = [System.Collections.ArrayList]::new()
            spellcastingTags = [System.Collections.ArrayList]::new()
            conditionInflictSpell = [System.Collections.ArrayList]::new()
        })
        $(                                  # SPELLCASTING
#            if ($spellcastingActions) {    # Uncomment this section if you find an FG
#                $_.actions.ChildNodes      # .mod that actually puts spellcasting blocks
#            } else {                       # inside the creature's actions section.
                $_.traits.ChildNodes
#            }
        ) | Where-Object {$_.name.$t -match '^(innate |shared )?spellcasting( \(.+\))?$'} | ForEach-Object {
            if ($spellcastingActions) {
                $spellcastingBuilder = [PSCustomObject]@{
                    type = "spellcasting"
                    name = $_.name.$t
                    headerEntries = @(($_.desc.$t -split '\\n')[0] -creplace '\bDC ?(\d+)\b', '{@dc $1}' -replace '\+?(-?\d+) to hit\b', '{@hit $1} to hit')
                    ability = switch -Regex (($_.desc.$t -split '\\n')[0]) {
                        '\bStrength\b' { "str" }
                        '\bDexterity\b' { "dex" }
                        '\bConstitution\b' { "con" }
                        '\bIntelligence\b' { "int" }
                        '\bWisdom\b' { "wis" }
                        '\bCharisma\b' { "cha" }
                        default {
                            "xxxERRORxxx : Unknown spellcasting ability"
                            $status += "e"
                        }
                    }
                    displayAs = "action"
                }
            } else {
                $spellcastingBuilder = [PSCustomObject]@{
                    type = "spellcasting"
                    name = $_.name.$t
                    headerEntries = @(($_.desc.$t -split '\\n')[0] -creplace '\bDC ?(\d+)\b', '{@dc $1}' -replace '\+?(-?\d+) to hit\b', '{@hit $1} to hit')
                    ability = switch -Regex (($_.desc.$t -split '\\n')[0]) {
                        '\bStrength\b' { "str" }
                        '\bDexterity\b' { "dex" }
                        '\bConstitution\b' { "con" }
                        '\bIntelligence\b' { "int" }
                        '\bWisdom\b' { "wis" }
                        '\bCharisma\b' { "cha" }
                        default {
                            "xxxERRORxxx : Unknown spellcasting ability"
                            $status += "e"
                        }
                    }
                }
            }
            if ($_.desc.$t -notmatch '\\n') {
                $spellcastingBuilder | Add-Member -MemberType NoteProperty -Name hidden -Value @("xxxERRORxxx : Condensed spellcasting block")
                $status += "e"
            } else {
                $spellcastingBuilder | Add-Member -NotePropertyMembers @{
                    spells = [PSCustomObject]::new()
                    rest = [PSCustomObject]::new()
                    day = [PSCustomObject]::new()
                    week = [PSCustomObject]::new()
                    year = [PSCustomObject]::new()
                    hidden = [System.Collections.ArrayList]::new()
                }
                switch -Regex (($_.desc.$t -split '\\n') | Select-Object -Skip 1) {
                    '^at will' {
                        $spellcastingBuilder | Add-Member -MemberType NoteProperty -Name will -Value @(Process-SpellList ($_ -replace '^at will: '))
                        continue
                    }
                    '^(?<num>\d+) ?/ ?day( (?<e>e)ach)?' {
                        $spellcastingBuilder.day | Add-Member -MemberType NoteProperty -Name ($Matches.num + $Matches.e) -Value @(Process-SpellList ($_ -replace '^\d+ ?/ ?day( each)?: '))
                        continue
                    }
                    '^(?<num>\d+)\w{2}[- –—]level( \((?<slots>\d+) slots?\))?' {
                        if ($Matches.slots) {
                            $spellcastingBuilder.spells | Add-Member -MemberType NoteProperty -Name $Matches.num -Value @{
                                slots = [int]$Matches.slots
                                spells = @(Process-SpellList ($_ -replace '^\d+\w{2}[- –—]level( \(\d+ slots?\))?: '))
                            }
                        } else {
                            $spellcastingBuilder.spells | Add-Member -MemberType NoteProperty -Name $Matches.num -Value @{
                                spells = @(Process-SpellList ($_ -replace '^\d+\w{2}[- –—]level( \(\d+ slots?\))?: '))
                            }
                        }
                        continue
                    }
                    '^(?<num>\d+) ?/ ?rest( (?<e>e)ach)?' {
                        $spellcastingBuilder.rest | Add-Member -MemberType NoteProperty -Name ($Matches.num + $Matches.e) -Value @(Process-SpellList ($_ -replace '^\d+ ?/ ?day( each)?: '))
                        continue
                    }
                    '^cantrips?' {
                        $spellcastingBuilder.spells | Add-Member -MemberType NoteProperty -Name '0' -Value @(Process-SpellList ($_ -replace '^cantrips?( \((at will|0th[ -]level)\))?: '))
                        continue
                    }
                    '^(?<lower>\d+)\w{2}[-–—](?<num>\d+)\w{2}[- –—]level \((?<slots>\d+)\b' {
                        $spellcastingBuilder.spells | Add-Member -MemberType NoteProperty -Name $Matches.num -Value @{
                            spells = @(Process-SpellList ($_ -replace '^\d+\w{2}[-–—]\d+\w{2}[- –—]level \(.*\): '))
                            slots = $Matches.slots
                            lower = $Matches.lower
                        }
                        continue
                    }
                    '^constant' {
                        $spellcastingBuilder | Add-Member -MemberType NoteProperty -Name constant -Value @(Process-SpellList ($_ -replace '^constant: '))
                        continue
                    }
                    '^(?<num>\d+) ?/ ?week( (?<e>e)ach)?' {
                        $spellcastingBuilder.week | Add-Member -MemberType NoteProperty -Name ($Matches.num + $Matches.e) -Value @(Process-SpellList ($_ -replace '^\d+ ?/ ?day( each)?: '))
                        continue
                    }
                    '^(?<num>\d+) ?/ ?year( (?<e>e)ach)?' {
                        $spellcastingBuilder.year | Add-Member -MemberType NoteProperty -Name ($Matches.num + $Matches.e) -Value @(Process-SpellList ($_ -replace '^\d+ ?/ ?day( each)?: '))
                    }
                    '^\* ?\w+\b' { $monster.spellcasting | Add-Member -MemberType NoteProperty -Name footerEntries -Value @($_) }
                    default {
                        $spellcastingBuilder.hidden += "xxxERRORxxx : Uninterpretable spellcasting line = ``$_``"
                        $status += "e"
                    }
                }
                if (-not $spellcastingBuilder.spells.PSObject.Properties.Name) {
                    $spellcastingBuilder.PSObject.Properties.Remove('spells')
                }
                if (-not $spellcastingBuilder.rest.PSObject.Properties.Name) {
                    $spellcastingBuilder.PSObject.Properties.Remove('rest')
                }
                if (-not $spellcastingBuilder.day.PSObject.Properties.Name) {
                    $spellcastingBuilder.PSObject.Properties.Remove('day')
                }
                if (-not $spellcastingBuilder.week.PSObject.Properties.Name) {
                    $spellcastingBuilder.PSObject.Properties.Remove('week')
                }
                if (-not $spellcastingBuilder.year.PSObject.Properties.Name) {
                    $spellcastingBuilder.PSObject.Properties.Remove('year')
                }
                if (-not $spellcastingBuilder.hidden) {
                    $spellcastingBuilder.PSObject.Properties.Remove('hidden')
                }
            }
            $null = $monster.spellcasting.Add($spellcastingBuilder)
        }

        # CONDITIONS INFLICTED FROM SPELLS
        if ($monster.conditionInflictSpell) {
            $monster.conditionInflictSpell = @($monster.conditionInflictSpell | Sort-Object -Unique)
        } else {
            $monster.PSObject.Properties.Remove('conditionInflictSpell')
        }

        # SPELLCASTING TAGS
        switch -Regex ($monster.spellcasting.name) {
            "\binnate\b" { $null = $monster.spellcastingTags.Add("I") }
            "\bpsionics\b" { $null = $monster.spellcastingTags.Add("P") }
            "\bform\b" { $null = $monster.spellcastingTags.Add("F") }
            "\bshared\b" { $null = $monster.spellcastingTags.Add("S") }
        }
        switch -Regex ($monster.spellcasting.headerEntries) {
            "\bartificer spells\b" {
                $null = $monster.spellcastingTags.Add("CA")
                break
            }
            "\bbard spells\b" {
                $null = $monster.spellcastingTags.Add("CB")
                break
            }
            "\bcleric spells\b" {
                $null = $monster.spellcastingTags.Add("CC")
                break
            }
            "\bdruid spells\b" {
                $null = $monster.spellcastingTags.Add("CD")
                break
            }
            "\bpaladin spells\b" {
                $null = $monster.spellcastingTags.Add("CP")
                break
            }
            "\branger spells\b" {
                $null = $monster.spellcastingTags.Add("CR")
                break
            }
            "\bsorcerer spells\b" {
                $null = $monster.spellcastingTags.Add("CS")
                break
            }
            "\bwarlock spells\b" {
                $null = $monster.spellcastingTags.Add("CL")
                break
            }
            "\bwizard spells\b" { $null = $monster.spellcastingTags.Add("CW") }
        }
    }

    # LEGENDARY ACTIONS
    if ($_.legendaryactions) {
        if ($_.legendaryactions.FirstChild.desc.$t -match "(?<name1>.+) can take (?<num>\d+) legendary actions?, choosing from the options below. Only one legendary (action )?option can be used at a time and only at the end of another creature's turn. (?<name2>.+) regains spent legendary actions at the start of its turn.") {
            if ($Matches.name1 -ceq "The " + $monster.name -and $Matches.name1 -ceq $Matches.name2) {
                $monster | Add-Member -MemberType NoteProperty -Name shortName -Value $true
            } elseif ($Matches.name1 -eq "The " + $monster.name -and $Matches.name1 -eq $Matches.name2) {
                # line deliberately left blank
            } elseif ($Matches.name1 -eq ($monster.name -replace '(?<=^\S+) .*$') -and $Matches.name1 -eq $Matches.name2) {
                $monster | Add-Member -MemberType NoteProperty -Name isNamedCreature -Value $true
            } elseif ($Matches.name1 -eq $Matches.name2) {
                $monster | Add-Member -MemberType NoteProperty -Name shortName -Value ($Matches.name1 -replace '^the ')
            } else {
                $monster | Add-Member -MemberType NoteProperty -Name legendaryHeader -Value @(Format-Entries @($_.legendaryactions.FirstChild.desc))
            }
            if ($Matches.num -ne 3) {
                $monster| Add-Member -MemberType NoteProperty -Name legendaryActions -Value ([int]$Matches.num)
            }
        } else {
            $monster | Add-Member -MemberType NoteProperty -Name legendaryHeader -Value @(Format-Entries @($_.legendaryactions.FirstChild.desc))
            if ($monster.legendaryHeader -match '\b(?<num>d+) legendary actions?\b') {
                $monster | Add-Member -MemberType NoteProperty -Name legendaryActions -Value ([int]$Matches.num)
            }
        }
        $monster | Add-Member -MemberType NoteProperty -Name legendary -Value ([System.Collections.ArrayList]::new())
        $_.legendaryactions.ChildNodes | Select-Object -Skip 1 | ForEach-Object {
            $null = $monster.legendary.Add([PSCustomObject]@{
                name = $_.name.$t
                entries = @(Format-Entries @($_.desc))
            })
            $null = $damageTags.AddRange(@(Enumerate-DamageTypes $_.desc.$t))
            $null = $conditionInflict.AddRange(@(Enumerate-Conditions $_.desc.$t))
        }

        # Mythic actions would go here but I don't know how FG formats them ¯\_(ツ)_/¯
    }

    # LAIR ACTIONS
    if ($_.lairactions -or $_.text.InnerText -cmatch 'Regional Effects') {
        $legendaryGroup = [PSCustomObject]@{
            source = $source
            name = $monster.name
            lairActions = @( # Assumes standard formatting
                $_.lairactions.'id-00001'.desc.$t,
                [PSCustomObject]@{
                    type = "list"
                    items = @(Tag-Entries @(($_.lairactions.ChildNodes.desc.$t | Select-Object -Skip 1) -replace '^• ?'))
                }
            )
        }

        # CONDITIONS INFLICTED BY LAIR ACTIONS/REGIONAL EFFECTS
        $monster | Add-Member -MemberType NoteProperty -Name conditionInflictLegendary -Value ([System.Collections.ArrayList]::new())
        if ($legendaryGroup.lairActions) {
            $null = $damageTags.AddRange(@(Enumerate-DamageTypes $legendaryGroup.lairActions[1].items))
            $null = $monster.conditionInflictLegendary.AddRange(@(Enumerate-Conditions $legendaryGroup.lairActions[1].items))
        } else {
            $legendaryGroup.PSObject.Properties.Remove('lairActions')
        }

        # REGIONAL EFFECTS
        if ($_.text.InnerText -cmatch 'Regional Effects') { # Also assumes standard formatting
            $legendaryGroup | Add-Member -MemberType NoteProperty -Name regionalEffects -Value (
                [System.Collections.ArrayList]@(
                    (Tag-Entries $_.text.ChildNodes.InnerText.Where({$_ -eq 'Regional Effects'},'SkipUntil')[1]),
                    [PSCustomObject]@{
                        type = "list"
                        items = Tag-Entries ([System.Collections.ArrayList]@($_.text.ChildNodes.InnerText.Where({$_ -eq 'Regional Effects'},'SkipUntil') | Select-Object -Skip 2 | Select-Object -SkipLast 1) -replace '^\s*•\s*')
                    },
                    (Tag-Entries $_.text.ChildNodes.InnerText.Where({$_ -eq 'Regional Effects'},'SkipUntil')[-1])
                )
            )
            $null = $monster.conditionInflictLegendary.AddRange(@(Enumerate-Conditions $legendaryGroup.regionalEffects[1].items))
        }

        if ($monster.conditionInflictLegendary) {
            $monster.conditionInflictLegendary = @($monster.conditionInflictLegendary | Sort-Object -Unique)
        } else {
            $monster.PSObject.Properties.Remove('conditionInflictLegendary')
        }

        $null = $5et.legendaryGroup.Add($legendaryGroup)
    }
    
    # DAMAGE TAGS
    if ($damageTags) {
        $monster | Add-Member -MemberType NoteProperty -Name damageTags -Value @($damageTags | Sort-Object -Unique)
    }

    # CONDITION INFLICT TAGS
    if ($conditionInflict) {
        $monster | Add-Member -MemberType NoteProperty -Name conditionInflict -Value @($conditionInflict | Sort-Object -Unique)
    }
   
    # MISC TAGS
    if ($monster.action.name -match '\b(s(hortbow|ling|hotgun)|(cross|long)bow|blowgun|dart|net|musket|pistol|r(evolver|ifle))\b') {
        $null = $miscTags.Add("RNG")
    }
    if ($miscTags) {
        $monster | Add-Member -MemberType NoteProperty -Name miscTags -Value @($miscTags | Sort-Object -Unique)
    }

    # TOKEN
    if ($addTokens -and $_.token.$t -match '\.\w+(?!@DD5E SRD Bestiary)$') {
        try {
            Copy-Item ($path + "\" + ($_.token.$t -replace '@.*$')) ($source + "\creature\" + $monster.name + " (Token)" + ($_.token.$t -replace '^.*(?=\.\w{2,6}$)')) -ErrorAction Stop
            $monster | Add-Member -MemberType NoteProperty -Name tokenUrl -Value ("$repo/$source/creature/" + $monster.name + " (Token)" + ($_.token.$t -replace '^.*(?=\.\w{2,6}$)'))
        } catch {
            $monster | Add-Member -MemberType NoteProperty -Name tokenUrl -Value "xxxERRORxxx : Could not find image"
            $status += "e"
        }
    }

    # FLUFF
    if ($_.text.InnerText) {
        $monster | Add-Member -MemberType NoteProperty -Name fluff -Value (
            [PSCustomObject]@{
                images = [System.Collections.ArrayList]::new()
                entries = [System.Collections.ArrayList]::new()
            }
        )

        # IMAGES
        if ($addImages -and $_.text.linklist) {
            foreach ($imageId in $_.text.linklist.link.recordname) {
                try {
                    Copy-Item ($path + "\" + $db.root.image.$c.$($imageId -replace '^image\.').image.layers.layer.bitmap) ($source + "\creature\" + $monster.name + ($db.root.image.$c.$($imageId -replace '^image\.').image.layers.layer.bitmap -replace '^.*(?=\.\w{2,6}$)')) -ErrorAction Stop
                    $null = $monster.fluff.images.Add([PSCustomObject]@{
                        type = "image"
                        href = [PSCustomObject]@{
                            type = "external"
                            url = "$repo/$source/creature/" + $monster.name + ($db.root.image.$c.$($imageId -replace '^image\.').image.layers.layer.bitmap -replace '^.*(?=\.\w{2,6}$)')
                        }
                    })
                } catch {
                    $null = $monster.fluff.images.Add([PSCustomObject]@{
                        type = "image"
                        href = [PSCustomObject]@{
                            type = "external"
                            url = "xxxERRORxxx : Could not find image"
                        }
                    })
                    $status += "e"
                }
            }
            if (-not $monster.fluff.images) {
                $monster.fluff.PSObject.Properties.Remove('images')
            }
        } else {
            $monster.fluff.PSObject.Properties.Remove('images')
        }

        # INFO TEXT
        if ($_.text.p) {
            $null = $monster.fluff.entries.AddRange(@(
                Format-Entries @(
                    $_.text.ChildNodes.Where({$_.b -in 'Lair Actions', 'Regional Effects' -or $_.h -in 'Lair Actions', 'Regional Effects'},'Until') | Where-Object {
                        $_.LocalName -ne "linklist" -and $_.InnerText -ne $monster.name -and $_.OuterXml -notmatch '/>$'
                    }
                )
            ))
        } else {
            $monster.fluff.PSObject.Properties.Remove('entries')
        }
    }
    
    ###
   
    $null = $5et.monster.Add($monster)
   
    if ($status -match 'e') {
        [Console]::ForegroundColor = 'red'
        [Console]::BackgroundColor = 'black'
        Write-Host ("`nERROR: Converted ``" + $monster.name + "`` with errors.") -NoNewline
        $errors++
        [Console]::ResetColor()
    } elseif ($status -match 'w') {
        [Console]::ForegroundColor = 'yellow'
        [Console]::BackgroundColor = 'black'
        Write-Host ("`nWARNING: Converted ``" + $monster.name + "`` with potential mistakes.") -NoNewline
        $warnings++
        [Console]::ResetColor()
    } else {
        Write-Host ("`nSuccessfully converted ``" + $monster.name + "``.") -NoNewline
    }

    $progress++
}

Write-Output ("`n`n`nCompleted conversion of " + $progmax + " monsters with " + $errors + " errors (" + [math]::Round($errors/$progmax*100) + "%) and " + $warnings + " warnings (" + [math]::Round($warnings/$progmax*100) + "%).`n")

Write-Host "`nExporting file..." -NoNewLine
([Regex]::Replace(
    (ConvertTo-Json $5et -Depth 99 -Compress),
    "\\u(?<Value>\w{4})",
    {
        PARAM($matches)
        ([char]([int]::Parse($matches.Groups['Value'].Value, [System.Globalization.NumberStyles]::HexNumber))).ToString()
    }
) -replace '—', '\u2014' -replace '–', '\u2013' -replace '−', '\u2212') | Out-File -FilePath ($definition.root.author + "; " + $definition.root.name + ".json") -Encoding UTF8
Write-Host " Done.`n`n"

if ((Read-Host "Save log to file? (Y/N)")[0] -eq "Y") {
	Start-Transcript -Path ("log-" + ($path -replace '^temp-') + ".txt")
}

Remove-Item $path -Recurse