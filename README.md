# BA_Menu_Bar

<img src = "https://github.com/user-attachments/assets/d9248ae2-aa40-4466-b3ab-bb3274595cbb" width="30%" height="30%">

#### 선택한 캐릭터 마크를 Mac의 메뉴바에서 키프레임 애니메이션으로 확인할 수 있는 앱입니다.

# Link

[Download & Manual](https://github.com/phillyWork/BA_Mac_MenuBar_Download_Page)

# 개발 기간 및 인원
- 2024.08
- 배포 이후 지속적 업데이트 중
- 최소 버전: MacOS 14.5
- 1인 개발

# 사용 기술
- **SwiftUI, Cocoa, Combine, ServiceManagement**
- **Sparkle**
- **MVVM, Singleton, UserDefaults**
- **NSMenuItem, Timer, Localization**

------

# 기능 구현

- 메뉴바에서의 키프레임 애니메이션 설정
  - 애니메이션 속도 조절용 인터벌 구성
  - 키프레임 애니메이션 목적의 타이머 구성
- 메뉴바 클릭 시, 옵션 메뉴 구성 및 해당 캐릭터 이미지 및 대사를 화면에 출력
  - 동일 인물 이격 캐릭터로 등장한 케이스 있는 경우, 매번 메뉴바 클릭마다 랜덤하게 출력
- `SMAppService` "로그인 시 자동 실행" 활성화
- `Sparkle` 프레임워크 활용 버전 업데이트 체크 및 최신 버전 다운로드 및 재설치 기능 활용


