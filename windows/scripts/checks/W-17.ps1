function Check-W_17 {
    Print-SecurityCheck -Code "W-17"
    $iisSvc = Get-Service -Name "W3SVC" -ErrorAction SilentlyContinue
    if ($null -eq $iisSvc) {
        Record-CheckResult -Code "W-17" -Status "PASS" -Detail "IIS 미설치"
        return
    }
    try {
        Import-Module WebAdministration -ErrorAction Stop
        $maxAllowed = Get-WebConfigurationProperty -Filter /system.webServer/security/requestFiltering/requestLimits -PSPath "IIS:\" -Name maxAllowedContentLength -ErrorAction SilentlyContinue
        $limitMB = [math]::Round($maxAllowed.Value / 1MB, 1)
        if ($maxAllowed.Value -le 50MB) {
            Record-CheckResult -Code "W-17" -Status "PASS" -Detail "파일 업로드 제한 설정됨 (최대: ${limitMB}MB)"
        } else {
            Record-CheckResult -Code "W-17" -Status "FAIL" -Detail "파일 업로드 제한이 너무 큼 (현재: ${limitMB}MB, 권장: 50MB 이하)"
        }
    } catch {
        Record-CheckResult -Code "W-17" -Status "REVIEW" -Detail "IIS 업로드 설정을 확인할 수 없음: $_"
    }
}
