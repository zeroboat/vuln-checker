#!/bin/bash

################################################################################
# U-01: root 계정 원격 접속 제한
################################################################################

check_U_01() {
    print_security_check "U-01" "root 계정 원격 접속 제한" 1
    
    # SSH 설정 파일 존재 여부 확인
    if [ ! -f /etc/ssh/sshd_config ]; then
        record_check_result "U-01" "REVIEW" "SSH 설정 파일(/etc/ssh/sshd_config)이 없음"
        return
    fi

    # 마지막 유효 설정값 사용 (SSH는 파일 내 마지막 지시문이 우선)
    local permit_root
    permit_root=$(grep -w "PermitRootLogin" /etc/ssh/sshd_config | grep -v "^#" | awk '{print $2}' | tail -1)
    append_log "  PermitRootLogin: ${permit_root:-미설정(기본값 prohibit-password)}"

    if [ -z "$permit_root" ] || [ "$permit_root" = "no" ] || [ "$permit_root" = "without-password" ] || [ "$permit_root" = "prohibit-password" ]; then
        record_check_result "U-01" "PASS" "root 원격 접속이 차단되어 있음 (${permit_root:-기본값})"
    else
        record_check_result "U-01" "FAIL" "root 원격 접속이 허용되어 있음 (현재: $permit_root)"
    fi
}
