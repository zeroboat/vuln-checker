function Check-W_38 {
    Print-SecurityCheck -Code "W-38"
    try {
        $policy = Get-SecurityPolicy
        $val = Get-SecurityPolicySetting -PolicyContent $policy -Setting "SeRemoteShutdownPrivilege"
        if ($null -eq $val) {
            Record-CheckResult -Code "W-38" -Status "PASS" -Detail "원격 종료 권한이 설정되지 않음"
        } elseif ($val -match "Administrators" -and $val -notmatch "Everyone|Users|Guests") {
            Record-CheckResult -Code "W-38" -Status "PASS" -Detail "원격 종료 권한이 관리자로 제한됨"
        } else {
            Record-CheckResult -Code "W-38" -Status "FAIL" -Detail "원격 종료 권한이 과다 부여됨: $val"
        }
    } catch {
        Record-CheckResult -Code "W-38" -Status "REVIEW" -Detail "원격 종료 권한을 확인할 수 없음: $_"
    }
}
