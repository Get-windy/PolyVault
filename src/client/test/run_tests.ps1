# PolyVault Flutter Test Runner
# 运行所有组件测试

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "PolyVault Flutter Component Test Suite" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 检查Flutter是否安装
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "错误: Flutter未安装或未添加到PATH" -ForegroundColor Red
    Write-Host "请确保Flutter SDK已正确安装" -ForegroundColor Yellow
    exit 1
}

# 进入项目目录
Set-Location $PSScriptRoot\..

Write-Host "项目目录: $(Get-Location)" -ForegroundColor Green
Write-Host ""

# 获取Flutter版本
Write-Host "Flutter版本:" -ForegroundColor Cyan
flutter --version
Write-Host ""

# 运行pub get
Write-Host "获取依赖..." -ForegroundColor Cyan
flutter pub get
Write-Host ""

# 运行所有测试
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "运行所有组件测试" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$testFiles = @(
    "test/widget_test.dart",
    "test/models_test.dart",
    "test/messages_test.dart",
    "test/devices_screen_test.dart",
    "test/credentials_screen_test.dart",
    "test/responsive_layout_test.dart",
    "test/custom_widgets_test.dart",
    "test/performance_test.dart",
    "test/integration_test.dart"
)

$passed = 0
$failed = 0
$total = $testFiles.Count

foreach ($file in $testFiles) {
    $testName = Split-Path $file -Leaf
    Write-Host "----------------------------------------" -ForegroundColor Gray
    Write-Host "运行测试: $testName" -ForegroundColor Yellow
    Write-Host "----------------------------------------" -ForegroundColor Gray
    
    try {
        flutter test $file --no-pub
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ $testName 通过" -ForegroundColor Green
            $passed++
        } else {
            Write-Host "✗ $testName 失败" -ForegroundColor Red
            $failed++
        }
    } catch {
        Write-Host "✗ $testName 错误: $_" -ForegroundColor Red
        $failed++
    }
    Write-Host ""
}

# 运行覆盖率测试
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "生成测试覆盖率报告" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

flutter test --coverage --no-pub

if (Test-Path "coverage/lcov.info") {
    Write-Host "覆盖率报告已生成: coverage/lcov.info" -ForegroundColor Green
    
    # 如果安装了lcov，生成HTML报告
    if (Get-Command genhtml -ErrorAction SilentlyContinue) {
        genhtml coverage/lcov.info -o coverage/html
        Write-Host "HTML报告已生成: coverage/html/index.html" -ForegroundColor Green
    }
} else {
    Write-Host "警告: 未生成覆盖率报告" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "测试完成摘要" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "总测试文件: $total" -ForegroundColor White
Write-Host "通过: $passed" -ForegroundColor Green
Write-Host "失败: $failed" -ForegroundColor Red
Write-Host "成功率: $([math]::Round(($passed/$total)*100, 2))%" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Yellow" })
Write-Host "========================================" -ForegroundColor Cyan

if ($failed -eq 0) {
    Write-Host "✓ 所有测试通过!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "✗ 部分测试失败" -ForegroundColor Red
    exit 1
}