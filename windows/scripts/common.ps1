################################################################################
# Common Functions - Windows 취약점 점검 공통 함수
################################################################################

# 보안 항목 코드 로드
. "$PSScriptRoot\security_codes.ps1"

################################################################################
# JSON 결과 누적
################################################################################

$script:JsonChecks = [System.Collections.ArrayList]::new()

function Get-CheckCategory {
    param([string]$Code)
    if ($script:SECURITY_CATEGORIES.ContainsKey($Code)) {
        return $script:SECURITY_CATEGORIES[$Code]
    }
    return "기타"
}

function Get-CheckName {
    param([string]$Code)
    if ($script:SECURITY_CODES.ContainsKey($Code)) {
        return $script:SECURITY_CODES[$Code]
    }
    return "알 수 없는 항목"
}

################################################################################
# 점검 결과 기록
################################################################################

function Print-SecurityCheck {
    param([string]$Code)
    $name = Get-CheckName -Code $Code
    Append-Log ""
    Append-Log ("=" * 50)
    Append-Log "[$Code] $name"
}

function Record-CheckResult {
    param(
        [string]$Code,
        [ValidateSet("PASS","FAIL","REVIEW")]
        [string]$Status,
        [string]$Detail = ""
    )

    $statusText = switch ($Status) {
        "PASS"   { "양호" }
        "FAIL"   { "취약" }
        "REVIEW" { "확인필요" }
    }

    $statusIcon = switch ($Status) {
        "PASS"   { "[PASS]" }
        "FAIL"   { "[FAIL]" }
        "REVIEW" { "[REVIEW]" }
    }

    Append-Log ""
    Append-Log "  $statusIcon 점검 결과: $statusText"
    if ($Detail) {
        Append-Log "  상세: $Detail"
    }
    Append-Log ("=" * 50)

    # JSON 결과 누적
    $null = $script:JsonChecks.Add([PSCustomObject]@{
        code      = $Code
        name      = Get-CheckName -Code $Code
        category  = Get-CheckCategory -Code $Code
        status    = $Status
        detail    = $Detail
        reference = [PSCustomObject]@{
            purpose     = ""
            check       = ""
            goodCriteria = ""
            badCriteria  = ""
            remediation  = ""
            threat       = ""
        }
    })

    # 콘솔 출력
    $color = switch ($Status) {
        "PASS"   { "Green" }
        "FAIL"   { "Red" }
        "REVIEW" { "Yellow" }
    }
    Write-Host "  $statusIcon [$Code] $(Get-CheckName -Code $Code): $statusText" -ForegroundColor $color
}

################################################################################
# 로그 출력
################################################################################

function Append-Log {
    param([string]$Message)
    if ($script:ResultFile) {
        $Message | Out-File -FilePath $script:ResultFile -Append -Encoding UTF8
    }
}

function Print-SectionHeader {
    param([string]$SectionName)
    Append-Log ""
    Append-Log ("############################################################################")
    Append-Log "## $SectionName"
    Append-Log ("############################################################################")
    Append-Log ""
}

################################################################################
# 관리자 권한 확인
################################################################################

function Test-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]$identity
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

################################################################################
# secedit 보안 정책 파싱
################################################################################

function Get-SecurityPolicy {
    $tempFile = [System.IO.Path]::GetTempFileName()
    try {
        $null = secedit /export /cfg $tempFile 2>$null
        $content = Get-Content -Path $tempFile -ErrorAction SilentlyContinue
        return $content
    } finally {
        Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
    }
}

function Get-SecurityPolicySetting {
    param(
        [string[]]$PolicyContent,
        [string]$Setting
    )
    foreach ($line in $PolicyContent) {
        if ($line -match "^\s*$Setting\s*=\s*(.+)$") {
            return $Matches[1].Trim()
        }
    }
    return $null
}

################################################################################
# JSON 생성
################################################################################

function Generate-Json {
    param(
        [string]$JsonFile,
        [string]$ExecTime,
        [string]$Hostname,
        [string]$OsType,
        [string]$OsVersion,
        [string]$Architecture,
        [int]$PassCount,
        [int]$FailCount,
        [int]$ReviewCount,
        [int]$TotalCount
    )

    $result = [PSCustomObject]@{
        metadata = [PSCustomObject]@{
            executionTime = $ExecTime
            hostname      = $Hostname
            os            = $OsType
            distro        = $OsVersion
            architecture  = $Architecture
        }
        summary = [PSCustomObject]@{
            total  = $TotalCount
            pass   = $PassCount
            fail   = $FailCount
            review = $ReviewCount
        }
        checks = $script:JsonChecks
    }

    $result | ConvertTo-Json -Depth 5 | Out-File -FilePath $JsonFile -Encoding UTF8
}

################################################################################
# 마크다운 요약 생성
################################################################################

function Generate-Summary {
    param(
        [string]$SummaryFile,
        [int]$PassCount,
        [int]$FailCount,
        [int]$ReviewCount,
        [int]$TotalCount
    )

    $runDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $hostname = $env:COMPUTERNAME
    $passRate  = if ($TotalCount -gt 0) { [math]::Round($PassCount * 100 / $TotalCount) } else { 0 }
    $failRate  = if ($TotalCount -gt 0) { [math]::Round($FailCount * 100 / $TotalCount) } else { 0 }
    $reviewRate = if ($TotalCount -gt 0) { [math]::Round($ReviewCount * 100 / $TotalCount) } else { 0 }

    $md = @"
# Windows 취약점 점검 결과 요약

| 항목 | 내용 |
|------|------|
| 점검 일시 | $runDate |
| 호스트명 | $hostname |
| OS | Windows |
| 결과 파일 | $(Split-Path $script:ResultFile -Leaf) |

## 점검 결과 통계

| 구분 | 건수 | 비율 |
|------|-----:|-----:|
| PASS 양호 | $PassCount | ${passRate}% |
| FAIL 취약 | $FailCount | ${failRate}% |
| REVIEW 확인필요 | $ReviewCount | ${reviewRate}% |
| **합계** | **$TotalCount** | **100%** |

"@

    # 취약 항목 목록
    $failItems = $script:JsonChecks | Where-Object { $_.status -eq "FAIL" }
    if ($failItems) {
        $md += "## FAIL 취약 항목 목록`n`n"
        foreach ($item in $failItems) {
            $md += "- **$($item.code)** $($item.name): $($item.detail)`n"
        }
        $md += "`n"
    }

    # 확인필요 항목 목록
    $reviewItems = $script:JsonChecks | Where-Object { $_.status -eq "REVIEW" }
    if ($reviewItems) {
        $md += "## REVIEW 확인필요 항목 목록`n`n"
        foreach ($item in $reviewItems) {
            $md += "- **$($item.code)** $($item.name): $($item.detail)`n"
        }
        $md += "`n"
    }

    $md += @"
## 상세 결과

> 상세 점검 내용은 ``$(Split-Path $script:ResultFile -Leaf)`` 파일을 참고하세요.
"@

    $md | Out-File -FilePath $SummaryFile -Encoding UTF8
}
