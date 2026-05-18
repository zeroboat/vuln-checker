function Check-W_60 {
    Print-SecurityCheck -Code "W-60"
    $snmpSvc = Get-Service -Name "SNMP" -ErrorAction SilentlyContinue
    if ($null -eq $snmpSvc) {
        Record-CheckResult -Code "W-60" -Status "PASS" -Detail "SNMP 서비스가 설치되어 있지 않음"
    } elseif ($snmpSvc.Status -eq "Running") {
        Record-CheckResult -Code "W-60" -Status "FAIL" -Detail "SNMP 서비스가 실행 중 (불필요 시 중지 필요)"
    } else {
        Record-CheckResult -Code "W-60" -Status "PASS" -Detail "SNMP 서비스가 중지 상태임"
    }
}
