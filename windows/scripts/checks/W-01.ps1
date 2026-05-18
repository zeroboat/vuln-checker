function Check-W_01 {
    Print-SecurityCheck -Code "W-01"
    try {
        $admin = Get-LocalUser | Where-Object { $_.SID -like "*-500" }
        if ($admin.Name -ne "Administrator") {
            Record-CheckResult -Code "W-01" -Status "PASS" -Detail "관리자 계정명이 변경됨: $($admin.Name)"
        } else {
            Record-CheckResult -Code "W-01" -Status "FAIL" -Detail "관리자 계정명이 기본값(Administrator) 사용 중"
        }
    } catch {
        Record-CheckResult -Code "W-01" -Status "REVIEW" -Detail "계정 정보를 확인할 수 없음: $_"
    }
}
