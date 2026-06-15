#!/bin/bash
# 섹션 1: 초기 설정 (CL-01 ~ CL-10)

check_CL_01() {
    cis_print_check "CL-01"
    local modules=("cramfs" "freevxfs" "jffs2" "hfs" "hfsplus" "udf")
    local loadable=""
    if ! cis_command_exists modprobe; then
        cis_record_result "CL-01" "REVIEW" "modprobe 명령을 사용할 수 없어 모듈 점검 불가"
        return
    fi
    for m in "${modules[@]}"; do
        # install ... /bin/false 또는 blacklist 설정이 없으면 로드 가능으로 간주
        local conf
        conf=$(modprobe -n -v "$m" 2>/dev/null | head -1)
        if echo "$conf" | grep -qiE "install[[:space:]]+/bin/(false|true)"; then
            continue
        fi
        # blacklist 확인
        if grep -rqi "blacklist[[:space:]]\+$m" /etc/modprobe.d/ 2>/dev/null; then
            continue
        fi
        loadable="${loadable}${m} "
    done
    if [ -z "$loadable" ]; then
        cis_record_result "CL-01" "PASS" "불필요한 파일시스템 모듈이 모두 비활성화됨"
    else
        cis_record_result "CL-01" "FAIL" "로드 가능한 파일시스템 모듈: ${loadable}"
    fi
}

check_CL_02() {
    cis_print_check "CL-02"
    if mount 2>/dev/null | grep -qE " on /tmp " || findmnt /tmp >/dev/null 2>&1; then
        cis_record_result "CL-02" "PASS" "/tmp가 별도 파티션/마운트로 분리됨"
    else
        cis_record_result "CL-02" "FAIL" "/tmp가 별도 파티션으로 분리되어 있지 않음"
    fi
}

check_CL_03() {
    cis_print_check "CL-03"
    local opts
    opts=$(findmnt -no OPTIONS /tmp 2>/dev/null || mount 2>/dev/null | grep " on /tmp " | sed 's/.*(\(.*\)).*/\1/')
    if [ -z "$opts" ]; then
        cis_record_result "CL-03" "REVIEW" "/tmp가 별도 마운트가 아니어서 옵션 점검 불가"
        return
    fi
    local missing=""
    for o in nodev nosuid noexec; do
        echo "$opts" | grep -qw "$o" || missing="${missing}${o} "
    done
    if [ -z "$missing" ]; then
        cis_record_result "CL-03" "PASS" "/tmp에 nodev,nosuid,noexec 적용됨 (${opts})"
    else
        cis_record_result "CL-03" "FAIL" "/tmp 누락 옵션: ${missing}(현재: ${opts})"
    fi
}

check_CL_04() {
    cis_print_check "CL-04"
    if findmnt /var/log >/dev/null 2>&1 || mount 2>/dev/null | grep -qE " on /var/log "; then
        cis_record_result "CL-04" "PASS" "/var/log가 별도 파티션으로 분리됨"
    else
        cis_record_result "CL-04" "FAIL" "/var/log가 별도 파티션으로 분리되어 있지 않음"
    fi
}

check_CL_05() {
    cis_print_check "CL-05"
    local opts
    opts=$(findmnt -no OPTIONS /home 2>/dev/null || mount 2>/dev/null | grep " on /home " | sed 's/.*(\(.*\)).*/\1/')
    if [ -z "$opts" ]; then
        cis_record_result "CL-05" "REVIEW" "/home가 별도 마운트가 아니어서 옵션 점검 불가"
        return
    fi
    if echo "$opts" | grep -qw nodev; then
        cis_record_result "CL-05" "PASS" "/home에 nodev 적용됨 (${opts})"
    else
        cis_record_result "CL-05" "FAIL" "/home에 nodev 미적용 (현재: ${opts})"
    fi
}

