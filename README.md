# BA_Menu_Bar

<img src = "https://github.com/user-attachments/assets/d9248ae2-aa40-4466-b3ab-bb3274595cbb" width="30%" height="30%">

#### 선택한 캐릭터 마크를 Mac의 메뉴바에서 키프레임 애니메이션으로 확인할 수 있는 앱입니다.

# Link

아래의 다운로드 링크에 앱 설명 및 설치 가이드가 추가로 작성되어 있습니다.

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

- `Timer` 활용, 메뉴바 아이콘 키프레임 애니메이션 설정
  - 애니메이션 재생 속도 조절용 인터벌 구성
- `NSStatusItem` 활용, 메뉴바 클릭 시 옵션 메뉴 구성
  - `NSHostingView` 활용, 추가 View를 할당해서 캐릭터 이미지 및 대사를 화면에 출력
- `SMAppService` 활용 "로그인 시 자동 실행" 활성화
- `Sparkle` 프레임워크 통한 버전 업데이트 체크 및 최신 버전 다운로드 및 재설치 기능 활용

-----

# Trouble Shooting

### A. Agent 어플리케이션으로 동작하기

앱의 근원적 목적이 "메뉴바에서 키프레임 애니메이션을 반복적으로 작동하도록 한다" 였으므로 디스플레이에 띄울 Window가 필요 없으며 사용자와의 상호작용을 줄이고 백그라운드에서 동작하는 기능이 필요했다. 이를 만족하는 Agent 모드의 필요성이 대두되었다. Dock에 앱 아이콘이 나타나지 않고 사용자 인터페이스를 최소화하는 방향으로 구성했다.
Info.plist에서 해당 옵션을 선택하면 Agent 모드 설정이 되었다.

<img width="470" alt="스크린샷 2024-09-11 오후 9 36 46" src="https://github.com/user-attachments/assets/34e8ecab-12b6-495a-8fd3-09beb56e9a54">

또한 Window가 따로 필요없으므로, 일반적인 SwiftUI에서 `WindowGroup`으로 나타내는 화면 대신 Settings를 활용해서 디스플레이에 View를 띄우지 않고, AppDelegate에서 NSMenu 구성을 하도록 구조를 설정했다.

```swift
@main
struct BAMenuBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        Settings {
            Text("Settings Example")
        }
    }
}
```

-----

### B. 버전 업데이트 체크

일반적인 AppStore를 통한 배포는 업데이트 관리를 AppStore에서 관리하도록 한다. 하지만 AppStore 외의 직접 배포(Direct Distribution)을 선택할 경우, 버전 체크 및 업데이트 기능을 제공하는 라이브러리/프레임워크 활용 외에는 유저가 매번 배포 페이지를 방문해서 새 버전을 체크해야 하는 불편함이 존재한다.
이에 오픈소스 프레임워크 Sparkle을 활용해 버전 업데이트 기능을 구현했다.

```swift
import Sparkle

final class AppDelegate: NSObject, NSApplicationDelegate {

  // other variables for setup

  private let updaterController: SPUStandardUpdaterController
  
  override init() {
    //start app with auto-update check
    updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
  }
}
```

다만 Sparkle 자체 권고문으로 Agent 어플리케이션은 백그라운드에서 동작하는 것이 전제기에 주기적 업데이트 체크를 하는 `SUScheduledCheckInterval`의 Notification을 받지 못할 수 있다고 한다. 따라서 자동 업데이트 체크 외에 추가로 직접 유저가 메뉴 버튼을 클릭해서 체크하도록 업데이트 체크 기능을 추가했다.

```swift
private func setupCheckUpdateMenu() -> NSMenuItem {
  let updateMenu = NSMenuItem()
  updateMenu.title = LanguageManager.shared.localizedString(forKey: MenuTitleType.checkUpdate.rawValue, comment: "")
  updateMenu.action = #selector(SPUStandardUpdaterController.checkForUpdates(_:))
  updateMenu.keyEquivalent = "u"
  updateMenu.representedObject = MenuTitleType.checkUpdate
        
  updateMenu.target = updaterController
  
  return updateMenu
}
```
-----

