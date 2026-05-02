# SplitToFloppies
> by Elmar Wenners / chaozz.nl / github.com/chaozznl

A PowerShell tool that compresses a folder, splits it into floppy‑sized chunks, and generates FAT12 IMG files suitable for vintage PCs with Gotek floppy emulators.

![screenshot](https://chaozz.nl/wp-content/uploads/2026/05/SplitToFloppies-768x395.png)

---

## Features

- Creates a ZIP archive from any folder
- Splits the ZIP into floppy‑sized binary chunks
- Generates FAT12 floppy images for each chunk
- Automatically copies each chunk into its own IMG file
- Supports all standard PC floppy formats (160 KB to 2.88 MB)
- Compatible with Gotek, FlashFloppy

---

## Requirements

- Windows with PowerShell
- `mformat.exe` and `mcopy.exe` from mtools (included in this repository)
- A valid `mtools.conf` (included)
- `pkunzip` or other unzip tool on the target system

---

## Supported Floppy Sizes

| Size (KB) | Tracks | Heads | Sectors |
|-----------|--------|--------|---------|
| 160       | 40     | 1      | 8       |
| 180       | 40     | 1      | 9       |
| 320       | 40     | 2      | 8       |
| 360       | 40     | 2      | 9       |
| 720       | 80     | 2      | 9       |
| 1200      | 80     | 2      | 15      |
| 1440      | 80     | 2      | 18      |
| 2880      | 80     | 2      | 36      |

---

## Usage

### Syntax

`SplitToFloppies.ps1 <floppySizeKB> <sourceFolder> <outputFolder>`

### Example

`.\SplitToFloppies.ps1 720 g:\doom8088\cga g:\doom8088\cga_split`

### Example Output

Step 1: Creating ZIP from folder...
Step 2: Splitting ZIP file into chunks...
Step 3: Creating IMG files...

Creating DISK001.img...

Creating DISK002.img...

Ready.
2 floppy images created in: g:\doom8088\cga_split

## Output Structure

The output folder will contain:

- `chunk001.bin`, `chunk002.bin`, ...
- `DISK001.img`, `DISK002.img`, ...
- (Optional) `bigzip.zip` after merging on the target PC

## Installing on the Target PC

1. Mount the first IMG on the Gotek.
2. On the target PC, copy the contents into a working folder:

`copy a:\*.* .`

3. Mount the next IMG and repeat.
4. After all chunks are copied, merge them:

`copy /b chunk001.zip+chunk002.zip+chunk003.zip bigzip.zip`

5. Extract using PKUNZIP:

`pkunzip bigzip.zip`
