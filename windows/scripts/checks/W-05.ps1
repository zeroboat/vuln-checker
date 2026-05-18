function Check-W_05 {
    Print-SecurityCheck -Code "W-05"
    try {
        $policy = Get-SecurityPolicy
        $clearText = Get-SecurityPolicySetting -PolicyContent $policy -Setting "ClearTextPassword"
        if ($null -eq $clearText -or $clearText -eq "0") {
            Record-CheckResult -Code "W-05" -Status "PASS" -Detail "해독 가능한 암호화로 암호 저장이 해제됨"
        } else {
            Record-CheckResult -Code "W-05" -Status "FAIL" -Detail "해독 가능한 암호화로 암호 저장이 활성화됨 (현재: $clearText)"
        }
    } catch {
        Record-CheckResult -Code "W-05" -Status "REVIEW" -Detail "암호 저장 정책을 확인할 수 없음: $_"
    }
}
