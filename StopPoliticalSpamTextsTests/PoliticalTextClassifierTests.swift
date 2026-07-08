import XCTest
@testable import StopPoliticalSpamTexts

final class PoliticalTextClassifierTests: XCTestCase {

    private let classifier = PoliticalTextClassifier()

    private func config(
        strictness: Strictness = .aggressive,
        blocked: [String] = [],
        allowed: [String] = [],
        toggles: CategoryToggles = .allOn,
        enabled: Bool = true
    ) -> FilterConfig {
        var c = FilterConfig.defaults
        c.strictness = strictness
        c.customBlockedTerms = blocked
        c.customAllowedTerms = allowed
        c.categoryToggles = toggles
        c.enabled = enabled
        return c
    }

    private func filtered(_ body: String, sender: String? = nil, strictness: Strictness) -> Bool {
        classifier.classify(sender: sender, body: body, config: config(strictness: strictness)).isFiltered
    }

    // MARK: - Should filter (both modes)

    func testShouldFilterBothModes() {
        let messages = [
            "Democrats need your help. Donate before midnight.",
            "GOP alert: can we count on your vote?",
            "WinRed: 700% match active now.",
            "ActBlue donation link inside.",
            "Election poll: who are you voting for?",
            "Republicans are counting on grassroots donors.",
            "DNC deadline tonight. Chip in $5.",
            "Reply STOP to end. Donate before midnight to help Senate Democrats.",
            "Use code MAGA2026. Donate $500.",
            "Vote yes on Prop 12 before Election Day.",
            "No on Proposition 4. Reply STOP to end.",
            "Signature drive deadline tonight. Donate now.",
            "PAC deadline: chip in before midnight."
        ]
        for message in messages {
            XCTAssertTrue(filtered(message, strictness: .normal), "Normal should filter: \(message)")
            XCTAssertTrue(filtered(message, strictness: .aggressive), "Aggressive should filter: \(message)")
        }
    }

    // MARK: - Should allow (both modes)

    func testShouldAllowBothModes() {
        let messages = [
            "Your verification code is 123456.",
            "Your Amazon order has shipped.",
            "Your bank alert: card ending 1234 was used.",
            "Your DoorDash order is arriving.",
            "Your password reset code is 888222.",
            "Your prescription is ready for pickup.",
            "Your flight gate changed to B12.",
            "UPS tracking update: package delivered.",
            "Emergency alert: evacuation warning.",
            "Campaign Monitor verification code: 123456.",
            "Dr. Harris appointment tomorrow at 3pm.",
            "Harris County flood warning.",
            "Harris Teeter delivery is arriving.",
            "Check out this magazine article.",
            "UPS package delivered today.",
            "The proper way to file taxes.",
            "DNCE concert tickets on sale."
        ]
        for message in messages {
            XCTAssertFalse(filtered(message, strictness: .normal), "Normal should allow: \(message)")
            XCTAssertFalse(filtered(message, strictness: .aggressive), "Aggressive should allow: \(message)")
        }
    }

    // MARK: - Should allow in Normal (aggressive may filter some)

    func testShouldAllowInNormal() {
        let messages = [
            "Vote on the board proposal tomorrow.",
            "Your donation receipt from Goodwill.",
            "Campaign Monitor verification code.",
            "Poll results for your fantasy league.",
            "The office campaign kickoff is tomorrow.",
            "Please vote in the HOA survey.",
            "Interesting proposition for you.",
            "The product initiative kickoff is tomorrow.",
            "The bond measure was discussed in class."
        ]
        for message in messages {
            XCTAssertFalse(filtered(message, strictness: .normal), "Normal should allow: \(message)")
        }
    }

    // MARK: - Boundary safety

