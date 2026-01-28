#!/bin/bash

################################################################################
# U-01: root 계정 원격 접속 제한
################################################################################

check_U_01() {
    print_security_check "U-01" "root 계정 원격 접속 제한" 1
    
    # SSH 설정 확인
    local permit_root=$(grep -w "PermitRootLogin" /etc/ssh/sshd_config 2>/dev/null | grep -v "^#" | awk '{print $2}' | head -1)
    if [ -z "$permit_root" ] || [ "$permit_root" = "no" ] || [ "$permit_root" = "without-password" ]; then
        record_check_result "U-01" "PASS" "root 원격 접속이 차단되어 있음"
    else
        record_check_result "U-01" "FAIL" "root 원격 접속이 허용되어 있음 (현재: $permit_root)"
    fi
}
