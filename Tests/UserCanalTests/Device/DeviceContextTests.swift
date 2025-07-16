// DeviceContextTests.swift
// UserCanal Swift SDK Tests
//
// Copyright © 2024 UserCanal. All rights reserved.
//

import XCTest
@testable import UserCanal

final class DeviceContextTests: XCTestCase {
    
    // MARK: - Test Properties
    
    private var deviceContext: DeviceContext!
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        deviceContext = DeviceContext()
    }
    
    override func tearDown() async throws {
        deviceContext = nil
        try await super.tearDown()
    }
    
    // MARK: - Device Context Collection Tests
    
    func testDeviceContextCollection() async {
        let context = await deviceContext.getContext()
        
        // Verify basic context is collected
        XCTAssertNotNil(context)
        XCTAssertFalse(context.isEmpty)
        
        // Verify common fields are present
        XCTAssertNotNil(context["device_model"])
        XCTAssertNotNil(context["os_name"])
        XCTAssertNotNil(context["os_version"])
        XCTAssertNotNil(context["app_version"])
        XCTAssertNotNil(context["sdk_version"])
        XCTAssertNotNil(context["device_id"])
        XCTAssertNotNil(context["locale"])
        XCTAssertNotNil(context["timezone"])
    }
    
    func testDeviceContextCaching() async {
        // First call should collect context
        let context1 = await deviceContext.getContext()
        
        // Second call within cache interval should return same data
        let context2 = await deviceContext.getContext()
        
        // Should be the same cached data
        XCTAssertEqual(context1.count, context2.count)
        
        // Device ID should be consistent
        XCTAssertEqual(
            context1["device_id"] as? String,
            context2["device_id"] as? String
        )
    }
    
    func testDeviceModelDetection() async {
        let context = await deviceContext.getContext()
        
        guard let deviceModel = context["device_model"] as? String else {
            XCTFail("Device model should be present")
            return
        }
        
        XCTAssertFalse(deviceModel.isEmpty)
        
        #if os(iOS)
        // iOS device models should contain "iPhone", "iPad", or simulator info
        XCTAssertTrue(
            deviceModel.contains("iPhone") || 
            deviceModel.contains("iPad") || 
            deviceModel.contains("Simulator")
        )
        #elseif os(macOS)
        // macOS device models should contain "Mac"
        XCTAssertTrue(deviceModel.contains("Mac"))
        #endif
    }
    
    func testOperatingSystemInfo() async {
        let context = await deviceContext.getContext()
        
        guard let osName = context["os_name"] as? String,
              let osVersion = context["os_version"] as? String else {
            XCTFail("OS info should be present")
            return
        }
        
        XCTAssertFalse(osName.isEmpty)
        XCTAssertFalse(osVersion.isEmpty)
        
        #if os(iOS)
        XCTAssertEqual(osName, "iOS")
        #elseif os(macOS)
        XCTAssertEqual(osName, "macOS")
        #elseif os(visionOS)
        XCTAssertEqual(osName, "visionOS")
        #endif
        
        // Version should be in format like "17.0" or "14.1.2"
        XCTAssertTrue(osVersion.contains("."))
    }
    
    func testAppVersionInfo() async {
        let context = await deviceContext.getContext()
        
        guard let appVersion = context["app_version"] as? String else {
            XCTFail("App version should be present")
            return
        }
        
        XCTAssertFalse(appVersion.isEmpty)
        // Should have some version format (could be "1.0" or build number)
        XCTAssertTrue(appVersion.count > 0)
    }
    
    func testSDKVersionInfo() async {
        let context = await deviceContext.getContext()
        
        guard let sdkVersion = context["sdk_version"] as? String else {
            XCTFail("SDK version should be present")
            return
        }
        
        XCTAssertFalse(sdkVersion.isEmpty)
        XCTAssertTrue(sdkVersion.contains("."))
    }
    
    func testDeviceIDGeneration() async {
        let context = await deviceContext.getContext()
        
        guard let deviceID = context["device_id"] as? String else {
            XCTFail("Device ID should be present")
            return
        }
        
        XCTAssertFalse(deviceID.isEmpty)
        // Device ID should be UUID format or vendor identifier
        XCTAssertTrue(deviceID.count > 10)
    }
    
    func testLocaleInfo() async {
        let context = await deviceContext.getContext()
        
        guard let locale = context["locale"] as? String else {
            XCTFail("Locale should be present")
            return
        }
        
        XCTAssertFalse(locale.isEmpty)
        // Locale should be in format like "en_US" or "en-US"
        XCTAssertTrue(locale.contains("_") || locale.contains("-"))
    }
    
    func testTimezoneInfo() async {
        let context = await deviceContext.getContext()
        
        guard let timezone = context["timezone"] as? String else {
            XCTFail("Timezone should be present")
            return
        }
        
        XCTAssertFalse(timezone.isEmpty)
        // Timezone should be like "America/New_York" or offset like "+0000"
        XCTAssertTrue(timezone.count > 3)
    }
    
    #if os(iOS)
    func testScreenInfo() async {
        let context = await deviceContext.getContext()
        
        // Screen info should be present on iOS
        XCTAssertNotNil(context["screen_width"])
        XCTAssertNotNil(context["screen_height"])
        XCTAssertNotNil(context["screen_scale"])
        
        if let width = context["screen_width"] as? Double,
           let height = context["screen_height"] as? Double,
           let scale = context["screen_scale"] as? Double {
            
            XCTAssertGreaterThan(width, 0)
            XCTAssertGreaterThan(height, 0)
            XCTAssertGreaterThan(scale, 0)
        }
    }
    #endif
    
    #if os(iOS)
    func testDeviceOrientation() async {
        let context = await deviceContext.getContext()
        
        // Orientation might be present
        if let orientation = context["device_orientation"] as? String {
            XCTAssertTrue([
                "portrait", "landscape", "portrait_upside_down", 
                "landscape_left", "landscape_right", "unknown"
            ].contains(orientation))
        }
    }
    #endif
    
    func testNetworkInfo() async {
        let context = await deviceContext.getContext()
        
        // Network info might be present depending on permissions
        if let networkType = context["network_type"] as? String {
            XCTAssertTrue([
                "wifi", "cellular", "ethernet", "none", "unknown"
            ].contains(networkType))
        }
    }
    
    func testBatteryInfo() async {
        let context = await deviceContext.getContext()
        
        #if os(iOS)
        // Battery info should be available on iOS
        if let batteryLevel = context["battery_level"] as? Double {
            XCTAssertGreaterThanOrEqual(batteryLevel, 0.0)
            XCTAssertLessThanOrEqual(batteryLevel, 1.0)
        }
        
        if let batteryState = context["battery_state"] as? String {
            XCTAssertTrue([
                "unknown", "unplugged", "charging", "full"
            ].contains(batteryState))
        }
        #endif
    }
    
    func testMemoryInfo() async {
        let context = await deviceContext.getContext()
        
        // Memory info might be present
        if let totalMemory = context["total_memory"] as? Int {
            XCTAssertGreaterThan(totalMemory, 0)
        }
        
        if let availableMemory = context["available_memory"] as? Int {
            XCTAssertGreaterThan(availableMemory, 0)
        }
    }
    
    func testStorageInfo() async {
        let context = await deviceContext.getContext()
        
        // Storage info might be present
        if let totalStorage = context["total_storage"] as? Int {
            XCTAssertGreaterThan(totalStorage, 0)
        }
        
        if let availableStorage = context["available_storage"] as? Int {
            XCTAssertGreaterThan(availableStorage, 0)
        }
    }
    
    // MARK: - Context Serialization Tests
    
    func testContextSerialization() async {
        let context = await deviceContext.getContext()
        
        // Context should be serializable to JSON
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: context)
            XCTAssertGreaterThan(jsonData.count, 0)
            
            // Should be deserializable back
            let deserializedContext = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
            XCTAssertNotNil(deserializedContext)
            XCTAssertEqual(context.count, deserializedContext?.count)
            
        } catch {
            XCTFail("Context should be JSON serializable: \(error)")
        }
    }
    
    // MARK: - Performance Tests
    
    func testContextCollectionPerformance() {
        measure {
            let expectation = expectation(description: "Context collection")
            
            Task {
                _ = await deviceContext.getContext()
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 1.0)
        }
    }
    
    func testConcurrentContextAccess() async {
        // Test that concurrent access to device context is safe
        await withTaskGroup(of: [String: Any].self) { group in
            for _ in 0..<10 {
                group.addTask {
                    return await self.deviceContext.getContext()
                }
            }
            
            var results: [[String: Any]] = []
            for await result in group {
                results.append(result)
            }
            
            // All results should have same device ID
            let deviceIDs = results.compactMap { $0["device_id"] as? String }
            XCTAssertEqual(Set(deviceIDs).count, 1, "Device ID should be consistent")
        }
    }
    
    // MARK: - Privacy Tests
    
    func testPrivacyCompliance() async {
        let context = await deviceContext.getContext()
        
        // Should not contain sensitive personal information
        let sensitiveKeys = [
            "contacts", "photos", "location", "calendar", 
            "personal_info", "private_data", "user_files"
        ]
        
        for key in sensitiveKeys {
            XCTAssertNil(context[key], "Should not contain sensitive key: \(key)")
        }
        
        // Device ID should be anonymous/pseudonymous
        if let deviceID = context["device_id"] as? String {
            // Should not be obviously personal (no email, phone, etc.)
            XCTAssertFalse(deviceID.contains("@"))
            XCTAssertFalse(deviceID.contains("phone"))
            XCTAssertFalse(deviceID.contains("email"))
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testContextCollectionErrorHandling() async {
        // Device context collection should never crash
        // Even if some individual pieces fail
        
        let context = await deviceContext.getContext()
        
        // Should always return some context, even if incomplete
        XCTAssertFalse(context.isEmpty)
        
        // Core fields should always be present
        XCTAssertNotNil(context["sdk_version"])
        XCTAssertNotNil(context["os_name"])
    }
}