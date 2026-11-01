param(
    [string]$AssetRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
    [switch]$Force
)

Add-Type -AssemblyName System.Drawing

function Get-PlistValue {
    param(
        [System.Xml.XmlNode]$Dictionary,
        [string]$Name
    )

    for ($index = 0; $index -lt $Dictionary.ChildNodes.Count - 1; $index++) {
        $key = $Dictionary.ChildNodes[$index]
        if ($key.Name -eq 'key' -and $key.InnerText -eq $Name) {
            return $Dictionary.ChildNodes[$index + 1]
        }
    }

    return $null
}

function Add-LotusMark {
    param(
        [System.Drawing.Graphics]$Graphics,
        [float]$CenterX,
        [float]$CenterY,
        [float]$Scale,
        [System.Drawing.Color]$Color
    )

    $petalBrush = [System.Drawing.SolidBrush]::new($Color)
    $centerBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 255, 216, 112))
    try {
        $Graphics.FillEllipse($petalBrush, $CenterX - 0.12 * $Scale, $CenterY - 0.33 * $Scale, 0.24 * $Scale, 0.42 * $Scale)
        $Graphics.FillEllipse($petalBrush, $CenterX - 0.34 * $Scale, $CenterY - 0.20 * $Scale, 0.30 * $Scale, 0.35 * $Scale)
        $Graphics.FillEllipse($petalBrush, $CenterX + 0.04 * $Scale, $CenterY - 0.20 * $Scale, 0.30 * $Scale, 0.35 * $Scale)
        $Graphics.FillEllipse($centerBrush, $CenterX - 0.08 * $Scale, $CenterY - 0.04 * $Scale, 0.16 * $Scale, 0.16 * $Scale)
    }
    finally {
        $petalBrush.Dispose()
        $centerBrush.Dispose()
    }
}

