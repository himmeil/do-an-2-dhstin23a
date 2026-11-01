$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$assetRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$assetsRoot = Split-Path $assetRoot -Parent
$outputRoot = Join-Path $assetsRoot 'mini_game\characters\lotus'
$frameCount = 6

function New-Brush([System.Drawing.Color]$Color) {
    return [System.Drawing.SolidBrush]::new($Color)
}

function Draw-LotusFlower(
    [System.Drawing.Graphics]$Graphics,
    [float]$CenterX,
    [float]$CenterY,
    [float]$Scale
) {
    $petal = New-Brush ([System.Drawing.Color]::FromArgb(255, 242, 113, 157))
    $lightPetal = New-Brush ([System.Drawing.Color]::FromArgb(255, 255, 179, 205))
    $gold = New-Brush ([System.Drawing.Color]::FromArgb(255, 255, 208, 105))
    try {
        $Graphics.FillEllipse($lightPetal, $CenterX - 0.12 * $Scale, $CenterY - 0.44 * $Scale, 0.24 * $Scale, 0.47 * $Scale)
        $Graphics.FillEllipse($petal, $CenterX - 0.38 * $Scale, $CenterY - 0.27 * $Scale, 0.38 * $Scale, 0.38 * $Scale)
        $Graphics.FillEllipse($petal, $CenterX, $CenterY - 0.27 * $Scale, 0.38 * $Scale, 0.38 * $Scale)
        $Graphics.FillEllipse($gold, $CenterX - 0.09 * $Scale, $CenterY - 0.12 * $Scale, 0.18 * $Scale, 0.18 * $Scale)
    }
    finally {
        $petal.Dispose()
        $lightPetal.Dispose()
        $gold.Dispose()
    }
}

