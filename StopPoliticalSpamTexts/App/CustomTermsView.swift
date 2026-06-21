import SwiftUI

struct CustomTermsView: View {
    @EnvironmentObject private var model: FilterConfigModel
    @State private var newBlocked = ""
    @State private var newAllowed = ""

    var body: some View {
        Form {
            Section {
                ForEach(model.config.customBlockedTerms, id: \.self) { Text($0) }
                    .onDelete { model.removeBlockedTerms(at: $0) }
                HStack {
                    TextField("Add a term to block", text: $newBlocked)
                        .autocorrectionDisabled()
                    Button("Add") {
                        model.addBlockedTerm(newBlocked)
                        newBlocked = ""
                    }
                    .disabled(newBlocked.trimmingCharacters(in: .whitespaces).isEmpty
                              || model.config.customBlockedTerms.count >= FilterConfigLimits.maxCustomTerms)
                }
            } header: {
                Text("Blocked terms")
            } footer: {
                Text("Messages containing these are pushed toward Junk. Up to \(FilterConfigLimits.maxCustomTerms) terms, \(FilterConfigLimits.maxCustomTermLength) characters each.")
            }

            Section {
                ForEach(model.config.customAllowedTerms, id: \.self) { Text($0) }
                    .onDelete { model.removeAllowedTerms(at: $0) }
                HStack {
                    TextField("Add a term to allow", text: $newAllowed)
                        .autocorrectionDisabled()
                    Button("Add") {
                        model.addAllowedTerm(newAllowed)
                        newAllowed = ""
                    }
                    .disabled(newAllowed.trimmingCharacters(in: .whitespaces).isEmpty
                              || model.config.customAllowedTerms.count >= FilterConfigLimits.maxCustomTerms)
                }
            } header: {
                Text("Allowed terms")
            } footer: {
                Text("These lower a message's score but never override ActBlue, WinRed, and similar platforms. Up to \(FilterConfigLimits.maxCustomTerms) terms, \(FilterConfigLimits.maxCustomTermLength) characters each.")
            }
        }
        .navigationTitle("Custom Block List")
        .toolbar { EditButton() }
    }
}
