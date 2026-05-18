function Check-W_32 {
    Print-SecurityCheck -Code "W-32"
    try {
        $hotfixes = Get-HotFix -ErrorAction Stop | Sort-Object InstalledOn -Descending -ErrorAction SilentlyContinue
        if ($hotfixes.Count -eq 0) {
            Record-CheckResult -Code "W-32" -Status "FAIL" -Detail "설치된 핫픽스를 찾을 수 없음"
            return
        }
        $latest = $hotfixes | Select-Object -First 1
        $daysSince = if ($latest.InstalledOn) { ((Get-Date) - $latest.InstalledOn).Days } else { 999 }
        if ($daysSince -le 90) {
            Record-CheckResult -Code "W-32" -Status "PASS" -Detail "최근 핫픽스 적용됨: $($latest.HotFixID) ($($latest.InstalledOn.ToString('yyyy-MM-dd')), ${daysSince}일 전)"
        } else {
            Record-CheckResult -Code "W-32" -Status "FAIL" -Detail "마지막 핫픽스가 오래됨: $($latest.HotFixID) (${daysSince}일 전, 권장: 90일 이내)"
        }
    } catch {
        Record-CheckResult -Code "W-32" -Status "REVIEW" -Detail "핫픽스 정보를 확인할 수 없음: $_"
    }
}
