import SwiftUI
import Combine

final class MainImageViewModel: ObservableObject {
    
    @Published var imageString: String?
    @Published var textString: String?
    
    init() {
        print("MainImageViewModel INIT!!!")
    }
    
    func loadImage(for character: CharacterName) {
        let randomContentData = character.randomMainContentData()
        self.imageString = randomContentData.imageString
        self.textString = randomContentData.textString
    }
    
    deinit {
        print("MaimImageViewModel DEINIT!!!")
    }
    
}
