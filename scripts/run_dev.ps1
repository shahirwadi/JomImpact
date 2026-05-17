param(
  [string]$Device = "",
  [switch]$NoCloudinary
)

$root = Split-Path -Parent $PSScriptRoot
$envFile = Join-Path $root "env\dev.json"

Push-Location $root
try {
  if ($NoCloudinary) {
    if ($Device) {
      flutter run -d $Device
    } else {
      flutter run
    }
    return
  }

  if (-not (Test-Path $envFile)) {
    Write-Host "Missing env\dev.json. Create it using env\dev.example.json first." -ForegroundColor Yellow
    exit 1
  }

  if ($Device) {
    flutter run -d $Device --dart-define-from-file=$envFile
  } else {
    flutter run --dart-define-from-file=$envFile
  }
}
finally {
  Pop-Location
}
