import SwiftUI
import UIKit

struct InternetDiagnosticsView: View {
    @StateObject private var vm = InternetDiagnosticsViewModel()
    @State private var showVPNUnavailable = false

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                VoidBackground()

                ScrollView {
                    VStack(spacing: 22) {
                        header

                        gaugeSection

                        if let report = vm.report {
                            statusPill(for: report)

                            metricsGrid(report)

                            locationCard(report)

                            if report.isJammed {
                                jammedCard
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                        } else if let error = vm.errorText {
                            errorCard(error)
                        }

                        actionButtons
                            .padding(.top, 4)
                    }
                    .padding(20)
                    .padding(.bottom, 24)
                    .animation(.spring(response: 0.55, dampingFraction: 0.85), value: vm.report)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("NetPulse")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .onAppear { if vm.report == nil && !vm.isLoading { vm.run() } }
            .onChange(of: vm.report) { newValue in
                guard let report = newValue else { return }
                if report.isJammed { Haptics.warning() } else { Haptics.success() }
            }
            .alert("VPN-приложение не найдено", isPresented: $showVPNUnavailable) {
                Button("Ок", role: .cancel) {}
            } message: {
                Text("Установите VPN-приложение, чтобы подключаться одной кнопкой.")
            }
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Диагностика сети")
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text(vm.isLoading ? "Измеряем соединение…" : "Скорость, задержка и качество связи")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var gaugeSection: some View {
        PulseGauge(
            score: vm.report?.qualityScore ?? 0,
            headline: vm.report.map { String(format: "%.0f", $0.ping) } ?? "—",
            caption: "Ping · ms",
            isLoading: vm.isLoading
        )
        .padding(.vertical, 6)
    }

    private func statusPill(for report: NetworkReport) -> some View {
        let color: Color = report.isJammed
            ? Color(red: 1.0, green: 0.55, blue: 0.2)
            : (report.qualityScore >= 0.55
               ? Color(red: 0.2, green: 0.92, blue: 0.62)
               : Color(red: 1.0, green: 0.78, blue: 0.28))
        return HStack(spacing: 8) {
            Circle().fill(color).frame(width: 9, height: 9)
            Text(report.statusTitle)
                .font(.system(size: 15, weight: .heavy))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(color.opacity(0.5), lineWidth: 1))
    }

    private func metricsGrid(_ report: NetworkReport) -> some View {
        LazyVGrid(columns: columns, spacing: 14) {
            MetricTile(icon: "arrow.down.circle.fill", title: "Загрузка",
                       value: String(format: "%.1f Mbps", report.downloadSpeed),
                       tint: Color(red: 0.3, green: 0.8, blue: 1.0))
            MetricTile(icon: "arrow.up.circle.fill", title: "Отдача",
                       value: String(format: "%.1f Mbps", report.uploadSpeed),
                       tint: Color(red: 0.6, green: 0.5, blue: 1.0))
            MetricTile(icon: "waveform.path.ecg", title: "Джиттер",
                       value: String(format: "%.0f ms", report.latencyJitter),
                       tint: Color(red: 0.4, green: 0.9, blue: 0.7))
            MetricTile(icon: "exclamationmark.triangle.fill", title: "Потери",
                       value: String(format: "%.0f%%", report.packetLoss),
                       tint: Color(red: 1.0, green: 0.7, blue: 0.3))
            MetricTile(icon: "wifi", title: "Тип сети",
                       value: report.networkType,
                       tint: Color(red: 0.5, green: 0.8, blue: 1.0))
            MetricTile(icon: "clock.fill", title: "Время",
                       value: report.localTime,
                       tint: Color(red: 0.8, green: 0.7, blue: 1.0))
        }
    }

    private func locationCard(_ report: NetworkReport) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                infoRow(icon: "globe", title: "IP-адрес", value: report.ip)
                Divider().overlay(Color.white.opacity(0.1))
                infoRow(icon: "mappin.and.ellipse", title: "Расположение",
                        value: "\(report.city), \(report.country)")
                Divider().overlay(Color.white.opacity(0.1))
                infoRow(icon: "server.rack", title: "Провайдер", value: report.asn)
            }
        }
    }

    private func infoRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color(red: 0.58, green: 0.5, blue: 1.0))
                .frame(width: 22)
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .heavy))
                .foregroundStyle(.white)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
        }
    }

    private var jammedCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.shield.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color(red: 1.0, green: 0.6, blue: 0.2))
                    Text("Возможное ограничение")
                        .font(.system(size: 17, weight: .heavy))
                        .foregroundStyle(.white)
                }
                Text("Обнаружены аномалии: высокий ping, потери пакетов или низкая скорость. Попробуйте включить VPN.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func errorCard(_ error: String) -> some View {
        GlassCard {
            VStack(spacing: 8) {
                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Color(red: 1.0, green: 0.4, blue: 0.45))
                Text("Не удалось проверить сеть")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(.white)
                Text(error)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            PrimaryButton(
                title: vm.isLoading ? "Проверяем…" : "Проверить интернет",
                systemImage: "bolt.fill",
                isLoading: vm.isLoading
            ) {
                vm.run()
            }

            SecondaryButton(title: "Подключить VPN", systemImage: "lock.shield.fill") {
                connectVPN()
            }
        }
    }

    private func connectVPN() {
        guard let url = URL(string: "happplusvpn://connect") else { return }
        UIApplication.shared.open(url, options: [:]) { success in
            if !success {
                Haptics.error()
                showVPNUnavailable = true
            }
        }
    }
}
