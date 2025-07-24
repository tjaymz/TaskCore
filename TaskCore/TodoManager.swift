//
//  TodoManager.swift
//  TaskCore
//
//  Created by James Trujillo on 5/2/25.
//

import Foundation
import CloudKit
import SwiftUI
import Combine

class TodoManager: ObservableObject {
    @Published var todos: [TodoItem] = []
    @Published var selectedTodo: TodoItem?
    @Published var syncStatus: String = "Checking iCloud..."
    @Published var cloudSyncEnabled: Bool = false
    @Published var iCloudAvailable: Bool = false
    
    private let todosKey = "savedTodos"
    private let selectedTodoKey = "selectedTodo"
    
    // CloudKit manager
    private let cloudKitManager = CloudKitManager()
    
    init() {
        loadTodos()
        loadSelectedTodo()
        
        // Check iCloud availability and auto-enable if available
        checkiCloudAvailabilityAndAutoEnable()
        
        // Setup notification observer for CloudKit changes
        setupNotificationObserver()
    }
    
    private func checkiCloudAvailabilityAndAutoEnable() {
        // Removed CloudKit functionality
    }
    
    private func setupNotificationObserver() {
        // Removed CloudKit functionality
    }
    
    @objc private func handleCloudKitNotification(_ notification: Notification) {
        // Removed CloudKit functionality
    }
    
    @objc private func handleiCloudAccountChange(_ notification: Notification) {
        // Removed CloudKit functionality
    }
    
    func enableCloudSync() {
        // Removed CloudKit functionality
    }
    
    func disableCloudSync() {
        // Removed CloudKit functionality
    }
    
    func syncWithCloudKit() {
        // Removed CloudKit functionality
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
            
            if selectedTodo?.id == todo.id {
                selectedTodo = updatedTodo
                saveSelectedTodo()
            }
        }
    }
    
    // Removed CloudKit-related properties and functions
}
