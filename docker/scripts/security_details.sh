#!/bin/bash

################################################################################
# Docker 보안 항목 상세 정보 (CIS Docker Benchmark v1.6.0 기반)
################################################################################

declare -A DOCKER_DETAILS=(
    # D-01
    ["D-01_PURPOSE"]="최신 커널의 보안 패치 및 기능을 활용하여 컨테이너 격리 취약점 방지"
    ["D-01_CHECK"]="uname -r로 커널 버전 확인"
    ["D-01_GOOD"]="커널이 최신 보안 패치 버전으로 유지됨"
    ["D-01_BAD"]="구버전 커널 사용 또는 보안 패치 미적용"
    ["D-01_ACTION"]="apt/yum 등 패키지 매니저로 커널 업데이트 후 재부팅"
    ["D-01_THREAT"]="구버전 커널의 취약점을 통한 컨테이너 탈출 및 권한 상승"

    # D-02
    ["D-02_PURPOSE"]="Docker 데이터를 별도 파티션에 격리하여 호스트 디스크 고갈 방지"
    ["D-02_CHECK"]="df /var/lib/docker로 별도 마운트 포인트 확인"
    ["D-02_GOOD"]="/var/lib/docker가 독립적인 파티션에 마운트됨"
    ["D-02_BAD"]="루트 파티션과 동일한 공간 사용"
    ["D-02_ACTION"]="별도 볼륨을 /var/lib/docker에 마운트 설정"
    ["D-02_THREAT"]="컨테이너 이미지·로그 증가로 인한 호스트 시스템 디스크 고갈 DoS"

    # D-03
    ["D-03_PURPOSE"]="docker 그룹 멤버는 root와 동등한 권한을 가지므로 최소화 필요"
    ["D-03_CHECK"]="getent group docker로 그룹 멤버 확인"
    ["D-03_GOOD"]="docker 그룹에 최소한의 인가된 사용자만 포함"
    ["D-03_BAD"]="불필요한 일반 사용자가 docker 그룹에 포함"
    ["D-03_ACTION"]="gpasswd -d <username> docker로 불필요한 멤버 제거"
    ["D-03_THREAT"]="docker 그룹 멤버는 컨테이너를 통해 사실상 root 권한 획득 가능"

    # D-04
    ["D-04_PURPOSE"]="Docker 실행 바이너리에 대한 접근을 감사하여 비인가 실행 탐지"
    ["D-04_CHECK"]="auditctl -l | grep docker 확인"
    ["D-04_GOOD"]="/usr/bin/docker 또는 /usr/local/bin/docker에 감사 규칙 설정"
    ["D-04_BAD"]="Docker 바이너리에 대한 감사 규칙 미설정"
    ["D-04_ACTION"]="echo '-w /usr/bin/docker -p rwxa -k docker' >> /etc/audit/rules.d/docker.rules && augenrules --load"
    ["D-04_THREAT"]="비인가자의 Docker 명령어 실행을 탐지하지 못함"

    # D-05
    ["D-05_PURPOSE"]="컨테이너 데이터 저장소에 대한 접근 변경 이력 확보"
    ["D-05_CHECK"]="auditctl -l | grep /var/lib/docker 확인"
    ["D-05_GOOD"]="/var/lib/docker에 감사 규칙 설정"
    ["D-05_BAD"]="/var/lib/docker 감사 규칙 미설정"
    ["D-05_ACTION"]="echo '-a always,exit -F path=/var/lib/docker -k docker' >> /etc/audit/rules.d/docker.rules"
    ["D-05_THREAT"]="컨테이너 데이터 위변조에 대한 사후 추적 불가"

    # D-06
    ["D-06_PURPOSE"]="Docker 데몬 설정 디렉토리 변경 이력 확보"
    ["D-06_CHECK"]="auditctl -l | grep /etc/docker 확인"
    ["D-06_GOOD"]="/etc/docker 디렉토리에 감사 규칙 설정"
    ["D-06_BAD"]="/etc/docker 감사 규칙 미설정"
    ["D-06_ACTION"]="echo '-w /etc/docker -p rwxa -k docker' >> /etc/audit/rules.d/docker.rules"
    ["D-06_THREAT"]="Docker 데몬 설정 무단 변경 탐지 불가"

    # D-07
    ["D-07_PURPOSE"]="Docker 서비스 파일 변경을 감사하여 서비스 설정 무단 변경 탐지"
    ["D-07_CHECK"]="auditctl -l | grep docker.service 확인"
    ["D-07_GOOD"]="docker.service 파일에 감사 규칙 설정"
    ["D-07_BAD"]="docker.service 감사 규칙 미설정"
    ["D-07_ACTION"]="echo '-w /lib/systemd/system/docker.service -p rwxa -k docker' >> /etc/audit/rules.d/docker.rules"
    ["D-07_THREAT"]="Docker 서비스 설정 무단 변경으로 인한 보안 기능 우회"

    # D-08
    ["D-08_PURPOSE"]="컨테이너 간 불필요한 네트워크 통신 차단으로 내부 피벗팅 방지"
    ["D-08_CHECK"]="docker network inspect bridge | grep -i 'com.docker.network.bridge.enable_icc'"
    ["D-08_GOOD"]="ICC(Inter-Container Communication)가 false로 설정됨"
    ["D-08_BAD"]="ICC가 true(기본값)로 설정되어 컨테이너 간 자유로운 통신 허용"
    ["D-08_ACTION"]="daemon.json에 {\"icc\": false} 추가 후 Docker 재시작"
    ["D-08_THREAT"]="침해된 컨테이너를 통한 다른 컨테이너 횡적 이동"

    # D-09
    ["D-09_PURPOSE"]="적절한 로깅 레벨로 보안 이벤트 기록 및 과도한 로그 방지"
    ["D-09_CHECK"]="docker info | grep -i 'logging level'"
    ["D-09_GOOD"]="로깅 레벨이 info로 설정됨"
    ["D-09_BAD"]="debug 레벨(과도한 로그) 또는 warn 이상(보안 이벤트 누락)"
    ["D-09_ACTION"]="daemon.json에 {\"log-level\": \"info\"} 설정"
    ["D-09_THREAT"]="부적절한 로그 레벨로 보안 사고 탐지 및 포렌식 어려움"

    # D-10
    ["D-10_PURPOSE"]="Docker가 관리하는 iptables 규칙을 유지하여 네트워크 격리 보장"
    ["D-10_CHECK"]="docker info | grep -i iptables"
    ["D-10_GOOD"]="iptables가 활성화됨 (Docker 기본값)"
    ["D-10_BAD"]="--iptables=false 설정으로 네트워크 격리 규칙 미적용"
    ["D-10_ACTION"]="daemon.json에서 {\"iptables\": false} 설정 제거"
    ["D-10_THREAT"]="iptables 비활성화로 컨테이너 네트워크 격리 우회 가능"

    # D-11
    ["D-11_PURPOSE"]="신뢰할 수 없는 레지스트리의 이미지 사용으로 인한 공급망 공격 방지"
    ["D-11_CHECK"]="docker info | grep -i 'insecure registries'"
    ["D-11_GOOD"]="insecure-registries 설정이 비어 있거나 없음"
    ["D-11_BAD"]="HTTP 통신을 허용하는 insecure-registries 설정 존재"
    ["D-11_ACTION"]="daemon.json에서 insecure-registries 항목 제거 후 HTTPS 레지스트리 사용"
    ["D-11_THREAT"]="중간자 공격으로 악성 이미지 배포 가능"

    # D-12
    ["D-12_PURPOSE"]="aufs는 보안 취약점이 많은 레거시 스토리지 드라이버"
    ["D-12_CHECK"]="docker info | grep -i 'storage driver'"
    ["D-12_GOOD"]="overlay2, devicemapper 등 현대적 스토리지 드라이버 사용"
    ["D-12_BAD"]="aufs 스토리지 드라이버 사용 중"
    ["D-12_ACTION"]="daemon.json에 {\"storage-driver\": \"overlay2\"} 설정"
    ["D-12_THREAT"]="aufs 드라이버의 알려진 취약점을 통한 컨테이너 탈출"

    # D-13
    ["D-13_PURPOSE"]="원격 Docker API 접근 시 TLS로 클라이언트·서버 상호 인증"
    ["D-13_CHECK"]="docker info | grep -i tls, ps aux | grep dockerd | grep -i tls"
    ["D-13_GOOD"]="TLS 인증이 활성화되어 있거나 Unix 소켓만 사용"
    ["D-13_BAD"]="TCP 소켓으로 원격 접근 허용하면서 TLS 미적용"
    ["D-13_ACTION"]="dockerd --tlsverify --tlscacert --tlscert --tlskey 옵션 설정"
    ["D-13_THREAT"]="비인가자의 Docker 데몬 원격 제어 및 컨테이너 임의 실행"

    # D-14
    ["D-14_PURPOSE"]="컨테이너의 기본 리소스 제한으로 DoS 공격 방지"
    ["D-14_CHECK"]="docker info | grep -i ulimit"
    ["D-14_GOOD"]="기본 ulimit 값이 적절히 설정됨"
    ["D-14_BAD"]="nofile 등 ulimit 기본값 미설정으로 무제한 리소스 사용 가능"
    ["D-14_ACTION"]="daemon.json에 {\"default-ulimits\": {\"nofile\": {\"Name\": \"nofile\", \"Hard\": 64000, \"Soft\": 64000}}} 설정"
    ["D-14_THREAT"]="컨테이너의 파일 디스크립터 고갈로 호스트 시스템 DoS"

    # D-15
    ["D-15_PURPOSE"]="사용자 네임스페이스로 컨테이너 root를 호스트 비권한 사용자로 매핑"
    ["D-15_CHECK"]="docker info | grep -i 'userns'"
    ["D-15_GOOD"]="userns-remap 설정 활성화"
    ["D-15_BAD"]="사용자 네임스페이스 미설정 (컨테이너 root = 호스트 root)"
    ["D-15_ACTION"]="daemon.json에 {\"userns-remap\": \"default\"} 설정"
    ["D-15_THREAT"]="컨테이너 탈출 시 호스트에서 root 권한으로 실행됨"

    # D-16
    ["D-16_PURPOSE"]="기본 cgroup을 통한 컨테이너 리소스 격리 보장"
    ["D-16_CHECK"]="docker info | grep -i cgroup"
    ["D-16_GOOD"]="cgroupns 모드가 host 또는 private으로 적절히 설정"
    ["D-16_BAD"]="cgroup 설정이 비정상적이거나 격리가 무력화됨"
    ["D-16_ACTION"]="daemon.json에 {\"default-cgroupns-mode\": \"private\"} 설정"
    ["D-16_THREAT"]="cgroup 격리 우회로 인한 컨테이너 간 리소스 정보 노출"

    # D-17
    ["D-17_PURPOSE"]="컨테이너 신규 권한 획득 방지로 권한 상승 공격 차단"
    ["D-17_CHECK"]="docker info 또는 daemon.json에서 no-new-privileges 설정 확인"
    ["D-17_GOOD"]="no-new-privileges가 true로 설정됨"
    ["D-17_BAD"]="컨테이너 프로세스의 신규 권한 획득 허용"
    ["D-17_ACTION"]="daemon.json에 {\"no-new-privileges\": true} 설정"
    ["D-17_THREAT"]="setuid 바이너리 실행을 통한 컨테이너 내 권한 상승"

    # D-18
    ["D-18_PURPOSE"]="Docker 데몬은 Unix 소켓으로만 접근하고 원격 TCP 접근 차단"
    ["D-18_CHECK"]="ps aux | grep dockerd | grep -E '\\-H tcp'"
    ["D-18_GOOD"]="TCP 바인딩 없음, Unix 소켓만 사용"
    ["D-18_BAD"]="-H tcp://로 원격 접근 허용"
    ["D-18_ACTION"]="dockerd 실행 옵션에서 -H tcp:// 제거, Unix 소켓만 사용"
    ["D-18_THREAT"]="원격에서 Docker API 무단 접근으로 호스트 완전 장악 가능"

    # D-19
    ["D-19_PURPOSE"]="데몬 재시작 시 실행 중인 컨테이너가 중단되지 않도록 보장"
    ["D-19_CHECK"]="cat /etc/docker/daemon.json | grep live-restore"
    ["D-19_GOOD"]="live-restore가 true로 설정됨"
    ["D-19_BAD"]="live-restore 미설정으로 데몬 재시작 시 모든 컨테이너 중단"
    ["D-19_ACTION"]="daemon.json에 {\"live-restore\": true} 설정"
    ["D-19_THREAT"]="불필요한 서비스 중단 및 보안 업데이트 지연"

    # D-20
    ["D-20_PURPOSE"]="userland 프록시 대신 헤어핀 NAT 사용으로 공격 표면 감소"
    ["D-20_CHECK"]="cat /etc/docker/daemon.json | grep userland-proxy"
    ["D-20_GOOD"]="userland-proxy가 false로 설정됨"
    ["D-20_BAD"]="userland-proxy 활성화(기본값)로 추가 프로세스 실행"
    ["D-20_ACTION"]="daemon.json에 {\"userland-proxy\": false} 설정"
    ["D-20_THREAT"]="userland 프록시 프로세스의 취약점을 통한 공격 가능성"

    # D-21
    ["D-21_PURPOSE"]="안정성이 검증되지 않은 실험적 기능 사용 방지"
    ["D-21_CHECK"]="docker version | grep -i experimental, docker info | grep -i experimental"
    ["D-21_GOOD"]="실험적 기능이 비활성화됨"
    ["D-21_BAD"]="Experimental: true로 실험적 기능 활성화"
    ["D-21_ACTION"]="daemon.json에서 {\"experimental\": false} 설정 또는 항목 제거"
    ["D-21_THREAT"]="불안정한 실험적 기능의 보안 취약점 노출"

    # D-22
    ["D-22_PURPOSE"]="시스템 콜 필터링으로 컨테이너에서 위험한 커널 호출 차단"
    ["D-22_CHECK"]="docker info | grep -i seccomp"
    ["D-22_GOOD"]="seccomp 기본 프로파일이 적용됨"
    ["D-22_BAD"]="seccomp 프로파일 미적용 또는 --security-opt seccomp=unconfined"
    ["D-22_ACTION"]="컨테이너 실행 시 --security-opt seccomp=default 또는 커스텀 프로파일 적용"
    ["D-22_THREAT"]="위험한 시스템 콜을 통한 커널 취약점 공격 및 컨테이너 탈출"

    # D-23
    ["D-23_PURPOSE"]="TLS 사용 시 인증서 파일이 올바르게 설정되었는지 확인"
    ["D-23_CHECK"]="ps aux | grep dockerd | grep -E 'tlscacert|tlscert|tlskey'"
    ["D-23_GOOD"]="TLS 미사용(Unix 소켓 전용)이거나 TLS 인증서 3종 모두 설정"
    ["D-23_BAD"]="TLS 활성화 시 인증서 파일 일부 누락"
    ["D-23_ACTION"]="--tlscacert, --tlscert, --tlskey 3개 옵션 모두 설정"
    ["D-23_THREAT"]="불완전한 TLS 설정으로 인증 우회 가능"

    # D-24
    ["D-24_PURPOSE"]="컨테이너 로그를 중앙 집중화하여 보안 이벤트 모니터링"
    ["D-24_CHECK"]="docker info | grep -i 'logging driver'"
    ["D-24_GOOD"]="json-file 외 중앙 로그 드라이버(syslog, fluentd 등) 또는 적절한 옵션 설정"
    ["D-24_BAD"]="로그 설정 없이 기본값만 사용하여 로그 관리 미흡"
    ["D-24_ACTION"]="daemon.json에 log-driver 및 log-opts 설정"
    ["D-24_THREAT"]="보안 사고 발생 시 컨테이너 로그 확인 불가"

    # D-25
    ["D-25_PURPOSE"]="컨테이너 포트 바인딩을 특정 인터페이스로 제한하여 노출 최소화"
    ["D-25_CHECK"]="docker ps --format '{{.Ports}}' | grep '0.0.0.0'"
    ["D-25_GOOD"]="모든 포트가 특정 IP에만 바인딩됨"
    ["D-25_BAD"]="0.0.0.0으로 모든 인터페이스에 포트 바인딩"
    ["D-25_ACTION"]="docker run -p 127.0.0.1:PORT:PORT 형식으로 특정 인터페이스에만 바인딩"
    ["D-25_THREAT"]="의도하지 않은 인터페이스로의 서비스 노출"

    # D-26
    ["D-26_PURPOSE"]="docker.service 파일의 무단 변경 방지"
    ["D-26_CHECK"]="stat /lib/systemd/system/docker.service | grep -i owner"
    ["D-26_GOOD"]="docker.service 파일 소유자가 root:root"
    ["D-26_BAD"]="root 외 사용자가 소유자"
    ["D-26_ACTION"]="chown root:root /lib/systemd/system/docker.service"
    ["D-26_THREAT"]="비권한 사용자의 Docker 서비스 설정 변경"

    # D-27
    ["D-27_PURPOSE"]="docker.service 파일의 비권한 사용자 쓰기 방지"
    ["D-27_CHECK"]="stat /lib/systemd/system/docker.service | grep -i 'access'"
    ["D-27_GOOD"]="권한이 644 이하"
    ["D-27_BAD"]="group/other 쓰기 권한 존재"
    ["D-27_ACTION"]="chmod 644 /lib/systemd/system/docker.service"
    ["D-27_THREAT"]="Docker 서비스 파일 무단 수정으로 보안 기능 우회"

    # D-28
    ["D-28_PURPOSE"]="docker.socket 파일의 무단 변경 방지"
    ["D-28_CHECK"]="stat /lib/systemd/system/docker.socket | grep -i owner"
    ["D-28_GOOD"]="docker.socket 파일 소유자가 root:root"
    ["D-28_BAD"]="root 외 사용자 소유"
    ["D-28_ACTION"]="chown root:root /lib/systemd/system/docker.socket"
    ["D-28_THREAT"]="Docker 소켓 설정 무단 변경으로 접근 제어 우회"

    # D-29
    ["D-29_PURPOSE"]="docker.socket 파일의 비권한 사용자 쓰기 방지"
    ["D-29_CHECK"]="stat /lib/systemd/system/docker.socket | grep -i 'access'"
    ["D-29_GOOD"]="권한이 644 이하"
    ["D-29_BAD"]="group/other 쓰기 권한 존재"
    ["D-29_ACTION"]="chmod 644 /lib/systemd/system/docker.socket"
    ["D-29_THREAT"]="Docker 소켓 설정 파일 무단 변경"

    # D-30
    ["D-30_PURPOSE"]="/etc/docker 디렉토리의 무단 변경 방지"
    ["D-30_CHECK"]="stat /etc/docker | grep -i owner"
    ["D-30_GOOD"]="/etc/docker 소유자가 root:root"
    ["D-30_BAD"]="root 외 사용자 소유"
    ["D-30_ACTION"]="chown root:root /etc/docker"
    ["D-30_THREAT"]="Docker 설정 파일 무단 변경으로 보안 정책 우회"

    # D-31
    ["D-31_PURPOSE"]="/etc/docker 디렉토리의 비권한 사용자 쓰기 방지"
    ["D-31_CHECK"]="stat /etc/docker | grep -i 'access'"
    ["D-31_GOOD"]="권한이 755 이하"
    ["D-31_BAD"]="group/other 쓰기 권한 존재"
    ["D-31_ACTION"]="chmod 755 /etc/docker"
    ["D-31_THREAT"]="비권한 사용자의 Docker 설정 변경"

    # D-32~D-37: TLS 인증서 파일 권한
    ["D-32_PURPOSE"]="TLS CA 인증서의 무단 변경 방지"
    ["D-32_CHECK"]="stat <ca.pem> | grep owner"
    ["D-32_GOOD"]="CA 인증서 소유자가 root:root"
    ["D-32_BAD"]="root 외 사용자 소유"
    ["D-32_ACTION"]="chown root:root <ca.pem>"
    ["D-32_THREAT"]="CA 인증서 변경으로 인한 인증 우회"

    ["D-33_PURPOSE"]="TLS CA 인증서의 비권한 읽기·쓰기 방지"
    ["D-33_CHECK"]="stat <ca.pem> | grep access"
    ["D-33_GOOD"]="권한이 444 이하"
    ["D-33_BAD"]="group/other 읽기·쓰기 권한 존재"
    ["D-33_ACTION"]="chmod 444 <ca.pem>"
    ["D-33_THREAT"]="CA 인증서 유출 또는 변조"

    ["D-34_PURPOSE"]="Docker 서버 인증서의 무단 변경 방지"
    ["D-34_CHECK"]="stat <server-cert.pem> | grep owner"
    ["D-34_GOOD"]="서버 인증서 소유자가 root:root"
    ["D-34_BAD"]="root 외 사용자 소유"
    ["D-34_ACTION"]="chown root:root <server-cert.pem>"
    ["D-34_THREAT"]="서버 인증서 변조로 인한 인증 우회"

    ["D-35_PURPOSE"]="Docker 서버 인증서의 비권한 쓰기 방지"
    ["D-35_CHECK"]="stat <server-cert.pem> | grep access"
    ["D-35_GOOD"]="권한이 444 이하"
    ["D-35_BAD"]="group/other 쓰기 권한 존재"
    ["D-35_ACTION"]="chmod 444 <server-cert.pem>"
    ["D-35_THREAT"]="서버 인증서 무단 변조"

    ["D-36_PURPOSE"]="Docker 서버 키 파일의 무단 접근 방지"
    ["D-36_CHECK"]="stat <server-key.pem> | grep owner"
    ["D-36_GOOD"]="서버 키 파일 소유자가 root:root"
    ["D-36_BAD"]="root 외 사용자 소유"
    ["D-36_ACTION"]="chown root:root <server-key.pem>"
    ["D-36_THREAT"]="개인키 유출로 인한 서버 사칭 및 통신 복호화"

    ["D-37_PURPOSE"]="Docker 서버 키 파일의 비권한 읽기·쓰기 방지"
    ["D-37_CHECK"]="stat <server-key.pem> | grep access"
    ["D-37_GOOD"]="권한이 400 이하"
    ["D-37_BAD"]="group/other 읽기 권한 존재"
    ["D-37_ACTION"]="chmod 400 <server-key.pem>"
    ["D-37_THREAT"]="개인키 탈취를 통한 인증 우회 및 통신 도청"

    # D-38
    ["D-38_PURPOSE"]="컨테이너 내 파일시스템 변조 방지 및 불변 인프라 보장"
    ["D-38_CHECK"]="docker inspect <container> | grep ReadonlyRootfs"
    ["D-38_GOOD"]="ReadonlyRootfs가 true"
    ["D-38_BAD"]="ReadonlyRootfs가 false(기본값)"
    ["D-38_ACTION"]="docker run --read-only 옵션 사용, 쓰기 필요 경로는 tmpfs 또는 볼륨 마운트"
    ["D-38_THREAT"]="침해된 컨테이너에서 바이너리 변조를 통한 지속적 악성 코드 배포"

    # D-39
    ["D-39_PURPOSE"]="검증된 공식 이미지 사용으로 공급망 공격 방지"
    ["D-39_CHECK"]="docker images | grep -v 'docker.io/library' 등 출처 확인"
    ["D-39_GOOD"]="Docker 공식 이미지 또는 신뢰할 수 있는 레지스트리 이미지 사용"
    ["D-39_BAD"]="출처 불명의 이미지 사용"
    ["D-39_ACTION"]="Docker Hub 공식 이미지 또는 서명된 이미지만 사용 (docker trust 활용)"
    ["D-39_THREAT"]="악성 코드가 포함된 이미지 배포로 인한 컨테이너 환경 전체 침해"

    # D-40
    ["D-40_PURPOSE"]="불필요한 패키지 제거로 공격 표면 최소화"
    ["D-40_CHECK"]="docker history <image> | grep -i install"
    ["D-40_GOOD"]="최소한의 패키지만 설치된 경량 이미지 사용"
    ["D-40_BAD"]="불필요한 개발 도구, 셸, 패키지 포함"
    ["D-40_ACTION"]="Dockerfile에서 불필요한 RUN apt/yum install 제거, distroless 이미지 검토"
    ["D-40_THREAT"]="불필요한 도구를 통한 컨테이너 내 공격 행위 수행"

    # D-41
    ["D-41_PURPOSE"]="알려진 취약점이 포함된 이미지 사용 방지"
    ["D-41_CHECK"]="docker scan 또는 trivy 등 취약점 스캐너 결과 확인"
    ["D-41_GOOD"]="CRITICAL, HIGH 취약점이 없는 이미지 사용"
    ["D-41_BAD"]="취약점 스캔 미실시 또는 미조치"
    ["D-41_ACTION"]="docker scout cves <image> 또는 trivy image <image> 실행 후 취약점 조치"
    ["D-41_THREAT"]="알려진 CVE를 통한 컨테이너 및 호스트 침해"

    # D-42
    ["D-42_PURPOSE"]="컨테이너 프로세스를 non-root로 실행하여 침해 시 피해 최소화"
    ["D-42_CHECK"]="docker inspect <container> | grep '\"User\"'"
    ["D-42_GOOD"]="컨테이너 실행 사용자가 root(0)가 아님"
    ["D-42_BAD"]="User가 비어있거나 root/0"
    ["D-42_ACTION"]="Dockerfile에 USER <non-root> 지시어 추가 또는 docker run --user 옵션 사용"
    ["D-42_THREAT"]="컨테이너 탈출 시 호스트에서 root 권한으로 실행"

    # D-43
    ["D-43_PURPOSE"]="latest 태그는 버전이 고정되지 않아 예기치 않은 변경 발생 가능"
    ["D-43_CHECK"]="docker images | grep ':latest'"
    ["D-43_GOOD"]="모든 이미지가 명시적인 버전 태그 사용"
    ["D-43_BAD"]="latest 태그 사용 이미지 존재"
    ["D-43_ACTION"]="Dockerfile 및 docker-compose.yml에서 latest 대신 명시적 버전 태그 사용"
    ["D-43_THREAT"]="이미지 업데이트 시 예기치 않은 보안 취약점 도입"

    # D-44
    ["D-44_PURPOSE"]="컨테이너 상태 모니터링으로 비정상 컨테이너 자동 감지"
    ["D-44_CHECK"]="docker inspect <container> | grep -i healthcheck"
    ["D-44_GOOD"]="HEALTHCHECK 지시어가 설정됨"
    ["D-44_BAD"]="HEALTHCHECK 미설정"
    ["D-44_ACTION"]="Dockerfile에 HEALTHCHECK 지시어 추가"
    ["D-44_THREAT"]="비정상 상태의 컨테이너가 감지되지 않고 계속 실행"

    # D-45
    ["D-45_PURPOSE"]="setuid/setgid 바이너리를 통한 권한 상승 방지"
    ["D-45_CHECK"]="docker run --rm <image> find / -perm /6000 -type f 2>/dev/null"
    ["D-45_GOOD"]="불필요한 setuid/setgid 바이너리 없음"
    ["D-45_BAD"]="불필요한 setuid/setgid 바이너리 존재"
    ["D-45_ACTION"]="Dockerfile에서 RUN find / -perm /6000 -type f -exec chmod a-s {} \\; 추가"
    ["D-45_THREAT"]="setuid 바이너리를 통한 컨테이너 내 권한 상승"

    # D-46
    ["D-46_PURPOSE"]="ADD는 URL 다운로드 및 tar 자동 압축 해제 기능으로 예측 불가 동작 유발"
    ["D-46_CHECK"]="dockerfile 내 ADD 지시어 확인"
    ["D-46_GOOD"]="ADD 대신 COPY 사용 (URL은 curl/wget 명시적 사용)"
    ["D-46_BAD"]="Dockerfile에 ADD 지시어 사용"
    ["D-46_ACTION"]="ADD를 COPY로 교체, 원격 파일은 RUN curl 사용"
    ["D-46_THREAT"]="ADD의 자동 압축 해제 동작으로 인한 의도하지 않은 파일 배치"

    # D-47
    ["D-47_PURPOSE"]="이미지 내 하드코딩된 민감 정보 유출 방지"
    ["D-47_CHECK"]="docker history <image> | grep -iE 'password|secret|key|token'"
    ["D-47_GOOD"]="이미지 레이어에 민감 정보 없음"
    ["D-47_BAD"]="ENV, RUN 등으로 민감 정보가 이미지 레이어에 포함"
    ["D-47_ACTION"]="Docker Secrets, 환경 변수 파일, Vault 등 외부 시크릿 관리 사용"
    ["D-47_THREAT"]="이미지 유출 시 민감 정보 노출 및 시스템 침해"

    # D-48
    ["D-48_PURPOSE"]="AppArmor로 컨테이너 프로세스의 시스템 접근 제한"
    ["D-48_CHECK"]="docker inspect <container> | grep AppArmorProfile"
    ["D-48_GOOD"]="AppArmorProfile이 docker-default 또는 커스텀 프로파일로 설정됨"
    ["D-48_BAD"]="AppArmor 비활성화 또는 미설정"
    ["D-48_ACTION"]="docker run --security-opt apparmor=docker-default 또는 커스텀 프로파일 적용"
    ["D-48_THREAT"]="AppArmor 없이 컨테이너 프로세스가 과도한 시스템 자원 접근"

    # D-49
    ["D-49_PURPOSE"]="SELinux로 컨테이너와 호스트 간 강제 접근 제어"
    ["D-49_CHECK"]="docker info | grep -i selinux, docker inspect | grep SecurityOpt"
    ["D-49_GOOD"]="SELinux 레이블이 설정됨 (RHEL/CentOS 계열)"
    ["D-49_BAD"]="SELinux 옵션 미설정"
    ["D-49_ACTION"]="docker run --security-opt label=type:container_runtime_t 등 SELinux 레이블 설정"
    ["D-49_THREAT"]="SELinux 없이 컨테이너 프로세스의 비인가 호스트 자원 접근"

    # D-50
    ["D-50_PURPOSE"]="privileged 컨테이너는 호스트와 동일한 권한으로 보안 격리 무력화"
    ["D-50_CHECK"]="docker inspect <container> | grep '\"Privileged\"'"
    ["D-50_GOOD"]="모든 컨테이너에서 Privileged: false"
    ["D-50_BAD"]="하나 이상의 컨테이너가 Privileged: true로 실행"
    ["D-50_ACTION"]="docker run --privileged 옵션 제거, 필요 capability만 --cap-add로 추가"
    ["D-50_THREAT"]="privileged 컨테이너에서 호스트 파일시스템, 디바이스, 커널 파라미터 완전 제어"

    # D-51
    ["D-51_PURPOSE"]="민감한 호스트 디렉토리의 컨테이너 마운트를 금지하여 호스트 보호"
    ["D-51_CHECK"]="docker inspect <container> | grep -E 'Binds|Mounts' | grep -E '/etc|/root|/proc|/sys|/dev'"
    ["D-51_GOOD"]="민감 호스트 디렉토리(/etc, /root, /proc 등) 마운트 없음"
    ["D-51_BAD"]="민감 디렉토리가 컨테이너에 마운트됨"
    ["D-51_ACTION"]="docker-compose.yml 또는 docker run의 -v 옵션에서 민감 경로 마운트 제거"
    ["D-51_THREAT"]="컨테이너에서 호스트의 민감 파일 접근 및 변조"

    # D-52
    ["D-52_PURPOSE"]="컨테이너 내 SSH 데몬은 불필요한 원격 접근 경로를 생성"
    ["D-52_CHECK"]="docker exec <container> ps -ef | grep sshd"
    ["D-52_GOOD"]="컨테이너 내 SSH 데몬 미실행"
    ["D-52_BAD"]="하나 이상의 컨테이너에서 SSH 데몬 실행"
    ["D-52_ACTION"]="컨테이너 접근은 docker exec 사용, Dockerfile에서 SSH 서비스 제거"
    ["D-52_THREAT"]="컨테이너 내 SSH를 통한 무차별 대입 공격 및 비인가 접근"

    # D-53
    ["D-53_PURPOSE"]="1024 미만 포트는 시스템 포트로 특권 바인딩 요구, 노출 최소화"
    ["D-53_CHECK"]="docker ps --format '{{.Ports}}' | grep -E ':[1-9][0-9]{0,2}->'"
    ["D-53_GOOD"]="모든 포트 바인딩이 1024 이상"
    ["D-53_BAD"]="1024 미만 포트 매핑 존재"
    ["D-53_ACTION"]="컨테이너 포트를 1024 이상으로 변경 또는 리버스 프록시 사용"
    ["D-53_THREAT"]="시스템 포트 노출로 인한 잘 알려진 서비스 공격"

    # D-54
    ["D-54_PURPOSE"]="필요하지 않은 포트 개방으로 인한 불필요한 공격 표면 제거"
    ["D-54_CHECK"]="docker inspect <container> | grep -i 'ExposedPorts'"
    ["D-54_GOOD"]="실제 필요한 포트만 개방"
    ["D-54_BAD"]="불필요한 포트 개방"
    ["D-54_ACTION"]="Dockerfile에서 불필요한 EXPOSE 제거, -p 옵션으로 필요한 포트만 바인딩"
    ["D-54_THREAT"]="불필요한 포트를 통한 내부 서비스 노출 및 공격"

    # D-55
    ["D-55_PURPOSE"]="호스트 네트워크 모드 사용 시 컨테이너 네트워크 격리 완전 무력화"
    ["D-55_CHECK"]="docker inspect <container> | grep '\"NetworkMode\"' | grep host"
    ["D-55_GOOD"]="모든 컨테이너가 bridge 또는 overlay 네트워크 사용"
    ["D-55_BAD"]="--network=host 사용 컨테이너 존재"
    ["D-55_ACTION"]="docker run --network=host 옵션 제거, bridge 네트워크 사용"
    ["D-55_THREAT"]="호스트 네트워크 공유로 컨테이너에서 호스트 네트워크 서비스 직접 접근"

    # D-56
    ["D-56_PURPOSE"]="메모리 제한으로 OOM으로 인한 호스트 시스템 DoS 방지"
    ["D-56_CHECK"]="docker inspect <container> | grep '\"Memory\"'"
    ["D-56_GOOD"]="Memory 제한이 0 이상으로 설정됨"
    ["D-56_BAD"]="Memory가 0 (무제한)"
    ["D-56_ACTION"]="docker run -m 512m 옵션으로 메모리 제한 설정"
    ["D-56_THREAT"]="메모리 무제한 컨테이너로 인한 호스트 시스템 자원 고갈"

    # D-57
    ["D-57_PURPOSE"]="CPU 제한으로 컨테이너의 호스트 CPU 독점 방지"
    ["D-57_CHECK"]="docker inspect <container> | grep '\"CpuShares\"\\|\"NanoCpus\"'"
    ["D-57_GOOD"]="CPU 제한이 설정됨"
    ["D-57_BAD"]="CpuShares가 0 또는 기본값(1024)으로 제한 없음"
    ["D-57_ACTION"]="docker run --cpus=0.5 또는 --cpu-shares=512 옵션으로 CPU 제한"
    ["D-57_THREAT"]="CPU 집약적 컨테이너로 인한 호스트 성능 저하 및 DoS"

    # D-58
    ["D-58_PURPOSE"]="루트 파일시스템 읽기 전용으로 컨테이너 내 파일 변조 방지"
    ["D-58_CHECK"]="docker inspect <container> | grep ReadonlyRootfs"
    ["D-58_GOOD"]="ReadonlyRootfs: true"
    ["D-58_BAD"]="ReadonlyRootfs: false"
    ["D-58_ACTION"]="docker run --read-only 옵션 사용"
    ["D-58_THREAT"]="악성 코드가 컨테이너 파일시스템에 저장되어 재시작 후에도 지속"

    # D-59
    ["D-59_PURPOSE"]="마운트 전파 모드 제한으로 호스트 파일시스템 변경 전파 방지"
    ["D-59_CHECK"]="docker inspect <container> | grep -i 'Propagation'"
    ["D-59_GOOD"]="마운트 전파가 private 또는 rprivate"
    ["D-59_BAD"]="shared, rshared, slave, rslave 등 전파 모드 사용"
    ["D-59_ACTION"]="docker run -v /host/path:/container/path:private 옵션 사용"
    ["D-59_THREAT"]="마운트 전파로 컨테이너에서 호스트 파일시스템 변경 가능"

    # D-60
    ["D-60_PURPOSE"]="호스트 UTS 네임스페이스 공유 시 컨테이너에서 호스트명 변경 가능"
    ["D-60_CHECK"]="docker inspect <container> | grep '\"UTSMode\"'"
    ["D-60_GOOD"]="UTSMode가 비어있음 (격리된 네임스페이스 사용)"
    ["D-60_BAD"]="UTSMode가 host"
    ["D-60_ACTION"]="docker run --uts=host 옵션 제거"
    ["D-60_THREAT"]="컨테이너에서 호스트명 변경으로 네트워크 혼란 및 보안 설정 우회"

    # D-61
    ["D-61_PURPOSE"]="기본 seccomp 프로파일 유지로 위험한 시스템 콜 차단"
    ["D-61_CHECK"]="docker inspect <container> | grep -i seccomp"
    ["D-61_GOOD"]="seccomp 프로파일이 기본값 또는 커스텀 프로파일로 설정됨"
    ["D-61_BAD"]="--security-opt seccomp=unconfined 사용"
    ["D-61_ACTION"]="seccomp=unconfined 옵션 제거"
    ["D-61_THREAT"]="seccomp 해제로 위험한 시스템 콜을 통한 커널 공격 가능"

    # D-62
    ["D-62_PURPOSE"]="호스트 PID/IPC 네임스페이스 공유 시 컨테이너에서 호스트 프로세스 접근 가능"
    ["D-62_CHECK"]="docker inspect <container> | grep -E '\"PidMode\"|\"IpcMode\"'"
    ["D-62_GOOD"]="PidMode, IpcMode가 비어있음 또는 private"
    ["D-62_BAD"]="PidMode 또는 IpcMode가 host"
    ["D-62_ACTION"]="docker run --pid=host 또는 --ipc=host 옵션 제거"
    ["D-62_THREAT"]="컨테이너에서 호스트 프로세스 목록 확인, 시그널 전송, IPC 자원 접근"

    # D-63
    ["D-63_PURPOSE"]="최신 이미지 사용으로 알려진 취약점 패치 적용"
    ["D-63_CHECK"]="docker images --format '{{.CreatedAt}}' | sort | head -1"
    ["D-63_GOOD"]="모든 이미지가 90일 이내에 업데이트됨"
    ["D-63_BAD"]="90일 이상 된 이미지 존재"
    ["D-63_ACTION"]="정기적으로 docker pull <image> 실행 및 컨테이너 재배포"
    ["D-63_THREAT"]="오래된 이미지의 알려진 취약점을 통한 시스템 침해"

    # D-64
    ["D-64_PURPOSE"]="불필요하게 정지된 컨테이너 제거로 공격 표면 감소"
    ["D-64_CHECK"]="docker ps -a | grep -v Up | grep -v CONTAINER"
    ["D-64_GOOD"]="정지된 컨테이너가 없거나 최소화됨"
    ["D-64_BAD"]="다수의 정지된 컨테이너 존재"
    ["D-64_ACTION"]="docker container prune 실행하여 불필요한 컨테이너 정리"
    ["D-64_THREAT"]="정지된 컨테이너 재시작을 통한 취약한 환경 복구"

    # D-65
    ["D-65_PURPOSE"]="실행 중인 컨테이너 수를 파악하여 인가되지 않은 컨테이너 탐지"
    ["D-65_CHECK"]="docker ps -q | wc -l"
    ["D-65_GOOD"]="실행 중인 컨테이너 수가 운영 정책과 일치"
    ["D-65_BAD"]="비인가 컨테이너 실행 또는 컨테이너 수 모니터링 미실시"
    ["D-65_ACTION"]="컨테이너 레지스트리와 실행 목록 주기적 비교 및 이상 감지 체계 구축"
    ["D-65_THREAT"]="인가되지 않은 컨테이너를 이용한 자원 남용 및 악성 서비스 실행"

    # D-66
    ["D-66_PURPOSE"]="사용하지 않는 Swarm 모드 비활성화로 불필요한 공격 표면 제거"
    ["D-66_CHECK"]="docker info | grep -i swarm"
    ["D-66_GOOD"]="Swarm: inactive"
    ["D-66_BAD"]="Swarm: active (사용하지 않는 경우)"
    ["D-66_ACTION"]="docker swarm leave --force 실행"
    ["D-66_THREAT"]="Swarm API를 통한 클러스터 무단 제어"

    # D-67
    ["D-67_PURPOSE"]="Swarm 매니저 노드 최소화로 클러스터 관리 접근 제한"
    ["D-67_CHECK"]="docker node ls | grep -i manager | wc -l"
    ["D-67_GOOD"]="매니저 노드가 홀수(1, 3, 5)로 최소화됨"
    ["D-67_BAD"]="매니저 노드가 과도하게 많음"
    ["D-67_ACTION"]="docker node demote <node> 로 불필요한 매니저를 워커로 강등"
    ["D-67_THREAT"]="매니저 노드 침해 시 클러스터 전체 제어권 상실"

    # D-68
    ["D-68_PURPOSE"]="Swarm Secret을 통한 민감 정보 안전한 배포"
    ["D-68_CHECK"]="docker secret ls 로 시크릿 관리 여부 확인"
    ["D-68_GOOD"]="민감 정보가 Docker Secret으로 관리됨"
    ["D-68_BAD"]="환경 변수나 파일로 민감 정보 직접 주입"
    ["D-68_ACTION"]="echo 'password' | docker secret create my_secret - 형식으로 Secret 생성"
    ["D-68_THREAT"]="환경 변수로 주입된 민감 정보가 docker inspect 등으로 노출"
)
