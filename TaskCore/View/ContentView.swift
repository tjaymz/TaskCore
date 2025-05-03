import SwiftUI

struct ContentView: View {
    @StateObject private var todoManager = TodoManager()
    @AppStorage("selectedMinutes") private var selectedMinutes = 5
    @AppStorage("maxNumber") private var maxNumber = 100
    
    @State private var timeRemaining = 0
    @State private var isTimerRunning = false
    @State private var timer: Timer?
    @State private var randomNumber = 0
    @State private var newTodoTitle = ""
    
    var body: some View {
        TabView {
            TimerTabView(
                timeRemaining: $timeRemaining,
                selectedMinutes: $selectedMinutes,
                isTimerRunning: $isTimerRunning,
                timer: $timer
            )
            .tabItem {
                Label("Timer", systemImage: "timer")
            }
            
            RandomNumberTabView(
                randomNumber: $randomNumber,
                maxNumber: $maxNumber
            )
            .tabItem {
                Label("Random", systemImage: "dice")
            }
            
            TodoListTabView(
                todoManager: todoManager,
                newTodoTitle: $newTodoTitle
            )
            .tabItem {
                Label("Todos", systemImage: "checklist")
            }
        }
    }
}

#Preview {
    ContentView()
}
