#!/bin/bash
################################################################################
# U-45: 메일 서비스 버전 점검
################################################################################
check_U_45() {
    print_security_check "U-45" "메일 서비스 버전 점검" 1

    local mail_found=false

    # sendmail 확인
    if command_exists sendmail; then
        local version
        version=$(sendmail -d0.1 -bv root 2>&1 | grep "Version" | head -1)
        append_log "  sendmail: ${version:-버전 확인 불가}"
        mail_found=true
    fi

    # postfix 확인
    if command_exists postconf; then
        local version
        version=$(postconf mail_version 2>/dev/null)
        append_log "  postfix: ${version:-버전 확인 불가}"
        mail_found=true
    fi

    # exim 확인
    if command_exists exim; then
        local version
        version=$(exim --version 2>/dev/null | head -1)
        append_log "  exim: ${version:-버전 확인 불가}"
        mail_found=true
    fi

    if $mail_found; then
        record_check_result "U-45" "REVIEW" "메일 서비스 버전을 최신 보안 패치 버전과 비교 필요"
    else
        record_check_result "U-45" "PASS" "메일 서비스 미설치"
    fi
}
