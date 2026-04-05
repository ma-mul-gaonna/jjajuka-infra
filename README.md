# jjajuka-infra

> jjajuka 서비스의 AWS 인프라를 Terraform으로 관리하는 레포지토리입니다.
> _(서비스 소개는 여기에 작성해주세요)_

---

## Architecture

### 인프라 아키텍처

<img width="1103" height="894" alt="Image" src="https://github.com/user-attachments/assets/6eb15537-188c-438e-af26-7cb9c4b485c5" />

### 네트워크 및 보안 구조

<img width="410" height="533" alt="Image" src="https://github.com/user-attachments/assets/9853c518-92ec-407c-bc23-da2e0115e4f5" />

### CI/CD 파이프라인

<img width="446" height="482" alt="Image" src="https://github.com/user-attachments/assets/d4123894-76ff-4406-9928-1f49108fc9ce" />

**트래픽 흐름**

```
User
 └── ALB (HTTPS 443 / HTTP 80 → 301 redirect)
      ├── /* → Frontend EC2 (port 3000)
      └── /api/* → Backend EC2 (port 8888)
                        └── AI EC2 (port 8000, internal only)
                        └── RDS MySQL (private subnet, port 3306)
```

---

## Tech Stack

| Category          | Tool / Service                                |
| ----------------- | --------------------------------------------- |
| IaC               | Terraform >= 1.10.0                           |
| Cloud             | AWS (ap-northeast-2)                          |
| Compute           | EC2 (Amazon Linux 2023)                       |
| Container         | Docker, Amazon ECR                            |
| Load Balancer     | ALB (Application Load Balancer)               |
| Database          | RDS MySQL                                     |
| DNS / TLS         | 가비아, ACM (Wildcard Certificate)            |
| Secret Management | SSM Parameter Store                           |
| Access            | AWS Systems Manager (Session Manager, no SSH) |
| Monitoring        | CloudWatch Alarms, SNS                        |

---

## Directory Structure

```
jjajuka-infra/
├── envs/
│   ├── global/         # 전역 공유 리소스 (ACM 인증서)
│   ├── dev/            # 개발 환경
│   └── prod/           # 운영 환경
└── modules/
    ├── acm/            # ACM TLS 인증서
    ├── vpc/            # VPC, 서브넷, 라우팅
    ├── ecr/            # ECR 레포지토리 (frontend / backend / ai)
    ├── backend/        # EC2 인스턴스, ALB, Security Group, IAM
    ├── database/       # RDS MySQL, DB Subnet Group, Security Group
    └── monitoring/     # SNS Topic, CloudWatch Alarms (EC2 / RDS), EventBridge
```

각 환경(`dev`, `prod`)은 독립된 `terraform.tfstate`를 가지며, 동일한 모듈을 재사용합니다.
`global` 환경은 ACM 인증서처럼 환경에 무관하게 공유되는 리소스를 관리합니다.

---

## Modules

### `vpc`

- VPC, Internet Gateway, Public/Private 서브넷 2개씩, 라우팅 테이블 구성
- Public 서브넷: ALB, EC2 배치
- Private 서브넷: RDS 배치 (인터넷 접근 차단)

### `ecr`

- `frontend`, `backend`, `ai` 3개 레포지토리를 `for_each`로 생성

### `backend`

- EC2 인스턴스 3개 (Frontend / Backend / AI)
- ALB: HTTP(80) → HTTPS(301) 리다이렉트, HTTPS(443) 리스너
- ALB 라우팅 룰: `/api/*` → Backend, 그 외 → Frontend
- Security Group 계층 분리:
  - ALB SG ← 인터넷 (80, 443)
  - Frontend SG ← ALB SG만 허용
  - Backend SG ← ALB SG만 허용 (지정 포트)
  - AI SG ← Backend SG만 허용 (내부 통신)
- AI 인스턴스에 EIP 부착 (고정 퍼블릭 IP)
- IAM Instance Profile: SSM Session Manager + ECR ReadOnly 권한만 부여 (최소 권한 원칙)
- EC2 접속: SSH 키 없이 SSM Session Manager로만 접근

### `database`

- RDS MySQL, Private 서브넷 배치
- Security Group: Backend EC2 SG에서만 인바운드 허용
- DB 접속 정보는 SSM Parameter Store에 저장 (평문 환경변수 미사용)

### `acm`

- `jjajuka.site`, `*.jjajuka.site` 와일드카드 인증서 발급 (DNS 검증)
- `global` 환경에서 한 번 발급 후, 각 환경에서 `data` 소스로 참조

### `monitoring`