    func testBoundarySafety() {
        XCTAssertFalse(filtered("Check out this magazine article.", strictness: .aggressive))
        XCTAssertFalse(filtered("UPS package delivered.", strictness: .aggressive))
        XCTAssertFalse(filtered("The proper way to file taxes.", strictness: .aggressive))
        XCTAssertFalse(filtered("DNCE concert tickets on sale.", strictness: .aggressive))

        XCTAssertTrue(filtered("MAGA deadline tonight. Chip in $5.", strictness: .normal))
        XCTAssertTrue(filtered("DNC deadline tonight. Chip in $5.", strictness: .normal))
        XCTAssertTrue(filtered("PAC deadline: chip in before midnight.", strictness: .normal))
    }

    // MARK: - Regression scenarios

    func testCustomAllowDoesNotBypassHardPolitical() {
        let result = classifier.classify(
            sender: nil,
            body: "ActBlue needs your vote. Donate now.",
            config: config(allowed: ["vote"])
        )
        XCTAssertTrue(result.isFiltered)
        XCTAssertEqual(result.confidence, .high)
    }

    func testAuthRegexRejectsPoliticalCode() {
        XCTAssertTrue(filtered("Use code MAGA2026. Donate $500 before midnight.", strictness: .normal))
    }

    func testStop2EndPlusFundraisingIsHardPolitical() {
        // "stop2end" is only SMS mechanics on its own, but paired with a
        // fundraising/org signal it escalates to a hard-political filter.
        let result = classifier.classify(
            sender: nil,
            body: "Reply STOP2END. Donate $10 before midnight.",
            config: config(strictness: .normal)
        )
        XCTAssertTrue(result.isFiltered)
        XCTAssertEqual(result.confidence, .high)
        XCTAssertEqual(result.reason, "hard_political")
    }

    func testStop2EndAloneDoesNotFilter() {
        // Without a political pairing, the SMS-mechanics term must not filter.
        XCTAssertFalse(filtered("Reply STOP2END to unsubscribe.", strictness: .aggressive))
    }

    func testShortCodeAloneDoesNotFilter() {
        XCTAssertFalse(filtered("Your appointment is tomorrow at 9am.", sender: "12345", strictness: .aggressive))
    }

    func testShortCodeBoostsPoliticalContext() {
        XCTAssertTrue(filtered("Donate before midnight to help Democrats.", sender: "12345", strictness: .normal))
    }

    func testShortenerAloneDoesNotFilter() {
        XCTAssertFalse(filtered("Here is the link: bit.ly/example", strictness: .aggressive))
    }

    func testShortenerPlusCampaignFilters() {
        XCTAssertTrue(filtered("Donate before midnight: bit.ly/example", strictness: .normal))
    }

    func testNoBuiltInCandidateNames() {
        XCTAssertFalse(filtered("Dr. Harris appointment tomorrow.", strictness: .aggressive))
        XCTAssertFalse(filtered("Harris County flood warning.", strictness: .aggressive))
    }

    func testBallotTermsAloneDoNotFilter() {
        XCTAssertFalse(filtered("Interesting proposition for you.", strictness: .aggressive))
    }

    func testBallotPlusContextFilters() {
        XCTAssertTrue(filtered("Vote no on Proposition 4. Reply STOP to end.", strictness: .normal))
    }

    func testPhraseMatchRequiresAdjacency() {
        XCTAssertTrue(filtered("Vote YES on Prop 12", strictness: .normal))
    }

    // MARK: - Custom terms & toggles

    func testCustomBlockedTermFilters() {
        // A single custom block adds +4, enough for the aggressive threshold.
        let result = classifier.classify(
            sender: nil,
            body: "Our weekly newsletter is here.",
            config: config(strictness: .aggressive, blocked: ["newsletter"])
        )
        XCTAssertTrue(result.isFiltered)
    }

    func testCustomBlockedTermDoesNotMatchSubstring() {
        // Blocking "vote" must not catch "devote" / "pivotal" / "voter" appearing
        // inside larger words. Without boundary-aware matching this filtered.
        let result = classifier.classify(
            sender: nil,
            body: "I devote my time to pivotal projects.",
            config: config(strictness: .aggressive, blocked: ["vote"])
        )
        XCTAssertFalse(result.isFiltered)
    }

