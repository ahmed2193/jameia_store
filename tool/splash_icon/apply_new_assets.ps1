# =============================================================================
# apply_new_assets.ps1 - rebuild JameiaMart app-icon + splash source assets from
# two inputs, WHITE splash background, wide wordmark composed onto a soft GREEN
# gradient (so a round/squircle launcher mask never clips the wordmark).
#
#   powershell -File tool\splash_icon\apply_new_assets.ps1 `
#       -IconPath "C:\path\app_icon.png" -SplashPath "C:\path\splash.png"
#
# Outputs (consumed afterwards by flutter_launcher_icons + flutter_native_splash):
#   assets/launcher/app_icon.png         1024^2  adaptive FOREGROUND (green grad + wordmark @0.64w)
#   assets/launcher/app_icon_square.png  1024^2  iOS + legacy square  (green grad + wordmark @0.86w)
#   assets/launcher/a12_splash.png       1152^2  Android-12 native splash icon (green grad + wordmark @0.62w)
#   assets/images/splash_screen.png      1080x2339 full-bleed (BoxFit.cover) splash art on white
#
# GDI+ (System.Drawing) only - no ImageMagick / Python. Windows PowerShell 5.1.
# =============================================================================
param(
  [string]$IconPath   = 'C:\Users\Fawaly\Downloads\app_icon.png',
  [string]$SplashPath = 'C:\Users\Fawaly\Downloads\splash.png',
  [string]$Root       = 'F:\_jam3eia_apps\keeta_clone'
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

function Save-Png($bmp, $path) {
  $dir = Split-Path -Parent $path
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
}

function New-Canvas([int]$w, [int]$h, $fill) {
  $b = New-Object System.Drawing.Bitmap($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [System.Drawing.Graphics]::FromImage($b)
  if ($null -ne $fill) { $g.Clear($fill) } else { $g.Clear([System.Drawing.Color]::Transparent) }
  $g.Dispose()
  return $b
}

# Vertical (top->bottom) linear-gradient canvas.
function New-GradientCanvas([int]$w, [int]$h, $c1, $c2) {
  $b = New-Object System.Drawing.Bitmap($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [System.Drawing.Graphics]::FromImage($b)
  $rect = New-Object System.Drawing.Rectangle(0, 0, $w, $h)
  $lgb = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, $c1, $c2, 90.0)
  $g.FillRectangle($lgb, $rect)
  $g.Dispose(); $lgb.Dispose()
  return $b
}

function Draw-Scaled($canvas, $img, [int]$x, [int]$y, [int]$w, [int]$h) {
  $g = [System.Drawing.Graphics]::FromImage($canvas)
  $g.InterpolationMode  = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.PixelOffsetMode    = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $g.SmoothingMode      = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
  $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
  $attr = New-Object System.Drawing.Imaging.ImageAttributes
  $attr.SetWrapMode([System.Drawing.Drawing2D.WrapMode]::TileFlipXY)
  $dest = New-Object System.Drawing.Rectangle($x, $y, $w, $h)
  $g.DrawImage($img, $dest, 0, 0, $img.Width, $img.Height, [System.Drawing.GraphicsUnit]::Pixel, $attr)
  $g.Dispose()
}

# Key a white background out to transparency by the per-pixel MIN channel:
# min>=hi -> transparent, min<=lo -> opaque, linear between (soft edges).
# Colored ink (green/orange/yellow) has a low min channel so it is preserved.
function Convert-WhiteToAlpha($src, [int]$lo = 232, [int]$hi = 250) {
  $w = $src.Width; $h = $src.Height
  $bmp = New-Object System.Drawing.Bitmap($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [System.Drawing.Graphics]::FromImage($bmp); $g.DrawImage($src, 0, 0, $w, $h); $g.Dispose()
  $rect = New-Object System.Drawing.Rectangle(0, 0, $w, $h)
  $data = $bmp.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadWrite, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $n = $data.Stride * $h
  $buf = New-Object byte[] $n
  [System.Runtime.InteropServices.Marshal]::Copy($data.Scan0, $buf, 0, $n)
  $span = $hi - $lo
  for ($i = 0; $i -lt $n; $i += 4) {
    $mn = $buf[$i]                                   # B
    if ($buf[$i + 1] -lt $mn) { $mn = $buf[$i + 1] } # G
    if ($buf[$i + 2] -lt $mn) { $mn = $buf[$i + 2] } # R
    if ($mn -ge $hi) { $a = 0 }
    elseif ($mn -le $lo) { $a = 255 }
    else { $a = [int](255 * ($hi - $mn) / $span) }
    $buf[$i + 3] = [byte]$a
  }
  [System.Runtime.InteropServices.Marshal]::Copy($buf, 0, $data.Scan0, $n)
  $bmp.UnlockBits($data)
  return $bmp
}

# Crop a 32bpp ARGB bitmap to its non-transparent bounding box (+ margin frac).
function Get-AlphaCrop($src, [double]$margin = 0.0) {
  $w = $src.Width; $h = $src.Height
  $rect = New-Object System.Drawing.Rectangle(0, 0, $w, $h)
  $data = $src.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $stride = $data.Stride
  $n = $stride * $h
  $buf = New-Object byte[] $n
  [System.Runtime.InteropServices.Marshal]::Copy($data.Scan0, $buf, 0, $n)
  $src.UnlockBits($data)
  $minX = $w; $minY = $h; $maxX = -1; $maxY = -1
  for ($y = 0; $y -lt $h; $y++) {
    $row = $y * $stride
    for ($x = 0; $x -lt $w; $x++) {
      if ($buf[$row + $x * 4 + 3] -gt 16) {
        if ($x -lt $minX) { $minX = $x }; if ($x -gt $maxX) { $maxX = $x }
        if ($y -lt $minY) { $minY = $y }; if ($y -gt $maxY) { $maxY = $y }
      }
    }
  }
  if ($maxX -lt 0) { return $src }
  $bw = $maxX - $minX + 1; $bh = $maxY - $minY + 1
  $mx = [int]($bw * $margin); $my = [int]($bh * $margin)
  $cx = [Math]::Max(0, $minX - $mx); $cy = [Math]::Max(0, $minY - $my)
  $cw = [Math]::Min($w - $cx, $bw + 2 * $mx); $ch = [Math]::Min($h - $cy, $bh + 2 * $my)
  $crop = New-Object System.Drawing.Bitmap($cw, $ch, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [System.Drawing.Graphics]::FromImage($crop)
  $srcRect = New-Object System.Drawing.Rectangle($cx, $cy, $cw, $ch)
  $dstRect = New-Object System.Drawing.Rectangle(0, 0, $cw, $ch)
  $g.DrawImage($src, $dstRect, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)
  $g.Dispose()
  return $crop
}

# Wordmark (transparent-bg, tight) centered at $widthFrac of a square gradient tile.
function Compose-Icon([int]$size, [double]$widthFrac, $logo, $g1, $g2) {
  $canvas = New-GradientCanvas $size $size $g1 $g2
  $tw = [int]($size * $widthFrac)
  $th = [int]($tw * $logo.Height / $logo.Width)
  $tx = [int](($size - $tw) / 2)
  $ty = [int](($size - $th) / 2)
  Draw-Scaled $canvas $logo $tx $ty $tw $th
  return $canvas
}

$white = [System.Drawing.Color]::White
$g1 = [System.Drawing.Color]::FromArgb(255, 0xEA, 0xF7, 0xE6)   # #EAF7E6 gradient top
$g2 = [System.Drawing.Color]::FromArgb(255, 0xCD, 0xEB, 0xC2)   # #CDEBC2 gradient bottom
$launcher = Join-Path $Root 'assets\launcher'
$images   = Join-Path $Root 'assets\images'

Write-Host 'Keying wordmark off white...'
$icoRaw   = New-Object System.Drawing.Bitmap($IconPath)
$icoKeyed = Convert-WhiteToAlpha $icoRaw 232 250
$icoTight = Get-AlphaCrop $icoKeyed 0.02

Write-Host 'Composing icons on green gradient...'
$fg = Compose-Icon 1024 0.78 $icoTight $g1 $g2
Save-Png $fg (Join-Path $launcher 'app_icon.png'); $fg.Dispose()

$sq = Compose-Icon 1024 0.94 $icoTight $g1 $g2
Save-Png $sq (Join-Path $launcher 'app_icon_square.png'); $sq.Dispose()

$a12 = Compose-Icon 1152 0.72 $icoTight $g1 $g2
Save-Png $a12 (Join-Path $launcher 'a12_splash.png'); $a12.Dispose()

$icoRaw.Dispose(); $icoKeyed.Dispose(); $icoTight.Dispose()

Write-Host 'Building full-bleed splash 1080x2339...'
$spl = New-Object System.Drawing.Bitmap($SplashPath)
$cw = 1080; $ch = 2339
$scale = [Math]::Max($cw / [double]$spl.Width, $ch / [double]$spl.Height)
$iw = [int][Math]::Round($spl.Width * $scale)
$ih = [int][Math]::Round($spl.Height * $scale)
$ix = [int][Math]::Round(($cw - $iw) / 2)
$iy = [int][Math]::Round(($ch - $ih) / 2)
$splash = New-Canvas $cw $ch $white
Draw-Scaled $splash $spl $ix $iy $iw $ih
Save-Png $splash (Join-Path $images 'splash_screen.png')
$splash.Dispose(); $spl.Dispose()

Write-Host 'DONE'
