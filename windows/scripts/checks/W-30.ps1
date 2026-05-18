function Check-W_30 {
    Print-SecurityCheck -Code "W-30"
    $dnsSvc = Get-Service -Name "DNS" -ErrorAction SilentlyContinue
    if ($null -eq $dnsSvc) {
        Record-CheckResult -Code "W-30" -Status "PASS" -Detail "DNS 서비스가 설치되어 있지 않음"
    } elseif ($dnsSvc.Status -eq "Running") {
        Record-CheckResult -Code "W-30" -Status "REVIEW" -Detail "DNS 서비스가 실행 중 (필요 여부 확인 필요)"
    } else {
        Record-CheckResult -Code "W-30" -Status "PASS" -Detail "DNS 서비스가 중지 상태임"
    }
}
