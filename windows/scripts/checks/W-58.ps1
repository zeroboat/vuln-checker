function Check-W_58 {
    Print-SecurityCheck -Code "W-58"
    $snmpSvc = Get-Service -Name "SNMP" -ErrorAction SilentlyContinue
    if ($null -eq $snmpSvc -or $snmpSvc.Status -ne "Running") {
        Record-CheckResult -Code "W-58" -Status "PASS" -Detail "SNMP 서비스가 실행되고 있지 않음"
        return
    }
    try {
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\ValidCommunities"
        if (Test-Path $regPath) {
            $communities = Get-ItemProperty -Path $regPath -ErrorAction Stop
            $weakNames = @("public", "private", "community", "snmp", "default")
            $props = $communities.PSObject.Properties | Where-Object { $_.Name -notin @("PSPath","PSParentPath","PSChildName","PSDrive","PSProvider") }
            $issues = @()
            foreach ($p in $props) {
                if ($weakNames -contains $p.Name.ToLower()) {
                    $issues += $p.Name
                }
            }
            if ($issues.Count -eq 0) {
                Record-CheckResult -Code "W-58" -Status "PASS" -Detail "SNMP 커뮤니티 스트링이 복잡하게 설정됨"
            } else {
                Record-CheckResult -Code "W-58" -Status "FAIL" -Detail "취약한 커뮤니티 스트링 사용: $($issues -join ', ')"
            }
        } else {
            Record-CheckResult -Code "W-58" -Status "PASS" -Detail "SNMP 커뮤니티 스트링이 설정되어 있지 않음"
        }
    } catch {
        Record-CheckResult -Code "W-58" -Status "REVIEW" -Detail "SNMP 커뮤니티 설정을 확인할 수 없음: $_"
    }
}
