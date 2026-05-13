#Requires -Version 5.1
<#
.SYNOPSIS
  一鍵發版腳本：改版本號 -> build APK -> commit -> push -> 建 GitHub Release

.EXAMPLE
  .\release.ps1 1.0.2 "修正定位 BUG 並新增匯出功能"
  .\release.ps1 1.0.2 -Notes "修正 BUG"
#>

param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidatePattern('^\d+\.\d+\.\d+$')]
    [string]$Version,

    [Parameter(Mandatory = $true, Position = 1)]
    [string]$Notes
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = $PSScriptRoot
$Flutter = 'C:\Users\User\flutter\bin\flutter.bat'
$ApkPath = Join-Path $ProjectRoot 'build\app\outputs\flutter-apk\app-release.apk'
$PubspecPath = Join-Path $ProjectRoot 'pubspec.yaml'

function Write-Step($msg) {
    Write-Host ""
    Write-Host "==> $msg" -ForegroundColor Cyan
}

Write-Step "1/6 檢查環境"
if (-not (Test-Path $Flutter))    { throw "找不到 Flutter: $Flutter" }
if (-not (Test-Path $PubspecPath)) { throw "找不到 pubspec.yaml" }
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { throw "找不到 gh CLI" }

# 檢查有沒有未 commit 的程式碼變更
$status = git -C $ProjectRoot status --porcelain
if ($status) {
    Write-Host "偵測到未 commit 的變更：" -ForegroundColor Yellow
    Write-Host $status
    $ans = Read-Host "要繼續嗎？這些變更會一起包進 v$Version commit (y/N)"
    if ($ans -ne 'y') { Write-Host "已取消"; exit 1 }
}

Write-Step "2/6 更新 pubspec.yaml 版本號"
$content = Get-Content $PubspecPath -Raw -Encoding UTF8
if ($content -notmatch '(?m)^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$') {
    throw "pubspec.yaml 找不到 version: 行"
}
$oldVersion = $Matches[1]
$oldBuild   = [int]$Matches[2]
$newBuild   = $oldBuild + 1
$newLine    = "version: $Version+$newBuild"
$content = $content -replace '(?m)^version:\s*\d+\.\d+\.\d+\+\d+\s*$', $newLine
# 保留原本檔案編碼(UTF8 無 BOM)
[System.IO.File]::WriteAllText($PubspecPath, $content, [System.Text.UTF8Encoding]::new($false))
Write-Host "  $oldVersion+$oldBuild  ->  $Version+$newBuild" -ForegroundColor Green

Write-Step "3/6 Flutter build APK (release)"
& $Flutter build apk --release
if ($LASTEXITCODE -ne 0) { throw "flutter build 失敗" }
if (-not (Test-Path $ApkPath)) { throw "找不到 APK: $ApkPath" }
$apkSize = [math]::Round((Get-Item $ApkPath).Length / 1MB, 2)
Write-Host "  APK $apkSize MB" -ForegroundColor Green

Write-Step "4/6 Git commit & push"
git -C $ProjectRoot add .
if ($LASTEXITCODE -ne 0) { throw "git add 失敗" }
$commitMsg = "v${Version}: $Notes"
git -C $ProjectRoot commit -m $commitMsg
if ($LASTEXITCODE -ne 0) { throw "git commit 失敗" }
git -C $ProjectRoot push
if ($LASTEXITCODE -ne 0) { throw "git push 失敗" }

Write-Step "5/6 建立 GitHub Release"
$tag = "v$Version"
# 檢查 tag 是否已存在
$existing = gh release view $tag --json tagName 2>$null
if ($LASTEXITCODE -eq 0) {
    throw "Release $tag 已存在，請改用其他版本號"
}
gh release create $tag $ApkPath --title $tag --notes $Notes
if ($LASTEXITCODE -ne 0) { throw "gh release create 失敗" }

Write-Step "6/6 完成"
$releaseUrl = "https://github.com/Xingkkk091/expense_tracker/releases/tag/$tag"
Write-Host "  Release: $releaseUrl" -ForegroundColor Green
Write-Host "  使用者下次開啟 App 時會自動跳出更新通知 ✓" -ForegroundColor Green
