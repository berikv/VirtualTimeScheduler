
import XCTest
import VirtualTimeScheduler

final class VirtualTimeScheduler_step_Tests: XCTestCase {

    func test_nowNotChanged_whenNoActions() {
        let scheduler = VirtualTimeScheduler()
        scheduler.setTime(to: .seconds(3))

        XCTAssertEqual(scheduler.now, .seconds(3))
        scheduler.step()
        XCTAssertEqual(scheduler.now, .seconds(3))
    }

    func test_nowChanged() {
        let scheduler = VirtualTimeScheduler()
        scheduler.setTime(to: .seconds(3))

        scheduler.schedule(after: .seconds(4)) {}

        XCTAssertEqual(scheduler.now, .seconds(3))
        scheduler.step()
        XCTAssertEqual(scheduler.now, .seconds(4))
    }

    func test_runsAction() {
        let scheduler = VirtualTimeScheduler()
        var actionRunTime: Time?
        scheduler.schedule(after: .seconds(1)) {
            actionRunTime = scheduler.now
        }
        scheduler.step()

        XCTAssertEqual(actionRunTime, .seconds(1))
    }

    func test_runsActionsInSequence() {
        let scheduler = VirtualTimeScheduler()
        var actionsRan = 0

        scheduler.schedule(after: .seconds(2)) {
            XCTAssertEqual(scheduler.now, .seconds(2))
            actionsRan += 1
        }

        scheduler.schedule(after: .seconds(1)) {
            XCTAssertEqual(scheduler.now, .seconds(1))
            actionsRan += 1
        }

        XCTAssertEqual(actionsRan, 0)
        scheduler.step()
        XCTAssertEqual(actionsRan, 1)
        scheduler.step()
        XCTAssertEqual(actionsRan, 2)
    }

    func test_runsActionsWithPastDueTime() {
        let scheduler = VirtualTimeScheduler()
        var actionRan = false
        
        scheduler.schedule(after: .seconds(2)) {
            scheduler.schedule(after: .referenceTime) {
                actionRan = true
            }
            XCTAssertFalse(actionRan)
        }

        XCTAssertFalse(actionRan)
        scheduler.step()
        XCTAssertTrue(actionRan)
        XCTAssertEqual(scheduler.now, .seconds(2))
    }
}
