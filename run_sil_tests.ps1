# Build the firmware, make the QEMU flash image, and run the pytest SIL tests.
# Run from any PowerShell in this folder:   .\run_sil_tests.ps1
# Extra pytest options pass through, e.g.:   .\run_sil_tests.ps1 -k bad_input
#
# Why this script exists: pytest-embedded normally builds the flash image by launching
# "esptool.py" itself. On Windows that fails (WinError 2), because esptool.py is only a
# PowerShell function here, not an .exe that Python's subprocess can start. So we make
# the image ourselves with "python -m esptool" and tell pytest-embedded to reuse it.

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

# Activate ESP-IDF if this terminal isn't already an ESP-IDF terminal.
if (-not $env:IDF_PATH) {
    Write-Host "== Activating ESP-IDF v6.1 =="
    . "C:\Espressif\tools\Microsoft.v6.1.PowerShell_profile.ps1" | Out-Null
}
# Make sure Espressif QEMU is on PATH for this run.
if (-not (Get-Command qemu-system-xtensa -ErrorAction SilentlyContinue)) {
    $qemuBin = Get-ChildItem "C:\Espressif\tools\tools\qemu-xtensa\*\qemu\bin" -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($qemuBin) { $env:PATH = "$($qemuBin.FullName);$env:PATH" }
}
if (-not $env:IDF_PATH) { Write-Host "Could not activate ESP-IDF."; exit 1 }

Write-Host "== Building =="
python "$env:IDF_PATH\tools\idf.py" build
if ($LASTEXITCODE -ne 0) { Write-Host "Build failed."; exit $LASTEXITCODE }

Write-Host "`n== Making QEMU flash image (build\flash_image.bin) =="
Push-Location build
# flash_args (written by the build) lists the bootloader, partition table and app offsets.
python -m esptool --chip esp32 merge-bin --fill-flash-size 2MB -o flash_image.bin "@flash_args"
$merge = $LASTEXITCODE
Pop-Location
if ($merge -ne 0) { Write-Host "Image merge failed."; exit $merge }

Write-Host "`n== Running SIL tests in QEMU =="
python -m pytest pytest_toy.py --embedded-services idf,qemu --target esp32 -s `
    --qemu-image-path build\flash_image.bin --skip-regenerate-image y @args
exit $LASTEXITCODE
