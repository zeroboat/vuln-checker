#!/bin/bash
################################################################################
# U-21: /etc/(r)syslog.conf 파일 소유자 및 권한 설정
################################################################################
check_U_21() {
    print_security_check "U-21" "/etc/(r)syslog.conf 파일 소유자 및 권한 설정" 1

    local found=false
    for f in /etc/syslog.conf /etc/rsyslog.conf; do
        if [ -f "$f" ]; then
            found=true
            check_file_permissions "$f" "640" "U-21" "root"
        fi
    done

    if ! $found; then
        record_check_result "U-21" "REVIEW" "syslog.conf/rsyslog.conf 파일 없음"
    fi
}
