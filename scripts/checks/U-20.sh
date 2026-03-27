#!/bin/bash
################################################################################
# U-20: /etc/(x)inetd.conf 파일 소유자 및 권한 설정
################################################################################
check_U_20() {
    print_security_check "U-20" "/etc/(x)inetd.conf 파일 소유자 및 권한 설정" 1

    local found=false
    for f in /etc/inetd.conf /etc/xinetd.conf; do
        if [ -f "$f" ]; then
            found=true
            check_file_permissions "$f" "600" "U-20" "root"
        fi
    done

    if ! $found; then
        record_check_result "U-20" "PASS" "/etc/inetd.conf, /etc/xinetd.conf 파일이 존재하지 않음 (양호)"
    fi
}
