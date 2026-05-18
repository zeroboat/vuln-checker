function Check-W_42 {
    Print-SecurityCheck -Code "W-42"
    try {
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
        $val = Get-ItemProperty -Path $regPath -Name "RestrictAnonymousSAM" -ErrorAction Stop
        if ($val.RestrictAnonymousSAM -eq 1) {
            Record-CheckResult -Code "W-42" -Status "PASS" -Detail "SAM 계정의 익명 열거가 차단됨"
        } else {
            Record-CheckResult -Code "W-42" -Status "FAIL" -Detail "SAM 계정의 익명 열거가 허용됨"
        }
    } catch {
        Record-CheckResult -Code "W-42" -Status "REVIEW" -Detail "SAM 익명 열거 설정을 확인할 수 없음: $_"
    }
}
