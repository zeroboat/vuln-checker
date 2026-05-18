function Check-W_52 {
    Print-SecurityCheck -Code "W-52"
    try {
        $policy = Get-SecurityPolicy
        $history = Get-SecurityPolicySetting -PolicyContent $policy -Setting "PasswordHistorySize"
        if ($null -eq $history -or [int]$history -lt 12) {
            $val = if ($history) { $history } else { "0" }
            Record-CheckResult -Code "W-52" -Status "FAIL" -Detail "비밀번호 기억 수가 부족함 (현재: ${val}개, 권장: 12개 이상)"
        } else {
            Record-CheckResult -Code "W-52" -Status "PASS" -Detail "비밀번호 기억 수가 적절함 (현재: ${history}개)"
        }
    } catch {
        Record-CheckResult -Code "W-52" -Status "REVIEW" -Detail "비밀번호 정책을 확인할 수 없음: $_"
    }
}
