//
//  TabBarItemView.swift
//  TrackEd
//
//  Created by Pradeep Reddy Kumbam on 10/06/2025.
//

import SwiftUI

struct TabBarItemView: View {
    
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4){
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(isSelected ? .blue : .gray)
                
                Text(label)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .blue : .gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
        }
        .accessibilityIdentifier(label)
    }
}
