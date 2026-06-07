import SwiftUI
import Charts

struct HealthStatsView: View {
    @StateObject private var vm = HealthViewModel()

    private var barUnit: Calendar.Component { vm.selectedRange == .day ? .hour : .day }
    private var hasData: Bool { vm.points.contains { $0.steps > 0 } }

    private let accent = [Color(red: 0.58, green: 0.5, blue: 1.0),
                          Color(red: 0.2, green: 0.82, blue: 0.98)]

    var body: some View {
        NavigationStack {
            ZStack {
                VoidBackground()

                ScrollView {
                    VStack(spacing: 22) {
                        header
                        periodPicker
                        totalCard
                        chartCard
                        metricsRow
                    }
                    .padding(20)
                    .padding(.bottom, 24)
                    .animation(.spring(response: 0.5, dampingFraction: 0.85), value: vm.points.count)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Здоровье")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .onAppear { if vm.points.isEmpty { vm.load() } }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Статистика шагов")
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text("Активность из приложения «Здоровье»")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var periodPicker: some View {
        Picker("Период", selection: $vm.selectedRange) {
            Text("День").tag(HealthRange.day)
            Text("Неделя").tag(HealthRange.week)
            Text("Месяц").tag(HealthRange.month)
            Text("Всё").tag(HealthRange.all)
        }
        .pickerStyle(.segmented)
        .onChange(of: vm.selectedRange) { _ in
            Haptics.selection()
            vm.load()
        }
    }

    private var totalCard: some View {
        GlassCard {
            VStack(spacing: 6) {
                Text("ВСЕГО ШАГОВ")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(1.5)
                    .foregroundStyle(.secondary)
                Text("\(Int(vm.total))")
                    .font(.system(size: 52, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: accent, startPoint: .leading, endPoint: .trailing)
                    )
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.6, dampingFraction: 0.85), value: vm.total)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var chartCard: some View {
        GlassCard {
            Group {
                if vm.isLoading {
                    ProgressView()
                        .tint(.white)
                        .frame(height: 240)
                        .frame(maxWidth: .infinity)
                } else if hasData {
                    Chart(vm.points) { point in
                        BarMark(
                            x: .value("Дата", point.date, unit: barUnit),
                            y: .value("Шаги", point.steps)
                        )
                        .foregroundStyle(
                            LinearGradient(colors: accent, startPoint: .top, endPoint: .bottom)
                        )
                        .cornerRadius(6)
                    }
                    .chartYAxis {
                        AxisMarks { _ in
                            AxisGridLine().foregroundStyle(Color.white.opacity(0.08))
                            AxisValueLabel().foregroundStyle(Color.white.opacity(0.5))
                        }
                    }
                    .chartXAxis {
                        AxisMarks { _ in
                            AxisValueLabel().foregroundStyle(Color.white.opacity(0.5))
                        }
                    }
                    .frame(height: 240)
                } else {
                    emptyState
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.walk.motion")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(Color(red: 0.58, green: 0.5, blue: 1.0))
            Text("Нет данных о шагах")
                .font(.system(size: 17, weight: .heavy))
                .foregroundStyle(.white)
            Text("Разрешите доступ к «Здоровью» в Настройках или подвигайтесь с телефоном, чтобы появились данные.")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                Haptics.soft()
                vm.load()
            } label: {
                Text("Обновить")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().stroke(.white.opacity(0.2), lineWidth: 1))
            }
            .buttonStyle(PressableStyle())
            .padding(.top, 4)
        }
        .frame(height: 240)
        .frame(maxWidth: .infinity)
    }

    private var metricsRow: some View {
        HStack(spacing: 14) {
            statTile("Максимум", vm.max, "flame.fill", Color(red: 1.0, green: 0.6, blue: 0.3))
            statTile("Среднее", vm.avg, "chart.bar.fill", Color(red: 0.4, green: 0.85, blue: 0.7))
        }
    }

    private func statTile(_ title: String, _ value: Double, _ icon: String, _ tint: Color) -> some View {
        GlassCard(padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(tint)
                    .frame(width: 34, height: 34)
                    .background(tint.opacity(0.16), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                Text("\(Int(value))")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
