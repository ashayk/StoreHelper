//
//  ProductView.swift
//  StoreHelper
//
//  Created by Russell Archer on 21/06/2021.
//
// View hierachy:
// Non-Consumables: [Products].[ProductListView].[ProductListViewRow]......[ProductView]......[if purchased].[PurchaseInfoView].....[PurchaseInfoSheet]
// Consumables:     [Products].[ProductListView].[ProductListViewRow]......[ConsumableView]...[if purchased].[PurchaseInfoView].....[PurchaseInfoSheet]
// Subscriptions:   [Products].[ProductListView].[SubscriptionListViewRow].[SubscriptionView].[if purchased].[SubscriptionInfoView].[SubscriptionInfoSheet]

import SwiftUI
import StoreKit
import WidgetKit

/// Displays a single row of product information for the main content List.
public struct ProductView: View {
    @EnvironmentObject var storeHelper: StoreHelper
    @State var purchaseState: PurchaseState = .unknown
    @Binding var productInfoProductId: ProductId
    #if os(iOS)
    @Binding var showRefundSheet: Bool
    @Binding var refundRequestTransactionId: UInt64
    #endif
    var productId: ProductId
    var displayName: String
    var description: String
    var price: String
    
    public var body: some View {
        VStack {
            Text(displayName).font(.largeTitle).padding(.bottom, 1)
            Text(description)
                #if os(iOS)
                .font(.subheadline)
                #endif
                .padding(EdgeInsets(top: 0, leading: 5, bottom: 3, trailing: 5))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .contentShape(Rectangle())
                .onTapGesture { productInfoProductId = productId }
            
            HStack {
                Image(productId)
                    .resizable()
                    .frame(maxWidth: 250, maxHeight: 250)
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(25)
                    .contentShape(Rectangle())
                    .onTapGesture { productInfoProductId = productId }
                
                Spacer()
                PurchaseButton(purchaseState: $purchaseState, productId: productId, price: price)
            }
            #if os(macOS)
            .frame(width: 500)
            #endif
            .padding()
            
            if purchaseState == .purchased {
                #if os(iOS)
                PurchaseInfoView(showRefundSheet: $showRefundSheet, refundRequestTransactionId: $refundRequestTransactionId, productId: productId)
                #elseif os(macOS)
                PurchaseInfoView(productId: productId)
                #endif
            }
            else {
                ProductInfoView(productInfoProductId: $productInfoProductId, productId: productId, displayName: displayName)
            }
            
            Divider()
        }
        .padding()
        .onAppear {
            Task.init { await purchaseState(for: productId) }
        }
        .onChange(of: storeHelper.purchasedProducts) { _ in
            Task.init {
                await purchaseState(for: productId)
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }
    
    func purchaseState(for productId: ProductId) async {
        let purchased = (try? await storeHelper.isPurchased(productId: productId)) ?? false
        purchaseState = purchased ? .purchased : .unknown
    }
}
