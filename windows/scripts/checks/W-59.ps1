function Check-W_59 {
    Print-SecurityCheck -Code "W-59"
    $dnsSvc = Get-Service -Name "DNS" -ErrorAction SilentlyContinue
    if ($null -eq $dnsSvc -or $dnsSvc.Status -ne "Running") {
        Record-CheckResult -Code "W-59" -Status "PASS" -Detail "DNS 서비스가 실행되고 있지 않음"
        return
    }
    try {
        $zones = Get-DnsServerZone -ErrorAction Stop | Where-Object { $_.ZoneType -eq "Primary" }
        $issues = @()
        foreach ($zone in $zones) {
            if ($zone.DynamicUpdate -eq "NonsecureAndSecure") {
                $issues += "$($zone.ZoneName)(비보안 동적 업데이트 허용)"
            }
        }
        if ($issues.Count -eq 0) {
            Record-CheckResult -Code "W-59" -Status "PASS" -Detail "DNS 동적 업데이트가 안전하게 설정됨"
        } else {
            Record-CheckResult -Code "W-59" -Status "FAIL" -Detail ($issues -join "; ")
        }
    } catch {
        Record-CheckResult -Code "W-59" -Status "REVIEW" -Detail "DNS 동적 업데이트 설정을 확인할 수 없음: $_"
    }
}
