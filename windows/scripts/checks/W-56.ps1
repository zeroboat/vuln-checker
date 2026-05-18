function Check-W_56 {
    Print-SecurityCheck -Code "W-56"
    $iisSvc = Get-Service -Name "W3SVC" -ErrorAction SilentlyContinue
    if ($null -eq $iisSvc) {
        Record-CheckResult -Code "W-56" -Status "PASS" -Detail "IIS 미설치"
        return
    }
    try {
        Import-Module WebAdministration -ErrorAction Stop
        $errorMode = Get-WebConfigurationProperty -Filter /system.webServer/httpErrors -PSPath "IIS:\" -Name errorMode -ErrorAction SilentlyContinue
        if ($errorMode -eq "Custom" -or $errorMode -eq "DetailedLocalOnly") {
            Record-CheckResult -Code "W-56" -Status "PASS" -Detail "IIS 에러 페이지가 사용자 정의됨 (모드: $errorMode)"
        } else {
            Record-CheckResult -Code "W-56" -Status "FAIL" -Detail "IIS 상세 오류 정보가 노출될 수 있음 (모드: $errorMode)"
        }
    } catch {
        Record-CheckResult -Code "W-56" -Status "REVIEW" -Detail "IIS 에러 설정을 확인할 수 없음: $_"
    }
}
