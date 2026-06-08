#!/bin/bash
# 섹션 5: 컨테이너 런타임 (D-48 ~ D-62)

check_D_48() {
    docker_print_check "D-48"
    local containers
    containers=$(get_running_containers)
    if [ -z "$containers" ]; then
        docker_record_result "D-48" "REVIEW" "실행 중인 컨테이너 없음"
        return
    fi
    local no_apparmor=""
    for cid in $containers; do
        local profile
        profile=$(docker inspect "$cid" 2>/dev/null | grep '"AppArmorProfile"' | head -1 | sed 's/.*: "\(.*\)".*/\1/' | tr -d ' ')
        if [ -z "$profile" ] || [ "$profile" = "" ]; then
            local name
            name=$(docker inspect "$cid" 2>/dev/null | grep '"Name"' | head -1 | sed 's/.*: "\(.*\)".*/\1/')
            no_apparmor="${no_apparmor}${name} "
        fi
    done
    if [ -z "$no_apparmor" ]; then
        docker_record_result "D-48" "PASS" "모든 컨테이너에 AppArmor 프로파일 설정됨"
    else
        # AppArmor는 Debian/Ubuntu 계열에서만 지원
        if docker_command_exists apparmor_status; then
            docker_record_result "D-48" "REVIEW" "AppArmor 프로파일 미설정 컨테이너: ${no_apparmor}"
        else
            docker_record_result "D-48" "REVIEW" "AppArmor 미지원 시스템 — SELinux 또는 seccomp 사용 확인"
        fi
    fi
}

check_D_49() {
    docker_print_check "D-49"
    if docker_command_exists getenforce; then
        local selinux_status
        selinux_status=$(getenforce 2>/dev/null)
        if [ "$selinux_status" = "Enforcing" ] || [ "$selinux_status" = "Permissive" ]; then
            docker_record_result "D-49" "PASS" "SELinux 활성화됨: ${selinux_status}"
        else
            docker_record_result "D-49" "REVIEW" "SELinux 비활성화 — AppArmor 또는 seccomp 사용 확인"
        fi
    else
        docker_record_result "D-49" "REVIEW" "SELinux 미지원 시스템 — AppArmor 사용 여부 확인 (D-48)"
    fi
}

check_D_50() {
    docker_print_check "D-50"
    local containers
    containers=$(get_running_containers)
    if [ -z "$containers" ]; then
        docker_record_result "D-50" "PASS" "실행 중인 컨테이너 없음"
        return
    fi
    local privileged_list=""
    for cid in $containers; do
        local priv
        priv=$(docker inspect "$cid" 2>/dev/null | grep '"Privileged"' | head -1 | grep -o 'true\|false')
        if [ "$priv" = "true" ]; then
            local name
            name=$(docker inspect "$cid" 2>/dev/null | grep '"Name"' | head -1 | sed 's/.*: "\(.*\)".*/\1/')
            privileged_list="${privileged_list}${name} "
        fi
    done
    if [ -z "$privileged_list" ]; then
        docker_record_result "D-50" "PASS" "privileged 컨테이너 없음"
    else
        docker_record_result "D-50" "FAIL" "privileged 컨테이너 발견: ${privileged_list}"
    fi
}

check_D_51() {
    docker_print_check "D-51"
    local containers
    containers=$(get_running_containers)
    if [ -z "$containers" ]; then
        docker_record_result "D-51" "PASS" "실행 중인 컨테이너 없음"
        return
    fi
    local sensitive_mounts=""
    local sensitive_paths=("/etc" "/root" "/proc" "/sys" "/dev" "/boot")
    for cid in $containers; do
        local mounts
        mounts=$(docker inspect "$cid" 2>/dev/null | grep '"Source"' | grep -oE '"(/etc|/root|/proc|/sys|/dev|/boot)[^"]*"')
        if [ -n "$mounts" ]; then
            local name
            name=$(docker inspect "$cid" 2>/dev/null | grep '"Name"' | head -1 | sed 's/.*: "\(.*\)".*/\1/')
            sensitive_mounts="${sensitive_mounts}${name}:${mounts} "
        fi
    done
    if [ -z "$sensitive_mounts" ]; then
        docker_record_result "D-51" "PASS" "민감 호스트 디렉토리 마운트 없음"
    else
        docker_record_result "D-51" "FAIL" "민감 디렉토리 마운트 발견: ${sensitive_mounts}"
    fi
}

