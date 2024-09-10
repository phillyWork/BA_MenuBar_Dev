import Foundation

enum UserDefaultsError: Error {
    case noDataInUserDefaults
    case cannotDecodeData
}

final class UserDefaultsManager {
    
    static let shared = UserDefaultsManager()
    private init() { }
    
    private let userDefault = UserDefaults.standard
    
    func retrieveFromUserDefaults<T: Codable>(forKey: String) throws -> T {
        guard let retrievedData = userDefault.object(forKey: forKey) as? Data else {
            throw UserDefaultsError.noDataInUserDefaults
        }
        let decoder = JSONDecoder()
        do {
            let data = try decoder.decode(T.self, from: retrievedData)
            return data
        } catch {
            throw UserDefaultsError.cannotDecodeData
        }
    }
    
    func saveToUserDefaults<T: Codable>(newValue: T, forKey: String) -> Bool {
        let encoder = JSONEncoder()
        do {
            let encoded = try encoder.encode(newValue)
            userDefault.set(encoded, forKey: forKey)
            return true
        } catch {
            return false
        }
    }
    
    func deleteFromUserDefaults(forKey: String) {
        userDefault.removeObject(forKey: forKey)
    }
    
}
