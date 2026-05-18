function Check-W_07 {
    Print-SecurityCheck -Code "W-07"
    try {
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
        $val = Get-ItemProperty -Path $regPath -Name "EveryoneIncludesAnonymous" -ErrorAction Stop
        if ($val.EveryoneIncludesAnonymous -eq 0) {
            Record-CheckResult -Code "W-07" -Status "PASS" -Detail "Everyone 그룹에 익명 사용자 미포함"
        } else {
            Record-CheckResult -Code "W-07" -Status "FAIL" -Detail "Everyone 그룹에 익명 사용자가 포함되어 있음"
        }
    } catch {
        Record-CheckResult -Code "W-07" -Status "REVIEW" -Detail "레지스트리 설정을 확인할 수 없음: $_"
    }
}
