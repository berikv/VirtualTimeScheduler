import XCTest
import VirtualTimeScheduler

final class VirtualTimeScheduler_setTime_Tests: XCTestCase {
    func test_setsNow() {
        let scheduler = VirtualTimeScheduler()
        let time = Time.seconds(3)
        scheduler.setTime(to: time)
        XCTAssertEqual(scheduler.now, time)
    }

    func test_doesNotRunActionWithFutureDueTime() {
        let scheduler = VirtualTimeScheduler()

        let scheduleTime = Time.seconds(3)
        scheduler.schedule(after: scheduleTime) {
            XCTFail()
        }

        let time = Time.seconds(2)
        scheduler.setTime(to: time)
        XCTAssertEqual(scheduler.now, time)
    }

    func test_runsActionAtDueTime() {
        let scheduler = VirtualTimeScheduler()
        var actionRunTime: Time?

        let time = Time.seconds(3)
        scheduler.schedule(after: time) {
            actionRunTime = scheduler.now
        }

        scheduler.setTime(to: time)
        XCTAssertEqual(actionRunTime, time)
    }

    func test_runsActionPassedDueTime() {
        let scheduler = VirtualTimeScheduler()
        var actionRunTime: Time?

        let scheduleTime = Time.seconds(2)
        scheduler.schedule(after: scheduleTime) {
            actionRunTime = scheduler.now
        }

        let time = Time.seconds(3)
        scheduler.setTime(to: time)
        XCTAssertEqual(actionRunTime, time)
    }

    func test_runsActionOnce() {
        let scheduler = VirtualTimeScheduler()
        var actionRunTime: Time?

        let scheduleTime = Time.seconds(2)
        scheduler.schedule(after: scheduleTime) {
            XCTAssertNil(actionRunTime)
            actionRunTime = scheduler.now
        }

        let time = Time.seconds(2)
        scheduler.setTime(to: time)
        scheduler.setTime(to: time)
    }

    func test_runsMultipleActionsPassedDueTime() {
        let scheduler = VirtualTimeScheduler()
        var firstActionRunTime: Time?
        var secondActionRunTime: Time?

        scheduler.schedule(after: .seconds(3)) {
            secondActionRunTime = scheduler.now
        }

        scheduler.schedule(after: .seconds(2)) {
            firstActionRunTime = scheduler.now
        }

        scheduler.setTime(to: .seconds(3))
        XCTAssertEqual(firstActionRunTime, .seconds(3))
        XCTAssertEqual(secondActionRunTime, .seconds(3))
    }

    func test_runsMultipleActionsInOrder() {
        let scheduler = VirtualTimeScheduler()
        var firstActionRun = false
        var secondActionRun = false

        scheduler.schedule(after: .seconds(3)) {
            XCTAssertTrue(firstActionRun)
            XCTAssertFalse(secondActionRun)
            secondActionRun = true
        }

        scheduler.schedule(after: .seconds(2)) {
            XCTAssertFalse(firstActionRun)
            XCTAssertFalse(secondActionRun)
            firstActionRun = true
        }

        XCTAssertFalse(firstActionRun)
        XCTAssertFalse(secondActionRun)
        scheduler.setTime(to: .seconds(3))
        XCTAssertTrue(firstActionRun)
        XCTAssertTrue(secondActionRun)
    }

    func test_doesNotRunActionWithFutureDueTimeScheduledByAction() {
        let scheduler = VirtualTimeScheduler()
        var actionRan = false
        scheduler.schedule {
            scheduler.schedule(after: .seconds(1)) {
                XCTFail()
            }
            actionRan = true
        }

        XCTAssertFalse(actionRan)
        scheduler.setTime(to: scheduler.now)
        XCTAssertTrue(actionRan)
    }

    func test_runsActionScheduledByAction() {
        let scheduler = VirtualTimeScheduler()
        var actionRan = false
        scheduler.schedule {
            scheduler.schedule {
                actionRan = true
            }
            XCTAssertFalse(actionRan)
        }

        XCTAssertFalse(actionRan)
        scheduler.setTime(to: .referenceTime)
        XCTAssertTrue(actionRan)
    }
}
