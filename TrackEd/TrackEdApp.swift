//
//  TrackEdApp.swift
//  TrackEd
//
//  Created by Pradeep Reddy Kumbam on 10/06/2025.
//

import SwiftUI

@main
struct TrackEdApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
