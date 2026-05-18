function Check-W_29 {
    Print-SecurityCheck -Code "W-29"
    $dnsSvc = Get-Service -Name "DNS" -ErrorAction SilentlyContinue
    if ($null -eq $dnsSvc -or $dnsSvc.Status -ne "Running") {
        Record-CheckResult -Code "W-29" -Status "PASS" -Detail "DNS 서비스가 실행되고 있지 않음"
        return
    }
    try {
        $zones = Get-DnsServerZone -ErrorAction Stop | Where-Object { $_.ZoneType -eq "Primary" }
        $issues = @()
        foreach ($zone in $zones) {
            $zoneInfo = Get-DnsServerZone -Name $zone.ZoneName -ErrorAction SilentlyContinue
            if ($zoneInfo.SecureSecondaries -eq "TransferAnyServer") {
                $issues += $zone.ZoneName
            }
        }
        if ($issues.Count -eq 0) {
            Record-CheckResult -Code "W-29" -Status "PASS" -Detail "DNS Zone Transfer가 제한됨"
        } else {
            Record-CheckResult -Code "W-29" -Status "FAIL" -Detail "Zone Transfer 무제한 허용 영역: $($issues -join ', ')"
        }
    } catch {
        Record-CheckResult -Code "W-29" -Status "REVIEW" -Detail "DNS Zone Transfer 설정을 확인할 수 없음: $_"
    }
}