check_D_52() {
    docker_print_check "D-52"
    local containers
    containers=$(get_running_containers)
    if [ -z "$containers" ]; then
        docker_record_result "D-52" "PASS" "실행 중인 컨테이너 없음"
        return
    fi
    local ssh_running=""
    for cid in $containers; do
        local procs
        procs=$(docker exec "$cid" ps -ef 2>/dev/null | grep sshd | grep -v grep)
        if [ -n "$procs" ]; then
            local name
            name=$(docker inspect "$cid" 2>/dev/null | grep '"Name"' | head -1 | sed 's/.*: "\(.*\)".*/\1/')
            ssh_running="${ssh_running}${name} "
        fi
    done
    if [ -z "$ssh_running" ]; then
        docker_record_result "D-52" "PASS" "SSH 데몬 실행 컨테이너 없음"
    else
        docker_record_result "D-52" "FAIL" "SSH 데몬 실행 중인 컨테이너: ${ssh_running}"
    fi
}

check_D_53() {
    docker_print_check "D-53"
    local low_ports
    low_ports=$(docker ps --format '{{.Ports}}' 2>/dev/null | grep -oE '0\.0\.0\.0:[0-9]+|[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+' | \
        awk -F: '{if ($NF > 0 && $NF < 1024) print $0}')
    if [ -z "$low_ports" ]; then
        docker_record_result "D-53" "PASS" "1024 미만 포트 바인딩 없음"
    else
        docker_record_result "D-53" "REVIEW" "1024 미만 포트 바인딩: ${low_ports}"
    fi
}

check_D_54() {
    docker_print_check "D-54"
    local containers
    containers=$(get_running_containers)
    if [ -z "$containers" ]; then
        docker_record_result "D-54" "PASS" "실행 중인 컨테이너 없음"
        return
    fi
    local exposed_info=""
    for cid in $containers; do
        local ports
        ports=$(docker inspect "$cid" 2>/dev/null | grep -A2 '"ExposedPorts"' | grep -o '"[0-9]*/[a-z]*"' | tr '\n' ' ')
        if [ -n "$ports" ]; then
            local name
            name=$(docker inspect "$cid" 2>/dev/null | grep '"Name"' | head -1 | sed 's/.*: "\(.*\)".*/\1/')
            exposed_info="${exposed_info}${name}[${ports}] "
        fi
    done
    if [ -n "$exposed_info" ]; then
        docker_record_result "D-54" "REVIEW" "개방된 포트 확인 필요 (불필요한 포트 제거 권장): ${exposed_info}"
    else
        docker_record_result "D-54" "PASS" "개방된 포트 없음"
    fi
}

check_D_55() {
    docker_print_check "D-55"
    local containers
    containers=$(get_running_containers)
    if [ -z "$containers" ]; then
        docker_record_result "D-55" "PASS" "실행 중인 컨테이너 없음"
        return
    fi
    local host_net=""
    for cid in $containers; do
        local net_mode
        net_mode=$(docker inspect "$cid" 2>/dev/null | grep '"NetworkMode"' | head -1 | sed 's/.*: "\(.*\)".*/\1/' | tr -d ' ')
        if [ "$net_mode" = "host" ]; then
            local name
            name=$(docker inspect "$cid" 2>/dev/null | grep '"Name"' | head -1 | sed 's/.*: "\(.*\)".*/\1/')
            host_net="${host_net}${name} "
        fi
    done
    if [ -z "$host_net" ]; then
        docker_record_result "D-55" "PASS" "호스트 네트워크 모드 컨테이너 없음"
    else
        docker_record_result "D-55" "FAIL" "호스트 네트워크 모드 컨테이너: ${host_net}"
    fi
}

