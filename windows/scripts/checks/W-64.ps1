function Check-W_64 {
    Print-SecurityCheck -Code "W-64"
    $issues = @()
    $smtpSvc = Get-Service -Name "SMTPSVC" -ErrorAction SilentlyContinue
    if ($smtpSvc -and $smtpSvc.Status -eq "Running") {
        $issues += "SMTP 서비스 실행 중 (배너 확인 필요)"
    }
    $ftpSvc = Get-Service -Name "FTPSVC" -ErrorAction SilentlyContinue
    if ($ftpSvc -and $ftpSvc.Status -eq "Running") {
        try {
            Import-Module WebAdministration -ErrorAction Stop
            $banner = Get-WebConfigurationProperty -Filter /system.ftpServer/security/customBanner -PSPath "IIS:\" -Name "." -ErrorAction SilentlyContinue
            if ($null -eq $banner) {
                $issues += "FTP 배너가 사용자 정의되지 않음"
            }
        } catch {
            $issues += "FTP 배너 설정 확인 불가"
        }
    }
    $iisSvc = Get-Service -Name "W3SVC" -ErrorAction SilentlyContinue
    if ($iisSvc -and $iisSvc.Status -eq "Running") {
        $issues += "IIS 실행 중 (W-23에서 상세 점검)"
    }
    if ($issues.Count -eq 0) {
        Record-CheckResult -Code "W-64" -Status "PASS" -Detail "HTTP/FTP/SMTP 서비스가 실행되고 있지 않음"
    } else {
        Record-CheckResult -Code "W-64" -Status "REVIEW" -Detail ($issues -join "; ")
    }
}
