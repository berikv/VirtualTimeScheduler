import XCTest
import Combine
import VirtualTimeScheduler

final class VirtualTimeSchedulerTests: XCTestCase {
    func test_delay() {
        let scheduler = VirtualTimeScheduler()
        var publishedAt: TimeInterval?

        let cancellable = Just(42)
            .delay(for: .seconds(3), scheduler: scheduler)
            .sink { value in
                publishedAt = scheduler.now.timeInterval
            }

        scheduler.run()
        XCTAssertEqual(publishedAt, 3)
        _ = cancellable
    }

    func test_debounce() {
        let scheduler = VirtualTimeScheduler()
        var recievedValues = [Int]()

        let subject = PassthroughSubject<Int, Never>()
        let cancellable = subject
            .debounce(for: .seconds(1), scheduler: scheduler)
            .sink { value in
                recievedValues.append(value)
            }

        for value in 0..<4 {
            subject.send(value)
            scheduler.advanceTime(by: .seconds(0.1))
        }

        scheduler.advanceTime(by: .seconds(1))

        for value in 4..<8 {
            subject.send(value)
            scheduler.advanceTime(by: .seconds(0.1))
        }

        subject.send(4)
        scheduler.advanceTime(by: .seconds(1))

        XCTAssertEqual(recievedValues, [3, 4])
        _ = cancellable
    }

    func test_throttle() {
        let scheduler = VirtualTimeScheduler()
        var recievedValues = [Int]()

        let subject = PassthroughSubject<Int, Never>()
        let cancellable = subject
            .throttle(for: .seconds(1), scheduler: scheduler, latest: false)
            .sink { value in
                recievedValues.append(value)
            }

        for value in 0..<4 {
            subject.send(value)
            scheduler.advanceTime(by: .seconds(0.1))
        }

        scheduler.advanceTime(by: .seconds(1))

        for value in 4..<8 {
            subject.send(value)
            scheduler.advanceTime(by: .seconds(0.1))
        }

        scheduler.advanceTime(by: .seconds(1))

        XCTAssertEqual(recievedValues, [0, 1, 4])
        _ = cancellable
    }
}
