import XCTest
import VirtualTimeScheduler

final class VirtualTimeScheduler_run_Tests: XCTestCase {
    func test_nowNotChanged_whenNoActions() {
        let scheduler = VirtualTimeScheduler()
        let now = scheduler.now
        scheduler.run()
        XCTAssertEqual(now, scheduler.now)
    }

    func test_updateNowToActionDueTime() {
        let scheduler = VirtualTimeScheduler()

        scheduler.schedule(after: .seconds(1)) {}
        scheduler.run()

        XCTAssertEqual(scheduler.now, .seconds(1))
    }

    func test_runsAction() {
        let scheduler = VirtualTimeScheduler()
        var actionRunTime: Time?
        scheduler.schedule(after: .seconds(1)) {
            actionRunTime = scheduler.now
        }
        scheduler.run()

        XCTAssertEqual(actionRunTime, .seconds(1))
    }

    func test_runsActionsInSequence() {
        let scheduler = VirtualTimeScheduler()
        var actionsRan = 0

        scheduler.schedule(after: .seconds(2)) {
            XCTAssertEqual(actionsRan, 1)
            XCTAssertEqual(scheduler.now, .seconds(2))
            actionsRan += 1
        }

        scheduler.schedule(after: .seconds(1)) {
            XCTAssertEqual(actionsRan, 0)
            XCTAssertEqual(scheduler.now, .seconds(1))
            actionsRan += 1
        }

        XCTAssertEqual(actionsRan, 0)
        scheduler.run()
        XCTAssertEqual(actionsRan, 2)
    }

    func test_nowNotOnlyIncreased() {
        let scheduler = VirtualTimeScheduler()
        var actionRan = false
        
        scheduler.schedule(after: .seconds(2)) {
            scheduler.schedule(after: .referenceTime) {
                actionRan = true
            }
        }

        XCTAssertFalse(actionRan)
        scheduler.run()
        XCTAssertTrue(actionRan)
        XCTAssertEqual(scheduler.now, .seconds(2))
    }
}
