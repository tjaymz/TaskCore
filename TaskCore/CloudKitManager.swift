//
//  CloudKitManager.swift
//  TaskCore
//
//  Created by James Trujillo on 5/10/25.
//

import Foundation
import CloudKit
import SwiftUI

class CloudKitManager: ObservableObject {
    // Status properties
    @Published var isSignedInToiCloud: Bool = false
    @Published var isSyncing: Bool = false
    @Published var error: String? = nil
    
    // Container
    private let container: CKContainer
    private let database: CKDatabase
    
    // Subscription ID
    private let subscriptionID = "TodoItemsChanges"
    
    init() {
        // Use the default container on both simulator and device
        container = CKContainer.default()
        database = container.privateCloudDatabase
        
        print("CloudKit: Initialized with default container")
    }
    
    // Check if user is signed into iCloud with completion handler
    func checkiCloudAccountStatus(completion: @escaping (Bool) -> Void) {
        print("CloudKit: Checking iCloud account status")
        container.accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("CloudKit: Account status error: \(error.localizedDescription)")
                    self?.error = error.localizedDescription
                    completion(false)
                    return
                }
                
                let isAvailable: Bool
                let errorMessage: String?
                
                switch status {
                case .available:
                    print("CloudKit: iCloud account is available")
                    isAvailable = true
                    errorMessage = nil
                case .restricted:
                    print("CloudKit: iCloud account is restricted")
                    isAvailable = false
                    errorMessage = "iCloud access is restricted"
                case .noAccount:
                    print("CloudKit: No iCloud account found")
                    isAvailable = false
                    errorMessage = "Please sign in to iCloud in Settings"
                case .couldNotDetermine:
                    print("CloudKit: Could not determine iCloud account status")
                    isAvailable = false
                    errorMessage = "Cannot determine iCloud status"
                case .temporarilyUnavailable:
                    print("CloudKit: iCloud is temporarily unavailable")
                    isAvailable = false
                    errorMessage = "iCloud temporarily unavailable"
                @unknown default:
                    print("CloudKit: Unknown iCloud account status")
                    isAvailable = false
                    errorMessage = "Unknown iCloud status"
                }
                
