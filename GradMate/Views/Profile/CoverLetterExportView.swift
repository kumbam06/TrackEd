import SwiftUI

struct CoverLetterExportView: View {
    let coverLetter: String
    let companyName: String
    let positionTitle: String
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFormat: ExportFormat = .pdf
    @State private var showingShareSheet = false
    @State private var exportData: Data?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("appScreenBG")
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Format Selection
                    VStack(alignment: .leading, spacing: 16) {
                        Text("EXPORT FORMAT")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(Color("appTextPrimary"))
                            .kerning(1.5)
                        
                        HStack(spacing: 16) {
                            ForEach(ExportFormat.allCases, id: \.self) { format in
                                FormatCard(
                                    format: format,
                                    isSelected: selectedFormat == format
                                ) {
                                    selectedFormat = format
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color("appCardBG"))
                    .cornerRadius(16)
                    
                    // Preview
                    VStack(alignment: .leading, spacing: 16) {
                        Text("PREVIEW")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(Color("appTextPrimary"))
                            .kerning(1.5)
                        
                        ScrollView {
                            Text(coverLetter)
                                .font(.body)
                                .foregroundColor(Color("appTextPrimary"))
                                .lineSpacing(4)
                                .padding()
                                .background(Color("appScreenBG"))
                                .cornerRadius(12)
                        }
                        .frame(maxHeight: 400)
                    }
                    .padding()
                    .background(Color("appCardBG"))
                    .cornerRadius(16)
                    
                    Spacer()
                    
                    // Export Button
                    Button(action: exportCoverLetter) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Export Cover Letter")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("appPrimaryAccent"))
                        .cornerRadius(12)
                    }
                    .disabled(coverLetter.isEmpty)
                }
                .padding()
            }
            .navigationTitle("Export Cover Letter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let data = exportData {
                    ShareSheet(items: [data])
                }
            }
        }
    }
    
    private func exportCoverLetter() {
        switch selectedFormat {
        case .pdf:
            exportData = generatePDF()
        case .text:
            exportData = coverLetter.data(using: .utf8)
        }
        
        showingShareSheet = true
    }
    
    private func generatePDF() -> Data? {
        let pdfMetaData = [
            kCGPDFContextCreator: "GradMate",
            kCGPDFContextAuthor: companyName
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        return renderer.pdfData { context in
            context.beginPage()
            let left: CGFloat = 50
            var y: CGFloat = 50
            let titleFont = UIFont.systemFont(ofSize: 22, weight: .bold)
            let subtitleFont = UIFont.systemFont(ofSize: 14, weight: .medium)
            let bodyFont = UIFont.systemFont(ofSize: 12, weight: .regular)
            
            "Cover Letter".draw(at: CGPoint(x: left, y: y), withAttributes: [
                .font: titleFont,
                .foregroundColor: UIColor.black
            ])
            y += 32
            "\(positionTitle) — \(companyName)".draw(at: CGPoint(x: left, y: y), withAttributes: [
                .font: subtitleFont,
                .foregroundColor: UIColor.darkGray
            ])
            y += 28
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 4
            let attributes: [NSAttributedString.Key: Any] = [
                .font: bodyFont,
                .foregroundColor: UIColor.black,
                .paragraphStyle: paragraphStyle
            ]
            let attributed = NSAttributedString(string: coverLetter, attributes: attributes)
            let textRect = CGRect(x: left, y: y, width: pageRect.width - 100, height: pageRect.height - y - 50)
            attributed.draw(in: textRect)
        }
    }
}

// MARK: - Supporting Views

struct FormatCard: View {
    let format: ExportFormat
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color("appPrimaryAccent") : Color("appPrimaryAccent").opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: format.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isSelected ? .white : Color("appPrimaryAccent"))
                }
                
                Text(format.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? Color("appPrimaryAccent") : Color("appTextSecondary"))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? Color("appPrimaryAccent").opacity(0.1) : Color.clear)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

enum ExportFormat: String, CaseIterable {
    case pdf = "PDF"
    case text = "Text"
    
    var name: String {
        return self.rawValue
    }
    
    var icon: String {
        switch self {
        case .pdf: return "doc.text.fill"
        case .text: return "doc.plaintext"
        }
    }
}

#Preview {
    CoverLetterExportView(
        coverLetter: "Sample cover letter content...",
        companyName: "Sample Company",
        positionTitle: "Software Engineer"
    )
} 