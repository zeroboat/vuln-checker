function Check-W_51 {
    Print-SecurityCheck -Code "W-51"
    try {
        $policy = Get-SecurityPolicy
        $maxAge = Get-SecurityPolicySetting -PolicyContent $policy -Setting "MaximumPasswordAge"
        if ($null -eq $maxAge) {
            Record-CheckResult -Code "W-51" -Status "FAIL" -Detail "최대 비밀번호 사용 기간이 설정되지 않음"
        } elseif ([int]$maxAge -ge 1 -and [int]$maxAge -le 90) {
            Record-CheckResult -Code "W-51" -Status "PASS" -Detail "최대 비밀번호 사용 기간이 적절함 (현재: ${maxAge}일)"
        } elseif ([int]$maxAge -eq 0) {
            Record-CheckResult -Code "W-51" -Status "FAIL" -Detail "비밀번호 만료가 설정되지 않음 (무제한)"
        } else {
            Record-CheckResult -Code "W-51" -Status "FAIL" -Detail "최대 비밀번호 사용 기간이 너무 김 (현재: ${maxAge}일, 권장: 90일 이하)"
        }
    } catch {
        Record-CheckResult -Code "W-51" -Status "REVIEW" -Detail "비밀번호 정책을 확인할 수 없음: $_"
    }
}
