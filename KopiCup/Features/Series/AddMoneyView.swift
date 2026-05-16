import SwiftUI

struct AddMoneyView: View {
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: SeriesViewModel
    @State private var amountText = ""

    @AppStorage("settings.currency.code") private var currencyCode: String = "RUB"

    private let quickRow1: [Int] = [100, 300, 500, 800]
    private let quickSingle: Int = 1000

    var body: some View {
        VStack(spacing: 0) {
            header
            content
        }
        .background(Color(UIColor.systemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var header: some View {
        ZStack {
            Color(red: 102/255, green: 190/255, blue: 0)
                .ignoresSafeArea(edges: .top)

            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color(UIColor.systemFill))
                        .frame(width: 60, height: 60)
                    Image(systemName: "handbag.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 24, weight: .bold))
                }

                Text("Пополнить копилку")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                let current = viewModel.goal?.currentAmount ?? 0
                let target = viewModel.goal?.targetAmount ?? 0
                Text("Накоплено: \(viewModel.formatWithCurrentCurrency(current)) из \(viewModel.formatWithCurrentCurrency(target))")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.bottom, 12)
            }
            .padding(.horizontal, 16)
            .padding(.top, 40)
            .onAppear {
                if viewModel.selectedDayIndex == nil {
                    viewModel.selectedDayIndex = viewModel.currentDayIndex
                }
            }
            .onDisappear {
                viewModel.selectedDayIndex = nil
            }
        }
        .overlay(
            Button {
                isPresented = false
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color(UIColor.systemFill))
                    .clipShape(Circle())
            }
            .padding(.top, 14)
            .padding(.trailing, 14),
            alignment: .topTrailing
        )
        .frame(height: 200)
    }

    private var content: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                amountField

                quickButtonsRow

                quickSingleButton

                closeGoalButton

                addButton
            }
            .padding(16)
        }
    }

    private var amountField: some View {
        TextField("", text: $amountText)
            .keyboardType(.numberPad)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
            )
            .overlay(
                HStack {
                    Text(placeholderText)
                        .foregroundColor(Color(UIColor.placeholderText))
                        .padding(.leading, 16)
                        .opacity(amountText.isEmpty ? 1 : 0)
                    Spacer()
                }
            )
            .onChange(of: amountText) { newValue in
                let filtered = newValue.filter { $0.isNumber }
                if filtered != newValue {
                    amountText = filtered
                }
            }
    }

    private var placeholderText: String {
        let symbol = currencySymbol(for: currencyCode) ?? currencyCode
        return "Введите сумму \(symbol)"
    }

    private var quickButtonsRow: some View {
        HStack(spacing: 10) {
            ForEach(quickRow1, id: \.self) { amount in
                Button(action: { applyQuickAmount(amount) }) {
                    Text("+\(amount) \(currencySymbol(for: currencyCode) ?? "₽")")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(UIColor.systemBackground))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(UIColor.separator), lineWidth: 1)
                                )
                                .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var quickSingleButton: some View {
        Button(action: { applyQuickAmount(quickSingle) }) {
            Text("+\(quickSingle) \(currencySymbol(for: currencyCode) ?? "₽")")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(UIColor.separator), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private var closeGoalButton: some View {
        Group {
            if viewModel.goal != nil {
                Button(action: {
                    viewModel.closeFullGoal()
                    isPresented = false
                }) {
                    Text("Закрыть цель (\(viewModel.remainingToGoalText))")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(viewModel.canCloseFullGoal ? Color.blue : Color.blue.opacity(0.4))
                        .cornerRadius(12)
                        .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .disabled(!viewModel.canCloseFullGoal)
            } else {
                Button(action: {
                    viewModel.completeGoal()
                    isPresented = false
                }) {
                    Text("Закрыть цель (\(viewModel.remainingAmountText))")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(viewModel.canCloseGoal ? Color.blue : Color.blue.opacity(0.4))
                        .cornerRadius(12)
                        .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .disabled(!viewModel.canCloseGoal)
            }
        }
    }

    private var addButton: some View {
        let canAdd = enteredAmountRubles > 0

        return Button(action: {
            guard enteredAmountRubles > 0 else { return }
            
            let minorUnits = enteredAmountRubles * 100
            viewModel.addMoney(minorUnits)
            
            isPresented = false
        }) {
            ZStack(alignment: .top) {
                if canAdd {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(red: 78/255, green: 146/255, blue: 0))
                        .frame(height: 48)
                        .offset(y: 5)
                }

                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        canAdd
                        ? Color(red: 102/255, green: 190/255, blue: 0)
                        : Color(red: 102/255, green: 190/255, blue: 0).opacity(0.5)
                    )
                    .frame(height: 48)
                    .overlay(
                        Text("Добавить")
                            .foregroundColor(.white)
                            .bold()
                    )
            }
        }
        .disabled(!canAdd)
    }

    private var enteredAmountRubles: Int {
        Int(amountText) ?? 0
    }

    private func applyQuickAmount(_ amount: Int) {
        amountText = String(amount)
    }

    private func currencySymbol(for code: String) -> String? {
        let locale = Locale.availableIdentifiers
            .map(Locale.init(identifier:))
            .first { $0.currencyCode == code }
        return locale?.currencySymbol
    }
}
