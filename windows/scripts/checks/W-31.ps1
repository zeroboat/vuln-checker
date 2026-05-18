function Check-W_31 {
    Print-SecurityCheck -Code "W-31"
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $build = [int]$os.BuildNumber
        $version = $os.Caption
        # Windows Server 2019+ or Windows 10 build 17763+
        if ($build -ge 17763) {
            Record-CheckResult -Code "W-31" -Status "PASS" -Detail "최신 OS 버전 사용 중: $version (Build $build)"
        } else {
            Record-CheckResult -Code "W-31" -Status "FAIL" -Detail "OS 업데이트가 필요함: $version (Build $build)"
        }
    } catch {
        Record-CheckResult -Code "W-31" -Status "REVIEW" -Detail "OS 버전을 확인할 수 없음: $_"
    }
}
