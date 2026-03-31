# jjajuka-infra

- 환경 별 main.tf 한 파일에 여러 모듈을 선언한 구조
  - 두 리소스가 하나의 state로 묶여서 관리된다.
  - 개별 제거는 -target 옵션으로만 가능 (terraform destroy -target module.database)
  - 모듈이 추가될수록 변수가 무수히 늘어남

- 개선 예정
  - 구조적 분리
