import SwiftUI

struct InternetDiagnosticsView: View {
    @StateObject private var vm = InternetDiagnosticsViewModel()
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if vm.isLoading {
                        ProgressView(value: vm.progress)
                            .progressViewStyle(.linear)
                        Text("Идёт измерение сети...")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    if let report = vm.report {
                        card {
                            row("IP", report.ip)
                            row("Город", "\(report.city), \(report.country)")
                            row("Ping", "\(report.ping, specifier: "%.0f") ms")
                            row("Download", "\(report.downloadSpeed, specifier: "%.2f") Mbps")
                            row("Upload", "\(report.uploadSpeed, specifier: "%.2f") Mbps")
                            row("Тип сети", report.networkType)
                            row("ASN", report.asn)
                            row("Локальное время", report.localTime)
                        }

                        if report.isJammed {
                            card {
                                Text("Возможное ограничение интернет-соединения")
                                    .font(.headline)
                                    .foregroundStyle(.yellow)
                                Text("Обнаружены аномалии сети: высокий ping/потери/низкая скорость.")
                                    .font(.footnote)
                            }
                        }
                    }

                    Button("Проверить интернет") { vm.run() }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)

                    Button("Подключить VPN") {
                        if let url = URL(string: "happplusvpn://connect") { openURL(url) }
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                }
                .padding()
            }
            .navigationTitle("Диагностика")
            .onAppear { if vm.report == nil { vm.run() } }
            .alert(
                "Ошибка",
                isPresented: Binding(
                    get: { vm.errorText != nil },
                    set: { presented in if !presented { vm.errorText = nil } }
                ),
                presenting: vm.errorText
            ) { _ in
                Button("Повторить") {
                    vm.errorText = nil
                    vm.run()
                }
                Button("Отмена", role: .cancel) {
                    vm.errorText = nil
                }
            } message: { text in
                Text(text)
            }
        }
    }

    private func row(_ key: String, _ value: String) -> some View {
        HStack {
            Text(key).foregroundStyle(.secondary)
            Spacer()
            Text(value).multilineTextAlignment(.trailing)
        }
    }

    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8, content: content)
            .padding()
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
