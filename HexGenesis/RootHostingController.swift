import UIKit
import SwiftUI

final class RootHostingController: UIHostingController<AnyView> {

    required init?(coder aDecoder: NSCoder) {
        let appState = AppState()
        let root = RootView().environmentObject(appState)
        super.init(coder: aDecoder, rootView: AnyView(root))
    }
}
