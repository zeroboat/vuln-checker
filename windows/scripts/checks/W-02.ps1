function Check-W_02 {
    Print-SecurityCheck -Code "W-02"
    try {
        $guest = Get-LocalUser | Where-Object { $_.SID -like "*-501" }
        if ($guest.Enabled -eq $false) {
            Record-CheckResult -Code "W-02" -Status "PASS" -Detail "Guest 계정이 비활성화됨"
        } else {
            Record-CheckResult -Code "W-02" -Status "FAIL" -Detail "Guest 계정이 활성화되어 있음"
        }
    } catch {
        Record-CheckResult -Code "W-02" -Status "REVIEW" -Detail "Guest 계정 상태를 확인할 수 없음: $_"
    }
}
