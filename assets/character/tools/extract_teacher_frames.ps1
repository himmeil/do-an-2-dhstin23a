$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$assetRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$plistPath = Join-Path $assetRoot 'npc\npc_1.plist'
$sheetPath = Join-Path $assetRoot 'npc\npc_1.png'
$assetsRoot = Split-Path $assetRoot -Parent
$outputRoot = Join-Path $assetsRoot 'mini_game\characters\teacher'

function Get-PlistValue([System.Xml.XmlNode]$Dictionary, [string]$Name) {
    for ($index = 0; $index -lt $Dictionary.ChildNodes.Count - 1; $index++) {
        if (
            $Dictionary.ChildNodes[$index].Name -eq 'key' -and
            $Dictionary.ChildNodes[$index].InnerText -eq $Name
        ) {
            return $Dictionary.ChildNodes[$index + 1]
        }
    }

    return $null
}

$settings = [System.Xml.XmlReaderSettings]::new()
$settings.DtdProcessing = [System.Xml.DtdProcessing]::Ignore
$settings.XmlResolver = $null
$reader = [System.Xml.XmlReader]::Create($plistPath, $settings)
$document = [System.Xml.XmlDocument]::new()
try {
    $document.Load($reader)
}
finally {
    $reader.Dispose()
}

$rootDictionary = $document.SelectSingleNode('/plist/dict')
$framesDictionary = Get-PlistValue $rootDictionary 'frames'
$source = [System.Drawing.Bitmap]::new($sheetPath)
$created = 0
New-Item -ItemType Directory -Path $outputRoot -Force | Out-Null

try {
    for ($index = 0; $index -lt $framesDictionary.ChildNodes.Count - 1; $index++) {
        $nameNode = $framesDictionary.ChildNodes[$index]
        if (
            $nameNode.Name -ne 'key' -or
            $nameNode.InnerText -notmatch '^npc_1/0_1_2_\d+\.png$'
        ) {
            continue
        }

        $frameDictionary = $framesDictionary.ChildNodes[$index + 1]
        $frameNode = Get-PlistValue $frameDictionary 'frame'
        $rotatedNode = Get-PlistValue $frameDictionary 'rotated'
        $numbers = [regex]::Matches($frameNode.InnerText, '\d+') |
            ForEach-Object { [int]$_.Value }
        if ($numbers.Count -lt 4) {
            throw "Invalid frame rectangle for $($nameNode.InnerText)"
        }

        $x, $y, $width, $height = $numbers[0..3]
        $isRotated = $rotatedNode.Name -eq 'true'
        $cropWidth = if ($isRotated) { $height } else { $width }
        $cropHeight = if ($isRotated) { $width } else { $height }
        $frame = $source.Clone(
            [System.Drawing.Rectangle]::new($x, $y, $cropWidth, $cropHeight),
            [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
        )
        try {
            if ($isRotated) {
                $frame.RotateFlip([System.Drawing.RotateFlipType]::Rotate270FlipNone)
            }

            $frame.Save(
                (Join-Path $outputRoot ('frame_{0:D2}.png' -f $created)),
                [System.Drawing.Imaging.ImageFormat]::Png
            )
        }
        finally {
            $frame.Dispose()
        }

        $created++
    }
}
finally {
    $source.Dispose()
}

if ($created -ne 2) {
    throw "Expected two teacher idle frames, extracted $created."
}

Write-Output "Extracted $created teacher idle animation frames from npc_1.plist."
