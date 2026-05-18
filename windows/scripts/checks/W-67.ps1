function Check-W_67 {
    Print-SecurityCheck -Code "W-67"
    $svc = Get-Service -Name "RemoteRegistry" -ErrorAction SilentlyContinue
    if ($null -eq $svc) {
        Record-CheckResult -Code "W-67" -Status "PASS" -Detail "원격 레지스트리 서비스가 설치되어 있지 않음"
    } elseif ($svc.Status -eq "Running") {
        Record-CheckResult -Code "W-67" -Status "FAIL" -Detail "원격 레지스트리 서비스가 실행 중"
    } elseif ($svc.StartType -eq "Disabled") {
        Record-CheckResult -Code "W-67" -Status "PASS" -Detail "원격 레지스트리 서비스가 비활성화됨"
    } else {
        Record-CheckResult -Code "W-67" -Status "FAIL" -Detail "원격 레지스트리 서비스가 중지 상태이나 시작 유형이 '$($svc.StartType)'임 (권장: Disabled)"
    }
}
