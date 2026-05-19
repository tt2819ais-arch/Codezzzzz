import SwiftUI
import Charts

struct HealthStatsView: View {
    @StateObject private var vm = HealthViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Picker("Period", selection: $vm.selectedRange) {
                    Text("Day").tag(HealthRange.day)
                    Text("Week").tag(HealthRange.week)
                    Text("Month").tag(HealthRange.month)
                    Text("All").tag(HealthRange.all)
                }
                .pickerStyle(.segmented)
                .onChange(of: vm.selectedRange) { _ in vm.load() }

                if vm.isLoading {
                    ProgressView()
                }

                Chart(vm.points) { p in
                    BarMark(x: .value("Date", p.date), y: .value("Steps", p.steps))
                        .foregroundStyle(.blue.gradient)
                }
                .frame(height: 260)

                HStack {
                    metric("Max", vm.max)
                    Spacer()
                    metric("Avg", vm.avg)
                    Spacer()
                    metric("Total", vm.total)
                }
            }
            .padding()
            .navigationTitle("Статистика")
            .onAppear { vm.load() }
        }
    }

    private func metric(_ title: String, _ value: Double) -> some View {
        VStack {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text("\(Int(value))").font(.headline)
        }
    }
}
