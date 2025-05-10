//
//  TodoManager.swift
//  TaskCore
//
//  Created by James Trujillo on 5/2/25.
//


// TodoManager.swift
import Foundation
import CloudKit
import SwiftUI

class TodoManager: ObservableObject {
    @Published var todos: [TodoItem] = []
    @Published var selectedTodo: TodoItem?
    @Published var syncStatus: String = "Up to date"
    
    private let todosKey = "savedTodos"
    private let selectedTodoKey = "selectedTodo"
    
    // CloudKit manager
    private let cloudKitManager = CloudKitManager()
    
    init() {
        loadTodos()
        loadSelectedTodo()
        
        // Initial sync with CloudKit
        syncWithCloudKit()
        
        // Setup notification observer for CloudKit changes
        setupNotificationObserver()
    }
    
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCloudKitNotification),
            name: .NSPersistentStoreRemoteChange,
            object: nil
        )
    }
    
    @objc private func handleCloudKitNotification(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            self?.syncWithCloudKit()
        }
    }
    
    func syncWithCloudKit() {
        syncStatus = "Syncing..."
        
        cloudKitManager.syncWithCloudKit(localTodos: todos) { [weak self] mergedTodos in
            DispatchQueue.main.async {
                self?.todos = mergedTodos
                self?.saveTodos()
                self?.syncStatus = "Up to date"
                
                // Update selected todo if needed
                if let selectedID = self?.selectedTodo?.id {
                    self?.selectedTodo = mergedTodos.first(where: { $0.id == selectedID })
                    self?.saveSelectedTodo()
                }
            }
        }
    }
    
    func loadTodos() {
        if let data = UserDefaults.standard.data(forKey: todosKey) {
            if let decoded = try? JSONDecoder().decode([TodoItem].self, from: data) {
                todos = decoded
                return
            }
        }
        todos = []
    }
    
    func saveTodos() {
        if let encoded = try? JSONEncoder().encode(todos) {
            UserDefaults.standard.set(encoded, forKey: todosKey)
        }
    }
    
    func loadSelectedTodo() {
        if let data = UserDefaults.standard.data(forKey: selectedTodoKey) {
            if let decoded = try? JSONDecoder().decode(TodoItem.self, from: data) {
                if todos.contains(where: { $0.id == decoded.id }) {
                    selectedTodo = decoded
                    return
                }
            }
        }
        selectedTodo = nil
    }
    
    func saveSelectedTodo() {
        if let selected = selectedTodo {
            if let encoded = try? JSONEncoder().encode(selected) {
                UserDefaults.standard.set(encoded, forKey: selectedTodoKey)
            }
        } else {
            UserDefaults.standard.removeObject(forKey: selectedTodoKey)
        }
    }
    
    func addTodo(_ title: String) {
        let todo = TodoItem(title: title)
        todos.append(todo)
        saveTodos()
        
        // Save to CloudKit
        cloudKitManager.saveTodo(todo) { [weak self] updatedTodo, error in
            if let updatedTodo = updatedTodo {
                DispatchQueue.main.async {
                    if let index = self?.todos.firstIndex(where: { $0.id == todo.id }) {
                        self?.todos[index] = updatedTodo
                        self?.saveTodos()
                    }
                }
            }
        }
    }
    
    func deleteTodo(at offsets: IndexSet) {
        // Handle selected todo
        if let selected = selectedTodo {
            for index in offsets {
                if todos[index].id == selected.id {
                    selectedTodo = nil
                    saveSelectedTodo()
                    break
                }
            }
        }
        
        // Delete from CloudKit
        for index in offsets {
            let todo = todos[index]
            cloudKitManager.deleteTodo(todo) { _, _ in }
        }
        
        todos.remove(atOffsets: offsets)
        saveTodos()
    }
    
    func selectRandomTodo() {
        if !todos.isEmpty {
            selectedTodo = todos.randomElement()
            saveSelectedTodo()
        }
    }
    
    func toggleTodoCompletion(_ todo: TodoItem) {
        if let index = todos.firstIndex(where: { $0.id == todo.id }) {
            var updatedTodo = todos[index]
            updatedTodo.isCompleted.toggle()
            updatedTodo.modificationDate = Date()
            
            todos[index] = updatedTodo
            saveTodos()
            
            // Update in CloudKit
            cloudKitManager.saveTodo(updatedTodo) { _, _ in }
            
            if selectedTodo?.id == todo.id {
                selectedTodo = updatedTodo
                saveSelectedTodo()
            }
        }
    }
    
    // Check CloudKit sign-in status
    var isiCloudSignedIn: Bool {
        return cloudKitManager.isSignedInToiCloud
    }
    
    // CloudKit error
    var cloudKitError: String? {
        return cloudKitManager.error
    }
    
    // Force sync with CloudKit
    func forceSyncWithCloudKit() {
        syncWithCloudKit()
    }
}
