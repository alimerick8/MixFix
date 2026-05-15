 //
//  PaywallView.swift
//  MixFix
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var isPurchasing = false
    var onClose: (() -> Void)?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("MixFix Plus")
                        .font(.system(.largeTitle, weight: .bold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Study better, stress less. Ad‑free, full wellness, unlimited habits.")
                        .foregroundStyle(.secondary)
                }
                .padding(.top)

                ZStack { MF.glassBackground()
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Ad‑free experience", systemImage: "star.fill")
                        Label("Full wellness library", systemImage: "heart.text.square")
                        Label("Unlimited habits & custom reminders", systemImage: "bell")
                        Label("Busy week alerts", systemImage: "exclamationmark.triangle")
                    }
                    .labelStyle(.titleAndIcon)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                }

                VStack(spacing: 12) {
                    if isPurchasing {
                        ProgressView("Processing...")
                            .padding()
                    } else {
                        ForEach(subscriptionManager.products, id: \.id) { product in
                            Button {
                                Task {
                                    await purchaseProduct(product)
                                }
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(product.displayName)
                                            .font(.headline)
                                        Text(product.description)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text(product.displayPrice)
                                        .font(.headline)
                                }
                                .padding()
                                .background(
                                    product.id == SubscriptionManager.ProductID.annualPlus ? 
                                    AnyShapeStyle(MF.gradient) : AnyShapeStyle(.thinMaterial),
                                    in: .rect(cornerRadius: MF.cornerRadius)
                                )
                                .foregroundStyle(
                                    product.id == SubscriptionManager.ProductID.annualPlus ? .white : .primary
                                )
                            }
                        }
                    }

                    Text("Cancel anytime. Transparent pricing. No hidden fees.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                    
                    Button("Restore Purchases") {
                        Task {
                            await subscriptionManager.restorePurchases()
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Button("Not now") { onClose?() }
                    .buttonStyle(.bordered)
                    .padding(.top)
            }
            .padding()
        }
        .background(MF.appBackground())
    }
    
    private func purchaseProduct(_ product: Product) async {
        isPurchasing = true
        defer { isPurchasing = false }
        
        do {
            if let transaction = try await subscriptionManager.purchase(product) {
                print("Purchase successful: \(transaction.productID)")
                onClose?()
            }
        } catch {
            print("Purchase failed: \(error)")
        }
    }
}

#Preview {
    PaywallView()
}
