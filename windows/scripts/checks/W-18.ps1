function Check-W_18 {
    Print-SecurityCheck -Code "W-18"
    $iisSvc = Get-Service -Name "W3SVC" -ErrorAction SilentlyContinue
    if ($null -eq $iisSvc) {
        Record-CheckResult -Code "W-18" -Status "PASS" -Detail "IIS 미설치"
        return
    }
    $iisRoot = "$env:SystemDrive\inetpub\wwwroot"
    if (-not (Test-Path $iisRoot)) {
        Record-CheckResult -Code "W-18" -Status "PASS" -Detail "웹 루트 디렉터리 없음"
        return
    }
    $dbFiles = Get-ChildItem -Path $iisRoot -Recurse -Include "*.mdb","*.accdb","*.dsn","*.udl" -ErrorAction SilentlyContinue
    if ($null -eq $dbFiles -or @($dbFiles).Count -eq 0) {
        Record-CheckResult -Code "W-18" -Status "PASS" -Detail "웹 루트에 DB 연결 파일이 없음"
    } else {
        $names = @($dbFiles) | ForEach-Object { $_.FullName }
        Record-CheckResult -Code "W-18" -Status "FAIL" -Detail "웹 루트에 DB 파일 존재: $($names -join ', ')"
    }
}
