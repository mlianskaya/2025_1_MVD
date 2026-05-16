import SwiftUI

struct PiggyModalView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject private var economy: EconomyStore
    @State private var selectedOutfitId: String
    @State private var showAlert = false

    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
        self._selectedOutfitId = State(initialValue: "piggy_cool")
    }

    var body: some View {
        VStack(spacing: 0) {
            topEconomyBar

            VStack(spacing: 0) {
                Image(selectedOutfit?.imageName ?? "piggy_cool")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 180)
                    .padding(.top, 6)
                    .padding(.bottom, 0)

                Text("Выберите наряд")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .padding(.top, 0)
                    .padding(.bottom, 4)

                outfitGrid
                    .padding(.top, 2)
                    .padding(.bottom, 4)

                Spacer(minLength: 4)

                bottomAction
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                    .padding(.horizontal, 24)
            }
        }
        // Было .background(Color.white)
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onAppear {
            selectedOutfitId = economy.selectedOutfitId
        }
        .alert("Недостаточно средств", isPresented: $showAlert) {
            Button("OK", role: .cancel) {
                showAlert = false
            }
        } message: {
            Text("У вас недостаточно средств для покупки этого наряда.")
        }
    }

    private var selectedOutfit: Outfit? {
        economy.catalog.first(where: { $0.id == selectedOutfitId })
    }

    private var topEconomyBar: some View {
        HStack(spacing: 18) {
            counterChip(systemName: "dollarsign.circle.fill", value: economy.coins)
            counterChip(systemName: "trophy.fill", value: economy.trophies)

            Spacer()

            Button {
                Task {
                    let _ = await economy.collectDailyGift()
                }
            } label: {
                Image(systemName: "gift.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .bold))
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(UIColor.systemFill))
                    )
            }
            .disabled(!economy.isGiftAvailableToday)
            .buttonStyle(.plain)
            .accessibilityLabel("Ежедневный подарок")

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
            .padding(.leading, 2)
        }
        .padding(.horizontal, 26)
        .padding(.vertical, 8)
        .background(
            Color(red: 102/255, green: 190/255, blue: 0)
                .ignoresSafeArea(edges: .horizontal)
        )
    }

    private func counterChip(systemName: String, value: Int) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemName)
                .foregroundColor(.white)

            Text("\(value)")
                .foregroundColor(.white)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(UIColor.systemFill))
        .clipShape(Capsule())
    }

    private var outfitGrid: some View {
        let outfits = economy.catalog
        let columns = [GridItem(.flexible()), GridItem(.flexible())]

        return LazyVGrid(columns: columns, alignment: .center, spacing: 26) {
            ForEach(outfits) { outfit in
                OutfitCard(
                    outfit: outfit,
                    isSelected: selectedOutfitId == outfit.id,
                    isOwned: economy.ownedOutfitIds.contains(outfit.id),
                    action: {
                        selectedOutfitId = outfit.id
                    }
                )
            }
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
        .padding(.top, 6)
        .padding(.bottom, 10)
    }

    private var bottomAction: AnyView {
        let isOwned = economy.ownedOutfitIds.contains(selectedOutfitId)
        let isActive = selectedOutfitId != economy.selectedOutfitId && isOwned
        let canBuy = selectedOutfit.map { economy.canBuy($0) } ?? false
        let currentOutfit = selectedOutfit

        if isOwned {
            return AnyView(
                Button {
                    guard isActive, let outfit = currentOutfit else { return }

                    Task {
                        await economy.select(outfit)
                        isPresented = false
                    }
                } label: {
                    ZStack(alignment: .top) {
                        if isActive {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(red: 78/255, green: 146/255, blue: 0))
                                .frame(height: 54)
                                .offset(y: 5)
                        }

                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                isActive
                                ? Color(red: 102/255, green: 190/255, blue: 0)
                                : Color.gray.opacity(0.2)
                            )
                            .frame(height: 54)
                            .overlay(
                                Text(isActive ? "Выбрать" : "Получено")
                                    .foregroundColor(isActive ? .white : .gray)
                                    .bold()
                                    .font(.system(size: 18))
                            )
                    }
                }
                .disabled(!isActive)
            )
        } else if let outfit = currentOutfit {
            return AnyView(
                Button {
                    if !canBuy {
                        showAlert = true
                        return
                    }

                    Task {
                        if await economy.buy(outfit) {
                            selectedOutfitId = outfit.id
                        } else {
                            showAlert = true
                        }
                    }
                } label: {
                    ZStack(alignment: .top) {
                        if canBuy {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(red: 78/255, green: 146/255, blue: 0))
                                .frame(height: 54)
                                .offset(y: 5)
                                .opacity(0.3)
                        }

                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                canBuy
                                ? Color(red: 102/255, green: 190/255, blue: 0)
                                : Color.blue.opacity(0.13)
                            )
                            .frame(height: 54)
                            .overlay(
                                priceTag(price: outfit.price, isActive: canBuy)
                                    .font(.system(size: 18, weight: .semibold))
                            )
                    }
                }
            )
        } else {
            return AnyView(EmptyView())
        }
    }

    private func priceTag(price: Outfit.Price, isActive: Bool = false) -> some View {
        HStack(spacing: 4) {
            switch price {
            case .coins(let amount):
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(isActive ? .white : .blue)
                Text("\(amount)")
                    .foregroundColor(isActive ? .white : .blue)

            case .trophies(let amount):
                Image(systemName: "trophy.fill")
                    .foregroundColor(isActive ? .white : .blue)
                Text("\(amount)")
                    .foregroundColor(isActive ? .white : .blue)

            case .free:
                Text("Бесплатно")
                    .foregroundColor(isActive ? .white : .green)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 10)
    }

    private struct OutfitCard: View {
        let outfit: Outfit
        let isSelected: Bool
        let isOwned: Bool
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        // Было Color.white
                        .fill(Color(UIColor.systemBackground))
                        .shadow(
                            color: isSelected ? Color.green.opacity(0.09) : .clear,
                            radius: 6,
                            x: 0,
                            y: 2
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(
                                    isSelected ? Color.green : Color(UIColor.separator),
                                    lineWidth: isSelected ? 3 : 1
                                )
                        )

                    Image(outfit.imageName)
                        .resizable()
                        .scaledToFit()
                        .padding(20)
                }
                .frame(height: 180)
                .frame(maxWidth: .infinity)
                .overlay(
                    VStack {
                        Spacer()
                        if isOwned && isSelected {
                            statusBadge
                        } else if !isOwned {
                            priceTag
                        }
                    }
                    .padding(.bottom, 12)
                )
            }
            .buttonStyle(.plain)
        }

        private var priceTag: some View {
            HStack(spacing: 4) {
                switch outfit.price {
                case .coins(let amount):
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundColor(.blue)
                    Text("\(amount)")
                        .foregroundColor(.blue)

                case .trophies(let amount):
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.blue)
                    Text("\(amount)")
                        .foregroundColor(.blue)

                case .free:
                    Text("Бесплатно")
                        .foregroundColor(.green)
                }
            }
            .font(.system(size: 14, weight: .semibold))
            .padding(.vertical, 4)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.12))
            )
        }

        private var statusBadge: some View {
            Label("Получено", systemImage: "checkmark.seal.fill")
                .labelStyle(.titleAndIcon)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
                .padding(.vertical, 4)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(red: 102/255, green: 190/255, blue: 0))
                )
        }
    }
}

struct PiggyModalView_Previews: PreviewProvider {
    static var previews: some View {
        PiggyModalView(isPresented: .constant(true))
            .environmentObject(EconomyStore())
            .previewLayout(.sizeThatFits)
    }
}