    func testCustomBlockedTermStillMatchesWholeWord() {
        // Boundary-aware matching must still hit the actual word.
        let result = classifier.classify(
            sender: nil,
            body: "Please vote tomorrow.",
            config: config(strictness: .aggressive, blocked: ["vote"])
        )
        XCTAssertTrue(result.isFiltered)
    }

    // testCustomBlockedTermMatchesAcrossPunctuation moved to TermMatcherTests —
    // the punctuation-boundary behavior is a TermMatcher concern, not a
    // user-visible classifier decision.

    func testCustomAllowedTermDoesNotMatchSubstring() {
        // Pre-fix, custom-allow "art" used raw `contains`, so it silently
        // subtracted -4 from any message containing "party" / "smart" /
        // "depart". Boundary-aware matching keeps the score intact.
        let result = classifier.classify(
            sender: nil,
            body: "Democratic Party event Tuesday. Donate $5 before midnight.",
            config: config(strictness: .normal, allowed: ["art"])
        )
        XCTAssertTrue(result.isFiltered)
    }

    func testTightenedAllowlistDoesNotExemptFundraising() {
        // Pre-tightening, "order" in the commerce allowlist would early-exit
        // and let this fundraising text through. After tightening, bare "order"
        // no longer triggers the allowlist.
        let result = classifier.classify(
            sender: nil,
            body: "Order your Democrats yard sign and chip in $5 before midnight.",
            config: config(strictness: .normal)
        )
        XCTAssertTrue(result.isFiltered)
    }

    func testLegitOrderTextStillAllowed() {
        // The anchored "your order" / "order #" forms must still allow real
        // commerce traffic.
        XCTAssertFalse(filtered("Your order #12345 has shipped.", strictness: .aggressive))
        XCTAssertFalse(filtered("Order is ready for pickup at Whole Foods.", strictness: .aggressive))
    }

    func testPhoneBankNoLongerAllowlistedAsBank() {
        // Previously bare "bank" allowlisted any text mentioning a phone bank.
        // Anchored "bank alert" / "from your bank" no longer catch this.
        XCTAssertTrue(filtered(
            "Join our phone bank tonight. Donate $5 to help Democrats win.",
            strictness: .normal
        ))
    }

    func testDisabledAllowsEverything() {
        let result = classifier.classify(
            sender: nil,
            body: "ActBlue: donate before midnight to help Democrats!",
            config: config(enabled: false)
        )
        XCTAssertFalse(result.isFiltered)
        XCTAssertEqual(result.reason, "disabled")
    }

    func testDisabledCategoryExcludesItsRules() {
        var toggles = CategoryToggles.allOn
        toggles.pacPartyCommittee = false
        toggles.campaignFundraising = false
        let result = classifier.classify(
            sender: nil,
            body: "Republicans need grassroots donors.",
            config: config(strictness: .aggressive, toggles: toggles)
        )
        XCTAssertFalse(result.isFiltered)
    }

    func testHardPoliticalIgnoresDisabledCategories() {
        let result = classifier.classify(
            sender: nil,
            body: "ActBlue link inside.",
            config: config(
                strictness: .normal,
                toggles: CategoryToggles(
                    campaignFundraising: false,
                    ballotMeasures: false,
                    campaignSurveys: false,
                    volunteerRallyPetition: false,
                    pacPartyCommittee: false
                )
            )
        )
        XCTAssertTrue(result.isFiltered)
    }

    func testFECDisclaimerFilters() {
        let message = "Paid for by Smith for Senate. Chip in before midnight."
        XCTAssertTrue(filtered(message, strictness: .normal))
        XCTAssertTrue(filtered(message, strictness: .aggressive))
    }

    func testDiacriticEvasionStillFilters() {
        // "Dönate" folds to "donate" so accent evasion does not slip through.
        let message = "Dönate before midnight to help Democrats."
        XCTAssertTrue(filtered(message, strictness: .normal))
    }

    // MARK: - Evasion hardening (one end-to-end case per technique; the eval
    // corpus in StopPoliticalSpamTextsTests/Eval covers each in depth)

