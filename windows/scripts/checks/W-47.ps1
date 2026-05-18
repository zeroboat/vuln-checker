function Check-W_47 {
    Print-SecurityCheck -Code "W-47"
    try {
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters"
        $val = Get-ItemProperty -Path $regPath -Name "RestrictNullSessAccess" -ErrorAction Stop
        if ($val.RestrictNullSessAccess -eq 1) {
            Record-CheckResult -Code "W-47" -Status "PASS" -Detail "널 세션 접근이 제한됨"
        } else {
            Record-CheckResult -Code "W-47" -Status "FAIL" -Detail "널 세션을 통한 공유 접근이 허용됨"
        }
    } catch {
        Record-CheckResult -Code "W-47" -Status "REVIEW" -Detail "널 세션 설정을 확인할 수 없음: $_"
    }
}
