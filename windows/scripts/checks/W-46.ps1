function Check-W_46 {
    Print-SecurityCheck -Code "W-46"
    try {
        $defender = Get-MpComputerStatus -ErrorAction Stop
        if ($defender.AntivirusEnabled) {
            Record-CheckResult -Code "W-46" -Status "PASS" -Detail "Windows Defender가 활성화됨 (엔진: $($defender.AMEngineVersion))"
        } else {
            Record-CheckResult -Code "W-46" -Status "FAIL" -Detail "Windows Defender가 비활성화됨"
        }
    } catch {
        try {
            $av = Get-CimInstance -Namespace "root/SecurityCenter2" -ClassName AntiVirusProduct -ErrorAction Stop
            if ($av) {
                $names = $av | ForEach-Object { $_.displayName }
                Record-CheckResult -Code "W-46" -Status "PASS" -Detail "백신 프로그램 설치됨: $($names -join ', ')"
            } else {
                Record-CheckResult -Code "W-46" -Status "FAIL" -Detail "백신 프로그램이 설치되어 있지 않음"
            }
        } catch {
            Record-CheckResult -Code "W-46" -Status "REVIEW" -Detail "백신 설치 상태를 확인할 수 없음: $_"
        }
    }
}
