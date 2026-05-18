function Check-W_15 {
    Print-SecurityCheck -Code "W-15"
    $iisSvc = Get-Service -Name "W3SVC" -ErrorAction SilentlyContinue
    if ($null -eq $iisSvc) {
        Record-CheckResult -Code "W-15" -Status "PASS" -Detail "IIS 미설치"
        return
    }
    try {
        Import-Module WebAdministration -ErrorAction Stop
        $appPools = Get-ChildItem "IIS:\AppPools" -ErrorAction Stop
        $issues = @()
        foreach ($pool in $appPools) {
            $identity = $pool.processModel.identityType
            if ($identity -eq "LocalSystem") {
                $issues += "$($pool.Name)(LocalSystem)"
            }
        }
        if ($issues.Count -eq 0) {
            Record-CheckResult -Code "W-15" -Status "PASS" -Detail "모든 앱 풀이 제한된 권한으로 실행 중"
        } else {
            Record-CheckResult -Code "W-15" -Status "FAIL" -Detail "LocalSystem으로 실행 중인 앱 풀: $($issues -join ', ')"
        }
    } catch {
        Record-CheckResult -Code "W-15" -Status "REVIEW" -Detail "IIS 앱 풀 설정을 확인할 수 없음: $_"
    }
}
