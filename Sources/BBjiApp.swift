import SwiftUI

@main
struct BBjiApp: App {
    @StateObject private var session = Session()

    var body: some Scene {
        WindowGroup {
            Group {
                if session.loggedIn {
                    MainTabs().environmentObject(session)
                } else {
                    LoginView().environmentObject(session)
                }
            }
            .preferredColorScheme(.light)
        }
    }
}
