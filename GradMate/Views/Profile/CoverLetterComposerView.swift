import SwiftUI

struct CoverLetterExportData: Hashable {
    let coverLetter: String
    let companyName: String
    let positionTitle: String
}

struct CoverLetterComposerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var coverLetterDataService: CoverLetterDataService
    
    @State private var companyName = ""
    @State private var positionTitle = ""
    @State private var coverLetterContent = ""
    @State private var showingSaveAlert = false
    @State private var navigateToExport = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("appScreenBG")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Company and Position Info
                        VStack(spacing: 16) {
                            Text("COMPANY & POSITION")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(Color("appTextPrimary"))
                                .kerning(1.5)
                            
                            VStack(spacing: 12) {
                                CustomTextField(
                                    title: "Company Name",
                                    text: $companyName,
                                    placeholder: "Enter company name"
                                )
                                
                                CustomTextField(
                                    title: "Position Title",
                                    text: $positionTitle,
                                    placeholder: "Enter position title"
                                )
                            }
                        }
                        .padding()
                        .background(Color("appCardBG"))
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color("appStrokeGray"), lineWidth: 1))
                        
                        // Cover Letter Content
                        VStack(alignment: .leading, spacing: 16) {
                            Text("COVER LETTER CONTENT")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(Color("appTextPrimary"))
                                .kerning(1.5)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Write your cover letter content")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(Color("appTextPrimary"))
                                
                                TextEditor(text: $coverLetterContent)
                                    .font(.body)
                                    .foregroundColor(Color("appTextPrimary"))
                                    .background(Color("appStrokeGray"))
                                    .cornerRadius(12)
                                    .frame(minHeight: 300)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color("appStrokeGray"), lineWidth: 1)
                                    )
                                    .overlay(
                                        Group {
                                            if coverLetterContent.isEmpty {
                                                Text("Dear Hiring Manager,\n\nI am writing to express my interest in the [Position Title] role at [Company Name]...")
                                                    .foregroundColor(Color("appTextSecondary"))
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 12)
                                                    .allowsHitTesting(false)
                                            }
                                        },
                                        alignment: .topLeading
                                    )
                            }
                        }
                        .padding()
                        .background(Color("appCardBG"))
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color("appStrokeGray"), lineWidth: 1))
                        
                        // Action Buttons
                        HStack(spacing: 16) {
                            Button(action: saveCoverLetter) {
                                HStack(spacing: 8) {
                                    Image(systemName: "square.and.arrow.down")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Save")
                                        .font(.headline)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color("appPrimaryAccent"))
                                .cornerRadius(12)
                            }
                            .disabled(companyName.isEmpty || positionTitle.isEmpty || coverLetterContent.isEmpty)
                            
                            Button(action: { navigateToExport = true }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Export")
                                        .font(.headline)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color("appSuccess"))
                                .cornerRadius(12)
                            }
                            .disabled(companyName.isEmpty || positionTitle.isEmpty || coverLetterContent.isEmpty)
                        }
                        .padding(.top, 20)
                    }
                    .padding()
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Cover Letter")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(Color("appTextSecondary")),
                trailing: Button("Done") {
                    saveCoverLetter()
                    dismiss()
                }
                .font(.headline)
                .foregroundColor(Color("appPrimaryAccent"))
                .disabled(companyName.isEmpty || positionTitle.isEmpty || coverLetterContent.isEmpty)
            )
            .alert("Cover Letter Saved", isPresented: $showingSaveAlert) {
                Button("OK") { }
            } message: {
                Text("Your cover letter has been saved successfully.")
            }
            .background(
                NavigationLink(
                    destination: CoverLetterExportView(
                        coverLetter: coverLetterContent,
                        companyName: companyName,
                        positionTitle: positionTitle
                    ),
                    isActive: $navigateToExport
                ) {
                    EmptyView()
                }
                .opacity(0)
            )
        }
    }
    
    private func saveCoverLetter() {
        let coverLetter = CoverLetter(
            name: "Cover Letter for \(positionTitle)",
            companyName: companyName,
            positionTitle: positionTitle,
            openingParagraph: coverLetterContent
        )
        
        coverLetterDataService.createCoverLetter(coverLetter)
        showingSaveAlert = true
    }
}

// Note: CustomTextField and CustomTextFieldStyle are now defined in SharedFormComponents.swift

#Preview {
    CoverLetterComposerView()
        .environmentObject(CoverLetterDataService())
} 