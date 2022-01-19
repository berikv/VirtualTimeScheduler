
import XCTest
import VirtualTimeScheduler

final class VirtualTimeScheduler_advanceTime_Tests: XCTestCase {

    func test_nowNotChanged_whenSetToPast() {
        let scheduler = VirtualTimeScheduler()
        scheduler.setTime(to: .seconds(3))

        XCTAssertEqual(scheduler.now, .seconds(3))
        scheduler.advanceTime(by: -.seconds(1))
        XCTAssertEqual(scheduler.now, .seconds(3))
    }

    func test_nowChanged_whenSetToFuture() {
        let scheduler = VirtualTimeScheduler()
        scheduler.setTime(to: .seconds(3))

        XCTAssertEqual(scheduler.now, .seconds(3))
        scheduler.advanceTime(by: .seconds(1))
        XCTAssertEqual(scheduler.now, .seconds(4))
    }

    func test_runActionsDue() {
        let scheduler = VirtualTimeScheduler()
        var actionsRun = 0

        scheduler.schedule {
            actionsRun += 1

            scheduler.schedule(after: .seconds(3)) {
                actionsRun += 1
            }
        }

        scheduler.schedule(after: .seconds(3)) {
            actionsRun += 1

            scheduler.schedule(after: .seconds(10)) {
                XCTFail()
            }
        }

        scheduler.schedule(after: .seconds(10)) {
            XCTFail()
        }

        scheduler.advanceTime(by: .seconds(3))
        XCTAssertEqual(actionsRun, 3)
    }
}
