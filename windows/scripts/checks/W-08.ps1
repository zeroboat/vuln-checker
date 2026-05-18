function Check-W_08 {
    Print-SecurityCheck -Code "W-08"
    try {
        $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
        $val = Get-ItemProperty -Path $regPath -Name "DontDisplayLastUserName" -ErrorAction Stop
        if ($val.DontDisplayLastUserName -eq 1) {
            Record-CheckResult -Code "W-08" -Status "PASS" -Detail "마지막 로그온 사용자 이름이 표시되지 않음"
        } else {
            Record-CheckResult -Code "W-08" -Status "FAIL" -Detail "마지막 로그온 사용자 이름이 표시됨"
        }
    } catch {
        Record-CheckResult -Code "W-08" -Status "REVIEW" -Detail "레지스트리 설정을 확인할 수 없음: $_"
    }
}
