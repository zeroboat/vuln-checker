# Vulnerability Checker - Bash Project

주요통신기반시설 보안 기준(U-01 ~ U-72)에 기반한 Unix/Linux 서버 보안 점검 프로젝트입니다.

## 프로젝트 구조

```
├── main.sh                      # 메인 스크립트 (OS/배포판 감지, 시작/끝 알림)
├── scripts/
│   ├── common.sh               # 공통 함수들 (모든 보안 검사 함수)
│   ├── security_codes.sh       # 주요통신기반시설 보안 항목 코드 정의
│   ├── linux.sh                # Linux 배포판 감지 및 라우팅
│   ├── linux/
│   │   ├── debian.sh           # Debian/Ubuntu 검사
│   │   ├── redhat.sh           # CentOS/RHEL 검사
│   │   ├── alpine.sh           # Alpine Linux 검사
│   │   └── arch.sh             # Arch Linux 검사
│   └── macos.sh                # macOS 검사
│
├── results/                    # 검사 결과 저장 (타임스탬프 포함)
├── logs/                       # 로그 파일 저장 (타임스탬프 포함)
├── README.md                   # 프로젝트 설명 (이 파일)
└── PROJECT_GUIDE.md            # 상세 기술 가이드
```

## 실행 방법

### Linux/macOS
```bash
chmod +x main.sh
./main.sh
```

### 실행 결과
- **결과 파일**: `results/result_YYYYMMDD_HHMMSS.txt`
- **로그 파일**: `logs/run_YYYYMMDD_HHMMSS.log`

## 주요 기능

### 1. 계정 관리 (U-01 ~ U-54)

**기본 항목:**
- **U-01**: root 계정 원격 접속 제한
- **U-02**: 패스워드 복잡성 설정
- **U-03**: 계정 잠금 정책 설정
- **U-04**: 패스워드 파일 보호
- **U-44**: root 이외의 UID가 0인 계정 검사
- **U-45**: 불필요한 계정 제거
- **U-46**: 패스워드 최소 길이 설정
- **U-47/48**: 패스워드 최소/최대 사용기간 설정
- **U-50**: 관리자 그룹에 최소한의 계정 포함
- **U-52**: 동일한 UID 계정 확인
- **U-53**: 사용자 shell 설정
- **U-54**: Session timeout 설정

### 2. 파일 및 디렉토리 관리 (U-05 ~ U-18, U-55 ~ U-59)

**주요 파일 권한:**
- **U-05**: root 홈 디렉토리 권한
- **U-06**: 파일 및 디렉토리 소유자 설정
- **U-07**: /etc/passwd 파일 권한 (644)
- **U-08**: /etc/shadow 파일 권한 (640)
- **U-10**: /etc/group 파일 권한 (644)
- **U-11**: /etc/syslog.conf 권한
- **U-12**: /etc/services 파일 권한

**고급 파일 관리:**
- **U-13**: SUID/SGID/Sticky bit 파일 확인
- **U-14**: world writable 파일 확인
- **U-15**: /dev/null 파일 설정
- **U-16**: 심볼릭 링크 및 Device 파일
- **U-17**: $HOME/.rhosts 파일 설정
- **U-18**: 접속 IP 필터 제정
- **U-56**: UMASK 설정
- **U-57**: 로그 파일 소유자 및 권한
- **U-58**: 로그 디렉토리 관리
- **U-59**: 임시 파일 접근 설정

### 3. 서비스 관리 (U-19 ~ U-41, U-60 ~ U-71)

**불필요한 서비스 비활성화:**
- **U-19**: finger 서비스
- **U-20**: Anonymous FTP
- **U-21**: r 서비스 (rsh, rlogin, rcp)
- **U-24**: NFS 서비스
- **U-25**: NFS 접근 통제
- **U-27**: RPC 서비스 차단
- **U-28**: NIS 서비스
- **U-29**: tftp, talk 서비스

**메일 서비스 보안:**
- **U-30**: Sendmail 버전 확인
- **U-31**: 스팸 메일 정지
- **U-32**: 임시사용자의 Sendmail 설정 방지

**DNS 보안:**
- **U-33**: DNS 보안 설정
- **U-34**: DNS Zone Transfer 설정
- **U-35**: DNS 버전 숨김

**웹 서버 보안:**
- **U-36**: 웹서비스 프로세스 권한 제한
- **U-37**: 웹서비스 디렉토리 접근 금지
- **U-38**: 웹서비스 불필요한 기능 제거
- **U-39**: 웹서비스 링크 다운로드 제한
- **U-40**: 웹서비스 심볼릭 링크
- **U-41**: 웹서비스 영역외 보안
- **U-71**: Apache 웹 서버 정보 설정

