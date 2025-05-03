import Foundation

class TodoManager: ObservableObject {
    @Published var todos: [TodoItem] = []
    @Published var selectedTodo: TodoItem?
    
    private let todosKey = "savedTodos"
    private let selectedTodoKey = "selectedTodo"
    
    init() {
        loadTodos()
        loadSelectedTodo()
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
            todos[index].isCompleted.toggle()
            saveTodos()
            
            if selectedTodo?.id == todo.id {
                selectedTodo = todos[index]
                saveSelectedTodo()
            }
        }
    }
}
