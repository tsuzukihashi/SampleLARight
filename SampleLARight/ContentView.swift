import SwiftUI

struct ContentView: View {
    // NOTE: 本来ならViewModelで持つべき
    @StateObject var authManager = AppAuthManager.shared

    @State var showAlert: Bool = false
    @State var statusStr: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    individualLARight()

                    allLARight()
                }
                .padding(.horizontal)
                .navigationTitle(Text("Sample LARight"))
            }
            .scrollDismissesKeyboard(.immediately)
            .alert(statusStr, isPresented: $showAlert, actions: {
                Button("OK") {}
            })
        }
    }

    fileprivate func individualLARight() -> some View {
        return VStack(alignment: .leading, spacing: 16) {
            Text("個々のLARightで管理する認証情報")
                .font(.headline)

            TextField("KeyChainに保存する言葉", text: $authManager.secretValue)
                .textFieldStyle(.roundedBorder)
                .font(.headline)

            HStack {
                Spacer()
                Button("📝 保存") {
                    guard let encodedData = authManager.secretValue.data(using: .utf8) else {
                        statusStr = "保存処理に失敗しました"
                        showAlert.toggle()
                        return
                    }
                    Task {
                        do {
                            try await authManager.store(data: encodedData)
                            statusStr = "保存成功！"
                            authManager.secretValue = ""
                            showAlert.toggle()
                        } catch {
                            statusStr = error.localizedDescription
                            showAlert.toggle()
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .disabled(authManager.secretValue.isEmpty)

                Button("👀 閲覧") {
                    Task {
                        do {
                            let data = try await authManager.fetchData()
                            guard let decodedStr = String(data: data, encoding: .utf8) else {
                                statusStr = "Failed to decode data into string"
                                showAlert.toggle()
                                return
                            }
                            authManager.secretValue = decodedStr
                        } catch {
                            statusStr = error.localizedDescription
                            showAlert.toggle()
                        }
                    }
                }
                .buttonStyle(.borderedProminent)

                Button("🗑 削除", role: .destructive) {
                    Task {
                        do {
                            try await authManager.removeData()
                            authManager.secretValue = ""
                        } catch {
                            statusStr = error.localizedDescription
                            showAlert.toggle()
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    fileprivate func allLARight() -> some View {
        return VStack(alignment: .leading, spacing: 16) {
            Text("共通のLARightで管理する認証情報")
                .font(.headline)

            Label(
                (authManager.currentState == .authorized) ? "認証済み" : "未認証",
                systemImage: (authManager.currentState == .authorized) ? "checkmark.circle.fill" : "xmark"
            )

            ScrollView(.horizontal) {
                HStack {
                    ForEach(1...7, id: \.self) { index in
                        Image("\(index)")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .cornerRadius(120 / 22)
                            .redacted(reason: (authManager.currentState == .authorized) ? [] : .placeholder)
                    }
                }
            }

            HStack {
                Spacer()

                switch authManager.currentState {
                case .authorized:
                    Button("❎　解除する", role: .destructive) {
                        Task {
                            await authManager.logout()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                case .notAuthorized, .unknown:
                    Button("✅　認証する") {
                        Task {
                            do {
                                try await authManager.login()
                            } catch {
                                statusStr = error.localizedDescription
                                showAlert.toggle()
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                default:
                    ProgressView()
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
