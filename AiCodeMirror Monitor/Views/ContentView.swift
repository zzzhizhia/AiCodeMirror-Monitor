import SwiftUI

/// 主内容视图
struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var balanceViewModel: BalanceViewModel

    @State private var showingLoginSheet = false

    var body: some View {
        Group {
            if authViewModel.isLoggedIn {
                DashboardView()
            } else {
                LoginPromptView(showingLoginSheet: $showingLoginSheet)
            }
        }
        .frame(minWidth: 500, minHeight: 400)
        .sheet(isPresented: $showingLoginSheet) {
            LoginView(isPresented: $showingLoginSheet)
                .environmentObject(authViewModel)
        }
        .onAppear {
            authViewModel.checkLoginState()
            if authViewModel.isLoggedIn {
                balanceViewModel.startAutoRefresh()
            }
        }
        .onChange(of: authViewModel.isLoggedIn) { _, isLoggedIn in
            if isLoggedIn {
                balanceViewModel.startAutoRefresh()
            } else {
                balanceViewModel.stopAutoRefresh()
            }
        }
    }
}

/// 未登录提示视图
struct LoginPromptView: View {
    @Binding var showingLoginSheet: Bool

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 80))
                .foregroundColor(.secondary)

            VStack(spacing: 8) {
                Text("欢迎使用 AICodeMirror Monitor")
                    .font(.title)
                    .fontWeight(.semibold)

                Text("登录您的 AICodeMirror 账户以查看余额")
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            Button(action: {
                showingLoginSheet = true
            }) {
                Text("登录")
                    .font(.headline)
                    .frame(width: 120)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Spacer()

            Text("登录后可在菜单栏和桌面 Widget 查看余额")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
        .environmentObject(BalanceViewModel())
}