check_CL_06() {
    cis_print_check "CL-06"
    local grub_files=("/boot/grub/grub.cfg" "/boot/grub2/grub.cfg" "/boot/efi/EFI"*/grub.cfg)
    local found=""
    local bad=""
    for f in "${grub_files[@]}"; do
        [ -f "$f" ] || continue
        found="$f"
        local perm
        perm=$(cis_file_perm "$f")
        if cis_perm_le "$perm" "600"; then
            : # ok
        else
            bad="${bad}${f}(${perm}) "
        fi
    done
    if [ -z "$found" ]; then
        cis_record_result "CL-06" "REVIEW" "부트로더 설정 파일을 찾을 수 없음 (배포판별 경로 상이)"
    elif [ -z "$bad" ]; then
        cis_record_result "CL-06" "PASS" "부트로더 설정 파일 권한이 600 이하"
    else
        cis_record_result "CL-06" "FAIL" "권한 초과 부트로더 파일: ${bad}"
    fi
}

check_CL_07() {
    cis_print_check "CL-07"
    local val
    val=$(cis_sysctl_get kernel.randomize_va_space)
    if [ -z "$val" ]; then
        cis_record_result "CL-07" "REVIEW" "kernel.randomize_va_space 값을 확인할 수 없음"
    elif [ "$val" = "2" ]; then
        cis_record_result "CL-07" "PASS" "ASLR 완전 활성화 (randomize_va_space=2)"
    else
        cis_record_result "CL-07" "FAIL" "ASLR 미흡 (randomize_va_space=${val}, 권장:2)"
    fi
}

check_CL_08() {
    cis_print_check "CL-08"
    local suid_dump
    suid_dump=$(cis_sysctl_get fs.suid_dumpable)
    local hard_core="미설정"
    if grep -rqE "^\s*\*\s+hard\s+core\s+0" /etc/security/limits.conf /etc/security/limits.d/ 2>/dev/null; then
        hard_core="설정됨"
    fi
    if [ "$suid_dump" = "0" ] && [ "$hard_core" = "설정됨" ]; then
        cis_record_result "CL-08" "PASS" "core dump 제한됨 (suid_dumpable=0, hard core 0)"
    else
        cis_record_result "CL-08" "FAIL" "core dump 제한 미흡 (suid_dumpable=${suid_dump:-?}, hard core ${hard_core})"
    fi
}

check_CL_09() {
    cis_print_check "CL-09"
    # SELinux 우선 확인
    if cis_command_exists getenforce; then
        local se
        se=$(getenforce 2>/dev/null)
        if [ "$se" = "Enforcing" ]; then
            cis_record_result "CL-09" "PASS" "SELinux Enforcing 모드"
            return
        elif [ "$se" = "Permissive" ]; then
            cis_record_result "CL-09" "FAIL" "SELinux가 Permissive 모드 (Enforcing 권장)"
            return
        fi
    fi
    # AppArmor 확인
    if cis_command_exists aa-status; then
        if aa-status --enabled 2>/dev/null; then
            local enforced
            enforced=$(aa-status 2>/dev/null | grep -i "profiles are in enforce" | grep -oE "[0-9]+" | head -1)
            cis_record_result "CL-09" "PASS" "AppArmor 활성화 (enforce 프로파일 ${enforced:-?}개)"
            return
        fi
    fi
    cis_record_result "CL-09" "FAIL" "AppArmor/SELinux가 활성화되어 있지 않음"
}

check_CL_10() {
    cis_print_check "CL-10"
    local banner=""
    for f in /etc/issue /etc/issue.net /etc/motd; do
        if [ -s "$f" ]; then
            banner="${banner}${f} "
        fi
    done
    if [ -n "$banner" ]; then
        # OS 정보 노출 여부 간단 점검 (\m \r \s \v 또는 배포판명)
        if grep -qE '\\[mrsv]' /etc/issue 2>/dev/null; then
            cis_record_result "CL-10" "REVIEW" "배너 존재하나 OS 정보 노출 가능 이스케이프(\\m\\r\\s\\v) 포함 — 확인 필요 (${banner})"
        else
            cis_record_result "CL-10" "PASS" "로그인 경고 배너 설정됨 (${banner})"
        fi
    else
        cis_record_result "CL-10" "FAIL" "로그인 경고 배너가 설정되어 있지 않음"
    fi
}
