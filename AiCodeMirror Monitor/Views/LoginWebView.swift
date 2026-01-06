import SwiftUI
import WebKit

/// 登录 WebView - 使用 WKWebView 处理网站登录
struct LoginWebView: NSViewRepresentable {
    @Binding var isLoggedIn: Bool
    let onLoginSuccess: ([HTTPCookie]) -> Void
    let onLoginFailure: (Error) -> Void

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = WKWebsiteDataStore.default()

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"

        // 加载登录页面
        if let url = URL(string: "https://aicodemirror.com/login") {
            webView.load(URLRequest(url: url))
        }

        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: LoginWebView
        private var hasDetectedLogin = false

        init(_ parent: LoginWebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard let url = webView.url else { return }

            // 检测是否已跳转到 dashboard 页面 (登录成功)
            if url.path.contains("/dashboard") || (url.path == "/" && !url.path.contains("/login")) {
                if !hasDetectedLogin {
                    hasDetectedLogin = true
                    extractCookies(from: webView)
                }
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.onLoginFailure(error)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            // 忽略取消的请求
            let nsError = error as NSError
            if nsError.code == NSURLErrorCancelled { return }
            parent.onLoginFailure(error)
        }

        private func extractCookies(from webView: WKWebView) {
            webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { [weak self] cookies in
                guard let self = self else { return }

                // 过滤 aicodemirror.com 的 cookies
                let relevantCookies = cookies.filter {
                    $0.domain.contains("aicodemirror.com") || $0.domain.contains("aicodemirror")
                }

                // 检查是否有 session cookie
                let hasSessionCookie = relevantCookies.contains { cookie in
                    let name = cookie.name.lowercased()
                    return name.contains("session") ||
                           name.contains("token") ||
                           name.contains("auth") ||
                           name.contains("jwt") ||
                           name.contains("sid")
                }

                DispatchQueue.main.async {
                    if hasSessionCookie || !relevantCookies.isEmpty {
                        self.parent.isLoggedIn = true
                        self.parent.onLoginSuccess(relevantCookies)
                    }
                }
            }
        }
    }
}

/// 登录视图容器
struct LoginView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var isLoading = true

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("登录 AICodeMirror")
                    .font(.headline)

                Spacer()

                if isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                }

                Button("取消") {
                    isPresented = false
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // WebView
            LoginWebView(
                isLoggedIn: Binding(
                    get: { authViewModel.authState.isLoggedIn },
                    set: { _ in }
                ),
                onLoginSuccess: { cookies in
                    authViewModel.handleLoginSuccess(cookies: cookies)
                    isPresented = false
                },
                onLoginFailure: { error in
                    authViewModel.handleLoginFailure(error: error)
                }
            )
            .onAppear {
                // 模拟加载状态
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    isLoading = false
                }
            }
        }
    }
}
