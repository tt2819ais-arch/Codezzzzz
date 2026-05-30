import SwiftUI

/// Explains how each metric is measured. Transparency matters for a tool whose
/// whole job is to report trustworthy numbers.
struct MethodologyView: View {
    @Environment(\.dismiss) private var dismiss

    private struct Item: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let body: String
    }

    private let items: [Item] = [
        .init(icon: "timer", title: "Задержка (RTT)",
              body: "Время установки TCP-соединения с 1.1.1.1:443 напрямую через Network.framework. Это ближе к настоящему round-trip, чем замер полного HTTPS-запроса, который включает DNS и TLS."),
        .init(icon: "waveform.path.ecg", title: "Джиттер",
              body: "Средняя разница между соседними замерами задержки. Высокий джиттер означает нестабильное соединение — заметно в звонках и играх."),
        .init(icon: "chart.dots.scatter", title: "Потери пакетов",
              body: "Доля попыток подключения, не уложившихся в таймаут. Это реальные неудачи рукопожатия, а не просто ошибки HTTP."),
        .init(icon: "arrow.down.circle", title: "Скорость загрузки/отдачи",
              body: "Сначала идёт прогрев, чтобы раскрыть TCP-окно, затем берётся несколько замеров и считается медиана. Так результат не занижается из-за медленного старта. Данные передаются через speed.cloudflare.com."),
        .init(icon: "gauge.with.dots.needle.67percent", title: "Общая оценка",
              body: "Взвешенная оценка 0–100: задержка и потери важнее всего, затем скорость и джиттер — то, что реально ощущается при использовании сети."),
    ]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("NetPulse измеряет качество соединения честно. Вот как считается каждый показатель.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                ForEach(items) { item in
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: item.icon)
                            .font(.title3)
                            .foregroundStyle(Theme.accent)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title).font(.subheadline.weight(.semibold))
                            Text(item.body).font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Как мы измеряем")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }
                }
            }
        }
    }
}
