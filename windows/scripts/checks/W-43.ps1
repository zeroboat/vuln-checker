function Check-W_43 {
    Print-SecurityCheck -Code "W-43"
    try {
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
        $val = Get-ItemProperty -Path $regPath -Name "RestrictAnonymous" -ErrorAction Stop
        if ($val.RestrictAnonymous -ge 1) {
            Record-CheckResult -Code "W-43" -Status "PASS" -Detail "공유 및 명명된 파이프의 익명 열거가 차단됨 (값: $($val.RestrictAnonymous))"
        } else {
            Record-CheckResult -Code "W-43" -Status "FAIL" -Detail "공유의 익명 열거가 허용됨"
        }
    } catch {
        Record-CheckResult -Code "W-43" -Status "REVIEW" -Detail "익명 열거 설정을 확인할 수 없음: $_"
    }
}