- SNS Topic + 이메일 구독으로 알림 수신 채널 구성
- EventBridge로 EC2 stopped / terminated 이벤트 감지 → SNS 알림
- EC2 알람 (frontend / app / ai 인스턴스 공통):
  - CPU 사용률 > 80% (5분 평균, 2회 연속)
  - StatusCheckFailed >= 1 (1분 간격, 2회 연속)
- RDS 알람:
  - CPU 사용률 > 80%
  - FreeStorageSpace < 2GB
  - DatabaseConnections > 100
- 알람 복구 시에도 OK 알림 발송

---

## Environments

| Resource                | dev         | prod        |
| ----------------------- | ----------- | ----------- |
| VPC CIDR                | 10.0.0.0/16 | 10.1.0.0/16 |
| ECR                     | ✅          | ✅          |
| ALB + EC2               | ✅          | ✅          |
| RDS MySQL               | ✅          | ✅          |
| SSM Parameters          | ✅          | ✅          |
| CloudWatch Alarms + SNS | ✅          | ✅          |
| Multi-AZ RDS            | ❌          | ✅          |

---

## How to Deploy

### 사전 조건

- Terraform >= 1.10.0
- AWS CLI 설정 완료 (`aws configure`)
- `terraform.tfvars` 파일에 변수 값 입력

### 배포 순서

**1. 인증서 발급 (최초 1회)**

```bash
cd envs/global
terraform init
terraform apply
```

**2. 환경 프로비저닝**

```bash
cd envs/dev   # 또는 envs/prod
terraform init
terraform plan
terraform apply
```

### 주요 변수 (`terraform.tfvars`)

| Variable                        | Description                    |
| ------------------------------- | ------------------------------ |
| `ami`                           | EC2 AMI ID (Amazon Linux 2023) |
| `MYSQL_USER` / `MYSQL_PASSWORD` | RDS 접속 정보                  |
| `discord_webhook_url`           | 알림용 Discord Webhook         |
| `google_api_key`                | AI 서비스용 Google API Key     |
| `alert_email`                   | CloudWatch 알림 수신 이메일    |

> 민감한 변수는 `.gitignore`에 추가하거나 별도로 관리하세요.

---

## 📌 설계 포인트

- 프리티어 한도 내 비용 최소화
- 개발환경은 단일 구성, 운영환경은 일부 이중화 (RDS Multi-AZ)
- 보안 요건을 고려한 서브넷 분리 (Public/Private)
- NAT Gateway 미사용으로 네트워크 비용 최소화 (인스턴스 Public 서브넷 배치), 
  - 계층적 Security Group으로 인바운드 접근 제어

- SSH 미오픈, SSM Session Manager로만 인스턴스 접근
- 최소 권한 IAM
- CloudWatch + EventBridge + SNS로 장애 감지 및 알림 구성

### 보안 요건

- DB 퍼블릭 노출 차단 → RDS Private Subnet 배치
- HTTPS 적용 → ALB + ACM (Wildcard 인증서)
- 시크릿 관리 → SSM Parameter Store

---

## 📌 Design Decisions

**SSH 미사용, SSM Session Manager로 접근**
EC2에 SSH 포트(22)를 열지 않고 AWS SSM을 통해서만 접속합니다. 키 관리 부담을 없애고 접근 이력이 CloudTrail에 기록됩니다.

**RDS Private 서브넷 배치**
데이터베이스는 인터넷 라우팅이 없는 Private 서브넷에 배치하고, Backend EC2 Security Group에서만 접근을 허용합니다.

**Security Group 계층 구조**
ALB → Frontend/Backend → AI 방향으로만 통신을 허용하여, AI 서비스가 인터넷 또는 ALB에 직접 노출되지 않습니다.

**GitHub Actions CD: OIDC + SSM Send Command**
GitHub Actions에서 AWS Access Key를 직접 발급하지 않고 OIDC(OpenID Connect)로 임시 자격증명을 발급받습니다. ECR push 후 `ssm:SendCommand`로 EC2에 docker pull/run 명령을 원격 실행하여 배포합니다. OIDC Role의 권한은 dev ECR 레포지토리 3개와 SSM 명령 실행으로만 한정했습니다.

**SSM Parameter Store로 시크릿 관리**
DB 접속 정보, API 키 등 민감한 값을 SSM Parameter Store(SecureString)에 저장하고, EC2 IAM 역할을 통해 런타임에 읽어옵니다.

