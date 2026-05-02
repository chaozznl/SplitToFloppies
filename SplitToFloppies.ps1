# SplitToFloppies
# By E. Wenners
# chaozz.nl / github.com/chaozznl

param(
    [Parameter(Mandatory=$true)]
    [int]$DiskSize,        # Size of the floppy in KB (e.g., 720)

    [Parameter(Mandatory=$true)]
    [string]$SourceFolder,    # Folder to compress and split

    [Parameter(Mandatory=$true)]
    [string]$OutputFolder     # Output directory for chunks and IMG files
)

# -------------------------------
# Input validation
# -------------------------------

# Validate DiskSize is numeric
if (-not ($DiskSize -as [int])) {
    Write-Host "ERROR: DiskSize must be a numeric value in KB (e.g., 720)."
    exit 1
}

$DiskSize = [int]$DiskSize

# Validate DiskSize is a known floppy size
$ValidFloppySizes = @(160, 180, 320, 360, 720, 1200, 1440, 2880)

if ($DiskSize -notin $ValidFloppySizes) {
    Write-Host "ERROR: DiskSize must be one of the valid floppy sizes: $($ValidFloppySizes -join ', ')"
    exit 1
}

# Validate SourceFolder exists
if (-not (Test-Path $SourceFolder)) {
    Write-Host "ERROR: SourceFolder does not exist: $SourceFolder"
    exit 1
}

# Validate OutputFolder (create if missing)
if (-not (Test-Path $OutputFolder)) {
    try {
        New-Item -ItemType Directory -Path $OutputFolder | Out-Null
    }
    catch {
        Write-Host "ERROR: Could not create OutputFolder: $OutputFolder"
        exit 1
    }
}

# -------------------------------
# Derived values
# -------------------------------

$DiskBytes = $DiskSize * 1024

# Chunk size must be slightly smaller than the floppy size so it fits
$ChunkSize = $DiskSize - 60

$ChunkFolder = "chunks"
$ZIPname = "output.zip"

# Absolute paths for mtools executables
$MFormat = Join-Path $PSScriptRoot "mformat.exe"
$MCopy   = Join-Path $PSScriptRoot "mcopy.exe"

# Validate mtools presence
if (!(Test-Path $MFormat)) {
    Write-Host "ERROR: mformat.exe not found in script folder."
    exit 1
}
if (!(Test-Path $MCopy)) {
    Write-Host "ERROR: mcopy.exe not found in script folder."
    exit 1
}

# -------------------------------
# Step 1: Create ZIP
# -------------------------------

$zipPath = Join-Path $OutputFolder $ZIPname

Write-Host ">> Step 1: Creating ZIP from folder..."
if (Test-Path $zipPath) { Remove-Item $zipPath }
Compress-Archive -Path $SourceFolder -DestinationPath $zipPath

# -------------------------------
# Step 2: Split ZIP into chunks
# -------------------------------

Write-Host ">> Step 2: Splitting ZIP file into chunks..."
$ChunkFolder = Join-Path $OutputFolder $ChunkFolder
if (Test-Path $ChunkFolder) { Remove-Item $ChunkFolder -Recurse -Force }
New-Item -ItemType Directory -Path $ChunkFolder | Out-Null

$fs = [System.IO.File]::OpenRead($zipPath)
$bufferSize = $ChunkSize * 1024
$buffer = New-Object byte[] $bufferSize
$index = 1

while (($read = $fs.Read($buffer, 0, $bufferSize)) -gt 0) {
    $chunkName = "chunk{0:D3}.bin" -f $index
    $chunkPath = Join-Path $ChunkFolder $chunkName
    $out = [System.IO.File]::OpenWrite($chunkPath)
    $out.Write($buffer, 0, $read)
    $out.Close()
    $index++
}
$fs.Close()

# -------------------------------
# Step 3: Create IMG files
# -------------------------------

Write-Host ">> Step 3: Creating IMG files..."

$diskIndex = 1
foreach ($chunk in Get-ChildItem $ChunkFolder | Sort-Object Name) {

    $imgName = "DISK{0:D3}.img" -f $diskIndex
    $imgPath = Join-Path $OutputFolder $imgName

    Write-Host "   - Creating $imgName..."

    # 1. Create an empty floppy image
    [IO.File]::WriteAllBytes($imgPath, (New-Object byte[] $DiskBytes))

    # 2. Format the image as FAT12
    & $MFormat -f $DiskSize -i $imgPath ::

    # 3. Copy the chunk into the floppy image
    & $MCopy -i $imgPath $chunk.FullName ::

    $diskIndex++
}

Write-Host ""
Write-Host ">> Ready."
Write-Host ">> $($diskIndex-1) floppy images created in: $OutputFolder"