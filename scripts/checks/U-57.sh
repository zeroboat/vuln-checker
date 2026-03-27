#!/bin/bash
################################################################################
# U-57: Ftpusers 파일 설정
################################################################################
check_U_57() {
    print_security_check "U-57" "Ftpusers 파일 설정" 1

    local fail=false
    local ftpusers_files=("/etc/ftpusers" "/etc/vsftpd/ftpusers" "/etc/vsftpd.ftpusers")
    local found=false

    for f in "${ftpusers_files[@]}"; do
        [ -f "$f" ] || continue
        found=true
        append_log "  ftpusers 파일 발견: $f"

        local restricted_accounts=("root" "bin" "daemon" "sys" "adm" "lp" "smtp" "uucp" "nuucp" "listen")
        for acct in "${restricted_accounts[@]}"; do
            if ! grep -q "^${acct}$" "$f" 2>/dev/null; then
                if id "$acct" &>/dev/null; then
                    append_log "  ⚠️  ${acct}이 ftpusers에 등록되지 않음"
                    fail=true
                fi
            fi
        done
    done

    if ! $found; then
        # vsftpd가 설치된 경우에만 문제
        if command_exists vsftpd; then
            record_check_result "U-57" "FAIL" "ftpusers 파일이 없음"
        else
            record_check_result "U-57" "PASS" "FTP 서비스 미설치"
        fi
        return
    fi

    if $fail; then
        record_check_result "U-57" "FAIL" "시스템 계정이 ftpusers에 등록되지 않음"
    else
        record_check_result "U-57" "PASS" "ftpusers 파일 설정 양호"
    fi
}
