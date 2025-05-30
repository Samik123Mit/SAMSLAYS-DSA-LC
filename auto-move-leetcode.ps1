# Paths
$source = "$env:USERPROFILE\.leetcode"
$destinationRoot = "$env:USERPROFILE\OneDrive\Documents\react prac\samslays-dsa-lc"

# Navigate to repo folder
Set-Location $destinationRoot

# Create destination root if it doesn't exist
if (!(Test-Path $destinationRoot)) {
    New-Item -Path $destinationRoot -ItemType Directory
}

$filesMoved = $false

# Move and sort files by difficulty
Get-ChildItem -Path $source -Filter *.cpp | ForEach-Object {
    $originalPath = $_.FullName
    $lines = Get-Content $originalPath -TotalCount 5
    $difficulty = "unsorted"

    foreach ($line in $lines) {
        if ($line -match "(?i)difficulty\s*:\s*(easy|medium|hard)") {
            $difficulty = $Matches[1].ToLower()
            break
        }
    }

    $cleanName = $_.BaseName -replace "^\d+\.", ""
    $destination = Join-Path $destinationRoot $difficulty

    if (!(Test-Path $destination)) {
        New-Item -Path $destination -ItemType Directory
    }

    $newFileName = "$cleanName.cpp"
    $finalPath = Join-Path $destination $newFileName

    Copy-Item -Path $originalPath -Destination $finalPath -Force
    Write-Output "Moved: $($_.Name) ➝ $difficulty\$newFileName"
    $filesMoved = $true
}

# Git auto commit & push only if files moved
if ($filesMoved) {
    git add .
    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    git commit -m "Auto commit: Synced LeetCode solutions [$time]"
    git push origin main
    Write-Output "✅ Code committed and pushed to GitHub!"
} else {
    Write-Output "ℹ️ No new files to move. Nothing to commit."
}
