function Check-W_48 {
    Print-SecurityCheck -Code "W-48"
    try {
        $policy = Get-SecurityPolicy
        $complexity = Get-SecurityPolicySetting -PolicyContent $policy -Setting "PasswordComplexity"
        if ($complexity -eq "1") {
            Record-CheckResult -Code "W-48" -Status "PASS" -Detail "비밀번호 복잡성 정책이 활성화됨"
        } else {
            Record-CheckResult -Code "W-48" -Status "FAIL" -Detail "비밀번호 복잡성 정책이 비활성화됨 (현재: $complexity)"
        }
    } catch {
        Record-CheckResult -Code "W-48" -Status "REVIEW" -Detail "비밀번호 복잡성 정책을 확인할 수 없음: $_"
    }
}
