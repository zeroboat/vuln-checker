#!/bin/bash
################################################################################
# U-25: world writable 파일 점검
################################################################################
check_U_25() {
    print_security_check "U-25" "world writable 파일 점검" 1

    append_log "  world writable 파일 검색 중..."
    local ww_files
    ww_files=$(find / -xdev -perm -002 -not -type l -not -type d 2>/dev/null | head -20)

    if [ -n "$ww_files" ]; then
        append_log "  발견된 world writable 파일 (상위 20개):"
        echo "$ww_files" | while read -r f; do
            append_log "    $f"
        done
        record_check_result "U-25" "FAIL" "world writable 파일 존재"
    else
        record_check_result "U-25" "PASS" "world writable 파일 없음"
    fi
}
