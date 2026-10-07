import SwiftUI

@main
struct BBjiApp: App {
    @StateObject private var session = Session()

    var body: some Scene {
        WindowGroup {
            Group {
                if session.loggedIn {
                    WebRoot().environmentObject(session)      // B 方案：真实界面 = 效果图那套 HTML/CSS
                } else {
                    AuthFlow().environmentObject(session)      // 0.0.2：启动页 → 登录 / 注册 / 取名字 / 找回
                }
            }
            .preferredColorScheme(.light)
        }
    }
}
