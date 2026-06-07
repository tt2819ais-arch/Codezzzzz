import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings

    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

    var body: some View {
        NavigationStack {
            Form {
                Section("Внешний вид") {
                    Picker("Тема", selection: $settings.appearance) {
                        ForEach(AppSettings.Appearance.allCases) { option in
                            Text(option.label).tag(option)
                        }
                    }
                }

                Section {
                    Stepper(value: $settings.pingCount, in: 3...20) {
                        HStack {
                            Text("Замеров задержки")
                            Spacer()
                            Text("\(settings.pingCount)")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                    Toggle("Тест скорости", isOn: $settings.runThroughput)
                    Toggle("Автозапуск при открытии", isOn: $settings.autoRunOnLaunch)
                } header: {
                    Text("Диагностика")
                } footer: {
                    Text("Больше замеров — точнее задержка и потери, но проверка идёт дольше. Тест скорости можно отключить, если нужен только пинг.")
                }

                Section {
                    Toggle("Виброотклик", isOn: $settings.hapticsEnabled)
                } header: {
                    Text("Отклик")
                }

                Section {
                    TextField("vpn-схема://connect", text: $settings.vpnScheme)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                } header: {
                    Text("Кнопка VPN")
                } footer: {
                    Text("URL-схема приложения VPN, которое откроется по кнопке «VPN» на экране диагностики.")
                }

                Section {
                    LabeledContent("Версия", value: appVersion)
                    LabeledContent("Замеры", value: "TCP RTT · медиана скорости")
                } header: {
                    Text("О приложении")
                } footer: {
                    Text("NetPulse измеряет качество соединения честными методами и хранит историю проверок локально на устройстве.")
                }
            }
            .navigationTitle("Настройки")
        }
    }
}
