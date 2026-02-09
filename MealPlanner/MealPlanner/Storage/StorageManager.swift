//
//  StorageManager.swift
//  MyApp
//
//  Created for Meal Planning Assistant
//

import Foundation

/// Errors that can occur during storage operations
enum StorageError: Error {
    case encodingFailed
    case decodingFailed
    case saveFailed
    case fetchFailed
}

/// Generic storage manager for persisting Codable types using UserDefaults
class StorageManager {
    static let shared = StorageManager()
    private let userDefaults: UserDefaults
    
    /// Initialize with a UserDefaults instance
    /// - Parameter userDefaults: The UserDefaults instance to use (defaults to .standard)
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    /// Save a Codable value to storage
    /// - Parameters:
    ///   - value: The value to save
    ///   - key: The key to store the value under
    /// - Throws: StorageError.encodingFailed if encoding fails
    func save<T: Encodable>(_ value: T, forKey key: String) throws {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(value)
            userDefaults.set(data, forKey: key)
        } catch {
            throw StorageError.encodingFailed
        }
    }
    
    /// Fetch a Codable value from storage
    /// - Parameters:
    ///   - type: The type to decode
    ///   - key: The key to fetch the value from
    /// - Returns: The decoded value, or nil if no data exists for the key
    /// - Throws: StorageError.decodingFailed if decoding fails
    func fetch<T: Decodable>(_ type: T.Type, forKey key: String) throws -> T? {
        guard let data = userDefaults.data(forKey: key) else {
            return nil
        }
        
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw StorageError.decodingFailed
        }
    }
    
    /// Remove a value from storage
    /// - Parameter key: The key to remove
    func remove(forKey key: String) {
        userDefaults.removeObject(forKey: key)
    }
}
