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
                Text("Open source under the MIT License. Fork it, steal it, improve it — the full code is public so you can verify every privacy promise for yourself.")
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
