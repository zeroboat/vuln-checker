function Check-W_25 {
    Print-SecurityCheck -Code "W-25"
    $ftpSvc = Get-Service -Name "FTPSVC" -ErrorAction SilentlyContinue
    if ($null -eq $ftpSvc) {
        Record-CheckResult -Code "W-25" -Status "PASS" -Detail "FTP 서비스가 설치되어 있지 않음"
    } elseif ($ftpSvc.Status -eq "Running") {
        Record-CheckResult -Code "W-25" -Status "FAIL" -Detail "FTP 서비스가 실행 중 (불필요 시 중지 필요)"
    } else {
        Record-CheckResult -Code "W-25" -Status "PASS" -Detail "FTP 서비스가 중지 상태임 ($($ftpSvc.Status))"
    }
}
