#!/bin/bash
################################################################################
# U-63: sudo 명령어 접근 관리
################################################################################
check_U_63() {
    print_security_check "U-63" "sudo 명령어 접근 관리" 1

    if [ ! -f /etc/sudoers ]; then
        record_check_result "U-63" "REVIEW" "/etc/sudoers 파일 없음"
        return
    fi

    local fail=false

    # NOPASSWD 설정 확인
    local nopasswd
    nopasswd=$(grep -v "^#" /etc/sudoers 2>/dev/null | grep "NOPASSWD")
    if [ -n "$nopasswd" ]; then
        append_log "  ⚠️  NOPASSWD 설정 발견:"
        echo "$nopasswd" | while read -r line; do
            append_log "    $line"
        done
        fail=true
    fi

    # ALL=(ALL) ALL 광범위한 권한 부여 확인
    local all_perms
    all_perms=$(grep -v "^#" /etc/sudoers 2>/dev/null | grep "ALL.*NOPASSWD\|^root.*ALL")
    if [ -n "$all_perms" ]; then
        append_log "  sudo ALL 권한 설정:"
        echo "$all_perms" | head -5 | while read -r line; do
            append_log "    $line"
        done
    fi

    # /etc/sudoers.d 확인
    if [ -d /etc/sudoers.d ]; then
        for f in /etc/sudoers.d/*; do
            [ -f "$f" ] || continue
            local np
            np=$(grep -v "^#" "$f" 2>/dev/null | grep "NOPASSWD")
            if [ -n "$np" ]; then
                append_log "  ⚠️  $f 에서 NOPASSWD 설정: $np"
                fail=true
            fi
        done
    fi

    if $fail; then
        record_check_result "U-63" "FAIL" "sudo NOPASSWD 설정 존재 - 보안 위험"
    else
        record_check_result "U-63" "PASS" "sudo 설정 양호"
    fi
}
