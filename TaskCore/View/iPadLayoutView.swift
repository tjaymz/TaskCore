import SwiftUI

struct iPadLayoutView: View {
    @ObservedObject var todoManager: TodoManager
    @Binding var timeRemaining: Int
    @Binding var selectedMinutes: Int
    @Binding var isTimerRunning: Bool
    @Binding var timer: Timer?
    @Binding var randomNumber: Int
    @Binding var maxNumber: Int
    @Binding var newTodoTitle: String
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            List {
                NavigationLink {
                    TimerTabView(
                        timeRemaining: $timeRemaining,
                        selectedMinutes: $selectedMinutes,
                        isTimerRunning: $isTimerRunning,
                        timer: $timer
                    )
                } label: {
                    Label("Timer", systemImage: "timer")
                }
                
                NavigationLink {
                    RandomNumberTabView(
                        randomNumber: $randomNumber,
                        maxNumber: $maxNumber
                    )
                } label: {
                    Label("Random", systemImage: "dice")
                }
                
                NavigationLink {
                    TodoListTabView(
                        todoManager: todoManager,
                        newTodoTitle: $newTodoTitle
                    )
                } label: {
                    Label("Todos", systemImage: "checklist")
                }
            }
            .navigationTitle("Features")
        } detail: {
            // Default detail view when no item is selected
            VStack {
                Image(systemName: "arrow.left")
                    .font(.largeTitle)
                Text("Select a feature from the sidebar")
                    .font(.title)
            }
            .foregroundColor(.gray)
        }
    }
}
