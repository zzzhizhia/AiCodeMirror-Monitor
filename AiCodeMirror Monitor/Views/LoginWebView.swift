import SwiftUI

/// 登录视图
struct LoginView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var identifier = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 12) {
            Text("登录")
                .font(.headline)

            TextField("账号", text: $identifier)
                .textFieldStyle(.roundedBorder)

            SecureField("密码", text: $password)
                .textFieldStyle(.roundedBorder)

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            HStack(spacing: 8) {
                Button("取消") {
                    isPresented = false
                }
                .keyboardShortcut(.escape)

                Button(action: performLogin) {
                    Group {
                        if isLoading {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Text("登录")
                        }
                    }
                    .frame(width: 32)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading || identifier.isEmpty || password.isEmpty)
                .keyboardShortcut(.return)
            }
        }
        .padding(20)
        .frame(width: 240)
        .fixedSize()
    }

    private func performLogin() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let cookies = try await AuthService.shared.login(
                    identifier: identifier,
                    password: password
                )
                await MainActor.run {
                    authViewModel.handleLoginSuccess(cookies: cookies)
                    isPresented = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}
