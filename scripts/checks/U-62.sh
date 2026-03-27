#!/bin/bash
################################################################################
# U-62: 로그인 시 경고 메시지 설정
################################################################################
check_U_62() {
    print_security_check "U-62" "로그인 시 경고 메시지 설정" 1

    local fail=false

    for f in /etc/motd /etc/issue /etc/issue.net; do
        if [ -f "$f" ]; then
            local content
            content=$(cat "$f" 2>/dev/null)
            if [ -z "$content" ] || [ "$(echo "$content" | tr -d '[:space:]')" = "" ]; then
                append_log "  ⚠️  $f 내용이 비어있음"
                fail=true
            else
                append_log "  $f 내용: $(echo "$content" | head -2)"
                # 버전 정보 노출 확인
                if echo "$content" | grep -qiE "ubuntu [0-9]|debian [0-9]|centos [0-9]|red hat|kernel [0-9]"; then
                    append_log "  ⚠️  $f 에 OS/버전 정보가 노출됨"
                    fail=true
                fi
            fi
        else
            append_log "  $f 파일 없음"
            fail=true
        fi
    done

    if $fail; then
        record_check_result "U-62" "FAIL" "로그인 경고 메시지 설정 미흡 또는 버전 정보 노출"
    else
        record_check_result "U-62" "PASS" "로그인 경고 메시지 설정 양호"
    fi
}
