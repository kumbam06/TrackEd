import SwiftUI

struct CertificationsListView: View {
    let certs = [
        (title: "Google PM Cert", org: "Google", year: "2023"),
        (title: "SwiftUI Pro", org: "Apple", year: "2022")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(certs, id: \.title) { cert in
                VStack(alignment: .leading, spacing: 2) {
                    Text(cert.title)
                        .font(.subheadline.bold())
                    Text(cert.org)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(cert.year)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color("appPrimaryAccent").opacity(0.08))
                )
            }
        }
    }
} 