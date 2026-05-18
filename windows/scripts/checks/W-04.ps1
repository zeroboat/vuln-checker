function Check-W_04 {
    Print-SecurityCheck -Code "W-04"
    try {
        $policy = Get-SecurityPolicy
        $threshold = Get-SecurityPolicySetting -PolicyContent $policy -Setting "LockoutBadCount"
        if ($null -eq $threshold -or [int]$threshold -eq 0) {
            Record-CheckResult -Code "W-04" -Status "FAIL" -Detail "계정 잠금 임계값이 설정되지 않음 (현재: 제한없음)"
        } elseif ([int]$threshold -le 5) {
            Record-CheckResult -Code "W-04" -Status "PASS" -Detail "계정 잠금 임계값이 적절히 설정됨 (현재: $threshold 회)"
        } else {
            Record-CheckResult -Code "W-04" -Status "FAIL" -Detail "계정 잠금 임계값이 너무 높음 (현재: $threshold 회, 권장: 5회 이하)"
        }
    } catch {
        Record-CheckResult -Code "W-04" -Status "REVIEW" -Detail "계정 잠금 정책을 확인할 수 없음: $_"
    }
}
