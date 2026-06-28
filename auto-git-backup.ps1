# auto-git-backup.ps1 - 全自动 Git 备份脚本
# 用法: 每天定时运行，自动扫描项目目录提交并推送

$ScanPaths = @(
    "$env:USERPROFILE\Desktop",
    "$env:USERPROFILE\Documents",
    "$env:USERPROFILE\source\repos"
)

$LogFile = "$env:USERPROFILE\Desktop\.git\auto-backup-log.txt"

# 时间戳
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
"`n=== [$timestamp] Auto Git Backup Start ===" | Out-File -Append $LogFile -Encoding UTF8

# 解决 Git 安全目录问题
git config --global --add safe.directory "*" 2>$null

foreach ($basePath in $ScanPaths) {
    if (-not (Test-Path $basePath)) { continue }

    $gitDirs = Get-ChildItem -Path $basePath -Directory -Recurse -Depth 3 -ErrorAction SilentlyContinue | 
        Where-Object { Test-Path (Join-Path $_.FullName ".git") }

    foreach ($dir in $gitDirs) {
        $repoPath = $dir.FullName
        Push-Location $repoPath
        try {
            # 跳过没有远程仓库的
            $remote = (git remote get-url origin 2>$null)
            if (-not $remote) {
                "[SKIP] $repoPath - no remote" | Out-File -Append $LogFile -Encoding UTF8
                continue
            }

            # 检查是否有改动
            $status = git status --porcelain 2>$null
            if ($status) {
                git add .
                git commit -m "auto backup $($timestamp)" 2>$null
            }

            # 推送
            $pushResult = git push 2>&1
            $shortPath = $repoPath.Replace($env:USERPROFILE, "~")
            "[OK] $shortPath" | Out-File -Append $LogFile -Encoding UTF8
        }
        catch {
            "[FAIL] $repoPath - $_" | Out-File -Append $LogFile -Encoding UTF8
        }
        finally {
            Pop-Location
        }
    }
}

"[$timestamp] Done" | Out-File -Append $LogFile -Encoding UTF8
