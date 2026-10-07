import SwiftUI

/// 手机端设计稿（v5 全套）里的那套色 / 尺寸，集中放这儿，别处不要再写死颜色。
enum T {
    static let ink = Color(red: 0.10, green: 0.13, blue: 0.19)         // #1A2130
    static let sub = Color(red: 0.44, green: 0.50, blue: 0.56)         // #71798A
    static let gray = Color(red: 0.54, green: 0.58, blue: 0.64)
    static let line = Color(red: 0.88, green: 0.90, blue: 0.93)
    static let blue = Color(red: 0.29, green: 0.55, blue: 0.96)        // #4A8BF6
    static let blueLight = Color(red: 0.47, green: 0.69, blue: 1.0)    // #79B0FF
    static let green = Color(red: 0.20, green: 0.78, blue: 0.35)
    static let red = Color(red: 0.95, green: 0.23, blue: 0.19)
    static let cardRadius: CGFloat = 14
    static let bg = LinearGradient(
        colors: [Color(red: 0.914, green: 0.945, blue: 0.992),
                 Color(red: 0.961, green: 0.976, blue: 0.996),
                 Color(red: 0.949, green: 0.937, blue: 0.988)],
        startPoint: .topLeading, endPoint: .bottomTrailing)
}

extension View {
    /// 那层半透明白卡（跟设计稿里 .grp / .card 一样）
    func glassCard(_ radius: CGFloat = T.cardRadius) -> some View {
        background(Color.white.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
    }
}

struct AppBg: View {
    var body: some View { T.bg.ignoresSafeArea() }
}

/// 官方 logo（图标资源，1024 那张圆的）
struct LogoMark: View {
    var size: CGFloat
    var body: some View {
        Image("Logo").resizable().interpolation(.high)
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.24, style: .continuous))
    }
}

/// 主按钮：跟设计稿一样的蓝色胶囊
struct BigButton: View {
    let title: String
    var busy = false
    var disabled = false
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(busy ? "请稍等…" : title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity).frame(height: 50)
                .background(LinearGradient(colors: [T.blueLight, T.blue], startPoint: .top, endPoint: .bottom))
                .clipShape(Capsule())
                .shadow(color: T.blue.opacity(0.25), radius: 12, y: 6)
                .opacity(disabled || busy ? 0.55 : 1)
        }
        .disabled(disabled || busy)
    }
}

/// 表单里的一行：左边标签、右边输入框（设计稿里的 .row tall）
struct FieldRow: View {
    let label: String
    @Binding var text: String
    var placeholder = ""
    var secure = false
    var keyboard: UIKeyboardType = .default
    var trailing: AnyView? = nil

    var body: some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.system(size: 12.5)).foregroundColor(T.gray)
                .frame(width: 74, alignment: .leading)
            if secure {
                SecureField(placeholder, text: $text).font(.system(size: 13.5))
                    .textInputAutocapitalization(.never)
            } else {
                TextField(placeholder, text: $text).font(.system(size: 13.5))
                    .keyboardType(keyboard)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
            }
            if let t = trailing { t }
        }
        .padding(.horizontal, 14).frame(height: 48)
    }
}

/// 设置那种一行：左标题 + 小字说明 + 右边箭头（后面 M2 直接拿来用）
struct RowLine: View {
    let title: String
    var note: String = ""
    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 12.5, weight: .semibold)).foregroundColor(T.ink)
                if !note.isEmpty { Text(note).font(.system(size: 10.5)).foregroundColor(T.gray) }
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(red: 0.79, green: 0.82, blue: 0.85))
        }
        .padding(.horizontal, 14).frame(minHeight: 44)
    }
}
