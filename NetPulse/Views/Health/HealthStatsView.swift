import SwiftUI
import Charts

struct HealthStatsView: View {
    @StateObject private var vm = HealthViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.stackSpacing) {
                    Picker("Период", selection: $vm.selectedRange) {
                        ForEach(HealthRange.allCases) { range in
                            Text(range.label).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: vm.selectedRange) { vm.load() }

                    content
                }
                .padding()
            }
            .navigationTitle("Шаги")
            .onAppear { vm.load() }
        }
    }

    @ViewBuilder private var content: some View {
        switch vm.accessState {
        case .unavailable:
            unavailableState
        case .denied:
            deniedState
        case .authorized, .none:
            if vm.isLoading && vm.points.isEmpty {
                ProgressView().padding(.vertical, 60)
            } else if vm.hasData {
                chartCard
                statsRow
            } else if vm.accessState == .authorized {
                noDataState
            } else {
                ProgressView().padding(.vertical, 60)
            }
        }
    }

    private var chartCard: some View {
        Card {
            SectionHeader(title: "Шаги за период", systemImage: "figure.walk")
            Chart(vm.points) { point in
                BarMark(
                    x: .value("Дата", point.date, unit: barUnit),
                    y: .value("Шаги", point.steps)
                )
                .foregroundStyle(Theme.accent.gradient)
                .cornerRadius(4)
            }
            .frame(height: 240)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            statTile("Сумма", vm.total, "sum")
            statTile("Среднее", vm.average, "chart.bar")
            statTile("Пик", vm.peak, "arrow.up.to.line")
        }
    }

    private func statTile(_ title: String, _ value: Double, _ icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.footnote)
                .foregroundStyle(Theme.accent)
            Text(value, format: .number.precision(.fractionLength(0)))
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .monospacedDigit()
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var barUnit: Calendar.Component {
        vm.selectedRange == .day ? .hour : .day
    }

    private var unavailableState: some View {
        ContentUnavailableView(
            "HealthKit недоступен",
            systemImage: "heart.slash",
            description: Text("На этом устройстве нет данных о здоровье.")
        )
        .padding(.vertical, 40)
    }

    private var deniedState: some View {
        ContentUnavailableView {
            Label("Нет доступа к шагам", systemImage: "lock")
        } description: {
            Text("Разрешите доступ к шагам в Настройки → Конфиденциальность → Здоровье, чтобы видеть статистику.")
        }
        .padding(.vertical, 40)
    }

    private var noDataState: some View {
        ContentUnavailableView(
            "Нет данных о шагах",
            systemImage: "figure.walk.motion",
            description: Text("За выбранный период шаги не записаны.")
        )
        .padding(.vertical, 40)
    }
}
