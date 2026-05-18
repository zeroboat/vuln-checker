function Check-W_62 {
    Print-SecurityCheck -Code "W-62"
    $snmpSvc = Get-Service -Name "SNMP" -ErrorAction SilentlyContinue
    if ($null -eq $snmpSvc -or $snmpSvc.Status -ne "Running") {
        Record-CheckResult -Code "W-62" -Status "PASS" -Detail "SNMP 서비스가 실행되고 있지 않음"
        return
    }
    try {
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters"
        $val = Get-ItemProperty -Path $regPath -Name "EnableAuthenticationTraps" -ErrorAction Stop
        if ($val.EnableAuthenticationTraps -eq 1) {
            Record-CheckResult -Code "W-62" -Status "PASS" -Detail "SNMP 인증 트랩이 활성화됨"
        } else {
            Record-CheckResult -Code "W-62" -Status "FAIL" -Detail "SNMP 인증 트랩이 비활성화됨"
        }
    } catch {
        Record-CheckResult -Code "W-62" -Status "REVIEW" -Detail "SNMP 인증 트랩 설정을 확인할 수 없음: $_"
    }
}
