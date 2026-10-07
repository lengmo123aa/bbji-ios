import SwiftUI

@main
struct BBjiApp: App {
    @StateObject private var session = Session()

    var body: some Scene {
        WindowGroup {
            Group {
                if session.loggedIn {
                    MainTabs().environmentObject(session)     // A 方案（2026-10-07 回）：原生精修 / 重塑
                } else {
                    AuthFlow().environmentObject(session)      // 0.0.2：启动页 → 登录 / 注册 / 取名字 / 找回
                }
            }
            .preferredColorScheme(.light)
        }
    }
}
