function Check-W_53 {
    Print-SecurityCheck -Code "W-53"
    try {
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
        $val = Get-ItemProperty -Path $regPath -Name "LimitBlankPasswordUse" -ErrorAction Stop
        if ($val.LimitBlankPasswordUse -eq 1) {
            Record-CheckResult -Code "W-53" -Status "PASS" -Detail "빈 비밀번호 사용이 제한됨"
        } else {
            Record-CheckResult -Code "W-53" -Status "FAIL" -Detail "빈 비밀번호로 콘솔 로그온이 허용됨"
        }
    } catch {
        Record-CheckResult -Code "W-53" -Status "REVIEW" -Detail "레지스트리 설정을 확인할 수 없음: $_"
    }
}
