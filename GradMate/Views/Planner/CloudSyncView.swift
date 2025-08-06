//
//  CloudSyncView.swift
//  GradMate
//
//  Created by Pradeep Reddy Kumbam on 23/06/2025.
//

import SwiftUI
import FirebaseAuth

struct CloudSyncView: View {
    @ObservedObject var taskManager: TaskManager
    @State private var showingSyncAlert = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Cloud Sync Status
            HStack {
                Image(systemName: taskManager.useCloudStorage ? "icloud.fill" : "icloud")
                    .font(.title2)
                    .foregroundColor(taskManager.useCloudStorage ? Color("appPrimaryAccent") : Color("appTextSecondary"))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(taskManager.useCloudStorage ? "Cloud Sync Enabled" : "Cloud Sync Disabled")
                        .font(.headline)
                        .foregroundColor(Color("appTextPrimary"))
                    
                    Text(taskManager.useCloudStorage ? "Tasks are syncing to the cloud" : "Tasks are stored locally only")
                        .font(.caption)
                        .foregroundColor(Color("appTextSecondary"))
                }
                
                Spacer()
                
                Button(action: {
                    if taskManager.useCloudStorage {
                        taskManager.disableCloudStorage()
                    } else {
                        if Auth.auth().currentUser != nil {
                            taskManager.enableCloudStorage()
                        } else {
                            showingSyncAlert = true
                        }
                    }
                }) {
                    Text(taskManager.useCloudStorage ? "Disable" : "Enable")
                        .font(.subheadline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(taskManager.useCloudStorage ? Color("appError").opacity(0.1) : Color("appPrimaryAccent").opacity(0.1))
                        )
                        .foregroundColor(taskManager.useCloudStorage ? Color("appError") : Color("appPrimaryAccent"))
                }
            }
            .padding()
            .background(Color("appCardBG"))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
            
            // Cloud Tasks Count
            if taskManager.useCloudStorage {
                HStack {
                    Image(systemName: "list.bullet")
                        .font(.caption)
                        .foregroundColor(Color("appTextSecondary"))
                    
                    Text("\(taskManager.cloudTasks.count) tasks in cloud")
                        .font(.caption)
                        .foregroundColor(Color("appTextSecondary"))
                    
                    Spacer()
                    
                    if !taskManager.cloudTasks.isEmpty {
                        Button("Sync Now") {
                            taskManager.syncTasksToCloud()
                        }
                        .font(.caption)
                        .foregroundColor(Color("appPrimaryAccent"))
                    }
                }
                .padding(.horizontal)
            }
        }
        .alert("Authentication Required", isPresented: $showingSyncAlert) {
            Button("OK") { }
        } message: {
            Text("Please sign in to enable cloud sync for your tasks.")
        }
    }
}

#Preview {
    CloudSyncView(taskManager: TaskManager())
} 