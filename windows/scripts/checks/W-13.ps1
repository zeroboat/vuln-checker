function Check-W_13 {
    Print-SecurityCheck -Code "W-13"
    $iisSvc = Get-Service -Name "W3SVC" -ErrorAction SilentlyContinue
    if ($null -eq $iisSvc) {
        Record-CheckResult -Code "W-13" -Status "PASS" -Detail "IIS 미설치"
        return
    }
    try {
        Import-Module WebAdministration -ErrorAction Stop
        $sites = Get-Website -ErrorAction Stop
        $issues = @()
        foreach ($site in $sites) {
            $enableParentPaths = Get-WebConfigurationProperty -Filter /system.webServer/asp -PSPath "IIS:\Sites\$($site.Name)" -Name "enableParentPaths" -ErrorAction SilentlyContinue
            if ($enableParentPaths.Value -eq $true) {
                $issues += $site.Name
            }
        }
        if ($issues.Count -eq 0) {
            Record-CheckResult -Code "W-13" -Status "PASS" -Detail "모든 사이트에서 상위 디렉터리 접근이 금지됨"
        } else {
            Record-CheckResult -Code "W-13" -Status "FAIL" -Detail "상위 디렉터리 접근 허용 사이트: $($issues -join ', ')"
        }
    } catch {
        Record-CheckResult -Code "W-13" -Status "REVIEW" -Detail "IIS 설정을 확인할 수 없음: $_"
    }
}
