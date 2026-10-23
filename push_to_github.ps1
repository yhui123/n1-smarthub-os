# =====================================================================
# N1-SmartHub-OS · 一键推送至 GitHub 并准备云端编译脚本
# =====================================================================

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   🚀 N1-SmartHub-OS 固件源码仓库 · 一键推送助手" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

# 检查当前目录
$repoDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $repoDir

# 确保 Git 仓库正常
if (-not (Test-Path ".git")) {
    Write-Host "正在初始化本地 Git 仓库..." -ForegroundColor Yellow
    git init
    git branch -M main
}

# 检查 Remote 地址
$remoteUrl = git remote get-url origin 2>$null
if (-not $remoteUrl) {
    Write-Host "⚠️ 检测到当前尚未绑定 GitHub 远端仓库地址。" -ForegroundColor Yellow
    Write-Host "请先在 GitHub 上新建一个仓库（例如: n1-smarthub-os），并复制其地址。" -ForegroundColor Yellow
    Write-Host ""
    $inputUrl = Read-Host "请输入你的 GitHub 仓库地址 (例如 https://github.com/your-username/n1-smarthub-os.git)"
    if ([string]::IsNullOrWhiteSpace($inputUrl)) {
        Write-Host "❌ 未输入地址，脚本退出。" -ForegroundColor Red
        Exit
    }
    git remote add origin $inputUrl.Trim()
    $remoteUrl = $inputUrl.Trim()
    Write-Host "✅ 已成功关联远端仓库: $remoteUrl" -ForegroundColor Green
} else {
    Write-Host "✅ 当前关联的 GitHub 仓库: $remoteUrl" -ForegroundColor Green
}

# 提交所有更新
Write-Host ""
Write-Host "📦 正在暂存并提交所有最新定制文件..." -ForegroundColor Yellow
git add -A
$status = git status --porcelain
if ($status) {
    $commitMsg = "feat: update N1-SmartHub-OS build pipeline and custom overlay (" + (Get-Date -Format "yyyy-MM-dd HH:mm") + ")"
    git commit -m $commitMsg
    Write-Host "✅ 本地提交完成" -ForegroundColor Green
} else {
    Write-Host "ℹ️ 工作区干净，无额外改动" -ForegroundColor Gray
}

# 推送到 GitHub
Write-Host ""
Write-Host "🚀 正在推送代码至 GitHub (main 分支)..." -ForegroundColor Yellow
git push -u origin main

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Green
    Write-Host "🎉 推送成功！代码已同步至 GitHub。" -ForegroundColor Green
    Write-Host "==========================================================" -ForegroundColor Green
    Write-Host ""
    
    # 提取仓库 URL 转网页链接
    $webUrl = $remoteUrl -replace '\.git$', ''
    if ($webUrl -match '^git@github\.com:(.+)$') {
        $webUrl = "https://github.com/" + $matches[1]
    }
    
    Write-Host "👉 接下来只需最后一步即可开启云端编译：" -ForegroundColor Cyan
    Write-Host "1. 打开 GitHub Actions 页面：" -ForegroundColor White
    Write-Host "   $webUrl/actions" -ForegroundColor Yellow
    Write-Host "2. 在左侧点击 'Build N1-SmartHub-OS (Kernel 6.1.y LTS)'" -ForegroundColor White
    Write-Host "3. 点击右侧下拉按钮 'Run workflow' -> 点击绿色的 'Run workflow'" -ForegroundColor White
    Write-Host ""
    Write-Host "⏱️ 云端将自动分配 4核 16G 环境编译约 1~1.5 小时，完成后在 Releases 页面直接下载 .img.gz！" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "❌ 推送失败，请检查网络连接或 GitHub 账号访问权限。" -ForegroundColor Red
}
