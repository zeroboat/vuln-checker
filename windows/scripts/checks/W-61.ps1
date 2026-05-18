function Check-W_61 {
    Print-SecurityCheck -Code "W-61"
    $snmpSvc = Get-Service -Name "SNMP" -ErrorAction SilentlyContinue
    if ($null -eq $snmpSvc -or $snmpSvc.Status -ne "Running") {
        Record-CheckResult -Code "W-61" -Status "PASS" -Detail "SNMP 서비스가 실행되고 있지 않음"
        return
    }
    try {
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\ValidCommunities"
        if (Test-Path $regPath) {
            $communities = Get-ItemProperty -Path $regPath -ErrorAction Stop
            $props = $communities.PSObject.Properties | Where-Object { $_.Name -notin @("PSPath","PSParentPath","PSChildName","PSDrive","PSProvider") }
            $rwCommunities = @()
            foreach ($p in $props) {
                # Value: 1=NONE, 2=NOTIFY, 4=READ ONLY, 8=READ WRITE, 16=READ CREATE
                if ($p.Value -ge 8) {
                    $rwCommunities += "$($p.Name)(권한:$($p.Value))"
                }
            }
            if ($rwCommunities.Count -eq 0) {
                Record-CheckResult -Code "W-61" -Status "PASS" -Detail "SNMP 커뮤니티 스트링이 읽기 전용으로 설정됨"
            } else {
                Record-CheckResult -Code "W-61" -Status "FAIL" -Detail "쓰기 권한 커뮤니티: $($rwCommunities -join ', ')"
            }
        } else {
            Record-CheckResult -Code "W-61" -Status "PASS" -Detail "SNMP 커뮤니티가 설정되어 있지 않음"
        }
    } catch {
        Record-CheckResult -Code "W-61" -Status "REVIEW" -Detail "SNMP 커뮤니티 권한을 확인할 수 없음: $_"
    }
}