### C. System 자동 실행 등록 처리

Agent 어플리케이션을 활용하려는 목적은 결국 유저가 추가적인 작업 없이도 한번 설정한 옵션 적용을 계속해서 백그라운드에서 동작하도록 하는데 목표가 있다고 생각한다. 매번 해당 앱을 Mac을 부팅할 때마다 따로 실행하도록 하려면 불편하므로 시스템 적으로 자동 로그인이 되도록 설정하는 기능을 추가했다.

전체 플로우는 다음과 같다.
1. 이미 시스템에 등록이 되어있는지 체크
2. 등록이 되어있다면 해제를, 되어있지 않다면 등록 요청

```swift
import ServiceManagement

@objc private func toggleStartAtLogin() {
  setLoginItem(shouldEnable: !checkLoginItem())
  autoLaunchAtStartMenu.title = LanguageManager.shared.localizedString(forKey: checkLoginItem() ? MenuTitleType.disableAutoLaunch.rawValue : MenuTitleType.enableAutoLaunch.rawValue, comment: "")
  autoLaunchAtStartMenu.representedObject = checkLoginItem() ? MenuTitleType.disableAutoLaunch : MenuTitleType.enableAutoLaunch
}

private func checkLoginItem() -> Bool {
  switch SMAppService.mainApp.status {
    // 해당 앱 등록되어있는지 확인
    case .enabled: return true
    default: return false
  }
}

// register to system
private func setLoginItem(shouldEnable: Bool) {
  do {
    shouldEnable ? try SMAppService.mainApp.register() : try SMAppService.mainApp.unregister()
  } catch {
    print("Error by SMAppService: \(error.localizedDescription)")
  }
}
```

-----

### D. NSMenu 구성 및 NSStatusItem 클릭 시 작업 처리

`NSStatusItem`을 단순하게 구성했다면 하위 attributed인 button에 selector 함수를 할당해서 메뉴바에서 해당 앱을 클릭할 때의 작업을 구현할 수 있다. 반면 하위 attribute인 menu에 NSMenu를 할당할 경우, selector 함수로는 원하는 클릭 액션이 작동하지 않는다. 클릭 액션이 이미 NSMenu를 디스플레이에 나타내는 것으로 menu 할당과 더불어 설정되기 때문이다.
해당 앱은 유저가 메뉴바에서 앱을 클릭할 때마다 선택한 캐릭터의 이미지를 보여주길 원하므로 따로 클릭을 인지하는 recognizer가 필요했으므로 `NSClickGestureRecognizer`를 활용했다.

또한 동일 캐릭터의 여러 이미지가 나타날 수 있으므로 클릭할 때마다 랜덤하게 이미지가 출력되도록 함수 호출이 매번 필요하다. 이를 위해선 statusBarItem을 클릭한 뒤, 해당 statusBarItem의 Button.performClick으로 인위적으로 클릭 액션이 작동하도록 한다.
button.performClick이 없다면 recognizer로 등록만 해놓고 실제 클릭 액션을 인식하지 못하는 상황이 발생한다.

```swift
import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {

  private let menu = NSMenu()
  private lazy var statusBarItem: NSStatusItem = {
    return NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
  }()

  private func setupStatusItem() {
    let iconTabRecognizer = NSClickGestureRecognizer(target: self, action: #selector(iconTapped))
    statusBarItem.button?.addGestureRecognizer(iconTabRecognizer)

    let contentView = NSHostingView(rootView: LazyView(MainImageView(viewModel: self.mainImageViewModel)))
    mainImageViewModel.loadImage(for: userSelectedCharacter)
    contentView.frame = NSRect(x: 0, y: 0, width: SetupFrame.mainContentViewWidth, height: SetupFrame.mainContentViewHeight)
    mainContentMenu.view = contentView
    menu.addItem(mainContentMenu)
        
    menu.addItem(setupCharacterMenu())
    menu.addItem(setupIntervalMenu())
    menu.addItem(setupLanguageMenu())
    menu.addItem(setupStartAtLoginMenu())
    menu.addItem(setupCheckUpdateMenu())
    menu.addItem(setupQuitMenu())
        
    statusBarItem.menu = menu
  }
    
  @objc private func iconTapped() {
    mainImageViewModel.loadImage(for: userSelectedCharacter)
        
    if let button = statusBarItem.button {
      statusBarItem.menu = menu
      button.performClick(nil)
    }
  }

}
```

