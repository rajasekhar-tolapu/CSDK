//
//  NSDKCommerceManager.swift
//  NSDK-Commerce
//
//  Created by Raj on 05/05/25.
//

import NSDK_Commerce
import StoreKit

final class NSDKCommerceManager {
    
    static let shared = NSDKCommerceManager()
    
    private init() {}
    
    
    func initlize() {
        NSDKCommerce.configure(withAPIKey: "")
        NSDKCommerce.logLevel = .debug

        Task {
            await self.fetchCustomerInfo()
            await self.login()
            
        }
    }
    
    func clearCache() {
    
        NSDKCommerce.shared.invalidateCustomerInfoCache()
    }
        
    func fetchCustomerInfo() async {
        
        self.clearCache()
        do {
            let customerInfo = try await NSDKCommerce.shared.customerInfo()
            printCustomerInfo(type: "fetchCustomerInfo", customerInfo: customerInfo)
            // Check if any entitlements or non-subscription transactions exist
            let hasTransaction = !customerInfo.entitlements.all.isEmpty || !customerInfo.nonSubscriptions.isEmpty
            
            if hasTransaction {
                print("✅ Found transactions. Syncing purchases...")
                let customerInfo = try await Purchases.shared.syncPurchases()
                printCustomerInfo(type: "syncPurchases", customerInfo: customerInfo)
            } else {
                print("ℹ️ No transactions found. Skipping sync.")
            }
            // ✅ Check entitlement status
            if customerInfo.entitlements["premium"]?.isActive == true {
                print("🚀 User has active premium access!")
            } else {
                print("🛑 User does not have premium access.")
            }
            
            print("👤 Customer Info:", customerInfo)
            
        } catch {
            print("❌ Error fetching customer info:", error)
        }
    }

    func login() async {
        // Step 1: Get existing ID or create and store a new one
        clearCache()
//        let appUserID: String
//        if let storedID = UserDefaults.standard.string(forKey: "revenuecat_user_id") {
//            appUserID = storedID
//        } else {
        let random = Int.random(in: 1000...1000000)
        let appUserID = "test_users_18June\(random)"
//        UserDefaults.standard.set(newID, forKey: "revenuecat_user_id")
//        appUserID = newID
//        }
        
        do {
            let (customerInfo, created) = try await NSDKCommerce.shared.logIn(appUserID)
            printCustomerInfo(type: "login", customerInfo: customerInfo)

            if created {
                print("🆕 New user created in RevenueCat with ID: \(appUserID)")
            } else {
                print("✅ Existing user logged in with ID: \(appUserID)")
            }
            
            if customerInfo.entitlements["premium"]?.isActive == true {
                print("🎉 User has active premium access")
            } else {
                print("🔒 No premium access")
            }
            
        } catch {
            print("❌ Login failed with error: \(error)")
        }
    }
    
    func setUserAttributes(_ attributes: [String: String]) {
        NSDKCommerce.shared.attribution.setAttributes(attributes)
    }
    
    func logout() async -> CustomerInfo? {
        clearCache()
        do {
            print("✅ User logged out")
            UserDefaults.standard.removeObject(forKey: "revenuecat_user_id")
            return try await NSDKCommerce.shared.logOut()
        } catch {
            NSDKCommerce.shared.invalidateCustomerInfoCache()
            UserDefaults.standard.removeObject(forKey: "revenuecat_user_id")
            print("❌ Logout failed with error: \(error)")
            return nil
        }
    }
    
    func printCustomerInfo(type: String, customerInfo: CustomerInfo) {
        print("🤷🏻‍♂️ CustomerInfo \(type): \(String(describing: try? JSONSerialization.jsonObject(with: JSONEncoder().encode(customerInfo))))")
    }
    
    
    func purchase(package: Package) async {
        do {
            let (transaction, customerInfo, userCancelled) = try await NSDKCommerce.shared.purchase(package: package)
            print(" ✅ Customer Info (Purchased) \(customerInfo)")
            if userCancelled {
                print("User cancelled the purchase.")
            } else if customerInfo.entitlements["premium"]?.isActive == true { // Need to check premium
                print("Purchase successful. User now has premium access.")
            }
            
            printCustomerInfo(type: "purchase", customerInfo: customerInfo)
            
            
        } catch {
            print("Purchase failed: \(error)")
        }
    }
    
    func fetchAvailablePackages() async -> [Package]? {
        do {
            let offerings = try await NSDKCommerce.shared.offerings()
            return offerings.current?.availablePackages
        } catch {
            print("Failed to fetch offerings: \(error)")
            return nil
        }
    }

    
    func restorePurchases() async {
        do {
            let customerInfo = try await NSDKCommerce.shared.restorePurchases()
            printCustomerInfo(type: "restorePurchases", customerInfo: customerInfo)
            if customerInfo.entitlements["premium"]?.isActive == true {
                print("Restored: User has premium access.")
            } else {
                print("Restored: No premium access found.")
            }
        } catch {
            print("Restore failed: \(error)")
        }
    }
    
    func checkSubscriptionStatus() async {
        do {
            let customerInfo = try await NSDKCommerce.shared.customerInfo()
            printCustomerInfo(type: "checkSubscriptionStatus", customerInfo: customerInfo)
            let isPremium = customerInfo.entitlements["premium"]?.isActive == true
            print("User is \(isPremium ? "" : "not ")a premium subscriber.")
        } catch {
            print("Failed to check subscription: \(error)")
        }
    }
    
    
}
