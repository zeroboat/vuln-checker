#!/bin/bash
################################################################################
# U-54: 암호화되지 않는 FTP 서비스 비활성화
################################################################################
check_U_54() {
    print_security_check "U-54" "암호화되지 않는 FTP 서비스 비활성화" 1

    local ftp_running=false
    local ssl_enabled=false

    # vsftpd 실행 여부
    if command_exists systemctl; then
        local status
        status=$(systemctl is-active vsftpd 2>/dev/null)
        if [ "$status" = "active" ]; then
            ftp_running=true
            # SSL 설정 확인
            for f in /etc/vsftpd.conf /etc/vsftpd/vsftpd.conf; do
                if [ -f "$f" ]; then
                    local ssl_enable
                    ssl_enable=$(grep "^ssl_enable" "$f" | awk -F= '{print $2}' | tr -d '[:space:]')
                    append_log "  vsftpd ssl_enable: ${ssl_enable:-미설정}"
                    [ "$ssl_enable" = "YES" ] && ssl_enabled=true
                fi
            done
        fi
    fi

    # 21번 포트 listening 확인
    if command_exists ss; then
        if ss -tlnp 2>/dev/null | grep -q ":21 "; then
            append_log "  ⚠️  21번 포트(FTP)가 열려 있음"
            ftp_running=true
        fi
    fi

    if $ftp_running && ! $ssl_enabled; then
        record_check_result "U-54" "FAIL" "암호화되지 않는 FTP 서비스가 실행 중 (SFTP/FTPS 사용 권장)"
    elif $ftp_running && $ssl_enabled; then
        record_check_result "U-54" "PASS" "FTP 서비스가 SSL/TLS로 암호화됨"
    else
        record_check_result "U-54" "PASS" "FTP 서비스 비활성화됨"
    fi
}
