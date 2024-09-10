import Cocoa
import SwiftUI
import Combine
import ServiceManagement

import Sparkle

@main
struct BAMenuBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        Settings {
            Text("Settings Example")
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    
    private lazy var statusBarItem: NSStatusItem = {
        return NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    }()
    
    private let menu = NSMenu()
    private let mainContentMenu = NSMenuItem()
    private let autoLaunchAtStartMenu = NSMenuItem()
    
    private let characterOutput = PassthroughSubject<CharacterName, Never>()
    private let intervalOutput = PassthroughSubject<PlayInterval, Never>()
    private let languageOutput = PassthroughSubject<LanguageSetup, Never>()
    
    private let updaterController: SPUStandardUpdaterController
    private let mainImageViewModel = MainImageViewModel()
    
    private var timer: Timer? = nil
    
    private var cancellables = Set<AnyCancellable>()
    
    private var frameIndex: Int = 0
    
    @Published var userSelectedCharacter: CharacterName = {
        do {
            let savedCharacter = try UserDefaultsManager.shared.retrieveFromUserDefaults(forKey: SetupStrings.userDefaultsCharacterKey) as CharacterName
            return savedCharacter
        } catch {
            return CharacterName.allCases.randomElement()!
        }
    }()
        
    private lazy var interval: Double = {
        do {
            let savedInterval = try UserDefaultsManager.shared.retrieveFromUserDefaults(forKey: SetupStrings.userDefaultsIntervalKey) as Double
            return savedInterval
        } catch {
            return 1.0
        }
    }()
    
    //MARK: - menu bar image: rotation/position change halo image in frames
    private lazy var frames: [NSImage] = {
        return (0..<8).map { frame in
            if let image = NSImage(named: userSelectedCharacter.rawValue+"\(frame)") {
                image.size = NSSize(width: 28, height: 18)
                return image
            } else {
                let errorImage = NSImage(named: "ErrorImage")!
                errorImage.size = NSSize(width: 28, height: 18)
                return errorImage
            }
        }
    }()
    
    override init() {
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        bind()
        setupStatusItem()
        startRunning()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        stopRunning()
    }
    