**SSH 보안:**
- **U-60**: ssh 암호정책 적용
- **U-61**: sftp 서비스 사용
- **U-62**: sftp/shell 설정

**FTP/SNMP 보안:**
- **U-63**: FTPusers 파일 설정
- **U-64**: SNMP 커뮤니티 공개 설정
- **U-65**: SNMP 서비스 자동 시작 설정
- **U-66**: SNMP 서비스 네트워크 라우팅 설정

**기타 서비스:**
- **U-22**: cron 파일 권한 설정
- **U-26**: automount 비활성화
- **U-68**: 로그 스트림 정책
- **U-69**: NFS 설정파일 제어
- **U-70**: 프린트 서버 보안

### 4. 보안 관리 (U-42)

- **U-42**: 직접 보안재 및 법력 공격자 직접

### 5. 로그 관리 (U-72)

- **U-72**: 정책 파일 시스템 설정

## 배포판 지원

모든 배포판에서 **동일한 검사 항목(U-01 ~ U-72)**을 수행합니다:

- **Debian/Ubuntu** - APT 패키지 매니저
- **CentOS/RHEL** - YUM/DNF + SELinux + Firewalld
- **Alpine Linux** - APK 패키지 매니저
- **Arch Linux** - Pacman 패키지 매니저
- **macOS** - dscl 사용자 관리

## 검사 항목 코드 매핑

### 계정 관리
| 코드 | 항목 | 심각도 |
|------|------|--------|
| U-01 | root 원격 접속 제한 | 상 |
| U-02 | 패스워드 복잡성 | 상 |
| U-03 | 계정 잠금 정책 | 상 |
| U-44 | UID 0 중복 계정 | 상 |
| U-50 | 관리자 그룹 최소화 | 상 |

### 서비스 관리
| 코드 | 항목 | 심각도 |
|------|------|--------|
| U-19 | finger 비활성화 | 상 |
| U-20 | FTP 비활성화 | 상 |
| U-24 | NFS 비활성화 | 상 |
| U-29 | tftp/talk 비활성화 | 상 |
| U-60 | SSH 암호정책 | 상 |

## 검사 결과 해석

### 출력 형식
```
[U-XX] 항목명
  상세 설정 내용
  ⚠️  경고: 권장 설정과 다른 경우
```

### 예시
```
[U-01] root 계정 원격 접속 제한
  PermitRootLogin: no
  
[U-20] Anonymous FTP 비활성화
  ⚠️  경고: ftp 서비스가 활성화되어 있습니다
```

## 공통 함수 (common.sh)

모든 배포판에서 사용 가능한 함수들:

**계정 함수:**
- `get_system_accounts()` - 시스템 계정 목록
- `get_user_accounts()` - 사용자 계정 목록
- `get_uid()` / `get_gid()` - 계정의 UID/GID 조회
- `is_account_locked()` - 계정 잠금 여부 확인

**파일/권한 함수:**
- `check_critical_files()` - 주요 파일 권한 확인 (U-05 ~ U-18)
- `check_file_permissions()` - 개별 파일 권한 검사

**보안 검사 함수:**
- `check_system_logs()` - 시스템 로그 확인 (U-57, U-58)
- `check_open_ports()` / `check_dangerous_ports()` - 포트 검사
- `check_running_services()` / `check_unnecessary_services()` - 서비스 검사 (U-19 ~ U-71)
- `check_ssh_config()` / `check_ssh_security()` - SSH 설정 (U-01, U-60 ~ U-62)
- `check_firewall_status()` - 방화벽 상태 (U-18)

## 자세한 기술 정보

더 상세한 기술 정보는 [PROJECT_GUIDE.md](PROJECT_GUIDE.md)를 참고하세요.

## 향후 계획

- [ ] 파일 무결성 검사 (AIDE, Tripwire)
- [ ] 취약한 암호 정책 심화 감지
- [ ] SELinux 정책 검사 (RHEL 계열)
- [ ] AppArmor 정책 검사 (Debian 계열)
- [ ] 불필요한 SUID/SGID 바이너리 상세 탐지
- [ ] 커널 파라미터 보안 검사
- [ ] 네트워크 보안 정책 상세 검사
- [ ] 시스템 패치 상태 확인
- [ ] 설정 파일 변조 감시
- [ ] 보안 감사 로그 자동 분석
- [ ] HTML/PDF 리포트 생성
- [ ] 중앙 관리 시스템 통합
