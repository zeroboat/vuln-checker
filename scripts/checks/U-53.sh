#!/bin/bash
################################################################################
# U-53: FTP 서비스 정보 노출 제한
################################################################################
check_U_53() {
    print_security_check "U-53" "FTP 서비스 정보 노출 제한" 1

    local fail=false

    # vsftpd 배너 확인
    for f in /etc/vsftpd.conf /etc/vsftpd/vsftpd.conf; do
        if [ -f "$f" ]; then
            local banner
            banner=$(grep "^ftpd_banner\|^banner_file" "$f" 2>/dev/null)
            append_log "  vsftpd 배너 설정: ${banner:-미설정}"
            # 버전 정보 포함 여부 확인
            if echo "$banner" | grep -qiE "vsFTPd [0-9]|version|ready"; then
                append_log "  ⚠️  배너에 버전 정보가 포함됨"
                fail=true
            fi
            if [ -z "$banner" ]; then
                append_log "  ⚠️  ftpd_banner 미설정 (기본 배너에 버전 정보 포함될 수 있음)"
                fail=true
            fi
        fi
    done

    if $fail; then
        record_check_result "U-53" "FAIL" "FTP 서비스 정보 노출 가능"
    else
        record_check_result "U-53" "PASS" "FTP 서비스 정보 노출 제한 설정 양호"
    fi
}
