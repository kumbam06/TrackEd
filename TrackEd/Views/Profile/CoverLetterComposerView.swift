import SwiftUI

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
                
                VStack(spacing: 20) {
                    // Company and Position Info
                    VStack(spacing: 16) {
                        Text("COMPANY & POSITION")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(Color("appTextPrimary"))
                            .kerning(1.5)
                        
                        VStack(spacing: 12) {
                            TextField("Company Name", text: $companyName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.subheadline)
                            
                            TextField("Position Title", text: $positionTitle)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.subheadline)
                        }
                    }
                    .padding()
                    .background(Color("appCardBG"))
                    .cornerRadius(16)
                    
                    // Cover Letter Content
                    VStack(alignment: .leading, spacing: 16) {
                        Text("COVER LETTER CONTENT")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(Color("appTextPrimary"))
                            .kerning(1.5)
                        
                        TextEditor(text: $coverLetterContent)
                            .font(.body)
                            .foregroundColor(Color("appTextPrimary"))
                            .background(Color("appScreenBG"))
                            .cornerRadius(12)
                            .frame(minHeight: 300)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color("appStrokeGray"), lineWidth: 1)
                            )
                    }
                    .padding()
                    .background(Color("appCardBG"))
                    .cornerRadius(16)
                    
                    Spacer()
                    
                    // Action Buttons
                    HStack(spacing: 16) {
                        Button(action: saveCoverLetter) {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.down")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Save")
                                    .font(.headline)
                                    .fontWeight(.semibold)
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
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("appSecondaryAccent"))
                            .cornerRadius(12)
                        }
                        .disabled(companyName.isEmpty || positionTitle.isEmpty || coverLetterContent.isEmpty)
                    }
                }
                .padding()
            }
            .navigationTitle("Cover Letter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        saveCoverLetter()
                        dismiss()
                    }
                    .disabled(companyName.isEmpty || positionTitle.isEmpty || coverLetterContent.isEmpty)
                }
            }
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

#Preview {
    CoverLetterComposerView()
        .environmentObject(CoverLetterDataService())
} 