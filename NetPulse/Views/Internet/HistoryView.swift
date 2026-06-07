import SwiftUI
import Charts

/// Shows past diagnostics runs: a trend chart of the quality score plus a list
/// of individual runs.
struct HistoryView: View {
    let history: [NetworkReport]
    let onClear: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showClearConfirm = false

    private var chronological: [NetworkReport] {
        history.sorted { $0.timestamp < $1.timestamp }
    }

    var body: some View {
        NavigationStack {
            Group {
                if history.isEmpty {
                    ContentUnavailableView("Нет истории", systemImage: "clock",
                                           description: Text("Запустите проверку, и результаты появятся здесь."))
                } else {
                    List {
                        if chronological.count > 1 {
                            Section("Динамика оценки") {
                                trendChart
                                    .frame(height: 180)
                                    .padding(.vertical, 8)
                            }
                        }
                        Section("Проверки") {
                            ForEach(history) { report in
                                runRow(report)
                            }
                        }
                    }
                }
            }
            .navigationTitle("История")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }
                }
                ToolbarItem(placement: .topBarLeading) {
                    if !history.isEmpty {
                        Button(role: .destructive) { showClearConfirm = true } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
            .confirmationDialog("Очистить всю историю?", isPresented: $showClearConfirm, titleVisibility: .visible) {
                Button("Очистить", role: .destructive) { onClear(); dismiss() }
                Button("Отмена", role: .cancel) {}
            }
        }
    }

    private var trendChart: some View {
        Chart(chronological) { report in
            LineMark(
                x: .value("Время", report.timestamp),
                y: .value("Оценка", report.qualityScore)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(Theme.accent)

            AreaMark(
                x: .value("Время", report.timestamp),
                y: .value("Оценка", report.qualityScore)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(Theme.accent.opacity(0.12))
        }
        .chartYScale(domain: 0...100)
    }

    private func runRow(_ r: NetworkReport) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(scoreColor(r.qualityScore).opacity(0.15))
                    .frame(width: 42, height: 42)
                Text("\(r.qualityScore)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(scoreColor(r.qualityScore))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(r.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                Text("\(NetReportFormat.ms(r.latencyMs)) · ↓\(NetReportFormat.mbps(r.downloadMbps)) · ↑\(NetReportFormat.mbps(r.uploadMbps))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: r.connectionType.systemImage)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 80...: return Theme.good
        case 50..<80: return Theme.warn
        default: return Theme.bad
        }
    }
}