    private func bind() {
        characterOutput
            .sink { [weak self] selectedCharacter in
                self?.userSelectedCharacter = selectedCharacter
                self?.mainImageViewModel.loadImage(for: selectedCharacter)
                self?.updateIcon()
                UserDefaultsManager.shared.saveToUserDefaults(newValue: selectedCharacter, forKey: SetupStrings.userDefaultsCharacterKey)
            }
            .store(in: &self.cancellables)
        
        intervalOutput
            .sink { [weak self] selectedInterval in
                self?.stopRunning()
                self?.interval = selectedInterval.interval
                UserDefaultsManager.shared.saveToUserDefaults(newValue: selectedInterval.interval, forKey: SetupStrings.userDefaultsIntervalKey)
                self?.startRunning()
            }
            .store(in: &self.cancellables)
        
        languageOutput
            .sink { [weak self] selectedLanguage in
                self?.updateLanguage(selectedLanguage)
                UserDefaultsManager.shared.saveToUserDefaults(newValue: selectedLanguage, forKey: SetupStrings.userDefaultsLanguageKey)
                self?.updateMenuTitles(self!.menu)
            }
            .store(in: &self.cancellables)
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
    
    private func setupStatusItem() {
        statusBarItem.button?.imagePosition = .imageTrailing
        statusBarItem.button?.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        statusBarItem.button?.image = frames.first
        
        let iconTabRecognizer = NSClickGestureRecognizer(target: self, action: #selector(iconTapped))
        statusBarItem.button?.addGestureRecognizer(iconTabRecognizer)
        
        do {
            let savedLanguage = try UserDefaultsManager.shared.retrieveFromUserDefaults(forKey: SetupStrings.userDefaultsLanguageKey) as LanguageSetup
            LanguageManager.shared.setLanguage(savedLanguage.rawValue)
        } catch {
            let defaultLanguage = Locale.current.language.languageCode?.identifier ?? LanguageSetup.en.rawValue
            LanguageManager.shared.setLanguage(defaultLanguage)
        }
        
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
            statusBarItem.menu = nil
        }
    }
    
    private func setupCharacterMenu() -> NSMenuItem {
        let characterSelectionMenu = NSMenuItem()
        let submenu = NSMenu()
        for character in CharacterName.allCases {
            let menuItem = submenu.addItem(withTitle: LanguageManager.shared.localizedString(forKey: character.rawValue, comment: ""), action: #selector(selectedType), keyEquivalent: "")
            
            menuItem.representedObject = character
        }
        characterSelectionMenu.submenu = submenu
        characterSelectionMenu.title = LanguageManager.shared.localizedString(forKey: MenuTitleType.character.rawValue, comment: "")
        characterSelectionMenu.representedObject = MenuTitleType.character
        return characterSelectionMenu
    }
    
    @objc private func selectedType(_ sender: NSMenuItem) {
        if let selectedCharacter = sender.representedObject as? CharacterName {
            characterOutput.send(selectedCharacter)
        }
    }
    
    private func setupIntervalMenu() -> NSMenuItem {
        let intervalSelectionMenu = NSMenuItem()
        let submenu = NSMenu()
        for interval in PlayInterval.allCases {
            let menuItem = submenu.addItem(withTitle: LanguageManager.shared.localizedString(forKey: interval.rawValue, comment: ""), action: #selector(selectedInterval), keyEquivalent: "")
            
            menuItem.representedObject = interval
        }
        intervalSelectionMenu.submenu = submenu
        intervalSelectionMenu.title = LanguageManager.shared.localizedString(forKey: MenuTitleType.interval.rawValue, comment: "")
        intervalSelectionMenu.representedObject = MenuTitleType.interval
        return intervalSelectionMenu
    }
    
    @objc private func selectedInterval(_ sender: NSMenuItem) {
        if let selectedInterval = sender.representedObject as? PlayInterval {
            intervalOutput.send(selectedInterval)
        }
    }
    
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
    
    private func setupStartAtLoginMenu() -> NSMenuItem {
        autoLaunchAtStartMenu.title = LanguageManager.shared.localizedString(forKey: checkLoginItem() ? MenuTitleType.disableAutoLaunch.rawValue : MenuTitleType.enableAutoLaunch.rawValue, comment: "")
        autoLaunchAtStartMenu.action = #selector(toggleStartAtLogin)
        autoLaunchAtStartMenu.keyEquivalent = "a"
        autoLaunchAtStartMenu.representedObject = checkLoginItem() ? MenuTitleType.disableAutoLaunch : MenuTitleType.enableAutoLaunch
        return autoLaunchAtStartMenu
    }
    
    @objc private func toggleStartAtLogin() {
        setLoginItem(shouldEnable: !checkLoginItem())
        autoLaunchAtStartMenu.title = LanguageManager.shared.localizedString(forKey: checkLoginItem() ? MenuTitleType.disableAutoLaunch.rawValue : MenuTitleType.enableAutoLaunch.rawValue, comment: "")
        autoLaunchAtStartMenu.representedObject = checkLoginItem() ? MenuTitleType.disableAutoLaunch : MenuTitleType.enableAutoLaunch
    }
    
    private func setLoginItem(shouldEnable: Bool) {
        do {
            shouldEnable ? try SMAppService.mainApp.register() : try SMAppService.mainApp.unregister()
        } catch {
            print("Error by SMAppService: \(error.localizedDescription)")
        }
    }
    
    private func checkLoginItem() -> Bool {
        switch SMAppService.mainApp.status {
        case .enabled: return true
        default: return false
        }
    }
        
    private func setupCheckUpdateMenu() -> NSMenuItem {
        let updateMenu = NSMenuItem()
        updateMenu.title = LanguageManager.shared.localizedString(forKey: MenuTitleType.checkUpdate.rawValue, comment: "")
        updateMenu.action = #selector(SPUStandardUpdaterController.checkForUpdates(_:))
        updateMenu.keyEquivalent = "u"
        updateMenu.representedObject = MenuTitleType.checkUpdate
        
        updateMenu.target = updaterController
  
        return updateMenu
    }
    
    private func setupQuitMenu() -> NSMenuItem {
        let quizMenu = NSMenuItem()
        quizMenu.title = LanguageManager.shared.localizedString(forKey: MenuTitleType.quit.rawValue, comment: "")
        quizMenu.action = #selector(terminateApp)
        quizMenu.keyEquivalent = "q"
        quizMenu.representedObject = MenuTitleType.quit
        
        return quizMenu
    }
    
    @objc private func terminateApp(_ sender: Any?) {
        NSApp.terminate(nil)
    }
    
    private func updateIcon() {
        stopRunning()
        
        frames.removeAll()
        frameIndex = 0
        frames = (0..<8).map { frame in
            if let image = NSImage(named: userSelectedCharacter.rawValue+"\(frame)") {
                image.size = NSSize(width: 28, height: 18)
                return image
            } else {
                return NSImage(named: "ErrorImage")!
            }
        }
        statusBarItem.button?.image = frames.first
        startRunning()
    }
    
    private func updateLanguage(_ language: LanguageSetup) {
        LanguageManager.shared.setLanguage(language.rawValue)
    }
    
    private func startRunning() {
        timer = Timer(timeInterval: self.interval, repeats: true, block: { [weak self] _ in
            self?.next()
        })
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    private func next() {
        frameIndex = (frameIndex + 1) % frames.count
        statusBarItem.button?.image = frames[frameIndex]
    }
    
    private func stopRunning() {
        timer?.invalidate()
    }
    
}
