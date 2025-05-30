# CONFIG - change these if needed
$source = "$env:USERPROFILE\.leetcode"
$repoRoot = "$env:USERPROFILE\OneDrive\Documents\react prac\samslays-dsa-lc"
$githubBaseUrl = "https://github.com/Samik123Mit/SAMSLAYS-DSA-LC/blob/main"

# Helper: Map difficulty keywords to folder names
function Get-DifficultyFolder($diff) {
    switch ($diff) {
        "easy" { return "easy" }
        "medium" { return "medium" }
        "hard" { return "hard" }
        default { return "unsorted" }
    }
}

# Helper: Extract problem slug & number from filename, e.g. "11.container-with-most-water.cpp"
function Parse-Filename($filename) {
    if ($filename -match "^(\d+)\.(.+)\.cpp$") {
        return @{ Number = [int]$Matches[1]; Slug = $Matches[2] }
    }
    else {
        return @{ Number = $null; Slug = $filename }
    }
}

# Helper: Build LeetCode URL from slug
function Get-LeetCodeUrl($slug) {
    return "https://leetcode.com/problems/$slug"
}

# Ensure repo folders exist
@("easy","medium","hard","unsorted") | ForEach-Object {
    $folder = Join-Path $repoRoot $_
    if (!(Test-Path $folder)) { New-Item -Path $folder -ItemType Directory | Out-Null }
}

# Track if any file moved
$filesMoved = $false

# Collect problems info for README
$problems = @()

# Process each .cpp file in source folder
Get-ChildItem -Path $source -Filter *.cpp | ForEach-Object {
    $file = $_
    $content = Get-Content $file.FullName -TotalCount 10

    # Try extract difficulty from file content, example line: "Difficulty: Medium"
    $difficulty = "unsorted"
    foreach ($line in $content) {
        if ($line -match "(?i)difficulty\s*:\s*(easy|medium|hard)") {
            $difficulty = $Matches[1].ToLower()
            break
        }
    }

    # If difficulty not found in content, try infer from filename (optional)
    if ($difficulty -eq "unsorted") {
        # Here you can add mapping or API call if you want to upgrade later
    }

    # Parse problem number and slug
    $info = Parse-Filename $file.Name
    $slug = $info.Slug -replace "_", "-"  # just in case underscores
    $number = $info.Number

    # Clean filename to just slug.cpp (remove number prefix)
    $cleanName = "$slug.cpp"

    # Target folder
    $folderName = Get-DifficultyFolder $difficulty
    $destFolder = Join-Path $repoRoot $folderName
    $destPath = Join-Path $destFolder $cleanName

    # Copy file to repo folder (overwrite)
    Copy-Item -Path $file.FullName -Destination $destPath -Force
    Write-Output "Moved $file to $folderName/$cleanName"
    $filesMoved = $true

    # Store problem info for README
    $problems += [PSCustomObject]@{
        Difficulty = $folderName
        Number = $number
        Slug = $slug
        GithubPath = "$folderName/$cleanName"
        LeetCodeUrl = Get-LeetCodeUrl $slug
    }
}

if (-not $filesMoved) {
    Write-Output "No new files to move."
}

# Generate README.md in repo root

$readmePath = Join-Path $repoRoot "README.md"

$readmeContent = @"
# LeetCode Solutions Repository

This repository contains my LeetCode solutions organized by difficulty.

---

"@

# Group problems by difficulty, sort by number
$grouped = $problems | Group-Object Difficulty

foreach ($group in $grouped) {
    $diff = $group.Name
    $readmeContent += "## " + ($diff.Substring(0,1).ToUpper() + $diff.Substring(1)) + "`n`n"

    # Sort problems by Number or slug if number is null
    $sorted = $group.Group | Sort-Object @{Expression = {[int]($_.Number)};Descending=$false}
    foreach ($p in $sorted) {
        $title = ($p.Slug -replace "-"," ") -replace "\b\w", { $args[0].Value.ToUpper() }  # Capitalize words
        $readmeContent += "- [$title]($($p.LeetCodeUrl)) - [Solution]($githubBaseUrl/$($p.GithubPath))`n"
    }
    $readmeContent += "`n"
}

# Write README.md file
Set-Content -Path $readmePath -Value $readmeContent -Encoding UTF8

Write-Output "README.md updated."

# Auto git add, commit & push if files moved
if ($filesMoved) {
    Set-Location $repoRoot
    git add .
    $now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    git commit -m "Auto commit: Sync LeetCode solutions at $now"
    git push origin main
    Write-Output "Changes committed and pushed to GitHub."
} else {
    Write-Output "No changes to commit."
}
