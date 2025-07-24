//
//  TodoListTabView.swift
//  TaskCore
//
//  Created by James Trujillo on 5/2/25.
//

import SwiftUI

struct TodoListTabView: View {
    @ObservedObject var todoManager: TodoManager
    @Binding var newTodoTitle: String
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Add Todo Section
                VStack(spacing: 15) {
                    HStack {
                        TextField("New Todo", text: $newTodoTitle)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.title3)
                        
                        Button(action: addTodo) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        .disabled(newTodoTitle.isEmpty)
                    }
                    
                    if let selected = todoManager.selectedTodo {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text("Selected: \(selected.title)")
                                .font(.headline)
                        }
                        .padding(.vertical, 5)
                        .padding(.horizontal, 10)
                        .background(Color.yellow.opacity(0.2))
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                
                // Todo List
                List {
                    ForEach(todoManager.todos) { todo in
                        HStack {
                            Button(action: { toggleTodo(todo) }) {
                                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(todo.isCompleted ? .green : .gray)
                            }
                            
                            Text(todo.title)
                                .font(.title3)
                                .strikethrough(todo.isCompleted)
                                .foregroundColor(todo.isCompleted ? .gray : .primary)
                            
                            Spacer()
                            
                            if todo.id == todoManager.selectedTodo?.id {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                    .font(.title2)
                            }
                        }
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation {
                                todoManager.selectedTodo = todo
                                todoManager.saveSelectedTodo()
                            }
                        }
                    }
                    .onDelete { offsets in
                        withAnimation {
                            todoManager.deleteTodo(at: offsets)
                        }
                    }
                }
                
                // Random Selection Button
                Button(action: { todoManager.selectRandomTodo() }) {
                    HStack {
                        Image(systemName: "shuffle")
                        Text("Pick Random Todo")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(15)
                    .padding()
                }
                .disabled(todoManager.todos.isEmpty)
            }
            .navigationTitle("Todo List")
        }
    }
    
    private func addTodo() {
        if !newTodoTitle.isEmpty {
            withAnimation {
                todoManager.addTodo(newTodoTitle)
                newTodoTitle = ""
            }
        }
    }
    
    private func toggleTodo(_ todo: TodoItem) {
        withAnimation {
            todoManager.toggleTodoCompletion(todo)
        }
    }
}
