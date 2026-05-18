function Check-W_28 {
    Print-SecurityCheck -Code "W-28"
    $ftpSvc = Get-Service -Name "FTPSVC" -ErrorAction SilentlyContinue
    if ($null -eq $ftpSvc -or $ftpSvc.Status -ne "Running") {
        Record-CheckResult -Code "W-28" -Status "PASS" -Detail "FTP 서비스가 실행되고 있지 않음"
        return
    }
    try {
        Import-Module WebAdministration -ErrorAction Stop
        $ipSecurity = Get-WebConfiguration -Filter /system.ftpServer/security/ipSecurity -PSPath "IIS:\" -ErrorAction SilentlyContinue
        if ($null -ne $ipSecurity -and $ipSecurity.Collection.Count -gt 0) {
            Record-CheckResult -Code "W-28" -Status "PASS" -Detail "FTP IP 접근 제어가 설정됨 ($($ipSecurity.Collection.Count)개 규칙)"
        } else {
            Record-CheckResult -Code "W-28" -Status "FAIL" -Detail "FTP IP 접근 제어가 설정되어 있지 않음"
        }
    } catch {
        Record-CheckResult -Code "W-28" -Status "REVIEW" -Detail "FTP 접근 제어를 확인할 수 없음: $_"
    }
}