function Draw-PlaceholderSprite {
    param(
        [System.Drawing.Graphics]$Graphics,
        [float]$X,
        [float]$Y,
        [float]$Width,
        [float]$Height,
        [string]$Kind,
        [System.Drawing.Color]$MainColor,
        [System.Drawing.Color]$AccentColor
    )

    $outline = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(255, 55, 75, 78), [Math]::Max(1, [Math]::Min($Width, $Height) * 0.035))
    $mainBrush = [System.Drawing.SolidBrush]::new($MainColor)
    $accentBrush = [System.Drawing.SolidBrush]::new($AccentColor)
    $skinBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 255, 218, 180))
    $darkBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 50, 67, 74))
    $scale = [Math]::Min($Width, $Height)

    try {
        if ($Kind -eq 'body') {
            $points = [System.Drawing.PointF[]]@(
                [System.Drawing.PointF]::new($X + 0.28 * $Width, $Y + 0.08 * $Height),
                [System.Drawing.PointF]::new($X + 0.72 * $Width, $Y + 0.08 * $Height),
                [System.Drawing.PointF]::new($X + 0.84 * $Width, $Y + 0.35 * $Height),
                [System.Drawing.PointF]::new($X + 0.94 * $Width, $Y + 0.94 * $Height),
                [System.Drawing.PointF]::new($X + 0.06 * $Width, $Y + 0.94 * $Height),
                [System.Drawing.PointF]::new($X + 0.16 * $Width, $Y + 0.35 * $Height)
            )
            $Graphics.FillPolygon($mainBrush, $points)
            $Graphics.DrawPolygon($outline, $points)
            $Graphics.DrawLine($outline, $X + 0.17 * $Width, $Y + 0.68 * $Height, $X + 0.83 * $Width, $Y + 0.68 * $Height)
            Add-LotusMark $Graphics ($X + 0.5 * $Width) ($Y + 0.45 * $Height) ($scale * 0.34) $AccentColor
        }
        elseif ($Kind -eq 'head') {
            $face = [System.Drawing.RectangleF]::new($X + 0.16 * $Width, $Y + 0.18 * $Height, 0.68 * $Width, 0.72 * $Height)
            $Graphics.FillEllipse($skinBrush, $face)
            $Graphics.DrawEllipse($outline, $face)
            $hair = [System.Drawing.PointF[]]@(
                [System.Drawing.PointF]::new($X + 0.14 * $Width, $Y + 0.47 * $Height),
                [System.Drawing.PointF]::new($X + 0.19 * $Width, $Y + 0.18 * $Height),
                [System.Drawing.PointF]::new($X + 0.49 * $Width, $Y + 0.07 * $Height),
                [System.Drawing.PointF]::new($X + 0.82 * $Width, $Y + 0.21 * $Height),
                [System.Drawing.PointF]::new($X + 0.87 * $Width, $Y + 0.48 * $Height),
                [System.Drawing.PointF]::new($X + 0.68 * $Width, $Y + 0.36 * $Height),
                [System.Drawing.PointF]::new($X + 0.36 * $Width, $Y + 0.39 * $Height)
            )
            $Graphics.FillPolygon($mainBrush, $hair)
            $Graphics.DrawPolygon($outline, $hair)
            $Graphics.FillEllipse($darkBrush, $X + 0.34 * $Width, $Y + 0.53 * $Height, 0.055 * $Width, 0.07 * $Height)
            $Graphics.FillEllipse($darkBrush, $X + 0.61 * $Width, $Y + 0.53 * $Height, 0.055 * $Width, 0.07 * $Height)
            Add-LotusMark $Graphics ($X + 0.5 * $Width) ($Y + 0.14 * $Height) ($scale * 0.26) $AccentColor
        }
        elseif ($Kind -eq 'weapon') {
            $Graphics.TranslateTransform($X + $Width / 2, $Y + $Height / 2)
            $Graphics.RotateTransform(-35)
            $staff = [System.Drawing.RectangleF]::new(-0.09 * $scale, -0.46 * $scale, 0.18 * $scale, 0.92 * $scale)
            $Graphics.FillRectangle($accentBrush, $staff)
            $Graphics.DrawRectangle($outline, $staff.X, $staff.Y, $staff.Width, $staff.Height)
            $Graphics.ResetTransform()
            Add-LotusMark $Graphics ($X + 0.67 * $Width) ($Y + 0.25 * $Height) ($scale * 0.48) $AccentColor
        }
        else {
            $Graphics.FillEllipse($mainBrush, $X + 0.04 * $Width, $Y + 0.17 * $Height, 0.55 * $Width, 0.66 * $Height)
            $Graphics.FillEllipse($mainBrush, $X + 0.40 * $Width, $Y + 0.17 * $Height, 0.55 * $Width, 0.66 * $Height)
            $Graphics.FillEllipse($accentBrush, $X + 0.18 * $Width, $Y + 0.08 * $Height, 0.64 * $Width, 0.82 * $Height)
            $Graphics.DrawEllipse($outline, $X + 0.18 * $Width, $Y + 0.08 * $Height, 0.64 * $Width, 0.82 * $Height)
            Add-LotusMark $Graphics ($X + 0.5 * $Width) ($Y + 0.5 * $Height) ($scale * 0.48) $MainColor
        }
    }
    finally {
        $outline.Dispose()
        $mainBrush.Dispose()
        $accentBrush.Dispose()
        $skinBrush.Dispose()
        $darkBrush.Dispose()
    }
}

$atlasRoot = Join-Path $AssetRoot 'character_atlas'
$missingList = Join-Path $AssetRoot 'docs\MISSING_character_png_sheets.txt'
$sheets = Get-Content -LiteralPath $missingList | Where-Object { $_.Trim() -ne '' }
$created = 0
$skipped = 0

