// debug-network.swift
// UserCanal Swift SDK - Network Debug Tool
//
// Copyright © 2024 UserCanal. All rights reserved.
//

import Foundation
import UserCanal
import Network

@main
struct NetworkDebugTool {
    static func main() async {
        print("🔍 UserCanal Swift SDK - Network Debug Tool")
        print("📡 Testing raw TCP + FlatBuffers transmission")

        // Test 1: Verify TCP connection to collector
        await testTCPConnection()

        // Test 2: Check API key format
        testAPIKeyFormat()

        // Test 3: Test FlatBuffers serialization directly
        await testFlatBuffersDirectly()

        // Test 4: Test SDK with debug logging
        await testSDKWithDebugLogging()

        print("🏁 Network debug completed")
    }

    // MARK: - TCP Connection Test

    static func testTCPConnection() async {
        print("\n🔍 TEST 1: Raw TCP Connection")

        let connection = NWConnection(
            to: NWEndpoint.hostPort(
                host: NWEndpoint.Host("localhost"),
                port: NWEndpoint.Port(rawValue: 50000)!
            ),
            using: .tcp
        )

        var isConnected = false

        connection.stateUpdateHandler = { state in
            switch state {
            case .setup:
                print("🔗 TCP: Setup")
            case .waiting(let error):
                print("⏳ TCP: Waiting - \(error)")
            case .preparing:
                print("🔧 TCP: Preparing")
            case .ready:
                print("✅ TCP: Connected to localhost:50000")
                isConnected = true
            case .failed(let error):
                print("❌ TCP: Failed - \(error)")
            case .cancelled:
                print("🚫 TCP: Cancelled")
            @unknown default:
                print("❓ TCP: Unknown state")
            }
        }

        connection.start(queue: DispatchQueue.global())

        // Wait for connection
        try? await Task.sleep(for: .seconds(2))

        if isConnected {
            // Test sending raw data
            let testData = "Hello from Swift SDK\n".data(using: .utf8)!

            connection.send(content: testData, completion: .contentProcessed { error in
                if let error = error {
                    print("❌ TCP Send failed: \(error)")
                } else {
                    print("✅ TCP Send successful: \(testData.count) bytes")
                }
            })

            try? await Task.sleep(for: .seconds(1))
        }

        connection.cancel()
        print("🔍 TCP connection test completed")
    }

    // MARK: - API Key Format Test

    static func testAPIKeyFormat() {
        print("\n🔍 TEST 2: API Key Format")

        let apiKeyString = "000102030405060708090a0b0c0d0e0f"
        print("📝 API Key String: \(apiKeyString)")
        print("📝 Length: \(apiKeyString.count) characters")

        // Convert to Data like the SDK does
        var apiKeyData = Data()
        var index = apiKeyString.startIndex
        while index < apiKeyString.endIndex {
            let nextIndex = apiKeyString.index(index, offsetBy: 2)
            let byteString = String(apiKeyString[index..<nextIndex])
            if let byte = UInt8(byteString, radix: 16) {
                apiKeyData.append(byte)
            }
            index = nextIndex
        }

        print("📝 API Key Data: \(apiKeyData.map { String(format: "%02x", $0) }.joined())")
        print("📝 Data Length: \(apiKeyData.count) bytes")
        print("📝 Expected: 16 bytes for 128-bit key")

        if apiKeyData.count == 16 {
            print("✅ API Key format looks correct")
        } else {
            print("❌ API Key format may be wrong")
        }
    }

    // MARK: - Direct FlatBuffers Test

