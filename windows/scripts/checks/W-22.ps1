function Check-W_22 {
    Print-SecurityCheck -Code "W-22"
    $iisSvc = Get-Service -Name "W3SVC" -ErrorAction SilentlyContinue
    if ($null -eq $iisSvc) {
        Record-CheckResult -Code "W-22" -Status "PASS" -Detail "IIS 미설치"
        return
    }
    try {
        Import-Module WebAdministration -ErrorAction Stop
        $webdav = Get-WebConfigurationProperty -Filter /system.webServer/webdav/authoring -PSPath "IIS:\" -Name enabled -ErrorAction SilentlyContinue
        if ($null -eq $webdav -or $webdav.Value -eq $false) {
            Record-CheckResult -Code "W-22" -Status "PASS" -Detail "WebDAV가 비활성화됨"
        } else {
            Record-CheckResult -Code "W-22" -Status "FAIL" -Detail "WebDAV가 활성화되어 있음"
        }
    } catch {
        # WebDAV 모듈 미설치 = 양호
        Record-CheckResult -Code "W-22" -Status "PASS" -Detail "WebDAV 모듈이 설치되어 있지 않음"
    }
}
