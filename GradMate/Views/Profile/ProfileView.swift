//
//  ProfileView.swift
//  GradMate
//
//  Created by Pradeep Reddy Kumbam on 23/06/2025.
//

import SwiftUI

struct ProfileView: View {
    @State private var showEditProfile = false
    @State private var showAddSkill = false
    @State private var showAddExperience = false
    @State private var showAddProject = false
    @State private var showAddCert = false
    @State private var showAddEdu = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                ProfileHeaderView(onEdit: { showEditProfile = true })
                StatsRowView()
                AboutSectionView(onEdit: { showEditProfile = true })
                SectionCard(title: "Skills", addAction: { showAddSkill = true }) {
                    SkillsChipsView()
                }
                SectionCard(title: "Experience", addAction: { showAddExperience = true }) {
                    ExperienceListView()
                }
                SectionCard(title: "Projects", addAction: { showAddProject = true }) {
                    ProjectsListView()
                }
                SectionCard(title: "Certifications", addAction: { showAddCert = true }) {
                    CertificationsListView()
                }
                SectionCard(title: "Education", addAction: { showAddEdu = true }) {
                    EducationListView()
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 80)
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color("appScreenBG"), Color("appCardBG")]),
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
        .overlay(
            FloatingAddButton(action: { showAddExperience = true }),
            alignment: .bottomTrailing
        )
    }
} 