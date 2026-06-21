import SwiftUI

struct CategoryTogglesView: View {
    @EnvironmentObject private var model: FilterConfigModel

    var body: some View {
        Form {
            Section {
                Toggle("Campaign & fundraising", isOn: $model.config.categoryToggles.campaignFundraising)
                Toggle("Ballot measures & propositions", isOn: $model.config.categoryToggles.ballotMeasures)
                Toggle("Campaign surveys & polls", isOn: $model.config.categoryToggles.campaignSurveys)
                Toggle("Volunteer, rally & petition", isOn: $model.config.categoryToggles.volunteerRallyPetition)
                Toggle("PAC, party & committee", isOn: $model.config.categoryToggles.pacPartyCommittee)
            } footer: {
                Text("ActBlue, WinRed, and similar platforms are always filtered when the filter is enabled.")
            }
        }
        .navigationTitle("Categories")
    }
}
