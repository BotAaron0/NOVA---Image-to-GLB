param(
    [Parameter(Mandatory)][string]$Photos,
    [string]$Output,
    [ValidateSet(2, 4, 8)][int]$DepthDownscale = 4,
    [ValidateSet(2048, 4096, 8192)][int]$TextureSize = 4096
)

$ErrorActionPreference = 'Stop'
if (!$Output) { $Output = Join-Path $PSScriptRoot 'generated/scan' }
$photoFolder = Get-Item -LiteralPath $Photos
if (!$photoFolder.PSIsContainer) { throw 'Provide a folder of photos.' }
$images = @(Get-ChildItem -LiteralPath $photoFolder.FullName -File |
    Where-Object { $_.Extension -in '.jpg', '.jpeg', '.png' })
if ($images.Count -lt 3) { throw 'Add at least three overlapping JPEG or PNG photos.' }

$runtime = Join-Path $PSScriptRoot '.runtime'
$meshroom = Get-ChildItem -LiteralPath (Join-Path $runtime 'meshroom') -Recurse -Filter meshroom_batch.exe -File -ErrorAction SilentlyContinue |
    Select-Object -First 1
if (!$meshroom) { throw 'Run setup-multiview.ps1 first.' }

$destination = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Output)
if (Test-Path -LiteralPath (Join-Path $destination 'texturedMesh.obj')) {
    throw 'This output folder already contains a textured model. Choose a new output folder.'
}
$cache = Join-Path $runtime 'meshroom-cache'
$temp = Join-Path $runtime 'temp'
New-Item -ItemType Directory -Force -Path $destination, $cache, $temp | Out-Null
$previousTemp = $env:TEMP
$previousTmp = $env:TMP
try {
    $env:TEMP = $temp
    $env:TMP = $temp
    & $meshroom.FullName --input $photoFolder.FullName --output $destination --cache $cache --paramOverrides `
        "DepthMap:downscale=$DepthDownscale" `
        "Texturing:textureSide=$TextureSize" `
        "Texturing:downscale=1" `
        "Texturing:colorMapping.colorMappingFileType=png"
    if ($LASTEXITCODE) { throw "Meshroom failed with exit code $LASTEXITCODE. See its log above." }
} finally {
    $env:TEMP = $previousTemp
    $env:TMP = $previousTmp
}

$obj = Join-Path $destination 'texturedMesh.obj'
if (!(Test-Path -LiteralPath $obj)) {
    throw 'Meshroom did not publish a textured OBJ. Check the log for camera alignment, depth, or texturing errors.'
}
Write-Host "Saved $obj"