    func testLeetEvasionFilters() {
        let message = "D0nate before m1dnight to help Dem0crats."
        XCTAssertTrue(filtered(message, strictness: .normal))
        XCTAssertTrue(filtered(message, strictness: .aggressive))
    }

    func testHomoglyphEvasionFilters() {
        // Cyrillic о (U+043E) and е (U+0435) inside Latin words.
        let message = "D\u{043E}nate before midnight to help D\u{0435}mocrats."
        XCTAssertTrue(filtered(message, strictness: .normal))
    }

    func testHomoglyphSpoofedDomainIsHardPolitical() {
        // Cyrillic а/с in "асtblue.com" fold before URL extraction, so the
        // spoofed host hits the political-domain list at full strength.
        let result = classifier.classify(
            sender: nil,
            body: "Give now at \u{0430}\u{0441}tblue.com",
            config: config(strictness: .normal)
        )
        XCTAssertTrue(result.isFiltered)
        XCTAssertEqual(result.reason, "hard_political")
    }

    func testZeroWidthEvasionFilters() {
        let message = "Do\u{200B}nate before midnight to help Demo\u{200B}crats."
        XCTAssertTrue(filtered(message, strictness: .normal))
    }

    func testPunctuationStuffingEvasionFilters() {
        let message = "D.o.n.a.t.e before midnight to help D.e.m.o.c.r.a.t.s."
        XCTAssertTrue(filtered(message, strictness: .normal))
    }

    func testSpacedLetterEvasionFilters() {
        let message = "D O N A T E before midnight to help D E M O C R A T S."
        XCTAssertTrue(filtered(message, strictness: .normal))
    }

    func testRepeatedCharEvasionFilters() {
        let message = "Dooonate before midnight to help Demooocrats."
        XCTAssertTrue(filtered(message, strictness: .normal))
    }

    func testFullwidthEvasionFilters() {
        let message = "ＤＯＮＡＴＥ before midnight to help ＤＥＭＯＣＲＡＴＳ."
        XCTAssertTrue(filtered(message, strictness: .normal))
    }

    func testDeobfuscatedMatchIsMarked() {
        let result = classifier.classify(
            sender: nil,
            body: "D0nate before m1dnight to help Dem0crats.",
            config: config(strictness: .normal)
        )
        XCTAssertTrue(result.isFiltered)
        XCTAssertTrue(result.matchedRules.contains("deobfuscated"))
    }

    func testCanonicalMatchIsNotMarkedDeobfuscated() {
        // The marker means "this match needed de-obfuscation" — a clean
        // message that matches on the canonical view must never carry it.
        let result = classifier.classify(
            sender: nil,
            body: "Donate before midnight to help Democrats.",
            config: config(strictness: .normal)
        )
        XCTAssertTrue(result.isFiltered)
        XCTAssertFalse(result.matchedRules.contains("deobfuscated"))
    }

    func testHardeningDoesNotBreakLeetLookalikeAuthText() {
        // A typo'd auth code must not become a false positive: digits are
        // never folded, and the allowlist reads the canonical view.
        XCTAssertFalse(filtered("Your c0de is 123456.", strictness: .aggressive))
    }

    func testHardeningDoesNotBreakAdversarialLookingNegatives() {
        XCTAssertFalse(filtered("Sooooo excited for tonight!!! See you there.", strictness: .aggressive))
        XCTAssertFalse(filtered("V.I.P. sale ends tonight — 50% off everything.", strictness: .aggressive))
        XCTAssertFalse(filtered("F Y I the meeting moved to 3pm.", strictness: .aggressive))
        XCTAssertFalse(filtered("Schedule posted at www.example.com — see you Saturday!!!", strictness: .aggressive))
    }

    func testPartyCommitteeDomainFilters() {
        XCTAssertTrue(filtered("Give now at dscc.org", strictness: .aggressive))
        XCTAssertTrue(filtered("Donate at nrsc.org", strictness: .aggressive))
    }

    func testEmptyBodyAllowed() {
        let result = classifier.classify(sender: nil, body: "   ", config: config())
        XCTAssertFalse(result.isFiltered)
        XCTAssertEqual(result.reason, "empty_body")
    }
}