-----

### E. Localization 및 앱 언어 변경 처리

Mac에 설정된 언어 설정과 동일하게 시작하지만, 유저가 원할 경우, 캐릭터 대사를 다른 언어로 보고 싶을 경우를 위해 디바이스와 다른 언어 설정을 하도록 하는 기능 구현이 필요했다.

우선 변경된 언어 설정과 시스템 등록을 위해 singleton으로 LanguageManager를 구성한다.

시스템 설정이 아닌 직접 언어 설정을 위해 `Bundle.main.path`에 해당 언어 코드를 할당한다.

```swift
enum LanguageSetup: String, Codable, CaseIterable {
    case en = "en"
    case ko = "ko"
    case ja = "ja"
}

final class LanguageManager {
    static let shared = LanguageManager()
    private var bundle: Bundle?

    private init() { }
    
    func setLanguage(_ language: String) {
        guard let path = Bundle.main.path(forResource: language, ofType: "lproj"), let languageBundle = Bundle(path: path) else {
            self.bundle = nil
            return
        }
        self.bundle = languageBundle
    }
    
    func localizedString(forKey key: String, comment: String) -> String {
        return bundle?.localizedString(forKey: key, value: nil, table: nil) ?? NSLocalizedString(key, comment: comment)
    }
}
```

Localization된 String을 활용하기 위해선 다음과 같은 직접적인 String literal을 전달하지만, 후에 Localization된 값들을 변경하는데 enum type인 LanguageSetup을 활용하기 위해서 representedObject를 활용한다.

```swift
String(localized: LocalizedStringResource(stringLiteral: "stringLiteralExample"))
```

언어 변경과 관련된 액션 처리를 위해 Combine의 `PassthroughSubject`를 활용, 새로운 언어 설정 요청이 오면 다음의 과정을 처리하도록 bind에서 먼저 구독을 해놓는다.
1. 앱의 언어 설정 변경
2. UserDefaults에 변경한 언어 설정 저장
3. NSMenu와 submenu들의 언어 표현 변경

```swift
import Combine

private let languageOutput = PassthroughSubject<LanguageSetup, Never>()

private func bind() {
    languageOutput
        .sink { [weak self] selectedLanguage in
            self?.updateLanguage(selectedLanguage)
            UserDefaultsManager.shared.saveToUserDefaults(newValue: selectedLanguage, forKey: SetupStrings.userDefaultsLanguageKey)
            self?.updateMenuTitles(self!.menu)
        }
        .store(in: &self.cancellables)
}
```

그 후 처음 앱 초기화 시, UserDefaults에 저장된 언어 설정을 확인한다.

```swift
 private func setupStatusItem() {
    // retrieve language setup from UserDefaults
    do {
      let savedLanguage = try UserDefaultsManager.shared.retrieveFromUserDefaults(forKey: SetupStrings.userDefaultsLanguageKey) as LanguageSetup
      LanguageManager.shared.setLanguage(savedLanguage.rawValue)
    } catch {
      // No language setup saved: bring device's language setup, if fail, set as English 
      let defaultLanguage = Locale.current.language.languageCode?.identifier ?? LanguageSetup.en.rawValue
      LanguageManager.shared.setLanguage(defaultLanguage)
    }

    // setup only for language
    menu.addItem(setupLanguageMenu())
}
```

