# Script PowerShell d'upload des modeles 3D .glb compresses vers Cloudflare R2
# Les modeles sont ensuite servis en streaming + cache local via :
# https://otaku-verse-quiz-api.otakuverse-221.workers.dev/models/<skin_key>.glb

$ErrorActionPreference = "Stop"
$Bucket = "otaku-verse-quiz"
$ModelsDir = "C:\All-projects\2026\Otaku_verse\r2_build\models\skins"

if (-not (Test-Path $ModelsDir)) {
    throw "Dossier introuvable : $ModelsDir. Lance d'abord scripts/compress_skins_glb.mjs"
}

Set-Location "C:\All-projects\2026\Otaku_verse\cloudflare_worker"

$Files = Get-ChildItem -Path "$ModelsDir\*.glb"
$Total = $Files.Count
$Index = 0

Write-Host "=== Upload de $Total modeles 3D .glb vers Cloudflare R2 ($Bucket) ==="
foreach ($File in $Files) {
    $Index++
    $Key = "models/skins/$($File.Name)"
    $SizeMB = [math]::Round($File.Length / 1MB, 2)
    Write-Host "[$Index/$Total] Upload $Key ($SizeMB Mo)..."
    npx wrangler r2 object put "$Bucket/$Key" --file="$($File.FullName)" --content-type="model/gltf-binary"
    if ($LASTEXITCODE -ne 0) { throw "Echec upload $Key" }
}

Write-Host "=== Upload des $Total modeles 3D termine ! Pense a deployer le Worker si pas encore fait : npx wrangler deploy ==="
