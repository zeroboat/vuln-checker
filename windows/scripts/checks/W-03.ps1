function Check-W_03 {
    Print-SecurityCheck -Code "W-03"
    try {
        $defaultUnnecessary = @("DefaultAccount", "WDAGUtilityAccount")
        $found = @()
        $users = Get-LocalUser | Where-Object { $_.Enabled -eq $true }
        foreach ($u in $users) {
            if ($defaultUnnecessary -contains $u.Name) {
                $found += $u.Name
            }
            # 90일 이상 로그인하지 않은 활성 계정
            if ($u.LastLogon -and $u.LastLogon -lt (Get-Date).AddDays(-90)) {
                $found += "$($u.Name)(마지막 로그인: $($u.LastLogon.ToString('yyyy-MM-dd')))"
            }
        }
        if ($found.Count -eq 0) {
            Record-CheckResult -Code "W-03" -Status "PASS" -Detail "불필요한 활성 계정이 없음"
        } else {
            Record-CheckResult -Code "W-03" -Status "FAIL" -Detail "확인 필요 계정: $($found -join ', ')"
        }
    } catch {
        Record-CheckResult -Code "W-03" -Status "REVIEW" -Detail "계정 목록을 확인할 수 없음: $_"
    }
}
