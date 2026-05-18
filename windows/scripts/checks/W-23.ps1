function Check-W_23 {
    Print-SecurityCheck -Code "W-23"
    $iisSvc = Get-Service -Name "W3SVC" -ErrorAction SilentlyContinue
    if ($null -eq $iisSvc) {
        Record-CheckResult -Code "W-23" -Status "PASS" -Detail "IIS 미설치"
        return
    }
    try {
        Import-Module WebAdministration -ErrorAction Stop
        $customHeaders = Get-WebConfigurationProperty -Filter /system.webServer/httpProtocol/customHeaders -PSPath "IIS:\" -Name "." -ErrorAction SilentlyContinue
        $xpb = $customHeaders.Collection | Where-Object { $_.name -eq "X-Powered-By" }
        $removeServer = Get-WebConfigurationProperty -Filter /system.webServer/security/requestFiltering -PSPath "IIS:\" -Name removeServerHeader -ErrorAction SilentlyContinue
        $issues = @()
        if ($xpb) { $issues += "X-Powered-By header exposed" }
        if ($removeServer.Value -ne $true) { $issues += "Server header exposed" }
        if ($issues.Count -eq 0) {
            Record-CheckResult -Code "W-23" -Status "PASS" -Detail "IIS 서버 정보 헤더가 제거됨"
        } else {
            Record-CheckResult -Code "W-23" -Status "FAIL" -Detail ($issues -join "; ")
        }
    } catch {
        Record-CheckResult -Code "W-23" -Status "REVIEW" -Detail "IIS 헤더 설정을 확인할 수 없음: $_"
    }
}
