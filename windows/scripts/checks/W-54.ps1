function Check-W_54 {
    Print-SecurityCheck -Code "W-54"
    try {
        $rdpGroup = Get-LocalGroupMember -Group "Remote Desktop Users" -ErrorAction Stop
        if ($rdpGroup.Count -eq 0) {
            Record-CheckResult -Code "W-54" -Status "PASS" -Detail "Remote Desktop Users 그룹에 구성원이 없음"
        } else {
            $names = $rdpGroup | ForEach-Object { $_.Name }
            Record-CheckResult -Code "W-54" -Status "REVIEW" -Detail "RDP 접속 허용 사용자 ($($rdpGroup.Count)명): $($names -join ', ')"
        }
    } catch {
        Record-CheckResult -Code "W-54" -Status "PASS" -Detail "Remote Desktop Users 그룹이 없음"
    }
}
