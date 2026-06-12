# GitHub Actions Self-Hosted Runner Setup Script for UiPath
# This script automates the setup of a GitHub Actions runner for UiPath CI/CD

param(
    [string]$GitHubToken = "",
    [string]$RunnerName = "uipath-runner",
    [string]$RunnerPath = "C:\github-runner",
    [switch]$RunAsService = $false
)

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "GitHub Actions Runner Setup" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Verify UiPath Studio is installed
Write-Host "Step 1: Checking UiPath Studio installation..." -ForegroundColor Yellow
$studioPath = "C:\Program Files\UiPath\Studio"

if (Test-Path $studioPath) {
    Write-Host "[OK] UiPath Studio found at $studioPath" -ForegroundColor Green
} else {
    Write-Host "[ERROR] UiPath Studio not found at $studioPath" -ForegroundColor Red
    Write-Host "Please install UiPath Studio first from https://www.uipath.com/" -ForegroundColor Red
    exit 1
}

# Step 2: Verify .NET
Write-Host ""
Write-Host "Step 2: Checking .NET installation..." -ForegroundColor Yellow
$dotnetVersion = dotnet --version 2>$null

if ($null -ne $dotnetVersion) {
    Write-Host "[OK] .NET $dotnetVersion installed" -ForegroundColor Green
} else {
    Write-Host "[WARN] .NET not found - you may need to install it" -ForegroundColor Yellow
}

# Step 3: Create runner directory
Write-Host ""
Write-Host "Step 3: Setting up runner directory..." -ForegroundColor Yellow

if (-Not (Test-Path $RunnerPath)) {
    New-Item -ItemType Directory -Path $RunnerPath -Force | Out-Null
    Write-Host "[OK] Created directory: $RunnerPath" -ForegroundColor Green
} else {
    Write-Host "[OK] Directory exists: $RunnerPath" -ForegroundColor Green
}

# Step 4: Download runner
Write-Host ""
Write-Host "Step 4: Downloading GitHub Actions Runner..." -ForegroundColor Yellow

$runnerVersion = "2.319.0"  # Update as needed
$runnerUrl = "https://github.com/actions/runner/releases/download/v$runnerVersion/actions-runner-win-x64-$runnerVersion.zip"
$runnerZip = "$RunnerPath\runner.zip"

Write-Host "Downloading from: $runnerUrl" -ForegroundColor Gray

try {
    Invoke-WebRequest -Uri $runnerUrl -OutFile $runnerZip -UseBasicParsing
    Write-Host "[OK] Runner downloaded" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Failed to download runner: $_" -ForegroundColor Red
    exit 1
}

# Step 5: Extract runner
Write-Host ""
Write-Host "Step 5: Extracting runner..." -ForegroundColor Yellow

try {
    Expand-Archive -Path $runnerZip -DestinationPath $RunnerPath -Force
    Remove-Item $runnerZip -Force
    Write-Host "[OK] Runner extracted" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Failed to extract runner: $_" -ForegroundColor Red
    exit 1
}

# Step 6: Configure runner
Write-Host ""
Write-Host "Step 6: Configuring GitHub Actions Runner..." -ForegroundColor Yellow

if ([string]::IsNullOrEmpty($GitHubToken)) {
    Write-Host ""
    Write-Host "To get your token:" -ForegroundColor Cyan
    Write-Host "1. Go to: https://github.com/ranjitnk/ReFramework-ScrapingProject" -ForegroundColor Cyan
    Write-Host "2. Settings > Actions > Runners > New self-hosted runner" -ForegroundColor Cyan
    Write-Host "3. Copy the token from step 3 (config.cmd ...)" -ForegroundColor Cyan
    Write-Host ""
    $GitHubToken = Read-Host "Enter your GitHub token"
}

if ([string]::IsNullOrEmpty($GitHubToken)) {
    Write-Host "[ERROR] GitHub token is required" -ForegroundColor Red
    exit 1
}

try {
    cd $RunnerPath
    
    $configArgs = @(
        "--url",
        "https://github.com/ranjitnk/ReFramework-ScrapingProject",
        "--token",
        $GitHubToken,
        "--name",
        $RunnerName,
        "--unattended"
    )
    
    if ($RunAsService) {
        $configArgs += "--runAsService"
    }
    
    Write-Host "Running: ./config.cmd $($configArgs -join ' ')" -ForegroundColor Gray
    & .\config.cmd @configArgs
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Runner configured successfully" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] Runner configuration failed" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "[ERROR] Configuration failed: $_" -ForegroundColor Red
    exit 1
}

# Step 7: Start runner
Write-Host ""
Write-Host "Step 7: Starting runner..." -ForegroundColor Yellow

if ($RunAsService) {
    try {
        Start-Service "GitHub Actions Runner"
        Write-Host "[OK] Runner started as service" -ForegroundColor Green
        Write-Host "Runner will start automatically on system reboot" -ForegroundColor Green
    } catch {
        Write-Host "[WARN] Failed to start service: $_" -ForegroundColor Yellow
        Write-Host "You can start it manually with: Start-Service 'GitHub Actions Runner'" -ForegroundColor Yellow
    }
} else {
    Write-Host "[OK] Runner is ready to start manually with: ./run.cmd" -ForegroundColor Green
}

# Final instructions
Write-Host ""
Write-Host "======================================" -ForegroundColor Green
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Verify runner is registered:" -ForegroundColor Cyan
Write-Host "   https://github.com/ranjitnk/ReFramework-ScrapingProject/settings/actions/runners" -ForegroundColor Cyan
Write-Host ""
Write-Host "2. Update workflow to use self-hosted runner:" -ForegroundColor Cyan
Write-Host "   Edit .github/workflows/uipath-ci-cd.yml" -ForegroundColor Cyan
Write-Host "   Change: runs-on: windows-latest" -ForegroundColor Cyan
Write-Host "   To:     runs-on: self-hosted" -ForegroundColor Cyan
Write-Host ""
Write-Host "3. Push to main branch to trigger workflow" -ForegroundColor Cyan
Write-Host ""
Write-Host "For troubleshooting, see the runner logs in: $RunnerPath\_diag" -ForegroundColor Gray
