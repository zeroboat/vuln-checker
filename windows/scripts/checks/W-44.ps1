function Check-W_44 {
    Print-SecurityCheck -Code "W-44"
    try {
        $logs = @("Application", "Security", "System")
        $issues = @()
        foreach ($logName in $logs) {
            $log = Get-WinEvent -ListLog $logName -ErrorAction SilentlyContinue
            if ($log) {
                $maxSizeMB = [math]::Round($log.MaximumSizeInBytes / 1MB, 1)
                if ($maxSizeMB -lt 10) {
                    $issues += "$logName 로그 최대 크기 부족(${maxSizeMB}MB, 권장: 10MB 이상)"
                }
            } else {
                $issues += "$logName 로그를 확인할 수 없음"
            }
        }

        # 감사 정책 확인
        $policy = Get-SecurityPolicy
        $auditLogon = Get-SecurityPolicySetting -PolicyContent $policy -Setting "AuditLogonEvents"
        if ($null -eq $auditLogon -or $auditLogon -eq "0") {
            $issues += "로그온 이벤트 감사가 비활성화됨"
        }

        if ($issues.Count -eq 0) {
            Record-CheckResult -Code "W-44" -Status "PASS" -Detail "이벤트 로그 설정이 적절함"
        } else {
            Record-CheckResult -Code "W-44" -Status "FAIL" -Detail ($issues -join "; ")
        }
    } catch {
        Record-CheckResult -Code "W-44" -Status "REVIEW" -Detail "이벤트 로그 설정을 확인할 수 없음: $_"
    }
}