check_D_56() {
    docker_print_check "D-56"
    local containers
    containers=$(get_running_containers)
    if [ -z "$containers" ]; then
        docker_record_result "D-56" "PASS" "실행 중인 컨테이너 없음"
        return
    fi
    local no_mem_limit=""
    for cid in $containers; do
        local mem
        mem=$(docker inspect "$cid" 2>/dev/null | grep '"Memory"' | head -1 | grep -o '[0-9]*')
        if [ -z "$mem" ] || [ "$mem" = "0" ]; then
            local name
            name=$(docker inspect "$cid" 2>/dev/null | grep '"Name"' | head -1 | sed 's/.*: "\(.*\)".*/\1/')
            no_mem_limit="${no_mem_limit}${name} "
        fi
    done
    if [ -z "$no_mem_limit" ]; then
        docker_record_result "D-56" "PASS" "모든 컨테이너에 메모리 제한 설정됨"
    else
        docker_record_result "D-56" "REVIEW" "메모리 제한 미설정 컨테이너: ${no_mem_limit}"
    fi
}

check_D_57() {
    docker_print_check "D-57"
    local containers
    containers=$(get_running_containers)
    if [ -z "$containers" ]; then
        docker_record_result "D-57" "PASS" "실행 중인 컨테이너 없음"
        return
    fi
    local no_cpu_limit=""
    for cid in $containers; do
        local cpu_shares nano_cpus
        cpu_shares=$(docker inspect "$cid" 2>/dev/null | grep '"CpuShares"' | head -1 | grep -o '[0-9]*')
        nano_cpus=$(docker inspect "$cid" 2>/dev/null | grep '"NanoCpus"' | head -1 | grep -o '[0-9]*')
        if { [ -z "$cpu_shares" ] || [ "$cpu_shares" = "0" ]; } && { [ -z "$nano_cpus" ] || [ "$nano_cpus" = "0" ]; }; then
            local name
            name=$(docker inspect "$cid" 2>/dev/null | grep '"Name"' | head -1 | sed 's/.*: "\(.*\)".*/\1/')
            no_cpu_limit="${no_cpu_limit}${name} "
        fi
    done
    if [ -z "$no_cpu_limit" ]; then
        docker_record_result "D-57" "PASS" "모든 컨테이너에 CPU 제한 설정됨"
    else
        docker_record_result "D-57" "REVIEW" "CPU 제한 미설정 컨테이너: ${no_cpu_limit}"
    fi
}

check_D_58() {
    docker_print_check "D-58"
    # D-38과 유사하나 런타임 관점에서 재확인
    local containers
    containers=$(get_running_containers)
    if [ -z "$containers" ]; then
        docker_record_result "D-58" "PASS" "실행 중인 컨테이너 없음"
        return
    fi
    local writable=""
    for cid in $containers; do
        local readonly
        readonly=$(docker inspect "$cid" 2>/dev/null | grep '"ReadonlyRootfs"' | grep -o 'true\|false' | head -1)
        if [ "$readonly" != "true" ]; then
            local name
            name=$(docker inspect "$cid" 2>/dev/null | grep '"Name"' | head -1 | sed 's/.*: "\(.*\)".*/\1/')
            writable="${writable}${name} "
        fi
    done
    if [ -z "$writable" ]; then
        docker_record_result "D-58" "PASS" "모든 컨테이너 루트 파일시스템 읽기 전용"
    else
        docker_record_result "D-58" "REVIEW" "쓰기 가능 루트 파일시스템 컨테이너: ${writable}"
    fi
}

check_D_59() {
    docker_print_check "D-59"
    local containers
    containers=$(get_running_containers)
    if [ -z "$containers" ]; then
        docker_record_result "D-59" "PASS" "실행 중인 컨테이너 없음"
        return
    fi
    local bad_prop=""
    for cid in $containers; do
        local propagation
        propagation=$(docker inspect "$cid" 2>/dev/null | grep '"Propagation"' | grep -oE '"shared"|"rshared"|"slave"|"rslave"' | head -1)
        if [ -n "$propagation" ]; then
            local name
            name=$(docker inspect "$cid" 2>/dev/null | grep '"Name"' | head -1 | sed 's/.*: "\(.*\)".*/\1/')
            bad_prop="${bad_prop}${name}(${propagation}) "
        fi
    done
    if [ -z "$bad_prop" ]; then
        docker_record_result "D-59" "PASS" "마운트 전파 모드 안전 (private)"
    else
        docker_record_result "D-59" "FAIL" "공유 마운트 전파 설정 컨테이너: ${bad_prop}"
    fi
}

