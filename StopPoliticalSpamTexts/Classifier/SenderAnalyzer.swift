import Foundation

/// The shape of a sender, used only as a score *boost*. Sender never filters
/// alone and is never stored.
struct SenderShape: Equatable {
    let boost: Int
    let ruleId: String?

    static let none = SenderShape(boost: 0, ruleId: nil)
}

enum SenderAnalyzer {
    /// 5–6 digit short codes boost +2; 10DLC-looking numbers boost +1.
    /// The boost is only applied by the classifier when political context exists.
    static func analyze(_ sender: String?) -> SenderShape {
        guard let sender = sender else { return .none }
        let digits = sender.filter { $0.isNumber }
        switch digits.count {
        case 5...6:
            return SenderShape(boost: 2, ruleId: "sender_shortcode")
        case 10...11:
            return SenderShape(boost: 1, ruleId: "sender_10dlc")
        default:
            return .none
        }
    }
}
