import XCTest
@testable import Sprouts

final class ConversionRunStateTests: XCTestCase {
    func testStoppingRunReturnsToIdleAfterDelayedCancellationFinishes() {
        var state = ConversionRunState()
        state.begin()

        XCTAssertTrue(state.isConverting)
        XCTAssertTrue(state.requestStop())
        XCTAssertTrue(state.isStopping)

        // This represents a synchronous native encoder finally returning
        // after it received the cancellation request.
        state.finish()

        XCTAssertFalse(state.isConverting)
        XCTAssertFalse(state.isStopping)
    }

    func testOnlyFirstStopRequestIsAccepted() {
        var state = ConversionRunState()
        state.begin()

        XCTAssertTrue(state.requestStop())
        XCTAssertFalse(state.requestStop())
    }
}
