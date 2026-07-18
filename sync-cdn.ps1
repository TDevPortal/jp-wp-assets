# ---------------------------------------------------------------------------
# sync-cdn.ps1
#
# Copies the jobpage-lk theme's static assets (style.css + assets/) and the
# WordPress media library (wp-content/uploads/) from the live WP install into
# THIS repo, then commits & pushes so jsDelivr serves the latest files.
#
# Run this whenever you add/change images or edit style.css:
#     powershell -ExecutionPolicy Bypass -File .\sync-cdn.ps1
# ---------------------------------------------------------------------------

$ErrorActionPreference = 'Stop'

# Source WordPress install. Change this if your WP path is different.
$src = 'd:\xampp\htdocs\jobpage\wp-content'
$dst = Join-Path $PSScriptRoot 'wp-content'

$themeSrc = Join-Path $src 'themes\jobpage-lk'
$themeDst = Join-Path $dst 'themes\jobpage-lk'

New-Item -ItemType Directory -Force -Path $themeDst | Out-Null

# Theme: only style.css + the assets folder (no PHP source goes public).
Copy-Item (Join-Path $themeSrc 'style.css') (Join-Path $themeDst 'style.css') -Force
robocopy (Join-Path $themeSrc 'assets') (Join-Path $themeDst 'assets') /MIR /NFL /NDL /NJH /NJS /NP | Out-Null

# Media library. ADDITIVE only (/E, no /PURGE): copies new/changed files but
# never deletes from the CDN. This is deliberate — the local uploads folder may
# be cleared (files live on the CDN as the master copy), so a mirror would wipe
# the CDN. Orphaned images stay on the CDN; remove them by hand if ever needed.
robocopy (Join-Path $src 'uploads') (Join-Path $dst 'uploads') /E /NFL /NDL /NJH /NJS /NP | Out-Null

# robocopy returns 0-7 on success; normalise so the script doesn't abort.
if ($LASTEXITCODE -lt 8) { $LASTEXITCODE = 0 }

git -C $PSScriptRoot add -A
if (git -C $PSScriptRoot status --porcelain) {
    git -C $PSScriptRoot commit -m ("Sync assets " + (Get-Date -Format 'yyyy-MM-dd HH:mm'))
    git -C $PSScriptRoot push
    Write-Host "CDN assets synced & pushed. Give jsDelivr a moment (branch cache ~12h; purge if needed)."
} else {
    Write-Host "No changes to sync."
}