언어 설정 메뉴 구성 시, representedObject를 같이 설정한다. 이는 selector로 objc 함수 호출 시에 해당 Object의 값을 전달받기 위함이다.

```swift
  private func setupLanguageMenu() -> NSMenuItem {
        let languageSelectionMenu = NSMenuItem()
        let submenu = NSMenu()
        for language in LanguageSetup.allCases {
            let menuItem = submenu.addItem(withTitle: LanguageManager.shared.localizedString(forKey: language.rawValue, comment: ""), action: #selector(selectedLanguage), keyEquivalent: "")
            
            menuItem.representedObject = language
        }
        languageSelectionMenu.submenu = submenu
        languageSelectionMenu.title = LanguageManager.shared.localizedString(forKey: MenuTitleType.language.rawValue, comment: "")
        languageSelectionMenu.representedObject = MenuTitleType.language
        return languageSelectionMenu
    }
    
  @objc private func selectedLanguage(_ sender: NSMenuItem) {
    if let selectedLanguage = sender.representedObject as? LanguageSetup {
      languageOutput.send(selectedLanguage)
    }
  }
```

유저가 언어 설정을 누르면 `languageOutput`에 전달해서 updateLanguage와 updateMenuTitles 메서드를 실행한다.
updateMenuTitles 메서드는 메뉴 설정 시에 할당한 representedObject를 기반으로 타입을 판단해서 설정한 언어 기반으로 String value를 새로 할당한다.

```swift
  private func updateLanguage(_ language: LanguageSetup) {
      LanguageManager.shared.setLanguage(language.rawValue)
  }

  private func updateMenuTitles(_ menu: NSMenu) {
      for item in menu.items {
            if let submenu = item.submenu {
                if let titleKey = item.representedObject as? MenuTitleType {
                    item.title = LanguageManager.shared.localizedString(forKey: titleKey.rawValue, comment: "")
                }
                updateMenuTitles(submenu)
            } else {
                if let titleKey = item.representedObject as? MenuTitleType {
                    item.title = LanguageManager.shared.localizedString(forKey: titleKey.rawValue, comment: "")
                } else if let characterKey = item.representedObject as? CharacterName {
                    item.title = LanguageManager.shared.localizedString(forKey: characterKey.rawValue, comment: "")
                } else if let intervalKey = item.representedObject as? PlayInterval {
                    item.title = LanguageManager.shared.localizedString(forKey: intervalKey.rawValue, comment: "")
                } else if let languageKey = item.representedObject as? LanguageSetup {
                    item.title = LanguageManager.shared.localizedString(forKey: languageKey.rawValue, comment: "")
                }
            }
      }
  }
```

-----

# 회고

- SwiftUI의 MenuBarExtra를 활용하면 AppDelegate를 활용하지 않아도 메뉴바 구성이 간편하게 되지만, 정적인 이미지 활용 위주로 제공이 되어서, 타이머 활용 같은 추가 액션을 활용하기 어려워서 NSStatusBarItem을 활용하는 방향으로 구성했다. 다른 프로젝트에서 본격적인 Window 구성이 들어간다면 그때는 MenuBarExtra를 활용해볼 수 있을 것 같다. 
- 자동 로그인 설정은 Mac 부팅 및 로그인 시의 한 로그인 계정에서만 등록이 가능한 설정이다. 동일 Mac에서 다른 계정으로 로그인 시에는 해당 앱이 등록되어있지 않다. 모든 로그인 계정에 동일하게 적용되려면 `LauncherDaemon`을 따로 구성해서 처음 설치 시에 설정해야 적용된다. 이는 추후 기능 업데이트로 구현해볼 수 있을 것 같다.
- 현재는 Github Pages에서 매번 버전 Release를 업로드 하지만 차후 프로젝트 규모가 커져서 웹페이지 구성 시에는 appcast.xml 구성을 서버에 따로 구성해야 할 것으로 예상한다.
