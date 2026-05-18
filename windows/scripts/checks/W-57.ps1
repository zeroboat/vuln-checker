function Check-W_57 {
    Print-SecurityCheck -Code "W-57"
    $snmpSvc = Get-Service -Name "SNMP" -ErrorAction SilentlyContinue
    if ($null -eq $snmpSvc -or $snmpSvc.Status -ne "Running") {
        Record-CheckResult -Code "W-57" -Status "PASS" -Detail "SNMP 서비스가 실행되고 있지 않음"
        return
    }
    try {
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\PermittedManagers"
        if (Test-Path $regPath) {
            $managers = Get-ItemProperty -Path $regPath -ErrorAction Stop
            $count = ($managers.PSObject.Properties | Where-Object { $_.Name -match "^\d+$" }).Count
            if ($count -gt 0) {
                Record-CheckResult -Code "W-57" -Status "PASS" -Detail "SNMP 접근 호스트가 제한됨 (${count}개 호스트)"
            } else {
                Record-CheckResult -Code "W-57" -Status "FAIL" -Detail "SNMP 접근 호스트 제한이 없음"
            }
        } else {
            Record-CheckResult -Code "W-57" -Status "FAIL" -Detail "SNMP 접근 제어가 설정되어 있지 않음 (모든 호스트 허용)"
        }
    } catch {
        Record-CheckResult -Code "W-57" -Status "REVIEW" -Detail "SNMP 접근 제어를 확인할 수 없음: $_"
    }
}
