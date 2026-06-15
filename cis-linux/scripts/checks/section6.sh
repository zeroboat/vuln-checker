#!/bin/bash
# 섹션 6: 시스템 유지보수 (CL-39 ~ CL-44)

# 파일 권한/소유자 점검 공통 헬퍼
_cis_file_check() {
    local code="$1" file="$2" max_perm="$3" expected_owner="$4"
    if [ ! -e "$file" ]; then
        cis_record_result "$code" "REVIEW" "${file}이(가) 존재하지 않음"
        return
    fi
    local perm owner
    perm=$(cis_file_perm "$file")
    owner=$(cis_file_owner "$file")
    if cis_perm_le "$perm" "$max_perm" && [ "$owner" = "$expected_owner" ]; then
        cis_record_result "$code" "PASS" "${file}: 권한=${perm}(최대 ${max_perm}), 소유자=${owner}"
    else
        cis_record_result "$code" "FAIL" "${file}: 권한=${perm}(최대 ${max_perm}), 소유자=${owner}(기대 ${expected_owner})"
    fi
}

check_CL_39() {
    cis_print_check "CL-39"
    _cis_file_check "CL-39" "/etc/passwd" "644" "root"
}

check_CL_40() {
    cis_print_check "CL-40"
    # shadow 소유자는 배포판별 root 또는 shadow 그룹 — 권한만 엄격히 점검
    if [ ! -e /etc/shadow ]; then
        cis_record_result "CL-40" "REVIEW" "/etc/shadow가 존재하지 않음"
        return
    fi
    local perm
    perm=$(cis_file_perm /etc/shadow)
    if cis_perm_le "$perm" "640"; then
        cis_record_result "CL-40" "PASS" "/etc/shadow 권한=${perm}(최대 640)"
    else
        cis_record_result "CL-40" "FAIL" "/etc/shadow 권한=${perm} — 640 이하로 제한 필요"
    fi
}

check_CL_41() {
    cis_print_check "CL-41"
    _cis_file_check "CL-41" "/etc/group" "644" "root"
}

check_CL_42() {
    cis_print_check "CL-42"
    if ! cis_command_exists find; then
        cis_record_result "CL-42" "REVIEW" "find 명령을 사용할 수 없음"
        return
    fi
    # 로컬 파일시스템에서 world-writable 파일 탐색 (파일만, 최대 100개까지만 수집)
    local hits
    hits=$(find / -xdev -type f -perm -0002 2>/dev/null | head -100)
    local count
    count=$(printf '%s\n' "$hits" | grep -c .)
    if [ "${count:-0}" -eq 0 ] 2>/dev/null; then
        cis_record_result "CL-42" "PASS" "world-writable 파일이 발견되지 않음"
    else
        local sample
        sample=$(printf '%s\n' "$hits" | head -3 | tr '\n' ' ')
        cis_record_result "CL-42" "REVIEW" "world-writable 파일 ${count}개 발견(최대 100개 집계) (예: ${sample}) — 검토 필요"
    fi
}

check_CL_43() {
    cis_print_check "CL-43"
    if ! cis_command_exists find; then
        cis_record_result "CL-43" "REVIEW" "find 명령을 사용할 수 없음"
        return
    fi
    local hits
    hits=$(find / -xdev \( -nouser -o -nogroup \) 2>/dev/null | head -100)
    local count
    count=$(printf '%s\n' "$hits" | grep -c .)
    if [ "${count:-0}" -eq 0 ] 2>/dev/null; then
        cis_record_result "CL-43" "PASS" "소유자/그룹 없는 파일이 발견되지 않음"
    else
        local sample
        sample=$(printf '%s\n' "$hits" | head -3 | tr '\n' ' ')
        cis_record_result "CL-43" "FAIL" "소유자/그룹 없는 파일 ${count}개 발견(최대 100개 집계) (예: ${sample})"
    fi
}

check_CL_44() {
    cis_print_check "CL-44"
    if [ ! -f /etc/passwd ]; then
        cis_record_result "CL-44" "REVIEW" "/etc/passwd가 없어 점검 불가"
        return
    fi
    local uid0
    uid0=$(awk -F: '($3 == 0) {print $1}' /etc/passwd)
    local count
    count=$(echo "$uid0" | grep -c . )
    if [ "$count" -eq 1 ] && [ "$uid0" = "root" ]; then
        cis_record_result "CL-44" "PASS" "UID 0 계정이 root 단독"
    else
        cis_record_result "CL-44" "FAIL" "root 외 UID 0 계정 존재: $(echo "$uid0" | tr '\n' ' ')"
    fi
}
