$ErrorActionPreference = 'Stop'
$runtime = Join-Path $PSScriptRoot '.runtime'
$meshroom = Join-Path $runtime 'meshroom'
New-Item -ItemType Directory -Force -Path $meshroom | Out-Null
if (!(Get-ChildItem -LiteralPath $meshroom -Recurse -Filter meshroom_batch.exe -File | Select-Object -First 1)) {
    $archive = Join-Path $runtime 'meshroom.zip'
    $url = 'https://github.com/alicevision/Meshroom/releases/download/v2023.3.0/Meshroom-2023.3.0-win64.zip'
    & curl.exe --fail --location --retry 2 --output $archive $url
    if ($LASTEXITCODE) { throw 'Could not download Meshroom.' }
    & tar.exe -xf $archive -C $meshroom
    if ($LASTEXITCODE) { throw 'Could not extract Meshroom.' }
    Remove-Item -LiteralPath $archive
}
Write-Host 'Meshroom is ready. See the multi-photo instructions in README.md.'
