#!/bin/bash
################################################################################
# U-33: 숨겨진 파일 및 디렉토리 검색
################################################################################
check_U_33() {
    print_security_check "U-33" "숨겨진 파일 및 디렉토리 검색" 1

    local suspicious_hidden
    # /tmp, /var/tmp, /dev/shm 등에서 숨겨진 파일 검색
    suspicious_hidden=$(find /tmp /var/tmp /dev/shm 2>/dev/null -name ".*" -not -name ".." -not -name "." 2>/dev/null | head -20)

    if [ -n "$suspicious_hidden" ]; then
        append_log "  임시 디렉토리 내 숨겨진 파일:"
        echo "$suspicious_hidden" | while read -r f; do
            append_log "    $f"
        done
        record_check_result "U-33" "REVIEW" "임시 디렉토리에 숨겨진 파일 존재 - 확인 필요"
    else
        record_check_result "U-33" "PASS" "임시 디렉토리 내 의심스러운 숨겨진 파일 없음"
    fi
}
