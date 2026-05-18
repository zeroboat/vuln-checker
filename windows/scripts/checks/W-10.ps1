function Check-W_10 {
    Print-SecurityCheck -Code "W-10"
    $iisSvc = Get-Service -Name "W3SVC" -ErrorAction SilentlyContinue
    if ($null -eq $iisSvc) {
        Record-CheckResult -Code "W-10" -Status "PASS" -Detail "IIS 서비스가 설치되어 있지 않음"
    } elseif ($iisSvc.Status -eq "Running") {
        Record-CheckResult -Code "W-10" -Status "REVIEW" -Detail "IIS 서비스가 실행 중 (필요 여부 확인 필요)"
    } else {
        Record-CheckResult -Code "W-10" -Status "PASS" -Detail "IIS 서비스가 중지 상태임"
    }
}
