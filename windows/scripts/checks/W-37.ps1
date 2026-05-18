function Check-W_37 {
    Print-SecurityCheck -Code "W-37"
    try {
        $policy = Get-SecurityPolicy
        $val = Get-SecurityPolicySetting -PolicyContent $policy -Setting "ShutdownWithoutLogon"
        if ($val -eq "0") {
            Record-CheckResult -Code "W-37" -Status "PASS" -Detail "보안 정책에서 로그온 없이 종료가 해제됨"
        } elseif ($null -eq $val) {
            Record-CheckResult -Code "W-37" -Status "REVIEW" -Detail "보안 정책 설정을 찾을 수 없음"
        } else {
            Record-CheckResult -Code "W-37" -Status "FAIL" -Detail "로그온 없이 시스템 종료가 허용됨"
        }
    } catch {
        Record-CheckResult -Code "W-37" -Status "REVIEW" -Detail "보안 정책을 확인할 수 없음: $_"
    }
}
