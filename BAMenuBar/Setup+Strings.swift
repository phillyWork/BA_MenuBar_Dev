import Foundation
import Cocoa

struct MainImageViewData {
    var imageString: String
    var textString: String
}

enum MenuTitleType: String {
    case character = "selectCharacterMenuTitle"
    case interval = "selectPlayIntervalMenuTitle"
    case language = "selectLanguageMenuTitle"
    case enableAutoLaunch = "selectEnableAutoLaunchAtLoginTitle"
    case disableAutoLaunch = "selectDisableAutoLaunchAtLoginTitle"
    case checkUpdate = "checkUpdate"
    case quit = "terminateAppMenuTitle"
}

enum CharacterName: String, Codable, CaseIterable {
    case aru
    case hoshino
    case hina
    case shiroko
    case yuuka
    case mika
    
    func randomMainContentData() -> MainImageViewData {
        var matchingIndexes: [Int] = []
        var index = 1
        
        while NSImage(named: "\(mainContentImageString)\(index)") != nil {
            matchingIndexes.append(index)
            index += 1
        }
        
        if matchingIndexes.isEmpty {
            return MainImageViewData(imageString: "", textString: "")
        } else {
            let index = matchingIndexes.randomElement()!
            return MainImageViewData(imageString: "\(mainContentImageString)\(index)", textString: "\(mainContentTextString)\(index)")
        }
    }
    
    private var mainContentImageString: String {
        return self.rawValue + "MainContentImage"
    }
    
    private var mainContentTextString: String {
        return self.rawValue + "Text"
    }
}

enum PlayInterval: String, Codable, CaseIterable {
    case superSlow = "superSlow"
    case slow = "slow"
    case mediateSlow = "mediateSlow"
    case normal = "normal"
    case mediateFast = "mediateFast"
    case fast = "fast"
    case superFast = "superFast"
    
    var interval: Double {
        switch self {
        case .superSlow:
            return 1.75
        case .slow:
            return 1.5
        case .mediateSlow:
            return 1.25
        case .normal:
            return 1.0
        case .mediateFast:
            return 0.75
        case .fast:
            return 0.5
        case .superFast:
            return 0.25
        }
    }
}

enum LanguageSetup: String, Codable, CaseIterable {
    case en = "en"
    case ko = "ko"
    case ja = "ja"
}

//MARK: - Settings

enum SetupStrings {
    
    static let userDefaultsCharacterKey = "selectedCharacter"
    static let userDefaultsIntervalKey = "selectedInterval"
    static let userDefaultsLanguageKey = "selectedLanguage"
    
    static let selectCharacterMenuTitle = "selectCharacterMenuTitle"
    static let selectPlayIntervalMenuTitle = "selectPlayIntervalMenuTitle"
    static let selectLanguageMenuTitle = "selectLanguageMenuTitle"
    
    static let selectEnableAutoLaunchAtLoginTitle = "selectEnableAutoLaunchAtLoginTitle"
    static let selectDisableAutoLaunchAtLoginTitle = "selectDisableAutoLaunchAtLoginTitle"
    
    static let terminateAppMenuTitle = "terminateAppMenuTitle"
    
    
    
}

enum SetupFrame {
    
    static let mainContentViewWidth = 300
    static let mainContentViewHeight = 200
    static let dividerViewHeight = 5

}
