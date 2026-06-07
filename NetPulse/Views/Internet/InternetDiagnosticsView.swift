import SwiftUI

struct InternetDiagnosticsView: View {
    @EnvironmentObject private var settings: AppSettings
    @StateObject private var vm = InternetDiagnosticsViewModel()
    @Environment(\.openURL) private var openURL

    @State private var showMethodology = false
    @State private var showHistory = false
    @State private var didAutoRun = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.stackSpacing) {
                    header
                    if let report = vm.report {
                        gauge(for: report)
                        if report.isLikelyRestricted {
                            restrictionBanner(report)
                        }
                        metricGrid(report)
                        identityCard(report)
                        actions(report)
                    } else if !vm.isRunning {
                        emptyState
                    }
                }
                .padding()
                .animation(.easeInOut(duration: 0.35), value: vm.report)
            }
            .navigationTitle("Сеть")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showMethodology = true } label: {
                        Image(systemName: "info.circle")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showHistory = true } label: {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                    .disabled(vm.history.isEmpty)
                }
            }
            .refreshable { await runAndWait() }
            .sheet(isPresented: $showMethodology) { MethodologyView() }
            .sheet(isPresented: $showHistory) {
                HistoryView(history: vm.history) { vm.clearHistory() }
            }
            .onAppear {
                if settings.autoRunOnLaunch && !didAutoRun && vm.report == nil {
                    didAutoRun = true
                    vm.run(settings: settings)
                }
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder private var header: some View {
        if vm.isRunning {
            VStack(spacing: 10) {
                ProgressView(value: vm.progress)
                    .tint(Theme.accent)
                Text(vm.phaseText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .transition(.opacity)
            }
            .padding(.top, 4)
            .animation(.easeInOut, value: vm.phaseText)
        }
    }

    private func gauge(for report: NetworkReport) -> some View {
        VStack(spacing: 12) {
            QualityGauge(score: report.qualityScore, caption: report.qualityLabel)
            Text("Последняя проверка: \(report.timestamp.formatted(date: .omitted, time: .shortened))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }

    private func metricGrid(_ r: NetworkReport) -> some View {
        let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
        return LazyVGrid(columns: columns, spacing: 12) {
            MetricTile(title: "Задержка", value: "\(Int(r.latencyMs.rounded()))", unit: "мс",
                       systemImage: "timer", rating: r.latencyRating)
            MetricTile(title: "Джиттер", value: "\(Int(r.jitterMs.rounded()))", unit: "мс",
                       systemImage: "waveform.path.ecg", rating: r.jitterRating)
            MetricTile(title: "Загрузка", value: speed(r.downloadMbps), unit: "Mbps",
                       systemImage: "arrow.down.circle", rating: r.downloadRating)
            MetricTile(title: "Отдача", value: speed(r.uploadMbps), unit: "Mbps",
                       systemImage: "arrow.up.circle", rating: r.uploadRating)
            MetricTile(title: "Потери", value: String(format: "%.1f", r.packetLoss), unit: "%",
                       systemImage: "chart.dots.scatter", rating: r.lossRating)
            MetricTile(title: "Сеть", value: r.connectionType.rawValue, unit: "",
                       systemImage: r.connectionType.systemImage, rating: .unknown)
        }
    }

    private func identityCard(_ r: NetworkReport) -> some View {
        Card {
            SectionHeader(title: "Подключение", systemImage: "globe")
            InfoRow(key: "Провайдер", value: r.isp)
            Divider().opacity(0.4)
            InfoRow(key: "Местоположение", value: location(r))
            Divider().opacity(0.4)
            InfoRow(key: "IP-адрес", value: r.ip, monospaced: true)
        }
    }

    private func restrictionBanner(_ r: NetworkReport) -> some View {
        Card {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.shield")
                    .foregroundStyle(Theme.warn)
                Text("Возможное ограничение соединения")
                    .font(.subheadline.weight(.semibold))
            }
            ForEach(r.restrictionSignals, id: \.self) { signal in
                HStack(alignment: .top, spacing: 6) {
                    Text("•").foregroundStyle(Theme.warn)
                    Text(signal).font(.footnote).foregroundStyle(.secondary)
                }
            }
        }
    }

    private func actions(_ r: NetworkReport) -> some View {
        VStack(spacing: 12) {
            Button {
                if settings.hapticsEnabled { Haptics.tap() }
                vm.run(settings: settings)
            } label: {
                Label("Проверить снова", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(vm.isRunning)

            HStack(spacing: 12) {
                ShareLink(item: vm.shareText()) {
                    Label("Поделиться", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button {
                    guard let url = URL(string: settings.vpnScheme) else { return }
                    openURL(url)
                } label: {
                    Label("VPN", systemImage: "lock.shield")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
        .padding(.top, 4)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi")
                .font(.system(size: 44))
                .foregroundStyle(Theme.accent)
            Text("Готов к проверке")
                .font(.headline)
            Text("Запустите тест, чтобы измерить задержку, потери и скорость соединения.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                vm.run(settings: settings)
            } label: {
                Label("Проверить интернет", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.top, 4)
        }
        .padding(.vertical, 48)
    }

    // MARK: - Helpers

    private func runAndWait() async {
        vm.run(settings: settings)
        while vm.isRunning {
            try? await Task.sleep(nanoseconds: 150_000_000)
        }
    }

    private func speed(_ v: Double) -> String { v <= 0 ? "—" : String(format: "%.1f", v) }

    private func location(_ r: NetworkReport) -> String {
        r.country.isEmpty ? r.city : "\(r.city), \(r.country)"
    }
}
