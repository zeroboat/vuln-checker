function Check-W_19 {
    Print-SecurityCheck -Code "W-19"
    $iisSvc = Get-Service -Name "W3SVC" -ErrorAction SilentlyContinue
    if ($null -eq $iisSvc) {
        Record-CheckResult -Code "W-19" -Status "PASS" -Detail "IIS 미설치"
        return
    }
    try {
        Import-Module WebAdministration -ErrorAction Stop
        $defaultVDirs = @("IISAdmin", "IISSamples", "MSADC", "Scripts", "IISHelp", "Printers")
        $sites = Get-Website -ErrorAction Stop
        $found = @()
        foreach ($site in $sites) {
            $vdirs = Get-WebVirtualDirectory -Site $site.Name -ErrorAction SilentlyContinue
            foreach ($vd in $vdirs) {
                if ($defaultVDirs -contains $vd.Name) {
                    $found += "$($site.Name)/$($vd.Name)"
                }
            }
        }
        if ($found.Count -eq 0) {
            Record-CheckResult -Code "W-19" -Status "PASS" -Detail "기본 가상 디렉터리가 제거됨"
        } else {
            Record-CheckResult -Code "W-19" -Status "FAIL" -Detail "기본 가상 디렉터리 존재: $($found -join ', ')"
        }
    } catch {
        Record-CheckResult -Code "W-19" -Status "REVIEW" -Detail "IIS 가상 디렉터리를 확인할 수 없음: $_"
    }
}
