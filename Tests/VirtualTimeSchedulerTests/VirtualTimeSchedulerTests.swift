import XCTest
@testable import VirtualTimeScheduler

final class VirtualTimeSchedulerTests: XCTestCase {
    func test_scheduleAfterDelay_firstDelayThenRepeatAtIntervalUntilCancelled() {
        let scheduler = VirtualTimeScheduler()
        var actionTimes = [Time]()

        let cancellable = scheduler.schedule(
            after: .seconds(3),
            interval: .seconds(1)) {
                actionTimes.append(scheduler.now)
            }

        for i in 0..<10 {
            if i == 4 { cancellable.cancel() }
            scheduler.step()
        }

        let expectation: [Time] = [
            .seconds(3),
            .seconds(4),
            .seconds(5),
            .seconds(6),
        ]

        XCTAssertEqual(actionTimes, expectation)
    }

    func test_scheduleAfterDelay_cancelledByDescoping() {
        let scheduler = VirtualTimeScheduler()
        var actionRunCount = 0

        func run() {
            let cancellable = scheduler.schedule(
                after: .seconds(3),
                interval: .seconds(1)) {
                    actionRunCount += 1
                }

            scheduler.step()

            _ = cancellable // fix lifetime
        }

        run()
        scheduler.step()

        XCTAssertEqual(actionRunCount, 1)
    }

//    func test_scheduleAfterDelay_intervalCalculatedFromLastRun() {
//        let scheduler = VirtualTimeScheduler()
//        var actionRunCount = 0
//
//        let cancellable = scheduler.schedule(
//            after: .seconds(0),
//            interval: .seconds(1)) {
//                if actionRunCount == 0 {
//                    scheduler.setTime(to: .seconds(2))
//                }
//
//                actionRunCount += 1
//            }
//
//        scheduler.step()
//        XCTAssertEqual(actionRunCount, 2)
//
//        _ = cancellable // fix lifetime
//    }

    func test_scheduleAfterDelay_runAllIntervals_onTimeChange() {
        XCTExpectFailure("Time adjustments run one repeated action")

        let scheduler = VirtualTimeScheduler()
        var actionRunCount = 0

        let cancellable = scheduler.schedule(
            after: .seconds(0),
            interval: .seconds(1)) {
                actionRunCount += 1
            }

        scheduler.setTime(to: .seconds(5))
        XCTAssertEqual(actionRunCount, 6)

        _ = cancellable // fix lifetime
    }

}
