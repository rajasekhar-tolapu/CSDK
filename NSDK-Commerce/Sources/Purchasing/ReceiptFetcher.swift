//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ReceiptFetcher.swift
//
//  Created by Javier de Martín Gil on 8/7/21.
//

import Foundation

class ReceiptFetcher {

    private let requestFetcher: StoreKitRequestFetcher
    private let receiptParser: PurchasesReceiptParser
    private let fileReader: FileReader

    private let lastReceiptRefreshRequest: Atomic<Date?> = nil

    let systemInfo: SystemInfo

    init(
        requestFetcher: StoreKitRequestFetcher,
        systemInfo: SystemInfo,
        receiptParser: PurchasesReceiptParser = .default,
        fileReader: FileReader = DefaultFileReader()
    ) {
        self.requestFetcher = requestFetcher
        self.systemInfo = systemInfo
        self.receiptParser = receiptParser
        self.fileReader = fileReader
    }

    func receiptData(refreshPolicy: ReceiptRefreshPolicy, completion: @escaping (Data?, URL?) -> Void) {
        let receiptURL = self.receiptURL

        switch refreshPolicy {
        case .always:
            if self.shouldThrottleRefreshRequest() {
                Logger.debug(Strings.receipt.throttling_force_refreshing_receipt)

                // If requested to refresh again within the throttle duration
                // Use `ReceiptRefreshPolicy.onlyIfEmpty` so receipt is not refreshed if it's already loaded.
                self.receiptData(refreshPolicy: .onlyIfEmpty, completion: completion)
            } else {
                Logger.debug(Strings.receipt.force_refreshing_receipt)
                self.refreshReceipt(completion)
            }

        case .onlyIfEmpty:
            let receiptData = self.receiptData()
            let isReceiptEmpty = receiptData?.isEmpty ?? true

            if isReceiptEmpty {
                Logger.debug(Strings.receipt.refreshing_empty_receipt)
                self.refreshReceipt(completion)
            } else {
                completion(receiptData, receiptURL)
            }

        case let .retryUntilProductIsFound(productIdentifier, maximumRetries, sleepDuration):
            Async.call(with: completion) {
                await self.refreshReceipt(untilProductIsFound: productIdentifier,
                                          maximumRetries: maximumRetries,
                                          sleepDuration: sleepDuration)
            }

        case .never:
            completion(self.receiptData(), receiptURL)
        }
    }

    func receiptData(refreshPolicy: ReceiptRefreshPolicy) async -> Data? {
        // Note: We're using UnsafeContinuation instead of Checked because
        // of a crash in iOS 18.0 devices when CheckedContinuations are used.
        // See: https://github.com/RevenueCat/purchases-ios/issues/4177
        return await withUnsafeContinuation { continuation in
            self.receiptData(refreshPolicy: refreshPolicy) { result, _ in
                continuation.resume(returning: result)
            }
        }
    }

    private func shouldThrottleRefreshRequest() -> Bool {
        guard let lastRefresh = self.lastReceiptRefreshRequest.value else {
            return false
        }

        let timeSinceLastRequest = DispatchTimeInterval(self.systemInfo.clock.now.timeIntervalSince(lastRefresh))
        return timeSinceLastRequest.nanoseconds < ReceiptRefreshPolicy.alwaysRefreshThrottleDuration.nanoseconds
    }

}

extension ReceiptFetcher {

    var receiptURL: URL? {
        guard var receiptURL = self.systemInfo.bundle.appStoreReceiptURL else {
            Logger.debug(Strings.receipt.no_sandbox_receipt_restore)
            return nil
        }

        #if os(watchOS)
        return self.watchOSReceiptURL(receiptURL)
        #else
        return receiptURL
        #endif
    }

}

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
extension ReceiptFetcher: @unchecked Sendable {}

//extension PurchasesReceiptParser {
//
//    /// A default instance of ``PurchasesReceiptParser``
//    @objc
//    public static let `default`: PurchasesReceiptParser = .init(logger: Logger())
//
//}

// MARK: -

private extension ReceiptFetcher {

    /// Returns non-empty `Data` for the receipt, or `nil` if it was empty or it couldn't be loaded.
    private func receiptData() -> Data? {
        guard let receiptURL = self.receiptURL else {
            return nil
        }

        do {
            let data = try self.fileReader.contents(of: receiptURL)
            guard !data.isEmpty else { throw Error.loadedEmptyReceipt }

            Logger.debug(Strings.receipt.loaded_receipt(url: receiptURL))
            return data
        } catch {
            Logger.appleWarning(Strings.receipt.unable_to_load_receipt(error))
            return nil
        }
    }

    func refreshReceipt(_ completion: @escaping (Data, URL?) -> Void) {
        self.lastReceiptRefreshRequest.value = self.systemInfo.clock.now

        self.requestFetcher.fetchReceiptData {
            completion(self.receiptData() ?? Data(), self.receiptURL)
        }
    }

    /// `async` version of `refreshReceipt(_:)`
    func refreshReceipt() async -> (Data, URL?) {
        // Note: We're using UnsafeContinuation instead of Checked because
        // of a crash in iOS 18.0 devices when CheckedContinuations are used.
        // See: https://github.com/RevenueCat/purchases-ios/issues/4177
        await withUnsafeContinuation { continuation in
            self.refreshReceipt {
                continuation.resume(returning: ($0, $1))
            }
        }
    }

    @MainActor
    private func refreshReceipt(
        untilProductIsFound productIdentifier: String,
        maximumRetries: Int,
        sleepDuration: DispatchTimeInterval
    ) async -> (Data, URL?) {
        return await Async.retry(maximumRetries: maximumRetries, pollInterval: sleepDuration) {
            let (data, receiptURL) = await self.refreshReceipt()
            if !data.isEmpty {
                do {
                    // Parse receipt in a background thread
                    let receipt = try await Task.detached { [currentData = data] in
                        try self.receiptParser.parse(from: currentData)
                    }.value

                    if receipt.containsActivePurchase(forProductIdentifier: productIdentifier) {
                        return (shouldRetry: false, (data, receiptURL))
                    } else {
                        Logger.appleWarning(Strings.receipt.local_receipt_missing_purchase(
                            receipt,
                            forProductIdentifier: productIdentifier
                        ))
                    }
                } catch {
                    Logger.error(Strings.receipt.parse_receipt_locally_error(error: error))
                }
            }

            Logger.debug(Strings.receipt.retrying_receipt_fetch_after(sleepDuration: sleepDuration.seconds))
            return (shouldRetry: true, (data, receiptURL))
        }
    }

}

// MARK: -

private extension ReceiptFetcher {

    private enum Error: Swift.Error, CustomNSError {

        case loadedEmptyReceipt

        var errorUserInfo: [String: Any] {
            switch self {
            case .loadedEmptyReceipt:
                return [ NSLocalizedDescriptionKey: "Receipt was empty" ]
            }
        }

    }

}
