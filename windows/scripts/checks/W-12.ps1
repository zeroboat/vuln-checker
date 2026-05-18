function Check-W_12 {
    Print-SecurityCheck -Code "W-12"
    $iisSvc = Get-Service -Name "W3SVC" -ErrorAction SilentlyContinue
    if ($null -eq $iisSvc) {
        Record-CheckResult -Code "W-12" -Status "PASS" -Detail "IIS 미설치"
        return
    }
    try {
        Import-Module WebAdministration -ErrorAction Stop
        $cgiRestrictions = Get-WebConfiguration -Filter /system.webServer/security/isapiCgiRestriction -PSPath "IIS:\" -ErrorAction Stop
        $notAllowed = $cgiRestrictions.Collection | Where-Object { $_.allowed -eq $true }
        if ($null -eq $notAllowed -or $notAllowed.Count -eq 0) {
            Record-CheckResult -Code "W-12" -Status "PASS" -Detail "CGI 실행이 제한됨"
        } else {
            $paths = $notAllowed | ForEach-Object { $_.path }
            Record-CheckResult -Code "W-12" -Status "REVIEW" -Detail "허용된 CGI/ISAPI: $($paths -join ', ')"
        }
    } catch {
        Record-CheckResult -Code "W-12" -Status "REVIEW" -Detail "IIS CGI 설정을 확인할 수 없음: $_"
    }
}
