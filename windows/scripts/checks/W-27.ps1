function Check-W_27 {
    Print-SecurityCheck -Code "W-27"
    $ftpSvc = Get-Service -Name "FTPSVC" -ErrorAction SilentlyContinue
    if ($null -eq $ftpSvc -or $ftpSvc.Status -ne "Running") {
        Record-CheckResult -Code "W-27" -Status "PASS" -Detail "FTP 서비스가 실행되고 있지 않음"
        return
    }
    try {
        Import-Module WebAdministration -ErrorAction Stop
        $ftpSites = Get-WebConfiguration -Filter /system.applicationHost/sites/site -PSPath "IIS:\" -ErrorAction Stop |
            Where-Object { $_.bindings.Collection.protocol -contains "ftp" }
        $issues = @()
        foreach ($site in $ftpSites) {
            $anonAuth = Get-WebConfigurationProperty -Filter /system.ftpServer/security/authentication/anonymousAuthentication -PSPath "IIS:\Sites\$($site.name)" -Name enabled -ErrorAction SilentlyContinue
            if ($anonAuth.Value -eq $true) {
                $issues += $site.name
            }
        }
        if ($issues.Count -eq 0) {
            Record-CheckResult -Code "W-27" -Status "PASS" -Detail "FTP 익명 접속이 차단됨"
        } else {
            Record-CheckResult -Code "W-27" -Status "FAIL" -Detail "FTP 익명 접속 허용 사이트: $($issues -join ', ')"
        }
    } catch {
        Record-CheckResult -Code "W-27" -Status "REVIEW" -Detail "FTP 인증 설정을 확인할 수 없음: $_"
    }
}
