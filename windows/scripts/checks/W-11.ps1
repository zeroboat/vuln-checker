function Check-W_11 {
    Print-SecurityCheck -Code "W-11"
    $iisSvc = Get-Service -Name "W3SVC" -ErrorAction SilentlyContinue
    if ($null -eq $iisSvc) {
        Record-CheckResult -Code "W-11" -Status "PASS" -Detail "IIS 미설치"
        return
    }
    try {
        Import-Module WebAdministration -ErrorAction Stop
        $sites = Get-Website -ErrorAction Stop
        $issues = @()
        foreach ($site in $sites) {
            $dirBrowse = Get-WebConfigurationProperty -Filter /system.webServer/directoryBrowse -PSPath "IIS:\Sites\$($site.Name)" -Name enabled -ErrorAction SilentlyContinue
            if ($dirBrowse.Value -eq $true) {
                $issues += $site.Name
            }
        }
        if ($issues.Count -eq 0) {
            Record-CheckResult -Code "W-11" -Status "PASS" -Detail "모든 사이트에서 디렉터리 리스팅이 비활성화됨"
        } else {
            Record-CheckResult -Code "W-11" -Status "FAIL" -Detail "디렉터리 리스팅 활성화 사이트: $($issues -join ', ')"
        }
    } catch {
        Record-CheckResult -Code "W-11" -Status "REVIEW" -Detail "IIS 설정을 확인할 수 없음: $_"
    }
}
