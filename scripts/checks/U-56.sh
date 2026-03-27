#!/bin/bash
################################################################################
# U-56: FTP 서비스 접근 제어 설정
################################################################################
check_U_56() {
    print_security_check "U-56" "FTP 서비스 접근 제어 설정" 1

    local found=false

    # vsftpd tcp_wrappers 또는 hosts_access 확인
    for f in /etc/vsftpd.conf /etc/vsftpd/vsftpd.conf; do
        if [ -f "$f" ]; then
            found=true
            local tcp_wrappers
            tcp_wrappers=$(grep "^tcp_wrappers\|^allow_hosts\|^deny_hosts" "$f" 2>/dev/null)
            if [ -n "$tcp_wrappers" ]; then
                append_log "  vsftpd 접근 제어 설정: $tcp_wrappers"
            else
                append_log "  ⚠️  vsftpd 접근 제어 설정 미흡"
            fi
        fi
    done

    # /etc/hosts.allow, /etc/hosts.deny 확인
    if [ -f /etc/hosts.allow ]; then
        local ftp_allow
        ftp_allow=$(grep -iE "^(ftp|vsftpd|in\.ftpd)" /etc/hosts.allow 2>/dev/null)
        [ -n "$ftp_allow" ] && append_log "  /etc/hosts.allow FTP 설정: $ftp_allow"
    fi
    if [ -f /etc/hosts.deny ]; then
        local ftp_deny
        ftp_deny=$(grep -iE "^(ftp|vsftpd|in\.ftpd|ALL)" /etc/hosts.deny 2>/dev/null)
        [ -n "$ftp_deny" ] && append_log "  /etc/hosts.deny FTP 설정: $ftp_deny"
    fi

    if $found; then
        record_check_result "U-56" "REVIEW" "FTP 접근 제어 설정 확인 필요"
    else
        record_check_result "U-56" "PASS" "FTP 서비스 미설치"
    fi
}