function Draw-LotusCharacter(
    [System.Drawing.Graphics]$Graphics,
    [int]$Frame,
    [string]$Outfit
) {
    $outline = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(255, 49, 77, 91), 3)
    $skin = New-Brush ([System.Drawing.Color]::FromArgb(255, 255, 218, 180))
    $dark = New-Brush ([System.Drawing.Color]::FromArgb(255, 48, 62, 76))
    $shoe = New-Brush ([System.Drawing.Color]::FromArgb(255, 100, 91, 133))
    $mint = New-Brush ([System.Drawing.Color]::FromArgb(255, 96, 178, 145))
    $gold = New-Brush ([System.Drawing.Color]::FromArgb(255, 255, 206, 112))
    $shirt = switch ($Outfit) {
        'school_uniform' { New-Brush ([System.Drawing.Color]::FromArgb(255, 250, 250, 242)); break }
        'plaid_shirt' { New-Brush ([System.Drawing.Color]::FromArgb(255, 255, 196, 132)); break }
        'adventure_jacket' { New-Brush ([System.Drawing.Color]::FromArgb(255, 72, 157, 199)); break }
        default { New-Brush ([System.Drawing.Color]::FromArgb(255, 255, 183, 203)) }
    }
    $trim = if ($Outfit -eq 'school_uniform') {
        New-Brush ([System.Drawing.Color]::FromArgb(255, 82, 130, 174))
    }
    else {
        New-Brush ([System.Drawing.Color]::FromArgb(255, 255, 231, 173))
    }

    $bounce = @(-1, -3, -2, 0, -2, -3)[$Frame]
    $swing = @(-3, -1, 2, 3, 1, -2)[$Frame]
    $Graphics.TranslateTransform(0, [float]$bounce)

    try {
        $Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $Graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

        $Graphics.FillEllipse($mint, 33, 217, 126, 15)
        $Graphics.FillEllipse($shoe, 61, 198, 29, 22)
        $Graphics.DrawEllipse($outline, 61, 198, 29, 22)
        $Graphics.FillEllipse($shoe, 103, 198, 29, 22)
        $Graphics.DrawEllipse($outline, 103, 198, 29, 22)
        $Graphics.DrawLine($outline, 75, 181, 75, 202)
        $Graphics.DrawLine($outline, 116, 181, 116, 202)

        $leftArm = [System.Drawing.RectangleF]::new(27, 128 + $swing, 40, 23)
        $rightArm = [System.Drawing.RectangleF]::new(125, 125 - $swing, 40, 23)
        $Graphics.FillEllipse($skin, $leftArm)
        $Graphics.DrawEllipse($outline, $leftArm)
        $Graphics.FillEllipse($skin, $rightArm)
        $Graphics.DrawEllipse($outline, $rightArm)

        $body = [System.Drawing.PointF[]]@(
            [System.Drawing.PointF]::new(59, 115),
            [System.Drawing.PointF]::new(130, 115),
            [System.Drawing.PointF]::new(150, 178),
            [System.Drawing.PointF]::new(39, 178)
        )
        $Graphics.FillPolygon($shirt, $body)
        $Graphics.DrawPolygon($outline, $body)

        if ($Outfit -eq 'plaid_shirt') {
            $gridPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(110, 179, 100, 72), 2)
            try {
                foreach ($x in @(62, 79, 96, 113, 130)) {
                    $Graphics.DrawLine($gridPen, $x, 121, $x, 175)
                }
                foreach ($y in @(132, 148, 164)) {
                    $Graphics.DrawLine($gridPen, 49, $y, 141, $y)
                }
            }
            finally {
                $gridPen.Dispose()
            }
        }
        elseif ($Outfit -eq 'adventure_jacket') {
            $Graphics.DrawLine($outline, 95, 119, 95, 175)
            $Graphics.FillEllipse($gold, 103, 130, 6, 6)
            $Graphics.FillEllipse($gold, 103, 147, 6, 6)
        }
        else {
            $collar = [System.Drawing.PointF[]]@(
                [System.Drawing.PointF]::new(75, 116),
                [System.Drawing.PointF]::new(95, 137),
                [System.Drawing.PointF]::new(115, 116),
                [System.Drawing.PointF]::new(106, 157),
                [System.Drawing.PointF]::new(95, 164),
                [System.Drawing.PointF]::new(84, 157)
            )
            $Graphics.FillPolygon($trim, $collar)
            $Graphics.DrawPolygon($outline, $collar)
        }
        $Graphics.FillEllipse($trim, 91, 139, 9, 9)

        $Graphics.FillEllipse($skin, 48, 41, 98, 91)
        $Graphics.DrawEllipse($outline, 48, 41, 98, 91)

        $hair = [System.Drawing.PointF[]]@(
            [System.Drawing.PointF]::new(48, 82),
            [System.Drawing.PointF]::new(44, 66),
            [System.Drawing.PointF]::new(53, 46),
            [System.Drawing.PointF]::new(67, 39),
            [System.Drawing.PointF]::new(78, 42),
            [System.Drawing.PointF]::new(91, 35),
            [System.Drawing.PointF]::new(105, 41),
            [System.Drawing.PointF]::new(120, 38),
            [System.Drawing.PointF]::new(139, 54),
            [System.Drawing.PointF]::new(147, 79),
            [System.Drawing.PointF]::new(132, 72),
            [System.Drawing.PointF]::new(119, 78),
            [System.Drawing.PointF]::new(104, 71),
            [System.Drawing.PointF]::new(89, 78),
            [System.Drawing.PointF]::new(71, 72)
        )
        $hairBrush = New-Brush ([System.Drawing.Color]::FromArgb(255, 135, 85, 111))
        try {
            $Graphics.FillPolygon($hairBrush, $hair)
            $Graphics.DrawPolygon($outline, $hair)
        }
        finally {
            $hairBrush.Dispose()
        }

        foreach ($petal in @(
            @([float]67, [float]62),
            @([float]82, [float]70),
            @([float]103, [float]68),
            @([float]121, [float]61)
        )) {
            $petalColor = New-Brush ([System.Drawing.Color]::FromArgb(255, 191, 81, 132))
            try {
                $Graphics.FillEllipse($petalColor, $petal[0], $petal[1], 23, 42)
            }
            finally {
                $petalColor.Dispose()
            }
        }
        Draw-LotusFlower $Graphics 96 39 28

        $Graphics.FillEllipse($dark, 75, 91, 7, 11)
        $Graphics.FillEllipse($dark, 112, 91, 7, 11)
        $smilePen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(255, 166, 80, 87), 3)
        try {
            $Graphics.DrawArc($smilePen, 86, 95, 23, 16, 15, 150)
        }
        finally {
            $smilePen.Dispose()
        }

        $Graphics.ResetTransform()
    }
    finally {
        $outline.Dispose()
        $skin.Dispose()
        $dark.Dispose()
        $shoe.Dispose()
        $mint.Dispose()
        $gold.Dispose()
        $shirt.Dispose()
        $trim.Dispose()
    }
}

$outfits = @('lotus', 'school_uniform', 'plaid_shirt', 'adventure_jacket')
foreach ($outfit in $outfits) {
    $directory = Join-Path $outputRoot (Join-Path 'idle' $outfit)
    New-Item -ItemType Directory -Path $directory -Force | Out-Null
    for ($frame = 0; $frame -lt $frameCount; $frame++) {
        $bitmap = [System.Drawing.Bitmap]::new(192, 240, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        try {
            $graphics.Clear([System.Drawing.Color]::Transparent)
            Draw-LotusCharacter $graphics $frame $outfit
            $bitmap.Save(
                (Join-Path $directory ('frame_{0:D2}.png' -f $frame)),
                [System.Drawing.Imaging.ImageFormat]::Png
            )
        }
        finally {
            $graphics.Dispose()
            $bitmap.Dispose()
        }
    }
}

Write-Output "Generated $($outfits.Count * $frameCount) animated lotus mascot frames."