**AI 서버 EIP 부착**
Backend 서버가 AI 서버의 IP를 환경변수로 참조합니다. AI 인스턴스가 재시작되면 퍼블릭 IP가 바뀌어 Backend 환경변수를 수정하고 재배포해야 하는 문제가 발생합니다. EIP로 고정 IP를 부여하여 AI 서버가 재시작되어도 Backend 환경변수 변경 없이 통신이 유지됩니다. Internal ALB 구성도 검토했으나 해커톤 일정상 EIP로 간단하게 해결했습니다.

**CloudWatch Alarms + SNS로 장애 감지**
EC2 CPU 과부하 및 상태 이상, RDS CPU/스토리지/연결 수에 대한 알람을 구성하고 SNS 이메일 구독으로 알림을 수신합니다. 알람 복구 시에도 OK 알림을 발송하여 정상화 여부를 확인할 수 있습니다. `terraform apply` 후 수신 이메일에서 구독 확인(Confirm subscription)이 필요합니다.

---

## Manually Managed Resources

Terraform으로 관리하지 않고 AWS 콘솔에서 수동으로 생성한 리소스입니다.

| Resource               | Description                                                                                                          |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------- |
| OIDC Identity Provider | GitHub Actions → AWS 연동을 위한 OIDC Provider 및 IAM Role. AWS 자격증명 없이 아래 권한으로 CI/CD 수행               |
| DNS (가비아)           | `jjajuka.site` 도메인의 DNS 레코드를 가비아에서 직접 관리. ACM 인증서 DNS 검증용 CNAME 및 ALB 연결용 CNAME 설정 포함 |

**OIDC Role 권한 (최소 권한 원칙 적용)**

| Permission                           | 용도                                               |
| ------------------------------------ | -------------------------------------------------- |
| `ec2:DescribeInstances`              | 배포 대상 EC2 인스턴스 ID 조회                     |
| `ecr:GetAuthorizationToken`          | ECR 로그인                                         |
| `ecr:BatchCheck / Upload / PutImage` | ECR 이미지 push (dev 레포지토리 3개로 리소스 한정) |
| `ssm:SendCommand`                    | EC2에 docker pull / run 명령 원격 실행             |
| `ssm:GetCommandInvocation`           | SSM 명령 실행 결과 확인                            |

**가비아 DNS 레코드 설정**

| 구분            | 호스트                    | 타입  | 값                  |
| --------------- | ------------------------- | ----- | ------------------- |
| ACM 인증서 검증 | (ACM 콘솔에서 확인)       | CNAME | (ACM 콘솔에서 확인) |
| prod ALB 연결   | `@` (또는 `jjajuka.site`) | CNAME | prod ALB DNS 주소   |
| dev ALB 연결    | `dev`                     | CNAME | dev ALB DNS 주소    |

> ALB DNS 주소는 `terraform output` 또는 AWS 콘솔 → EC2 → Load Balancers에서 확인할 수 있습니다.
> 수동 생성 리소스는 변경 시 이 문서에 반영해주세요.

---

## 현재 발생하고 있는 이슈

### `userdata` 실행 시 ssm-user docker 권한 미부여

인스턴스가 userdata로 초기화될 때 `usermod -aG docker ssm-user` 명령이 실행되지만, ssm-user는 첫 SSM 세션 접속 시 생성되는 계정이라 **userdata 실행 시점에는 존재하지 않아** docker 그룹 추가가 실패합니다.

**증상**

- SSM Session Manager로 접속 후 `docker` 명령 실행 시 permission denied 발생

**현재 임시 대응**

- SSM 세션 접속 후 수동으로 아래 명령 실행

```bash
sudo usermod -aG docker ssm-user
```

**미해결**

---

## 한계

- 환경별 `main.tf` 한 파일에 여러 모듈을 선언하는 구조로, 모든 리소스가 하나의 state로 관리됨
  - 특정 리소스만 제거하려면 `-target` 옵션 필요 (`terraform destroy -target module.database`)
  - 모듈이 추가될수록 환경별 변수 선언이 늘어남
- Terraform state 파일을 로컬에서 관리 중 (Remote Backend 미적용)

**개선 예정**

- 구조적 분리 (모듈별 state 분리 또는 Terragrunt 도입 검토)
- Remote Backend (S3 + DynamoDB) 적용 검토
- **ASG (Auto Scaling Group) 전환**: 현재 EC2 단독 인스턴스 3개(frontend / app / ai)를 각각 ASG로 전환
  - 인스턴스 다운 시 자동 재시작
  - 모니터링 알람/이벤트가 인스턴스 ID 고정이 아닌 ASG 단위로 동작하여 인스턴스 교체 후에도 자동 유지
  - ALB 타겟그룹 자동 등록/해제
