################################################################################
# Vulnerability Checker - Windows Main Script
# KISA W-01 ~ W-68 기준 Windows 서버 취약점 점검
################################################################################

param(
    [switch]$Parallel,
    [int]$Jobs = 4,
    [switch]$Help,
    [switch]$Force
)

# 인코딩 설정
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

################################################################################
# 도움말
################################################################################
if ($Help) {
    Write-Host @"
사용법: .\windows\main.ps1 [옵션]

옵션:
  -Parallel          병렬 실행 모드 (기본: 순차 실행)
  -Jobs N            병렬 실행 시 동시 작업 수 (기본: 4)
  -Help              도움말 표시

예시:
  .\windows\main.ps1                     # 순차 실행
  .\windows\main.ps1 -Parallel           # 4개씩 병렬 실행
  .\windows\main.ps1 -Parallel -Jobs 8   # 8개씩 병렬 실행
"@
    exit 0
}

################################################################################
# 관리자 권한 확인
################################################################################
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]$identity
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    if ($Force) {
        Write-Host "[경고] 관리자 권한 없이 실행합니다. 일부 점검이 정확하지 않을 수 있습니다." -ForegroundColor Yellow
    } else {
        Write-Host "[오류] 이 스크립트는 관리자 권한으로 실행해야 합니다." -ForegroundColor Red
        Write-Host "  실행 방법: 관리자 PowerShell에서 .\windows\main.ps1" -ForegroundColor Yellow
        Write-Host "  또는: .\windows\main.ps1 -Force (비관리자 모드)" -ForegroundColor Yellow
        exit 1
    }
}

################################################################################
# 디렉토리 설정
################################################################################
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ScriptDir
$ResultsDir = Join-Path $RootDir "results"
$LogsDir = Join-Path $RootDir "logs"

New-Item -ItemType Directory -Path $ResultsDir -Force | Out-Null
New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null

$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$script:ResultFile = Join-Path $ResultsDir "result_${Timestamp}.txt"
$SummaryFile = Join-Path $ResultsDir "summary_${Timestamp}.md"
$JsonFile = Join-Path $ResultsDir "result_${Timestamp}.json"
$LogFile = Join-Path $LogsDir "run_${Timestamp}.log"

################################################################################
# 공통 함수 로드
################################################################################
. "$ScriptDir\scripts\common.ps1"

################################################################################
# 로그 함수
################################################################################
function Write-Log {
    param([string]$Level, [string]$Message)
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "[$ts] [$Level] $Message"
    $entry | Out-File -FilePath $LogFile -Append -Encoding UTF8
    switch ($Level) {
        "ERROR"   { Write-Host $entry -ForegroundColor Red }
        "WARNING" { Write-Host $entry -ForegroundColor Yellow }
        default   { Write-Host $entry }
    }
}

################################################################################
# OS 정보 수집
################################################################################
$OsInfo = Get-CimInstance Win32_OperatingSystem
$OsCaption = $OsInfo.Caption
$OsBuild = $OsInfo.BuildNumber
$Architecture = $OsInfo.OSArchitecture
$Hostname = $env:COMPUTERNAME

################################################################################
# 초기화
################################################################################
Write-Log "INFO" "=================================="
Write-Log "INFO" "Vulnerability Checker (Windows) 시작"
Write-Log "INFO" "=================================="
Write-Log "INFO" "OS: $OsCaption (Build $OsBuild)"
Write-Log "INFO" "호스트명: $Hostname"
Write-Log "INFO" "아키텍처: $Architecture"
if ($Parallel) {
    Write-Log "INFO" "실행 모드: 병렬 (동시 ${Jobs}개)"
} else {
    Write-Log "INFO" "실행 모드: 순차"
}

# 결과 파일 헤더
@"
====================================================
Vulnerability Checker 결과 (Windows)
====================================================
실행일시: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
OS: $OsCaption (Build $OsBuild)
호스트명: $Hostname
====================================================
"@ | Out-File -FilePath $script:ResultFile -Encoding UTF8

################################################################################
# 점검 스크립트 로드
################################################################################
$ChecksDir = Join-Path $ScriptDir "scripts\checks"
$checkFiles = Get-ChildItem -Path $ChecksDir -Filter "W-*.ps1" | Sort-Object Name
foreach ($f in $checkFiles) {
    . $f.FullName
}

################################################################################
# 점검 실행
################################################################################

