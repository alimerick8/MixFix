//
//  SubscriptionManager.swift
//  MixFix
//
//  StoreKit 2 subscription management
//

import Foundation
import StoreKit
import Combine

@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    @Published var isPlusSubscriber = false
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    
    // Product IDs - configure these in App Store Connect
    enum ProductID {
        static let monthlyPlus = "com.mixfix.plus.monthly"
        static let annualPlus = "com.mixfix.plus.annual"
        static let foundingMember = "com.mixfix.founding.lifetime"
    }
    
    private var updateListenerTask: Task<Void, Error>?
    
    init() {
        updateListenerTask = listenForTransactions()
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Load Products
    func loadProducts() async {
        do {
            let productIDs = [
                ProductID.monthlyPlus,
                ProductID.annualPlus,
                ProductID.foundingMember
            ]
            products = try await Product.products(for: productIDs)
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    // MARK: - Purchase
    func purchase(_ product: Product) async throws -> Transaction? {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updatePurchasedProducts()
            await transaction.finish()
            return transaction
        case .userCancelled, .pending:
            return nil
        @unknown default:
            return nil
        }
    }
    
    // MARK: - Restore Purchases
    func restorePurchases() async {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.revocationDate == nil {
                purchasedProductIDs.insert(transaction.productID)
            }
        }
        updateSubscriptionStatus()
    }
    
    // MARK: - Check Subscription Status
    func updatePurchasedProducts() async {
        purchasedProductIDs.removeAll()
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.revocationDate == nil {
                purchasedProductIDs.insert(transaction.productID)
            }
        }
        updateSubscriptionStatus()
    }
    
    private func updateSubscriptionStatus() {
        isPlusSubscriber = purchasedProductIDs.contains(ProductID.monthlyPlus) ||
                          purchasedProductIDs.contains(ProductID.annualPlus) ||
                          purchasedProductIDs.contains(ProductID.foundingMember)
    }
    
    // MARK: - Transaction Listener
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else { continue }
                await self.updatePurchasedProducts()
                await transaction.finish()
            }
        }
    }
    
    // MARK: - Verification
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}

enum StoreError: Error {
    case failedVerification
}
