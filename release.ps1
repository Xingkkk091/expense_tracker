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
    [string]$Notes,

    # 跳過「有未 commit 變更要繼續嗎？」的詢問（非互動環境必加）
    [switch]$Force
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

# 在 Windows PowerShell 5.1 下，git/gh 的 stderr 警告（LF/CRLF 等）
# 在 $ErrorActionPreference='Stop' 時會被視為終止錯誤。這個 wrapper 暫時放寬
# ErrorActionPreference，只用 $LASTEXITCODE 來判斷成敗。
function Invoke-NativeChecked {
    param(
        [Parameter(Mandatory = $true)][scriptblock]$Block,
        [string]$ErrorMessage = '命令執行失敗'
    )
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        & $Block
        $code = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $prev
    }
    if ($code -ne 0) { throw "$ErrorMessage (exit $code)" }
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
    if (-not $Force) {
        try {
            $ans = Read-Host "要繼續嗎？這些變更會一起包進 v$Version commit (y/N)"
        } catch {
            throw "目前是非互動環境。若要在此情況下繼續，請加 -Force 參數重新執行。"
        }
        if ($ans -ne 'y') { Write-Host "已取消"; exit 1 }
    } else {
        Write-Host "(-Force 已啟用，自動繼續)" -ForegroundColor DarkGray
    }
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
Invoke-NativeChecked -Block { & $Flutter build apk --release } -ErrorMessage "flutter build 失敗"
if (-not (Test-Path $ApkPath)) { throw "找不到 APK: $ApkPath" }
$apkSize = [math]::Round((Get-Item $ApkPath).Length / 1MB, 2)
Write-Host "  APK $apkSize MB" -ForegroundColor Green

Write-Step "4/6 Git commit & push"
Invoke-NativeChecked -Block { git -C $ProjectRoot add . } -ErrorMessage "git add 失敗"
$commitMsg = "v${Version}: $Notes"
Invoke-NativeChecked -Block { git -C $ProjectRoot commit -m $commitMsg } -ErrorMessage "git commit 失敗"
Invoke-NativeChecked -Block { git -C $ProjectRoot push } -ErrorMessage "git push 失敗"

Write-Step "5/6 建立 GitHub Release"
$tag = "v$Version"
# 檢查 tag 是否已存在（這裡不用 Invoke-NativeChecked，因為「不存在」回非零是正常情況）
$prev = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
gh release view $tag --json tagName *> $null
$tagExists = ($LASTEXITCODE -eq 0)
$ErrorActionPreference = $prev
if ($tagExists) { throw "Release $tag 已存在，請改用其他版本號" }

# 多行 notes 透過 --notes 參數在 PS5.1 下偶爾會觸發 gh 互動模式，改用 --notes-file 比較穩
$notesFile = [System.IO.Path]::GetTempFileName()
try {
    [System.IO.File]::WriteAllText($notesFile, $Notes, [System.Text.UTF8Encoding]::new($false))
    Invoke-NativeChecked -Block { gh release create $tag $ApkPath --title $tag --notes-file $notesFile } -ErrorMessage "gh release create 失敗"
} finally {
    Remove-Item $notesFile -Force -ErrorAction SilentlyContinue
}

Write-Step "6/6 完成"
$releaseUrl = "https://github.com/Xingkkk091/expense_tracker/releases/tag/$tag"
Write-Host "  Release: $releaseUrl" -ForegroundColor Green
Write-Host "  使用者下次開啟 App 時會自動跳出更新通知 ✓" -ForegroundColor Green
