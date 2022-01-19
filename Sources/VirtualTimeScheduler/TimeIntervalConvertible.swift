
import Foundation

public protocol TimeIntervalConvertible {
    var timeInterval: TimeInterval { get }
}

extension VirtualTimeScheduler.SchedulerTimeType: TimeIntervalConvertible {
    public var timeInterval: TimeInterval {
        Double(timeInNanoseconds.value) / 1_000_000_000
    }
}
