function Check-W_20 {
    Print-SecurityCheck -Code "W-20"
    $iisSvc = Get-Service -Name "W3SVC" -ErrorAction SilentlyContinue
    if ($null -eq $iisSvc) {
        Record-CheckResult -Code "W-20" -Status "PASS" -Detail "IIS 미설치"
        return
    }
    $iisRoot = "$env:SystemDrive\inetpub\wwwroot"
    if (-not (Test-Path $iisRoot)) {
        Record-CheckResult -Code "W-20" -Status "PASS" -Detail "웹 루트 없음"
        return
    }
    try {
        $acl = Get-Acl -Path $iisRoot -ErrorAction Stop
        $everyone = $acl.Access | Where-Object {
            $_.IdentityReference -match "Everyone" -and
            $_.FileSystemRights -match "FullControl|Modify|Write"
        }
        if ($everyone) {
            Record-CheckResult -Code "W-20" -Status "FAIL" -Detail "웹 루트에 Everyone 쓰기 권한 존재"
        } else {
            Record-CheckResult -Code "W-20" -Status "PASS" -Detail "웹 루트 ACL이 적절히 설정됨"
        }
    } catch {
        Record-CheckResult -Code "W-20" -Status "REVIEW" -Detail "웹 루트 ACL을 확인할 수 없음: $_"
    }
}
