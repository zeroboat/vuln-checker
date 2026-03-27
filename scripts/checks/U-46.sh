#!/bin/bash
################################################################################
# U-46: 일반 사용자의 메일 서비스 실행 방지
################################################################################
check_U_46() {
    print_security_check "U-46" "일반 사용자의 메일 서비스 실행 방지" 1

    local fail=false

    # postfix - mail 데몬 소유자 확인
    if command_exists postfix; then
        local postfix_user
        postfix_user=$(ps aux 2>/dev/null | grep "postfix/master" | grep -v grep | awk '{print $1}' | head -1)
        if [ -n "$postfix_user" ] && [ "$postfix_user" != "root" ] && [ "$postfix_user" != "postfix" ]; then
            append_log "  ⚠️  postfix가 예상치 않은 계정으로 실행 중: ${postfix_user}"
            fail=true
        fi
    fi

    # sendmail - setuid 확인
    if [ -f /usr/sbin/sendmail ]; then
        local perm
        perm=$(stat -c %a /usr/sbin/sendmail 2>/dev/null)
        append_log "  sendmail 권한: ${perm}"
        # sendmail은 SUID가 정상이지만 일반 계정이 실행할 수 있으므로 REVIEW
        if echo "$perm" | grep -q "^[46]"; then
            append_log "  sendmail SUID 설정 확인"
        fi
    fi

    # /etc/mail/sendmail.cf - DaemonPortOptions 확인
    if [ -f /etc/mail/sendmail.cf ]; then
        local listen_all
        listen_all=$(grep "^O DaemonPortOptions" /etc/mail/sendmail.cf 2>/dev/null)
        if [ -n "$listen_all" ]; then
            append_log "  sendmail DaemonPortOptions: $listen_all"
        fi
    fi

    if $fail; then
        record_check_result "U-46" "FAIL" "메일 서비스 실행 계정 부적절"
    else
        record_check_result "U-46" "PASS" "메일 서비스 실행 계정 양호"
    fi
}
