import XCTest
import Combine
import VirtualTimeScheduler

final class VirtualTimeScheduler_scheduleAfterDelay_Tests: XCTestCase {
    func test_firstDelayThenRepeatAtIntervalUntilCancelled() {
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

    func test_cancelledByDescoping() {
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

        XCTAssertEqual(actionRunCount, 1)
        scheduler.step()
        XCTAssertEqual(actionRunCount, 1)
    }

    func test_runAllIntervals_onTimeChange() {
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

    func test_setTimeDuringActionRun_runsMoreActions() {
        let scheduler = VirtualTimeScheduler()
        var actionRunCount = 0

        let cancellable = scheduler.schedule(
            after: .seconds(0),
            interval: .seconds(1)) {
                if actionRunCount == 0 {
                    scheduler.setTime(to: .seconds(10))
                }

                actionRunCount += 1
            }

        scheduler.step()
        XCTAssertEqual(actionRunCount, 11)

        _ = cancellable // fix lifetime
    }

    func test_actionsRunAtScheduledTime() {
        let scheduler = VirtualTimeScheduler()
        var actionRunTimes = [Time]()

        var cancellable: Cancellable?
        cancellable = scheduler.schedule(
            after: .seconds(12),
            interval: .seconds(2)) {
                actionRunTimes.append(scheduler.now)

                if scheduler.now == .seconds(16) {
                    cancellable?.cancel()
                }
            }

        scheduler.run()

        let expected = [
            Time(.seconds(12)),
            Time(.seconds(14)),
            Time(.seconds(16)),
        ]

        XCTAssertEqual(actionRunTimes, expected)

        _ = cancellable // fix lifetime
    }

    func test_intervalCalculatedFromLastRun() {
        let scheduler = VirtualTimeScheduler()
        var actionRunTimes = [Time]()

        var cancellable: Cancellable?
        cancellable = scheduler.schedule(
            after: .seconds(12),
            interval: .seconds(2)) {
                actionRunTimes.append(scheduler.now)

                if scheduler.now == .seconds(12) {
                    scheduler.setTime(to: .seconds(13))
                } else if scheduler.now == .seconds(16) {
                    cancellable?.cancel()
                }
            }

        scheduler.run()

        let expected = [
            Time(.seconds(12)),
            Time(.seconds(14)),
            Time(.seconds(16)),
        ]

        XCTAssertEqual(actionRunTimes, expected)

        _ = cancellable // fix lifetime

    }
}