foreach ($sheet in $sheets) {
    $relative = $sheet.Substring('character/'.Length).Replace('/', '\')
    $plistPath = Join-Path $atlasRoot ([System.IO.Path]::ChangeExtension($relative, '.plist'))
    if (-not (Test-Path -LiteralPath $plistPath)) {
        throw "No atlas plist for missing sheet $sheet"
    }

    $plist = Get-Item -LiteralPath $plistPath
    $outputPath = Join-Path $AssetRoot ($sheet.Replace('/', '\'))
    if ((Test-Path -LiteralPath $outputPath) -and -not $Force) {
        $skipped++
        continue
    }

    $settings = [System.Xml.XmlReaderSettings]::new()
    $settings.DtdProcessing = [System.Xml.DtdProcessing]::Ignore
    $settings.XmlResolver = $null
    $reader = [System.Xml.XmlReader]::Create($plist.FullName, $settings)
    $document = [System.Xml.XmlDocument]::new()
    try {
        $document.Load($reader)
    }
    finally {
        $reader.Dispose()
    }

    $rootDictionary = $document.SelectSingleNode('/plist/dict')
    $framesDictionary = Get-PlistValue $rootDictionary 'frames'
    if ($null -eq $framesDictionary) {
        throw "No frames dictionary in $($plist.FullName)"
    }

    $frames = @()
    $maxX = 0
    $maxY = 0
    for ($index = 0; $index -lt $framesDictionary.ChildNodes.Count - 1; $index++) {
        $nameNode = $framesDictionary.ChildNodes[$index]
        if ($nameNode.Name -ne 'key') {
            continue
        }

        $frameDictionary = $framesDictionary.ChildNodes[$index + 1]
        $frameNode = Get-PlistValue $frameDictionary 'frame'
        if ($null -eq $frameNode -or $frameNode.Name -ne 'string') {
            continue
        }

        $numbers = [regex]::Matches($frameNode.InnerText, '\d+') | ForEach-Object { [int]$_.Value }
        if ($numbers.Count -lt 4) {
            throw "Invalid frame rectangle in $($plist.FullName): $($frameNode.InnerText)"
        }

        $x, $y, $width, $height = $numbers[0..3]
        $frames += [PSCustomObject]@{ X = $x; Y = $y; Width = $width; Height = $height }
        $maxX = [Math]::Max($maxX, $x + $width)
        $maxY = [Math]::Max($maxY, $y + $height)
    }

    if ($frames.Count -eq 0) {
        throw "No valid frame rectangles in $($plist.FullName)"
    }

    $imageWidth = [int]([Math]::Ceiling(($maxX + 2) / 64) * 64)
    $imageHeight = [int]([Math]::Ceiling(($maxY + 2) / 64) * 64)
    $bitmap = [System.Drawing.Bitmap]::new($imageWidth, $imageHeight, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.Clear([System.Drawing.Color]::Transparent)

    $kind = [System.IO.Path]::GetFileNameWithoutExtension($plist.Name) -replace '^set\d+_', '' -replace '_shop$', ''
    $setNumber = [regex]::Match($plist.Name, 'set(\d+)').Groups[1].Value
    $variant = if ($setNumber) { [int]$setNumber % 3 } else { 0 }
    $mainColors = @(
        [System.Drawing.Color]::FromArgb(255, 39, 139, 128),
        [System.Drawing.Color]::FromArgb(255, 210, 105, 139),
        [System.Drawing.Color]::FromArgb(255, 100, 112, 174)
    )
    $accentColors = @(
        [System.Drawing.Color]::FromArgb(255, 255, 190, 104),
        [System.Drawing.Color]::FromArgb(255, 246, 165, 190),
        [System.Drawing.Color]::FromArgb(255, 183, 205, 132)
    )
    if ($plist.Directory.Name -eq 'boy') {
        $variant = ($variant + 1) % 3
    }
    $mainColor = $mainColors[$variant]
    $accentColor = $accentColors[$variant]

    try {
        foreach ($frame in $frames) {
            Draw-PlaceholderSprite $graphics $frame.X $frame.Y $frame.Width $frame.Height $kind $mainColor $accentColor
        }

        $outputDirectory = Split-Path -Parent $outputPath
        New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
        $bitmap.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally {
        $graphics.Dispose()
        $bitmap.Dispose()
    }

    $created++
}

Write-Output "Generated $created placeholder atlas sheets; skipped $skipped existing files."
