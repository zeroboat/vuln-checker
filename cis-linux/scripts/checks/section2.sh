#!/bin/bash
# 섹션 2: 서비스 (CL-11 ~ CL-17)

check_CL_11() {
    cis_print_check "CL-11"
    local found=""
    for pkg in xinetd openbsd-inetd inetutils-inetd; do
        if cis_package_installed "$pkg"; then
            found="${found}${pkg} "
        fi
    done
    if [ -z "$found" ]; then
        cis_record_result "CL-11" "PASS" "inetd/xinetd가 설치되어 있지 않음"
    else
        cis_record_result "CL-11" "FAIL" "설치된 슈퍼데몬: ${found}"
    fi
}

check_CL_12() {
    cis_print_check "CL-12"
    local active=""
    for svc in chrony chronyd ntp ntpd systemd-timesyncd; do
        if cis_service_active "$svc"; then
            active="${active}${svc} "
        fi
    done
    if [ -n "$active" ]; then
        cis_record_result "CL-12" "PASS" "시간 동기화 서비스 동작 중: ${active}"
    else
        cis_record_result "CL-12" "FAIL" "시간 동기화 서비스가 활성화되어 있지 않음"
    fi
}

check_CL_13() {
    cis_print_check "CL-13"
    if ! cis_command_exists systemctl; then
        cis_record_result "CL-13" "REVIEW" "systemctl을 사용할 수 없어 서비스 점검 불가"
        return
    fi
    local svcs=("avahi-daemon" "cups" "isc-dhcp-server" "dhcpd" "slapd" "nfs-server" "named" "bind9" "vsftpd" "smbd" "snmpd" "squid" "dovecot")
    local running=""
    for s in "${svcs[@]}"; do
        if cis_service_active "$s"; then
            running="${running}${s} "
        fi
    done
    if [ -z "$running" ]; then
        cis_record_result "CL-13" "PASS" "불필요한 서버 서비스가 비활성화됨"
    else
        cis_record_result "CL-13" "REVIEW" "실행 중인 서버 서비스: ${running}— 필요 여부 확인 필요"
    fi
}

check_CL_14() {
    cis_print_check "CL-14"
    # 25번 포트가 외부(0.0.0.0/::)에 바인딩되어 있는지 확인
    local listen=""
    if cis_command_exists ss; then
        listen=$(ss -tlnH 2>/dev/null | awk '{print $4}' | grep -E ":25$")
    elif cis_command_exists netstat; then
        listen=$(netstat -tln 2>/dev/null | awk '{print $4}' | grep -E ":25$")
    else
        cis_record_result "CL-14" "REVIEW" "ss/netstat 미설치로 MTA 바인딩 점검 불가"
        return
    fi
    if [ -z "$listen" ]; then
        cis_record_result "CL-14" "PASS" "25번 포트가 외부에 노출되지 않음 (MTA 미실행 또는 로컬 전용)"
    elif echo "$listen" | grep -qE "^(127\.0\.0\.1|\[::1\]|localhost)"; then
        cis_record_result "CL-14" "PASS" "MTA가 로컬호스트에만 바인딩됨 (${listen})"
    else
        cis_record_result "CL-14" "FAIL" "MTA가 외부 인터페이스에 바인딩됨 (${listen})"
    fi
}

check_CL_15() {
    cis_print_check "CL-15"
    local found=""
    for pkg in rsh-client rsh-redone-client talk telnet ldap-utils nis; do
        if cis_package_installed "$pkg"; then
            found="${found}${pkg} "
        fi
    done
    if [ -z "$found" ]; then
        cis_record_result "CL-15" "PASS" "안전하지 않은 클라이언트가 설치되어 있지 않음"
    else
        cis_record_result "CL-15" "FAIL" "설치된 평문 클라이언트: ${found}"
    fi
}

check_CL_16() {
    cis_print_check "CL-16"
    local found=""
    for pkg in xserver-xorg-core xorg "xorg-x11-server-Xorg"; do
        if cis_package_installed "$pkg"; then
            found="${found}${pkg} "
        fi
    done
    if [ -z "$found" ]; then
        cis_record_result "CL-16" "PASS" "X Window System이 설치되어 있지 않음"
    else
        cis_record_result "CL-16" "REVIEW" "X Window 설치됨: ${found}— 서버 용도면 제거 권장"
    fi
}

check_CL_17() {
    cis_print_check "CL-17"
    if cis_service_active rsync || cis_service_active rsyncd; then
        cis_record_result "CL-17" "FAIL" "rsync 데몬이 활성화됨 — 비활성화 권장"
    else
        cis_record_result "CL-17" "PASS" "rsync 데몬이 비활성화됨"
    fi
}
