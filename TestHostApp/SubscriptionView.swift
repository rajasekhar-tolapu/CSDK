//
//  SubscriptionView.swift
//  NSDK-Commerce
//
//  Created by Raj on 05/05/25.
//

import SwiftUI
import NSDK_Commerce
import StoreKit

struct SubscriptionView: View {
    @State private var offerings: Offerings?
    @State private var isPurchasing = false
    
    var body: some View {
        VStack {
            if let current = offerings?.current, let package = current.availablePackages.first {
                Text("Subscribe: \(package.storeProduct.localizedTitle)")
                Text("Price: \(package.storeProduct.localizedPriceString)")
                
                Button("Buy Now") {
                    Task {
                        await NSDKCommerceManager.shared.purchase(package: package)
                    }
                }
                .disabled(isPurchasing)
                
                Button("Logout") {
                    Task {
                        await NSDKCommerceManager.shared.logout()
                    }
                }
            } else {
                Text("Loading products...")
            }
        }
        .onAppear {
            
            // Native Fetch
            let productIds: Set<String> = ["Kiddopia.Subscription3DayTrial.Yearly"]
            Task {
                do {
                    let products = try await Product.products(for: productIds)
                    print("✅ Products fetched from App Store:", products)
                    for product in products {
                        print(product.displayName)
                    }
                } catch {
                    print("❌ Failed to fetch products:", error)
                }
            }
            
            // NSDK Commerce fetch
            fetchOfferings()
            
        }
    }
    
    private func fetchOfferings() {
        NSDKCommerce.shared.getOfferings { result, error in
            if let result = result {
                offerings = result
            } else {
                print("Failed to fetch offerings: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
//    private func purchase(package: Package) {
//        isPurchasing = true
//        NSDKCommerce.shared.purchase(package: package) { (transaction, customerInfo, error, userCancelled) in
//            isPurchasing = false
//            if let customerInfo = customerInfo, customerInfo.entitlements["your_entitlement_identifier"]?.isActive == true {
//                print("User has active subscription!")
//                print(customerInfo)
//                                
//                
//            } else if userCancelled {
//                print("User cancelled purchase.")
//            } else {
//                print("Purchase failed: \(error?.localizedDescription ?? "Unknown error")")
//            }
//        }
//    }
}
