import XCTest
@testable import StopPoliticalSpamTexts

final class ClassifierFixturesTests: XCTestCase {

    func testReviewCorpusPassesWithDefaults() {
        let results = ClassifierFixtures.evaluate(config: .defaults)
        XCTAssertTrue(
            results.allSatisfy(\.passed),
            ClassifierFixtures.failureSummary(config: .defaults)
        )
    }

    func testReviewCorpusUsesSamePipelineAsExtension() {
        let config = FilterConfig.defaults
        let store = InMemoryConfigStore(config: config)

        for fixture in ClassifierFixtures.reviewCorpus {
            let direct = PoliticalTextClassifier().classify(
                sender: fixture.sender,
                body: fixture.body,
                config: config
            ).isFiltered
            let pipeline = MessageFilterPipeline.isFiltered(
                sender: fixture.sender,
                body: fixture.body,
                configStore: store
            )
            XCTAssertEqual(
                direct,
                pipeline,
                "Pipeline drift on fixture \(fixture.id)"
            )
        }
    }

    func testFixtureIDsAreUnique() {
        let ids = ClassifierFixtures.reviewCorpus.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
    }
}

private struct InMemoryConfigStore: FilterConfigStoring {
    let config: FilterConfig

    func load() -> FilterConfig { config }
    func save(_ config: FilterConfig) -> Bool { true }
}
