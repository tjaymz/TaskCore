import SwiftUI

struct iPhoneLayoutView: View {
    @ObservedObject var todoManager: TodoManager
    @Binding var timeRemaining: Int
    @Binding var selectedMinutes: Int
    @Binding var isTimerRunning: Bool
    @Binding var timer: Timer?
    @Binding var randomNumber: Int
    @Binding var maxNumber: Int
    @Binding var newTodoTitle: String
    
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
