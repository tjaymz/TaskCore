//
//  TaskFluxWidgetsBundle.swift
//  TaskFluxWidgets
//
//  Created by James Trujillo on 8/7/25.
//

import WidgetKit
import SwiftUI

@main
struct TaskFluxWidgetsBundle: WidgetBundle {
    var body: some Widget {
        TaskFluxWidgets()
        TaskFluxWidgetsControl()
        TaskFluxWidgetsLiveActivity()
    }
}
