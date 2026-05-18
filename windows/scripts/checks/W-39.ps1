function Check-W_39 {
    Print-SecurityCheck -Code "W-39"
    try {
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
        $val = Get-ItemProperty -Path $regPath -Name "CrashOnAuditFail" -ErrorAction Stop
        if ($val.CrashOnAuditFail -eq 1) {
            Record-CheckResult -Code "W-39" -Status "PASS" -Detail "감사 로그 실패 시 시스템 종료가 설정됨"
        } else {
            Record-CheckResult -Code "W-39" -Status "FAIL" -Detail "감사 로그 실패 시 시스템 종료가 해제됨"
        }
    } catch {
        Record-CheckResult -Code "W-39" -Status "REVIEW" -Detail "감사 로그 설정을 확인할 수 없음: $_"
    }
}
