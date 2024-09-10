import Foundation

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
