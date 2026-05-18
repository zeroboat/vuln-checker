function Check-W_49 {
    Print-SecurityCheck -Code "W-49"
    try {
        $policy = Get-SecurityPolicy
        $minLen = Get-SecurityPolicySetting -PolicyContent $policy -Setting "MinimumPasswordLength"
        if ($null -eq $minLen -or [int]$minLen -lt 8) {
            Record-CheckResult -Code "W-49" -Status "FAIL" -Detail "최소 비밀번호 길이가 부족함 (현재: $(if ($minLen) { $minLen } else { '0' })자, 권장: 8자 이상)"
        } else {
            Record-CheckResult -Code "W-49" -Status "PASS" -Detail "최소 비밀번호 길이가 적절함 (현재: ${minLen}자)"
        }
    } catch {
        Record-CheckResult -Code "W-49" -Status "REVIEW" -Detail "비밀번호 길이 정책을 확인할 수 없음: $_"
    }
}
