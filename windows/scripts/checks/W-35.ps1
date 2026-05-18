function Check-W_35 {
    Print-SecurityCheck -Code "W-35"
    $samPath = "$env:SystemRoot\System32\config\SAM"
    try {
        if (-not (Test-Path $samPath -ErrorAction Stop)) {
            Record-CheckResult -Code "W-35" -Status "REVIEW" -Detail "SAM 파일을 찾을 수 없음"
            return
        }
        $acl = Get-Acl -Path $samPath -ErrorAction Stop
        $everyone = $acl.Access | Where-Object {
            $_.IdentityReference -match "Everyone|BUILTIN\Users" -and
            $_.FileSystemRights -match "Read|FullControl|Modify"
        }
        if ($everyone) {
            Record-CheckResult -Code "W-35" -Status "FAIL" -Detail "SAM 파일에 일반 사용자 접근 권한이 설정됨"
        } else {
            Record-CheckResult -Code "W-35" -Status "PASS" -Detail "SAM 파일 접근 통제가 적절히 설정됨 (소유자: $($acl.Owner))"
        }
    } catch {
        Record-CheckResult -Code "W-35" -Status "REVIEW" -Detail "SAM 파일 ACL을 확인할 수 없음: $_"
    }
}