    static func testFlatBuffersDirectly() async {
        print("\n🔍 TEST 3: Direct FlatBuffers Serialization")

        let apiKeyString = "000102030405060708090a0b0c0d0e0f"
        var apiKeyData = Data()
        var index = apiKeyString.startIndex
        while index < apiKeyString.endIndex {
            let nextIndex = apiKeyString.index(index, offsetBy: 2)
            let byteString = String(apiKeyString[index..<nextIndex])
            if let byte = UInt8(byteString, radix: 16) {
                apiKeyData.append(byte)
            }
            index = nextIndex
        }

        // Create test event
        let testEvent = Event(
            userID: "debug_user_123",
            name: EventName("debug_test_event"),
            properties: Properties([
                "test": true,
                "debug_mode": "swift_sdk",
                "timestamp": Date().timeIntervalSince1970
            ])
        )

        print("📝 Created test event: \(testEvent.name.stringValue)")
        print("📝 User ID: \(testEvent.userID)")
        print("📝 Properties: \(testEvent.properties.count) items")

        do {
            // Serialize to FlatBuffers
            let flatBuffersData = try FlatBuffersProtocol.createEventBatch(
                events: [testEvent],
                apiKey: apiKeyData
            )

            print("✅ FlatBuffers serialization successful")
            print("📊 Serialized size: \(flatBuffersData.count) bytes")

            // Show first 32 bytes in hex
            let previewBytes = flatBuffersData.prefix(min(32, flatBuffersData.count))
            let hexString = previewBytes.map { String(format: "%02x", $0) }.joined(separator: " ")
            print("📊 First \(previewBytes.count) bytes: \(hexString)")

            // Create length-prefixed frame like NetworkClient does
            var frame = Data()
            let length = UInt32(flatBuffersData.count)
            withUnsafeBytes(of: length.bigEndian) { bytes in
                frame.append(contentsOf: bytes)
            }
            frame.append(flatBuffersData)

            print("📊 Length-prefixed frame: \(frame.count) bytes")
            print("📊 Length prefix: \(String(format: "%08x", length)) (\(length) bytes)")

            // Test sending this frame directly
            await sendFrameDirectly(frame)

        } catch {
            print("❌ FlatBuffers serialization failed: \(error)")
        }
    }

    static func sendFrameDirectly(_ frame: Data) async {
        print("\n📡 Sending frame directly to collector...")

        let connection = NWConnection(
            to: NWEndpoint.hostPort(
                host: NWEndpoint.Host("localhost"),
                port: NWEndpoint.Port(rawValue: 50000)!
            ),
            using: .tcp
        )

        var sendCompleted = false

        connection.stateUpdateHandler = { state in
            if case .ready = state {
                print("📡 Direct connection ready, sending frame...")

                connection.send(content: frame, completion: .contentProcessed { error in
                    if let error = error {
                        print("❌ Direct send failed: \(error)")
                    } else {
                        print("✅ Direct send successful: \(frame.count) bytes")
                        print("📊 This should appear in your collector logs!")
                    }
                    sendCompleted = true
                })
            }
        }

        connection.start(queue: DispatchQueue.global())

        // Wait for send to complete
        while !sendCompleted {
            try? await Task.sleep(for: .milliseconds(100))
        }

        try? await Task.sleep(for: .seconds(1)) // Give server time to process
        connection.cancel()
    }

    // MARK: - SDK Debug Test

    static func testSDKWithDebugLogging() async {
        print("\n🔍 TEST 4: SDK with Debug Logging")

        var errorCount = 0
        var totalErrors: [String] = []

        // Configure SDK with error tracking
        UserCanal.shared.configure(
            apiKey: "000102030405060708090a0b0c0d0e0f",
            endpoint: "localhost:50000",
            batchSize: 1, // Force immediate sending
            flushInterval: 1.0,
            onError: { error in
                errorCount += 1
                let errorMsg = "Error #\(errorCount): \(error)"
                totalErrors.append(errorMsg)
                print("🚨 SDK Error: \(errorMsg)")
            }
        )

        print("📊 SDK configured with batch size 1 (immediate send)")

        // Wait for initialization
        try? await Task.sleep(for: .seconds(2))
        print("⏰ SDK initialization wait completed")

        // Send test event
        print("📤 Sending test event...")
        UserCanal.shared.track(.userSignedUp, properties: [
            "debug_test": true,
            "sdk": "swift",
            "timestamp": Date().timeIntervalSince1970
        ])

        // Wait a moment
        try? await Task.sleep(for: .seconds(1))

        // Send test log
        print("📝 Sending test log...")
        UserCanal.shared.logInfo("Debug test from Swift SDK", data: [
            "test_type": "network_debug",
            "sdk_version": "swift"
        ])

        // Wait a moment
        try? await Task.sleep(for: .seconds(1))

        // Manual flush
        print("🚀 Manual flush...")
        do {
            try await UserCanal.shared.flush()
            print("✅ Manual flush completed")
        } catch {
            print("❌ Manual flush failed: \(error)")
            totalErrors.append("Flush error: \(error)")
        }

        // Wait for any delayed operations
        try? await Task.sleep(for: .seconds(3))

        // Summary
        print("\n📊 SDK Debug Summary:")
        print("📊 Total errors: \(errorCount)")

        if totalErrors.isEmpty {
            print("✅ No errors detected - data should have been sent!")
        } else {
            print("❌ Errors detected:")
            for error in totalErrors {
                print("   - \(error)")
            }
        }

        print("📊 Check your collector logs for data from Swift SDK")
    }
}
