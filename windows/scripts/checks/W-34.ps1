function Check-W_34 {
    Print-SecurityCheck -Code "W-34"
    try {
        $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
        $val = Get-ItemProperty -Path $regPath -Name "ShutdownWithoutLogon" -ErrorAction Stop
        if ($val.ShutdownWithoutLogon -eq 0) {
            Record-CheckResult -Code "W-34" -Status "PASS" -Detail "로그인하지 않고 시스템 종료가 해제됨"
        } else {
            Record-CheckResult -Code "W-34" -Status "FAIL" -Detail "로그인하지 않고 시스템 종료가 허용됨"
        }
    } catch {
        Record-CheckResult -Code "W-34" -Status "REVIEW" -Detail "레지스트리 설정을 확인할 수 없음: $_"
    }
}
