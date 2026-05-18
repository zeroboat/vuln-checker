function Check-W_65 {
    Print-SecurityCheck -Code "W-65"
    $telnetSvc = Get-Service -Name "TlntSvr" -ErrorAction SilentlyContinue
    if ($null -eq $telnetSvc) {
        Record-CheckResult -Code "W-65" -Status "PASS" -Detail "Telnet 서비스가 설치되어 있지 않음"
    } elseif ($telnetSvc.Status -eq "Running") {
        Record-CheckResult -Code "W-65" -Status "FAIL" -Detail "Telnet 서비스가 실행 중 (보안 위험)"
    } else {
        Record-CheckResult -Code "W-65" -Status "PASS" -Detail "Telnet 서비스가 중지 상태임"
    }
}
