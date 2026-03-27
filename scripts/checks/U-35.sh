#!/bin/bash
################################################################################
# U-35: 공유 서비스에 대한 익명 접근 제한 설정 (Anonymous FTP)
################################################################################
check_U_35() {
    print_security_check "U-35" "공유 서비스에 대한 익명 접근 제한 설정" 1

    local fail=false

    # vsftpd 설정 확인
    if [ -f /etc/vsftpd.conf ] || [ -f /etc/vsftpd/vsftpd.conf ]; then
        local conf
        conf=$([ -f /etc/vsftpd.conf ] && echo /etc/vsftpd.conf || echo /etc/vsftpd/vsftpd.conf)
        local anon_enable
        anon_enable=$(grep "^anonymous_enable" "$conf" | awk -F= '{print $2}' | tr -d '[:space:]')
        append_log "  vsftpd anonymous_enable: ${anon_enable:-미설정}"
        if [ "$anon_enable" = "YES" ]; then
            append_log "  FTP 익명 접근이 허용됨"
            fail=true
        fi
    fi

    # ftp 계정 확인
    if id ftp &>/dev/null; then
        local ftp_shell
        ftp_shell=$(get_shell ftp)
        append_log "  ftp 계정 쉘: ${ftp_shell}"
        local nologin
        nologin=$(is_nologin_shell "$ftp_shell")
        if [ "$nologin" = "false" ]; then
            append_log "  ftp 계정이 로그인 가능한 쉘 사용"
            fail=true
        fi
    fi

    if $fail; then
        record_check_result "U-35" "FAIL" "FTP 익명 접근이 허용됨"
    else
        record_check_result "U-35" "PASS" "FTP 익명 접근 제한됨"
    fi
}
