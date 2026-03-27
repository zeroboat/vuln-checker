#!/bin/bash
################################################################################
# U-07: 불필요한 계정 제거
################################################################################
check_U_07() {
    print_security_check "U-07" "불필요한 계정 제거" 1

    local unnecessary_accounts=("games" "news" "uucp" "gopher" "ftp" "operator")
    local found_accounts=""

    for acct in "${unnecessary_accounts[@]}"; do
        if id "$acct" &>/dev/null; then
            local shell
            shell=$(get_shell "$acct")
            found_accounts="${found_accounts} $acct(shell:${shell})"
        fi
    done

    append_log "  시스템 내 불필요 기본 계정 확인:"
    if [ -n "$found_accounts" ]; then
        append_log "  발견된 계정:${found_accounts}"
        record_check_result "U-07" "FAIL" "불필요한 기본 계정이 존재함:${found_accounts}"
    else
        append_log "  불필요한 기본 계정 없음"
        record_check_result "U-07" "PASS" "불필요한 기본 계정 없음"
    fi
}
