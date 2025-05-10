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
        // Get your container identifier from the one you created
        container = CKContainer(identifier: "iCloud.com.2ndstartech.TaskCore") // Replace with your actual container ID
        database = container.privateCloudDatabase
        
        checkiCloudAccountStatus()
        setupSubscription()
    }
    
    // Check if user is signed into iCloud
    func checkiCloudAccountStatus() {
        container.accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                switch status {
                case .available:
                    self?.isSignedInToiCloud = true
                    self?.error = nil
                case .restricted:
                    self?.isSignedInToiCloud = false
                    self?.error = "iCloud access is restricted. Check your device settings."
                case .noAccount:
                    self?.isSignedInToiCloud = false
                    self?.error = "No iCloud account found. Please sign in to iCloud to enable syncing."
                case .couldNotDetermine:
                    self?.isSignedInToiCloud = false
                    self?.error = "Could not determine iCloud account status. Please check your network connection."
                case .temporarilyUnavailable:
                    self?.isSignedInToiCloud = false
                    self?.error = "iCloud is temporarily unavailable. Please try again later."
                @unknown default:
                    self?.isSignedInToiCloud = false
                    self?.error = "Unknown iCloud account status."
                }
            }
        }
    }
    
    // Setup subscription for changes
    func setupSubscription() {
        let predicate = NSPredicate(value: true)
        let subscription = CKQuerySubscription(
            recordType: "TodoItem",
            predicate: predicate,
            subscriptionID: subscriptionID,
            options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
        )
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo
        
        database.save(subscription) { _, error in
            if let error = error {
                print("Subscription error: \(error.localizedDescription)")
            }
        }
    }
    
    // Fetch TodoItems from CloudKit
    func fetchTodos(completion: @escaping ([TodoItem]?, Error?) -> Void) {
        let query = CKQuery(recordType: "TodoItem", predicate: NSPredicate(value: true))
        
        DispatchQueue.main.async {
            self.isSyncing = true
        }
        
        // Using the newer API
        let queryOperation = CKQueryOperation(query: query)
        var fetchedRecords = [CKRecord]()
        
        // Configure the query operation
        queryOperation.recordMatchedBlock = { (recordID, result) in
            switch result {
            case .success(let record):
                fetchedRecords.append(record)
            case .failure(let error):
                print("Error fetching record: \(error.localizedDescription)")
            }
        }
        
        queryOperation.queryResultBlock = { [weak self] result in
            DispatchQueue.main.async {
                self?.isSyncing = false
                
                switch result {
                case .success:
                    let todoItems = fetchedRecords.compactMap { TodoItem.fromCKRecord($0) }
                    completion(todoItems, nil)
                case .failure(let error):
                    self?.error = "Failed to fetch todos: \(error.localizedDescription)"
                    completion(nil, error)
                }
            }
        }
        
        // Add the operation to the database
        database.add(queryOperation)
    }
    
    // Save a TodoItem to CloudKit
    func saveTodo(_ todo: TodoItem, completion: @escaping (TodoItem?, Error?) -> Void) {
        let record = todo.toCKRecord()
        
        DispatchQueue.main.async {
            self.isSyncing = true
        }
        
        database.save(record) { [weak self] record, error in
            DispatchQueue.main.async {
                self?.isSyncing = false
                
                if let error = error {
                    self?.error = "Failed to save todo: \(error.localizedDescription)"
                    completion(nil, error)
                    return
                }
                
                if let record = record, let todoItem = TodoItem.fromCKRecord(record) {
                    completion(todoItem, nil)
                } else {
                    completion(nil, NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert record"]))
                }
            }
        }
    }
    
    // Delete a TodoItem from CloudKit
    func deleteTodo(_ todo: TodoItem, completion: @escaping (Bool, Error?) -> Void) {
        guard let recordID = todo.recordID else {
            completion(false, NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No record ID"]))
            return
        }
        
        DispatchQueue.main.async {
            self.isSyncing = true
        }
        
        database.delete(withRecordID: recordID) { [weak self] (_, error) in
            DispatchQueue.main.async {
                self?.isSyncing = false
                
                if let error = error {
                    self?.error = "Failed to delete todo: \(error.localizedDescription)"
                    completion(false, error)
                    return
                }
                
                completion(true, nil)
            }
        }
    }
    
    // Manually sync with CloudKit
    func syncWithCloudKit(localTodos: [TodoItem], completion: @escaping ([TodoItem]) -> Void) {
        fetchTodos { cloudTodos, error in
            if let cloudTodos = cloudTodos {
                // Perform sync logic (merge local and cloud)
                let mergedTodos = self.mergeTodos(localTodos: localTodos, cloudTodos: cloudTodos)
                completion(mergedTodos)
            } else {
                // If can't fetch, just return local todos
                completion(localTodos)
            }
        }
    }
    
    // Merge local and cloud todos with conflict resolution
    private func mergeTodos(localTodos: [TodoItem], cloudTodos: [TodoItem]) -> [TodoItem] {
        var mergedTodos = [TodoItem]()
        var localTodoDict = [UUID: TodoItem]()
        
        // Create dictionary from local todos for faster lookup
        for todo in localTodos {
            localTodoDict[todo.id] = todo
        }
        
        // Process cloud todos first
        for cloudTodo in cloudTodos {
            if let localTodo = localTodoDict[cloudTodo.id] {
                // Todo exists in both places - use newer version
                if let cloudDate = cloudTodo.modificationDate, 
                   let localDate = localTodo.modificationDate,
                   cloudDate > localDate {
                    mergedTodos.append(cloudTodo)
                } else {
                    mergedTodos.append(localTodo)
                }
                
                // Remove from local dict to mark as processed
                localTodoDict.removeValue(forKey: cloudTodo.id)
            } else {
                // Todo only exists in cloud, add it
                mergedTodos.append(cloudTodo)
            }
        }
        
        // Add remaining local todos
        for (_, localTodo) in localTodoDict {
            mergedTodos.append(localTodo)
        }
        
        return mergedTodos
    }
}
