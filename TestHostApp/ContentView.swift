//
//  ContentView.swift
//  TestHostApp
//
//  Created by Raj on 30/04/25.
//

import SwiftUI
import NSDK_Commerce

struct ContentView: View {
    var body: some View {
        VStack {
//            Image(systemName: "cart.fill")
//                .imageScale(.large)
//                .foregroundStyle(Color.black)
//                .font(.system(size: 60, weight: .light))
//                .padding(.bottom, 5.0)
//                
//                
//            Text("NSDK Commerce")
//                .font(.system(size: 22, weight: .bold))
//                .foregroundColor(.black)
//                .padding(.bottom, 40.0)
            
         //   SubscriptionView()
            UnlockFlowView()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
