#!/bin/bash
################################################################################
# U-14: root 홈, 패스 디렉터리 권한 및 패스 설정
################################################################################
check_U_14() {
    print_security_check "U-14" "root 홈, 패스 디렉터리 권한 및 패스 설정" 1

    local fail=false

    # root PATH에 현재 디렉토리(.) 포함 여부
    local root_path
    root_path=$(su -l root -c 'echo $PATH' 2>/dev/null || echo "${PATH}")
    append_log "  root PATH: ${root_path}"

    # 빈 컴포넌트(::), 현재 디렉토리(.) 또는 상대 경로 포함 여부 검사
    if echo ":${root_path}:" | grep -qE ":\.?:|:\.[^/]|^\."; then
        append_log "  ⚠️  PATH에 현재 디렉토리(.) 또는 상대 경로가 포함됨"
        fail=true
    fi

    # root 홈 디렉토리 권한 확인
    local root_home
    root_home=$(grep "^root:" /etc/passwd | cut -d: -f6)
    if [ -d "$root_home" ]; then
        local perm
        perm=$(stat -c %a "$root_home" 2>/dev/null || stat -f %Lp "$root_home" 2>/dev/null)
        perm=$(echo "$perm" | tr -d '[:space:]' | sed 's/^0*//')
        append_log "  root 홈 디렉토리 ($root_home) 권한: ${perm}"
        if [ "$(printf '%d' "0${perm}")" -gt "$(printf '%d' 0700)" ] 2>/dev/null; then
            append_log "  root 홈 디렉토리 권한이 너무 넓음 (권장: 700 이하)"
            fail=true
        fi
    fi

    if $fail; then
        record_check_result "U-14" "FAIL" "root PATH 또는 홈 디렉토리 설정 미흡"
    else
        record_check_result "U-14" "PASS" "root PATH 및 홈 디렉토리 설정 양호"
    fi
}
