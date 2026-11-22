# Script PowerShell d'upload des 105 shards JSON.gz + catalog.json vers Cloudflare R2
# Compatible Wrangler v3 (upload distant par defaut sans flag --remote)

$ErrorActionPreference = "Stop"
$Bucket = "otaku-verse-quiz"
$BuildDir = "C:\All-projects\2026\Otaku_verse\r2_build"

Set-Location "C:\All-projects\2026\Otaku_verse\cloudflare_worker"

Write-Host "=== Upload de catalog.json vers R2 ($Bucket) ==="
npx wrangler r2 object put "$Bucket/catalog.json" --file="$BuildDir\catalog.json" --content-type="application/json"
if ($LASTEXITCODE -ne 0) { throw "Echec upload catalog.json" }

$Shards = Get-ChildItem -Path "$BuildDir\shards\*.json.gz"
$Total = $Shards.Count
$Index = 0

foreach ($File in $Shards) {
    $Index++
    $Key = "shards/$($File.Name)"
    Write-Host "[$Index/$Total] Upload $Key..."
    npx wrangler r2 object put "$Bucket/$Key" --file="$($File.FullName)" --content-type="application/gzip"
    if ($LASTEXITCODE -ne 0) { throw "Echec upload $Key" }
}

Write-Host "=== Upload R2 termine ($Total shards + catalog.json) ! ==="
