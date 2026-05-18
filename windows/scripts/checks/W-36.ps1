function Check-W_36 {
    Print-SecurityCheck -Code "W-36"
    try {
        $ssActive = Get-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "ScreenSaveActive" -ErrorAction SilentlyContinue
        $ssSecure = Get-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "ScreenSaverIsSecure" -ErrorAction SilentlyContinue
        $ssTimeout = Get-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "ScreenSaveTimeOut" -ErrorAction SilentlyContinue

        $isActive = $ssActive.ScreenSaveActive -eq "1"
        $isSecure = $ssSecure.ScreenSaverIsSecure -eq "1"
        $timeout = if ($ssTimeout) { [int]$ssTimeout.ScreenSaveTimeOut } else { 0 }

        if ($isActive -and $isSecure -and $timeout -gt 0 -and $timeout -le 600) {
            Record-CheckResult -Code "W-36" -Status "PASS" -Detail "화면보호기가 적절히 설정됨 (대기시간: ${timeout}초, 암호보호: 예)"
        } elseif (-not $isActive) {
            Record-CheckResult -Code "W-36" -Status "FAIL" -Detail "화면보호기가 비활성화됨"
        } elseif (-not $isSecure) {
            Record-CheckResult -Code "W-36" -Status "FAIL" -Detail "화면보호기 암호 보호가 비활성화됨"
        } else {
            Record-CheckResult -Code "W-36" -Status "FAIL" -Detail "화면보호기 대기시간이 부적절 (현재: ${timeout}초, 권장: 600초 이하)"
        }
    } catch {
        Record-CheckResult -Code "W-36" -Status "REVIEW" -Detail "화면보호기 설정을 확인할 수 없음: $_"
    }
}