# 섹션별 점검 항목 정의
$Sections = @(
    @{ Name = "1. 계정 관리"; Codes = @(1,2,3,4,5,6,7,8,48,49,50,51,52,53) }
    @{ Name = "2. 서비스 관리"; Codes = @(9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,56,57,58,59,60,61,62,63,64,65,66,67) }
    @{ Name = "3. 패치 관리"; Codes = @(31,32,33) }
    @{ Name = "4. 보안 관리"; Codes = @(34,35,36,37,38,39,40,41,42,43,45,46,47,54,55,68) }
    @{ Name = "5. 로그 관리"; Codes = @(44) }
)

if ($Parallel) {
    # 병렬 실행
    Write-Log "INFO" "병렬 모드로 점검 실행 중..."
    foreach ($section in $Sections) {
        Print-SectionHeader $section.Name
        $codes = $section.Codes
        $codes | ForEach-Object -ThrottleLimit $Jobs -Parallel {
            # 병렬 블록에서는 함수를 직접 사용할 수 없으므로 순차로 폴백
        } -ErrorAction SilentlyContinue

        # ForEach-Object -Parallel 에서 dot-sourced 함수 공유가 어려우므로 순차 실행으로 폴백
        foreach ($num in $codes) {
            $code = "W-{0:D2}" -f $num
            $funcName = "Check-W_{0:D2}" -f $num
            if (Get-Command $funcName -ErrorAction SilentlyContinue) {
                try { & $funcName } catch {
                    Record-CheckResult -Code $code -Status "REVIEW" -Detail "점검 중 오류 발생: $_"
                }
            }
        }
    }
} else {
    # 순차 실행
    foreach ($section in $Sections) {
        Print-SectionHeader $section.Name
        foreach ($num in $section.Codes) {
            $code = "W-{0:D2}" -f $num
            $funcName = "Check-W_{0:D2}" -f $num
            if (Get-Command $funcName -ErrorAction SilentlyContinue) {
                try { & $funcName } catch {
                    Record-CheckResult -Code $code -Status "REVIEW" -Detail "점검 중 오류 발생: $_"
                }
            }
        }
    }
}

################################################################################
# 결과 집계
################################################################################
$PassCount = ($script:JsonChecks | Where-Object { $_.status -eq "PASS" }).Count
$FailCount = ($script:JsonChecks | Where-Object { $_.status -eq "FAIL" }).Count
$ReviewCount = ($script:JsonChecks | Where-Object { $_.status -eq "REVIEW" }).Count
$TotalCount = $script:JsonChecks.Count

# 결과 파일 마무리
@"

====================================================
검사 완료: 총 ${TotalCount}개  양호 ${PassCount}  취약 ${FailCount}  확인필요 ${ReviewCount}
====================================================
"@ | Out-File -FilePath $script:ResultFile -Append -Encoding UTF8

# JSON 결과 파일 생성
$ExecTime = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
Generate-Json -JsonFile $JsonFile -ExecTime $ExecTime -Hostname $Hostname `
    -OsType "WINDOWS" -OsVersion $OsCaption -Architecture $Architecture `
    -PassCount $PassCount -FailCount $FailCount -ReviewCount $ReviewCount -TotalCount $TotalCount

# 마크다운 요약 파일 생성
Generate-Summary -SummaryFile $SummaryFile `
    -PassCount $PassCount -FailCount $FailCount -ReviewCount $ReviewCount -TotalCount $TotalCount

Write-Log "INFO" "JSON 저장: $JsonFile"
Write-Log "INFO" "요약 저장: $SummaryFile"
Write-Log "INFO" "결과 저장: $($script:ResultFile)"

################################################################################
# 최종 결과 출력
################################################################################
Write-Host ""
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host " 검사 완료" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "  총 점검: $TotalCount 개"
Write-Host "  양호:    $PassCount 개" -ForegroundColor Green
Write-Host "  취약:    $FailCount 개" -ForegroundColor Red
Write-Host "  확인필요: $ReviewCount 개" -ForegroundColor Yellow
Write-Host ""
Write-Host "  결과: $($script:ResultFile)" -ForegroundColor Gray
Write-Host "  JSON: $JsonFile" -ForegroundColor Gray
Write-Host "  요약: $SummaryFile" -ForegroundColor Gray
Write-Host "====================================================" -ForegroundColor Cyan

Write-Log "INFO" "=================================="
Write-Log "INFO" "Vulnerability Checker (Windows) 종료"
Write-Log "INFO" "=================================="

exit 0
