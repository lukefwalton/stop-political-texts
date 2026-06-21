import IdentityLookup
import Foundation

/// The product. Classifies unknown-sender SMS locally and returns an action.
///
/// Privacy doctrine (permanent): no `deferQueryRequestToNetwork`, no
/// `URLSession`, no analytics, no logging of message bodies or senders, and no
/// persistence of anything. It reads shared config, scores, answers, forgets.
final class MessageFilterExtension: ILMessageFilterExtension {}

extension MessageFilterExtension: ILMessageFilterQueryHandling {

    func handle(
        _ queryRequest: ILMessageFilterQueryRequest,
        context: ILMessageFilterExtensionContext,
        completion: @escaping (ILMessageFilterQueryResponse) -> Void
    ) {
        let response = ILMessageFilterQueryResponse()
        let filtered = MessageFilterPipeline.isFiltered(
            sender: queryRequest.sender,
            body: queryRequest.messageBody
        )
        response.action = filtered ? .junk : .none
        completion(response)
    }
}
