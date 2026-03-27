#!/bin/bash
################################################################################
# U-15: 파일 및 디렉터리 소유자 설정
################################################################################
check_U_15() {
    print_security_check "U-15" "파일 및 디렉터리 소유자 설정" 1

    append_log "  소유자 없는 파일/디렉토리 검색 중 (시간이 걸릴 수 있음)..."
    local noowner_files
    noowner_files=$(find / -xdev \( -nouser -o -nogroup \) 2>/dev/null | head -20)

    if [ -n "$noowner_files" ]; then
        append_log "  소유자 없는 파일:"
        echo "$noowner_files" | while read -r f; do
            append_log "    $f"
        done
        record_check_result "U-15" "FAIL" "소유자가 없는 파일/디렉토리 존재 (상위 20개 표시)"
    else
        record_check_result "U-15" "PASS" "소유자가 없는 파일/디렉토리 없음"
    fi
}
