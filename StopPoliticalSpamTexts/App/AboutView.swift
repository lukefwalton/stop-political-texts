import SwiftUI

struct AboutView: View {
    var body: some View {
        List {
            Section {
                Text("Built by Luke F. Walton, founder of Surmado. This is a personal project, not a Surmado product.")
            }
            Section {
                Text("Paid once. No ads. No tracking. No data business.")
                    .foregroundStyle(.secondary)
            }

            Section {
                Text("The full source is published so you can verify the privacy promises for yourself. It is not open source — see the license in the repository.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Section {
                Text("This app does not distinguish between political parties, candidates, or ideologies. All political campaign categories are filtered equally.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("About")
    }
}
