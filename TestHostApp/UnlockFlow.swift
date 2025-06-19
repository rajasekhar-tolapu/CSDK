//
//  UnlockFlow.swift
//  NSDK-Commerce
//
//  Created by Raj on 17/06/25.
//

import SwiftUI
import StoreKit
import NSDK_Commerce

struct UnlockFlowView: View {
    @State private var offerings: Offerings?
    @State private var isPurchasing = false
    @State private var isLoading = false
    @State private var isPremiumUser = false
    @State private var isLoggedIn = false
    @State private var statusMessage = "Getting ready..."
    @State private var showingVideo = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Status Header
                VStack {
                    Text("Subscription Status")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(statusMessage)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    HStack {
                        Circle()
                            .fill(isPremiumUser ? Color.green : Color.red)
                            .frame(width: 12, height: 12)
                        Text(isPremiumUser ? "Premium Active" : "Free User")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Premium Content Section
                if isPremiumUser {
                    VStack {
                        Text("🎉 Premium Content Unlocked!")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        
                        Button(action: {
                            showingVideo = true
                        }) {
                            HStack {
                                Image(systemName: "play.circle.fill")
                                Text("Watch Premium Video")
                            }
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                }
                
                // Subscription Options
                if !isPremiumUser {
                    VStack {
                        if let current = offerings?.current, let package = current.availablePackages.first {
                            VStack(spacing: 12) {
                                Text("Unlock Premium Features")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                
                                Text(package.storeProduct.localizedTitle)
                                    .font(.headline)
                                
                                Text(package.storeProduct.localizedPriceString)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                                
                                Button(action: {
                                    purchasePackage(package)
                                }) {
                                    HStack {
                                        if isPurchasing {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                        }
                                        Text(isPurchasing ? "Processing..." : "Subscribe Now")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(isPurchasing ? Color.gray : Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                }
                                .disabled(isPurchasing)
                            }
                        } else {
                            Text("Loading subscription options...")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    if !isLoggedIn {
                        Button(action: loginUser) {
                            HStack {
                                Image(systemName: "person.circle")
                                Text("Login")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(isLoading)
                    }
                    
                    Button(action: restorePurchases) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Restore Purchases")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(isLoading)
                    
                    if isLoggedIn {
                        Button(action: logoutUser) {
                            HStack {
                                Image(systemName: "person.circle.fill")
                                Text("Logout")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(isLoading)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Premium Access")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            initializeApp()
        }
        .sheet(isPresented: $showingVideo) {
            VideoPlayerView()
        }
        .overlay(
            Group {
                if isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading...")
                            .padding(.top)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                }
            }
        )
    }
    
    // MARK: - Functions
    
    private func initializeApp() {
        isLoading = true
        statusMessage = "Initializing app..."
        
        Task {
            // Initialize the commerce manager
            NSDKCommerceManager.shared.initlize()
            
            // Small delay to let initialization complete
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            await fetchOfferings()
            await checkLoginStatus()
            
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }
    
    private func clearCache() {
        NSDKCommerce.shared.invalidateCustomerInfoCache()
    }
    
    private func loginUser() {
        clearCache()
        isLoading = true
        statusMessage = "Logging in..."
        
        Task {
            await NSDKCommerceManager.shared.fetchCustomerInfo()
            await NSDKCommerceManager.shared.login()
            await checkSubscriptionStatus()
            
            DispatchQueue.main.async {
                self.isLoggedIn = true
                self.isLoading = false
                self.statusMessage = "Login successful!"
            }
        }
    }
    
    private func logoutUser() {
        isLoading = true
        statusMessage = "Logging out..."
        
        Task {
            _ = await NSDKCommerceManager.shared.logout()
            
            DispatchQueue.main.async {
                self.isLoggedIn = false
                self.isPremiumUser = false
                self.isLoading = false
                self.statusMessage = "Logged out successfully"
            }
        }
    }
    
    private func purchasePackage(_ package: Package) {
        isPurchasing = true
        statusMessage = "Processing purchase..."
        
        Task {
            await NSDKCommerceManager.shared.purchase(package: package)
            await checkSubscriptionStatus()
            
            DispatchQueue.main.async {
                self.isPurchasing = false
            }
        }
    }
    
    private func restorePurchases() {
        isLoading = true
        statusMessage = "Restoring purchases..."
        
        Task {
            await NSDKCommerceManager.shared.restorePurchases()
            await checkSubscriptionStatus()
            
            DispatchQueue.main.async {
                self.isLoading = false
                self.statusMessage = "Restore completed"
            }
        }
    }
    
    private func checkLoginStatus() async {
        // Check if user was previously logged in
        let hasStoredID = UserDefaults.standard.string(forKey: "revenuecat_user_id") != nil
        
        DispatchQueue.main.async {
            self.isLoggedIn = hasStoredID
            if hasStoredID {
                self.statusMessage = "Welcome back!"
                Task {
                    await self.checkSubscriptionStatus()
                }
            } else {
                self.statusMessage = "Please login to continue"
            }
        }
    }
    
    private func checkSubscriptionStatus() async {
        await NSDKCommerceManager.shared.checkSubscriptionStatus()
        
        // Fetch customer info to check premium status
        do {
            // This is a simplified check - you might want to add this method to your manager
            await NSDKCommerceManager.shared.fetchCustomerInfo()
            
            // You'll need to modify your manager to expose the premium status
            // For now, we'll simulate checking
            DispatchQueue.main.async {
                // This should be replaced with actual premium status check
                // self.isPremiumUser = NSDKCommerceManager.shared.isPremium
                self.updateUIBasedOnPremiumStatus()
            }
        }
    }
    
    private func updateUIBasedOnPremiumStatus() {
        // This method should be called after checking subscription status
        // You'll need to modify NSDKCommerceManager to expose premium status
        if isPremiumUser {
            statusMessage = "Premium subscription active!"
        } else {
            statusMessage = "Subscribe to unlock premium features"
        }
    }
    
    @MainActor
    private func fetchOfferings() async {
        // Native StoreKit fetch
//        let productIds: Set<String> = ["Kiddopia.Subscription3DayTrial.Yearly"]
//        do {
//            let products = try await Product.products(for: productIds)
//            print("✅ Products fetched from App Store:", products)
//            for product in products {
//                print(product.displayName)
//            }
//        } catch {
//            print("❌ Failed to fetch products:", error)
//        }
        
        // NSDK Commerce fetch
        await withCheckedContinuation { continuation in
            NSDKCommerce.shared.getOfferings { result, error in
                DispatchQueue.main.async {
                    if let result = result {
                        self.offerings = result
                        self.statusMessage = "Ready to subscribe!"
                    } else {
                        print("Failed to fetch offerings: \(error?.localizedDescription ?? "Unknown error")")
                        self.statusMessage = "Failed to load subscription options"
                    }
                    continuation.resume()
                }
            }
        }
    }
}

// MARK: - Video Player View
struct VideoPlayerView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                // Placeholder for video player
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black)
                    .overlay(
                        VStack {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.white)
                            Text("Premium Video Content")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(.top)
                        }
                    )
                    .aspectRatio(16/9, contentMode: .fit)
                
                Text("🎉 This is your exclusive premium content!")
                    .font(.headline)
                    .padding()
                
                Spacer()
            }
            .padding()
            .navigationTitle("Premium Video")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}
