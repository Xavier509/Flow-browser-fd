<#
PowerShell helper: clean_windows_project.ps1
Safely stop common Flutter/Dart processes and attempt to remove locked build directories
Usage: Run PowerShell as Administrator and run:
  .\scripts\clean_windows_project.ps1 -ProjectRoot "C:\Path\To\project"
If you omit ProjectRoot it will use the current folder.
#>
param(
  [string]$ProjectRoot = (Get-Location).Path,
  [switch]$SkipOneDrive
)

function Write-Info { param($m) Write-Host "[INFO] $m" -ForegroundColor Cyan }
function Write-Ok { param($m) Write-Host "[OK]   $m" -ForegroundColor Green }
function Write-Warn { param($m) Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Write-Err { param($m) Write-Host "[ERROR] $m" -ForegroundColor Red }

Push-Location $ProjectRoot
Write-Info "Project root: $ProjectRoot"

# Helpful list of processes that commonly hold file handles
$processNames = @('flutter','dart','dart.exe','flutter_tester','dart_analyzer','code','Code','msbuild','devenv','squirrel','OneDrive')

function Stop-CommonProcesses {
  Write-Info "Stopping common Flutter/Dart/IDE processes (if running)..."
  foreach ($name in $processNames) {
    try {
      $procs = Get-Process -Name $name -ErrorAction SilentlyContinue
      if ($procs) {
        foreach ($p in $procs) {
          try {
            Write-Info "Stopping PID $($p.Id) - $($p.ProcessName)"
            Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
          } catch {
            Write-Warn "Failed to stop process $($p.Id): $_"
          }
        }
      }
    } catch {}
  }
}

if (-not $SkipOneDrive) {
  # Attempt to pause OneDrive syncing which often holds handles to project files
  try {
    $one = Get-Process -Name OneDrive -ErrorAction SilentlyContinue
    if ($one) {
      Write-Info "Pausing OneDrive sync (stopping OneDrive process)..."
      Stop-Process -Name OneDrive -Force -ErrorAction SilentlyContinue
      Start-Sleep -Seconds 2
    }
  } catch {
    Write-Warn "Could not stop OneDrive automatically. If you use OneDrive, please pause syncing or exclude the project folder and retry."
  }
}

Stop-CommonProcesses

# Paths to attempt to remove
$targets = @(
  "$ProjectRoot\build",
  "$ProjectRoot\.dart_tool",
  "$ProjectRoot\windows\flutter\ephemeral",
  "$ProjectRoot\ios\Flutter\ephemeral",
  "$ProjectRoot\linux\flutter\ephemeral",
  "$ProjectRoot\macos\Flutter\ephemeral",
  "$ProjectRoot\.flutter-plugins-dependencies",
  "$ProjectRoot\.flutter-plugins",
  "$ProjectRoot\flutter\.packages",
  "$ProjectRoot\pubspec.lock"
)

function TryRemove($path) {
  if (-not (Test-Path $path)) { Write-Info "Not present: $path"; return $true }
  Write-Info "Attempting to remove: $path"

  # Try multiple times with small delays in case handles are transient
  for ($i=1; $i -le 6; $i++) {
    try {
      # Ensure we can take ownership and grant full control (may require Admin)
      try {
        takeown /F "$path" /R /D Y > $null 2>&1
        icacls "$path" /grant "$env:USERNAME:(F)" /T /C > $null 2>&1
      } catch { }

      # Remove reparse points (symlinks) directly
      $attr = (Get-Item $path -ErrorAction SilentlyContinue).Attributes
      if ($attr -band [System.IO.FileAttributes]::ReparsePoint) {
        Write-Info "Path is a symlink/reparse point; removing reparse point: $path"
        Remove-Item -Path $path -Force -Recurse -ErrorAction Stop
      } else {
        Remove-Item -Path $path -Force -Recurse -ErrorAction Stop
      }
      Write-Ok "Removed: $path"
      return $true
    } catch {
      $err = $_.ToString()
      Write-Warn ("Attempt {0} failed to remove {1}: {2}" -f $i, $path, $err)
      Start-Sleep -Seconds (2 * $i)
    }
  }

  # Final attempt using cmd rmdir (sometimes works for deeply nested paths)
  try {
    Write-Info "Trying cmd.exe rmdir /s /q"
    cmd /c "rmdir /s /q \"$path\"" | Out-Null
    if (-not (Test-Path $path)) { Write-Ok "Removed (cmd rmdir): $path"; return $true }
  } catch {}

  Write-Err "Unable to remove: $path"
  return $false
}

$failed = @()
foreach ($t in $targets) {
  if (-not (TryRemove $t)) { $failed += $t }
}

if ($failed.Count -eq 0) {
  Write-Ok 'All targeted directories removed. You can now retry: `flutter clean` and `flutter pub get`'
  Pop-Location
  exit 0
}

Write-Warn "Some directories could not be removed. Listing contents to help diagnose..."
foreach ($f in $failed) {
  Write-Host "--- $f ---" -ForegroundColor Yellow
  try { Get-ChildItem -Path $f -Force -Recurse -ErrorAction SilentlyContinue | Select-Object -First 50 | Format-List Name,FullName } catch {}
}

Write-Warn "If items remain, try the Sysinternals 'Handle' utility to find processes holding open handles: https://docs.microsoft.com/sysinternals/downloads/handle (run as Admin: handle.exe $ProjectRoot)."

  Write-Warn "Alternatively, rebooting the machine will generally clear file locks. If you use OneDrive, consider moving the project out of OneDrive or excluding the folder from sync."

Pop-Location
exit 1
