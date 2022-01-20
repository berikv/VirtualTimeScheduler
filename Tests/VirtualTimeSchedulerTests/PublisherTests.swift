import XCTest
import Combine
import VirtualTimeScheduler

final class PublisherTests: XCTestCase {
    func test_delay() {
        let scheduler = VirtualTimeScheduler()
        var publishedAt: TimeInterval?

        let cancellable = Just(42)
            .delay(for: .seconds(3), scheduler: scheduler)
            .sink { value in
                publishedAt = scheduler.now.timeIntervalSinceReferenceTime
            }

        scheduler.run()
        XCTAssertEqual(publishedAt, 3)
        _ = cancellable
    }

    func test_debounce() {
        let scheduler = VirtualTimeScheduler()
        var recievedValues = [Int]()
        var recievedTimes = [TimeInterval]()

        let subject = PassthroughSubject<Int, Never>()
        let cancellable = subject
            .debounce(for: .seconds(1), scheduler: scheduler)
            .sink { value in
                recievedValues.append(value)
                recievedTimes.append(
                    scheduler.now.timeIntervalSinceReferenceTime)
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

        XCTAssertEqual(recievedValues, [3, 7])
        XCTAssertEqual(recievedTimes, [1.4, 2.8000000000000003]) // yey for floating point values
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