                self?.isSignedInToiCloud = isAvailable
                self?.error = errorMessage
                completion(isAvailable)
            }
        }
    }
    
    // Check if user is signed into iCloud (synchronous version for compatibility)
    func checkiCloudAccountStatus() {
        checkiCloudAccountStatus { _ in }
    }
    
    // Setup subscription for changes
    func setupSubscription() {
        guard isSignedInToiCloud else {
            print("CloudKit: Cannot setup subscription - not signed in")
            return
        }
        
        print("CloudKit: Setting up subscription")
        
        let subscription = CKQuerySubscription(
            recordType: "TodoItem",
            predicate: NSPredicate(format: "TRUEPREDICATE"),
            subscriptionID: subscriptionID,
            options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
        )
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo
        
        database.save(subscription) { subscription, error in
            if let error = error {
                print("CloudKit: Failed to save subscription: \(error.localizedDescription)")
            } else {
                print("CloudKit: Subscription saved successfully")
            }
        }
    }
    
    // Fetch todos with better error handling
    func fetchTodos(completion: @escaping ([TodoItem], Error?) -> Void) {
        // Check if we're signed in first
        if !isSignedInToiCloud {
            print("CloudKit: Not signed in, skipping fetch")
            completion([], nil)
            return
        }
        
        DispatchQueue.main.async {
            self.isSyncing = true
            self.error = nil
        }
        
        print("CloudKit: Fetching todos from iCloud")
        
        let query = CKQuery(recordType: "TodoItem", predicate: NSPredicate(format: "TRUEPREDICATE"))
        query.sortDescriptors = [NSSortDescriptor(key: "modificationDate", ascending: false)]
        
        // Use the updated API for iOS 15+
        if #available(iOS 15.0, *) {
            database.fetch(withQuery: query, inZoneWith: nil, desiredKeys: nil, resultsLimit: CKQueryOperation.maximumResults) { [weak self] result in
                DispatchQueue.main.async {
                    self?.isSyncing = false
                    
                    switch result {
                    case .success(let (matchResults, _)):
                        print("CloudKit: Query succeeded with \(matchResults.count) results")
                        
                        var todoItems: [TodoItem] = []
                        for (_, recordResult) in matchResults {
                            switch recordResult {
                            case .success(let record):
                                if let todoItem = TodoItem.fromCKRecord(record) {
                                    todoItems.append(todoItem)
                                } else {
                                    print("CloudKit: Failed to convert record to TodoItem")
                                }
                            case .failure(let error):
                                print("CloudKit: Error processing individual record: \(error.localizedDescription)")
                            }
                        }
                        
                        print("CloudKit: Successfully converted \(todoItems.count) records to TodoItems")
                        completion(todoItems, nil)
                        
                    case .failure(let error):
                        print("CloudKit: Error fetching records: \(error.localizedDescription)")
                        self?.handleCloudKitError(error)
                        completion([], error)
                    }
                }
            }
        } else {
            // Legacy API for iOS 14 and earlier
            database.perform(query, inZoneWith: nil) { [weak self] (records, error) in
                DispatchQueue.main.async {
                    self?.isSyncing = false
                    
                    if let error = error {
                        print("CloudKit: Error fetching records: \(error.localizedDescription)")
                        self?.handleCloudKitError(error)
                        completion([], error)
                        return
                    }
                    
                    guard let records = records else {
                        print("CloudKit: No records found")
                        completion([], nil)
                        return
                    }
                    
                    print("CloudKit: Found \(records.count) records")
                    
                    var todoItems: [TodoItem] = []
                    for record in records {
                        if let todoItem = TodoItem.fromCKRecord(record) {
                            todoItems.append(todoItem)
                        }
                    }
                    
                    print("CloudKit: Successfully converted \(todoItems.count) records to TodoItems")
                    completion(todoItems, nil)
                }
            }
        }
    }
    
    // Handle CloudKit errors gracefully
    private func handleCloudKitError(_ error: Error) {
        if let ckError = error as? CKError {
            switch ckError.code {
            case .notAuthenticated:
                self.error = "Please sign in to iCloud"
                self.isSignedInToiCloud = false
            case .networkUnavailable, .networkFailure:
                self.error = "Network unavailable - using local data"
            case .quotaExceeded:
                self.error = "iCloud storage full"
            case .zoneBusy, .serviceUnavailable:
                self.error = "iCloud service busy - will retry"
            default:
                self.error = "iCloud sync issue - using local data"
            }
        } else {
            self.error = error.localizedDescription
        }
    }
    
    // Sync with CloudKit with better error handling
    func syncWithCloudKit(localTodos: [TodoItem], completion: @escaping ([TodoItem]) -> Void) {
        fetchTodos { [weak self] cloudTodos, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("CloudKit sync error: \(error.localizedDescription)")
                    // Return local todos if there's an error - graceful fallback
                    completion(localTodos)
                    return
                }
                
                // Perform sync logic (merge local and cloud)
                if let strongSelf = self {
                    let mergedTodos = strongSelf.mergeTodos(localTodos: localTodos, cloudTodos: cloudTodos)
                    completion(mergedTodos)
                } else {
                    completion(localTodos)
                }
            }
        }
    }
    
    // Save a TodoItem to CloudKit with better error handling
    func saveTodo(_ todo: TodoItem, completion: @escaping (TodoItem?, Error?) -> Void) {
        guard isSignedInToiCloud else {
            print("CloudKit: Cannot save - not signed in to iCloud")
            let error = NSError(domain: "CloudKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "Not signed in to iCloud"])
            completion(nil, error)
            return
        }
        
        DispatchQueue.main.async {
            self.isSyncing = true
        }
        
        let record = todo.toCKRecord()
        
        print("CloudKit: Saving todo '\(todo.title)' with id \(todo.id.uuidString)")
        
        database.save(record) { [weak self] savedRecord, error in
            DispatchQueue.main.async {
                self?.isSyncing = false
                
                if let error = error {
                    print("CloudKit: Error saving record: \(error.localizedDescription)")
                    self?.handleCloudKitError(error)
                    completion(nil, error)
                    return
                }
                
                if let savedRecord = savedRecord {
                    print("CloudKit: Successfully saved record: \(savedRecord.recordID.recordName)")
                    
                    if let todoItem = TodoItem.fromCKRecord(savedRecord) {
                        completion(todoItem, nil)
                    } else {
                        let error = NSError(domain: "CloudKit", code: 100, userInfo: [NSLocalizedDescriptionKey: "Failed to convert saved record"])
                        completion(nil, error)
                    }
                } else {
                    let error = NSError(domain: "CloudKit", code: 101, userInfo: [NSLocalizedDescriptionKey: "No record returned"])
                    completion(nil, error)
                }
            }
        }
    }
    
    // Delete a TodoItem from CloudKit with better error handling
    func deleteTodo(_ todo: TodoItem, completion: @escaping (Bool, Error?) -> Void) {
        guard let recordID = todo.recordID else {
            print("CloudKit: Cannot delete todo without recordID")
            let error = NSError(domain: "CloudKit", code: 102, userInfo: [NSLocalizedDescriptionKey: "No record ID"])
            completion(false, error)
            return
        }
        
        guard isSignedInToiCloud else {
            print("CloudKit: Cannot delete - not signed in to iCloud")
            let error = NSError(domain: "CloudKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "Not signed in to iCloud"])
            completion(false, error)
            return
        }
        
        DispatchQueue.main.async {
            self.isSyncing = true
        }
        
        print("CloudKit: Deleting todo with recordID: \(recordID.recordName)")
        
        database.delete(withRecordID: recordID) { [weak self] (_, error) in
            DispatchQueue.main.async {
                self?.isSyncing = false
                
                if let error = error {
                    print("CloudKit: Error deleting record: \(error.localizedDescription)")
                    self?.handleCloudKitError(error)
                    completion(false, error)
                    return
                }
                
                print("CloudKit: Successfully deleted record")
                completion(true, nil)
            }
        }
    }
    
    // Merge local and cloud todos with conflict resolution
    private func mergeTodos(localTodos: [TodoItem], cloudTodos: [TodoItem]) -> [TodoItem] {
        print("CloudKit: Merging \(localTodos.count) local todos with \(cloudTodos.count) cloud todos")
        
        var mergedTodos = [TodoItem]()
        var localTodoDict = [UUID: TodoItem]()
        
        // Create dictionary from local todos for faster lookup
        for todo in localTodos {
            localTodoDict[todo.id] = todo
        }
        
        // Process cloud todos first
        for cloudTodo in cloudTodos {
            if let localTodo = localTodoDict[cloudTodo.id] {
                // Todo exists in both places - use newer version based on modification date
                if let cloudDate = cloudTodo.modificationDate,
                   let localDate = localTodo.modificationDate,
                   cloudDate > localDate {
                    mergedTodos.append(cloudTodo)
                    print("CloudKit: Using cloud version of '\(cloudTodo.title)' (newer)")
                } else {
                    mergedTodos.append(localTodo)
                    print("CloudKit: Using local version of '\(localTodo.title)' (newer or same)")
                }
                
                // Remove from local dict to mark as processed
                localTodoDict.removeValue(forKey: cloudTodo.id)
            } else {
                // Todo only exists in cloud, add it
                mergedTodos.append(cloudTodo)
                print("CloudKit: Adding cloud-only todo '\(cloudTodo.title)'")
            }
        }
        
        // Add remaining local todos (they don't exist in cloud yet)
        for (_, localTodo) in localTodoDict {
            mergedTodos.append(localTodo)
            print("CloudKit: Adding local-only todo '\(localTodo.title)'")
        }
        
        print("CloudKit: Merge complete, resulting in \(mergedTodos.count) todos")
        return mergedTodos
    }
}
