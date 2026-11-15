# Windows version of link-skills.sh.
# Makes the skills in this folder available to every new Claude Code / T3 Code session.
#   - Each top-level folder with a SKILL.md is junctioned into ~/.claude/skills and ~/.codex/skills.
#   - The pstack submodule is installed as a Claude Code plugin from its local marketplace.
# Run again after adding a skill or pulling the submodule. Safe to re-run.
#   powershell -ExecutionPolicy Bypass -File .\link-skills.ps1

$ErrorActionPreference = 'Stop'
$Src = $PSScriptRoot
$Targets = @("$HOME\.claude\skills", "$HOME\.codex\skills")

foreach ($target in $Targets) {
    New-Item -ItemType Directory -Force $target | Out-Null

    # Remove stale links that point into this folder but no longer resolve
    Get-ChildItem $target -Force | Where-Object { $_.LinkType } | ForEach-Object {
        $dest = @($_.Target)[0]
        if ($dest -and $dest.StartsWith($Src, 'OrdinalIgnoreCase') -and -not (Test-Path $dest)) {
            [System.IO.Directory]::Delete($_.FullName)   # removes the link only, not the target
            Write-Host "removed stale: $($_.FullName)"
        }
    }

    # Link each skill (junctions need no admin rights or Developer Mode)
    Get-ChildItem $Src -Directory | Where-Object { Test-Path (Join-Path $_.FullName 'SKILL.md') } | ForEach-Object {
        $link = Join-Path $target $_.Name
        $existing = Get-Item $link -Force -ErrorAction SilentlyContinue
        if ($existing -and $existing.LinkType) { return }
        if ($existing) { Write-Host "skipped $($_.Name): $link already exists and is not a link"; return }
        New-Item -ItemType Junction -Path $link -Target $_.FullName | Out-Null
        Write-Host "linked $($_.Name) -> $target"
    }
}

# pstack: install the submodule's Claude Code plugin
$pstack = Join-Path $Src 'pstack'
if (-not (Test-Path (Join-Path $pstack '.claude-plugin\marketplace.json'))) {
    Write-Host 'initializing pstack submodule...'
    git -C $Src submodule update --init pstack
}
if (Get-Command claude -ErrorAction SilentlyContinue) {
    $markets = claude plugin marketplace list 2>$null | Out-String
    if ($markets -notmatch 'cursor-plugins') { claude plugin marketplace add $pstack }
    else { claude plugin marketplace update cursor-plugins }
    $plugins = claude plugin list 2>$null | Out-String
    if ($plugins -notmatch 'pstack@cursor-plugins') { claude plugin install pstack@cursor-plugins --scope user }
    else { Write-Host 'pstack plugin already installed' }
} else {
    Write-Host 'claude CLI not found; skipped pstack plugin install'
}
