function Check-W_41 {
    Print-SecurityCheck -Code "W-41"
    try {
        $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
        $val = Get-ItemProperty -Path $regPath -Name "AllocateDASD" -ErrorAction Stop
        if ($val.AllocateDASD -eq "0") {
            Record-CheckResult -Code "W-41" -Status "PASS" -Detail "이동식 미디어 포맷이 관리자만 허용됨"
        } else {
            Record-CheckResult -Code "W-41" -Status "FAIL" -Detail "이동식 미디어 포맷 허용 범위: $($val.AllocateDASD) (0=관리자만, 1=관리자+고급사용자, 2=관리자+대화형사용자)"
        }
    } catch {
        Record-CheckResult -Code "W-41" -Status "REVIEW" -Detail "이동식 미디어 설정을 확인할 수 없음: $_"
    }
}
