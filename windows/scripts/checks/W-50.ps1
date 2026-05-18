function Check-W_50 {
    Print-SecurityCheck -Code "W-50"
    try {
        $policy = Get-SecurityPolicy
        $minAge = Get-SecurityPolicySetting -PolicyContent $policy -Setting "MinimumPasswordAge"
        if ($null -eq $minAge) {
            Record-CheckResult -Code "W-50" -Status "FAIL" -Detail "최소 비밀번호 사용 기간이 설정되지 않음"
        } elseif ([int]$minAge -ge 1) {
            Record-CheckResult -Code "W-50" -Status "PASS" -Detail "최소 비밀번호 사용 기간이 적절함 (현재: ${minAge}일)"
        } else {
            Record-CheckResult -Code "W-50" -Status "FAIL" -Detail "최소 비밀번호 사용 기간이 0일 (권장: 1일 이상)"
        }
    } catch {
        Record-CheckResult -Code "W-50" -Status "REVIEW" -Detail "비밀번호 정책을 확인할 수 없음: $_"
    }
}
