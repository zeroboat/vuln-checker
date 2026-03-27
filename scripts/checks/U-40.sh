#!/bin/bash
################################################################################
# U-40: NFS 접근 통제
################################################################################
check_U_40() {
    print_security_check "U-40" "NFS 접근 통제" 1

    if [ ! -f /etc/exports ]; then
        record_check_result "U-40" "PASS" "/etc/exports 파일 없음 (NFS 미사용)"
        return
    fi

    local fail=false
    append_log "  /etc/exports 내용:"
    while IFS= read -r line; do
        [[ "$line" =~ ^# ]] && continue
        [ -z "$line" ] && continue
        append_log "  $line"
        # everyone(*) 접근 허용 여부 확인
        if echo "$line" | grep -qP '\*(\s|$|\()'; then
            append_log "  ⚠️  모든 호스트에 NFS 공유 허용: $line"
            fail=true
        fi
        # no_root_squash 확인
        if echo "$line" | grep -q "no_root_squash"; then
            append_log "  ⚠️  no_root_squash 설정 발견 (위험): $line"
            fail=true
        fi
    done < /etc/exports

    if $fail; then
        record_check_result "U-40" "FAIL" "NFS 접근 통제 미흡 (와일드카드 또는 no_root_squash)"
    else
        record_check_result "U-40" "PASS" "NFS 접근 통제 설정 양호"
    fi
}
