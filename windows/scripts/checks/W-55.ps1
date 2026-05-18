function Check-W_55 {
    Print-SecurityCheck -Code "W-55"
    try {
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"
        $val = Get-ItemProperty -Path $regPath -Name "MinEncryptionLevel" -ErrorAction Stop
        if ($val.MinEncryptionLevel -ge 3) {
            $level = switch ($val.MinEncryptionLevel) { 3 {"높음"} 4 {"FIPS 호환"} default {"$($val.MinEncryptionLevel)"} }
            Record-CheckResult -Code "W-55" -Status "PASS" -Detail "터미널 서비스 암호화 수준: $level"
        } else {
            $level = switch ($val.MinEncryptionLevel) { 1 {"낮음"} 2 {"클라이언트 호환"} default {"$($val.MinEncryptionLevel)"} }
            Record-CheckResult -Code "W-55" -Status "FAIL" -Detail "터미널 서비스 암호화 수준이 낮음: $level (권장: 높음 이상)"
        }
    } catch {
        Record-CheckResult -Code "W-55" -Status "REVIEW" -Detail "터미널 서비스 암호화 설정을 확인할 수 없음: $_"
    }
}
