function Check-W_24 {
    Print-SecurityCheck -Code "W-24"
    try {
        $adapters = Get-WmiObject Win32_NetworkAdapterConfiguration -Filter "IPEnabled=TRUE" -ErrorAction Stop
        $netbiosEnabled = @()
        foreach ($adapter in $adapters) {
            # TcpipNetbiosOptions: 0=default(DHCP), 1=enabled, 2=disabled
            if ($adapter.TcpipNetbiosOptions -ne 2) {
                $netbiosEnabled += $adapter.Description
            }
        }
        if ($netbiosEnabled.Count -eq 0) {
            Record-CheckResult -Code "W-24" -Status "PASS" -Detail "모든 네트워크 어댑터에서 NetBIOS가 비활성화됨"
        } else {
            Record-CheckResult -Code "W-24" -Status "FAIL" -Detail "NetBIOS가 활성화된 어댑터: $($netbiosEnabled -join ', ')"
        }
    } catch {
        Record-CheckResult -Code "W-24" -Status "REVIEW" -Detail "NetBIOS 설정을 확인할 수 없음: $_"
    }
}
