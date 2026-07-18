# ---------------------------------------------------------------------------
# sync-cdn.ps1
#
# Copies the jobpage-lk theme's static assets (style.css + assets/) and the
# WordPress media library (wp-content/uploads/) into THIS repo and pushes them so
# jsDelivr serves the latest files. After a CONFIRMED push it then DELETES the
# local wp-content/uploads/ files — their master copy now lives on the CDN, so the
# WordPress uploads folder is kept empty. Theme files are never deleted.
#
# Run this after adding/changing images or editing style.css:
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
    git -C $PSScriptRoot commit -m ("Sync " + (Get-Date -Format 'yyyy-MM-dd HH:mm')) | Out-Null
    git -C $PSScriptRoot push
} else {
    Write-Host "No new files to sync."
}

# Clean local uploads ONLY when the CDN repo is fully on GitHub. The uploads were
# copied above BEFORE this point, so a clean tree with nothing un-pushed proves
# every local image is now safely on jsDelivr. If the push failed, we keep the
# local files so nothing is lost.
git -C $PSScriptRoot fetch origin main --quiet 2>$null
$unpushed = (git -C $PSScriptRoot rev-list "origin/main..HEAD" --count 2>$null)
$dirty    = (git -C $PSScriptRoot status --porcelain)

if ((-not $dirty) -and ('0' -eq $unpushed)) {
    $srcUploads = Join-Path $src 'uploads'   # d:\xampp\htdocs\jobpage\wp-content\uploads
    if (Test-Path $srcUploads) {
        Get-ChildItem -Force $srcUploads -ErrorAction SilentlyContinue |
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }
    Write-Host "Synced & pushed. Local uploads cleaned — images now served from the CDN (jsDelivr)."
    Write-Host "If a just-pushed image still 404s, purge: https://purge.jsdelivr.net/gh/TDevPortal/jp-wp-assets@main/wp-content/uploads/<path>"
} else {
    Write-Host "PUSH NOT CONFIRMED (unpushed=$unpushed). Local uploads KEPT — fix auth/network and re-run."
}