check_D_60() {
    docker_print_check "D-60"
    local containers
    containers=$(get_running_containers)
    if [ -z "$containers" ]; then
        docker_record_result "D-60" "PASS" "실행 중인 컨테이너 없음"
        return
    fi
    local host_uts=""
    for cid in $containers; do
        local uts_mode
        uts_mode=$(docker inspect "$cid" 2>/dev/null | grep '"UTSMode"' | head -1 | sed 's/.*: "\(.*\)".*/\1/' | tr -d ' ')
        if [ "$uts_mode" = "host" ]; then
            local name
            name=$(docker inspect "$cid" 2>/dev/null | grep '"Name"' | head -1 | sed 's/.*: "\(.*\)".*/\1/')
            host_uts="${host_uts}${name} "
        fi
    done
    if [ -z "$host_uts" ]; then
        docker_record_result "D-60" "PASS" "호스트 UTS 네임스페이스 공유 컨테이너 없음"
    else
        docker_record_result "D-60" "FAIL" "호스트 UTS 네임스페이스 공유 컨테이너: ${host_uts}"
    fi
}

check_D_61() {
    docker_print_check "D-61"
    local containers
    containers=$(get_running_containers)
    if [ -z "$containers" ]; then
        docker_record_result "D-61" "PASS" "실행 중인 컨테이너 없음"
        return
    fi
    local unconfined=""
    for cid in $containers; do
        local sec_opt
        sec_opt=$(docker inspect "$cid" 2>/dev/null | grep -A5 '"SecurityOpt"' | grep "seccomp=unconfined")
        if [ -n "$sec_opt" ]; then
            local name
            name=$(docker inspect "$cid" 2>/dev/null | grep '"Name"' | head -1 | sed 's/.*: "\(.*\)".*/\1/')
            unconfined="${unconfined}${name} "
        fi
    done
    if [ -z "$unconfined" ]; then
        docker_record_result "D-61" "PASS" "seccomp=unconfined 컨테이너 없음"
    else
        docker_record_result "D-61" "FAIL" "seccomp 해제된 컨테이너: ${unconfined}"
    fi
}

check_D_62() {
    docker_print_check "D-62"
    local containers
    containers=$(get_running_containers)
    if [ -z "$containers" ]; then
        docker_record_result "D-62" "PASS" "실행 중인 컨테이너 없음"
        return
    fi
    local host_ns=""
    for cid in $containers; do
        local pid_mode ipc_mode
        pid_mode=$(docker inspect "$cid" 2>/dev/null | grep '"PidMode"' | head -1 | sed 's/.*: "\(.*\)".*/\1/' | tr -d ' ')
        ipc_mode=$(docker inspect "$cid" 2>/dev/null | grep '"IpcMode"' | head -1 | sed 's/.*: "\(.*\)".*/\1/' | tr -d ' ')
        if [ "$pid_mode" = "host" ] || [ "$ipc_mode" = "host" ]; then
            local name
            name=$(docker inspect "$cid" 2>/dev/null | grep '"Name"' | head -1 | sed 's/.*: "\(.*\)".*/\1/')
            host_ns="${host_ns}${name}(PID:${pid_mode}/IPC:${ipc_mode}) "
        fi
    done
    if [ -z "$host_ns" ]; then
        docker_record_result "D-62" "PASS" "호스트 PID/IPC 네임스페이스 공유 컨테이너 없음"
    else
        docker_record_result "D-62" "FAIL" "호스트 네임스페이스 공유 컨테이너: ${host_ns}"
    fi
}
