import SwiftUI

struct LazyView<Content: View>: View {
    //get real view as function
    let build: () -> Content
    
    //init: not calling build function, save in property
    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }
    
    //when actually shows on screen: calls build function, which initializes view
    var body: Content {
        build()
    }
}

struct MainImageView: View {
    
    @ObservedObject var viewModel: MainImageViewModel
    
    var body: some View {
        VStack {
            if let imageName = viewModel.imageString, let textName = viewModel.textString {
                Image(imageName, label: Text("mainContentImage"))
                    .resizable()
                    .scaledToFit()
                Text(LanguageManager.shared.localizedString(forKey: textName, comment: ""))
                    .font(.subheadline)
            } else {
                Text("Loading...")
                    .font(.title2)
            }
        }
        .padding(.vertical, 5)
        .onDisappear {
            viewModel.imageString = nil
            viewModel.textString = nil
        }
    }
}
