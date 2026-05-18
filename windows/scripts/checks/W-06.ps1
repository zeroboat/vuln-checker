function Check-W_06 {
    Print-SecurityCheck -Code "W-06"
    try {
        $members = Get-LocalGroupMember -Group "Administrators" -ErrorAction Stop
        $memberNames = $members | ForEach-Object { $_.Name }
        if ($members.Count -le 2) {
            Record-CheckResult -Code "W-06" -Status "PASS" -Detail "관리자 그룹 구성원 수가 적절함 ($($members.Count)명): $($memberNames -join ', ')"
        } else {
            Record-CheckResult -Code "W-06" -Status "FAIL" -Detail "관리자 그룹에 과다한 사용자 포함 ($($members.Count)명): $($memberNames -join ', ')"
        }
    } catch {
        Record-CheckResult -Code "W-06" -Status "REVIEW" -Detail "관리자 그룹을 확인할 수 없음: $_"
    }
}
