
import Foundation
import Combine

public final class VirtualClockScheduler: Scheduler {

    /// A type that defines options accepted by the immediate scheduler.
    public typealias SchedulerOptions = Never

    /// The time type used by the virtual clock scheduler.
    ///
    /// The virtual clock schedulers notion of time is relative to zero.
    /// Zero represents the time with no delayed scheduling applied.
    public struct SchedulerTimeType {

        /// The increment by which the immediate scheduler counts time.
        public typealias Stride = SchedulerTimeType

        /// Time stride in nanoseconds.
        public var magnitude: Int

        /// Creates a new SchedulerTimeType.Stride with the passed value in nanoseconds.
        init(_ value: Int) {
            magnitude = value
        }

        /// The `TimeInterval` relative to zero.
        var timeInterval: TimeInterval {
            TimeInterval(magnitude) / 1_000_000_000
        }
    }

    /// This scheduler’s definition of the current moment in time.
    public var now = SchedulerTimeType.zero

//
//    public var startDate: Date
//    public var date: Date {
//        if now < 0 { return startDate }
//        return startDate.addingTimeInterval(now.timeInterval)
//    }
//
//    init(date: Date = Date()) {
//        startDate = date
//    }

    /// A type that defines options accepted by the immediate scheduler.
    public var minimumTolerance = SchedulerTimeType.zero

    /// Performs the action immediately.
    public func schedule(options: Never?, _ action: @escaping () -> Void) {
        action()
    }

    /// The virtual clock scheduler performs the action immediately.
    ///
    /// While the action is performed, the scheduler updates its `now` property
    /// as if the action was performed on the exact future time.
    public func schedule(
        after date: SchedulerTimeType,
        tolerance: SchedulerTimeType,
        options: Never?,
        _ action: @escaping () -> Void
    ) {
        let past = now

        // Actions can't be performed before now
        let future = now + max(date, .zero)

        now = future
        action()
        now = past
    }

    /// Unimplemented
    public func schedule(
        after date: SchedulerTimeType,
        interval: SchedulerTimeType,
        tolerance: SchedulerTimeType,
        options: Never?,
        _ action: @escaping () -> Void
    ) -> Cancellable {
        fatalError("Unimplemented")
    }
}



extension VirtualClockScheduler.SchedulerTimeType.Stride: SignedNumeric {
    public init(integerLiteral value: Int) {
        magnitude = value
    }

    public init?<T>(exactly source: T) where T : BinaryInteger {
        guard let magnitude = Int(exactly: source) else {
            return nil
        }
        self.magnitude = magnitude
    }

    public static func + (lhs: Self, rhs: Self) -> Self {
        if lhs.magnitude > 0 && rhs.magnitude > Int.max - lhs.magnitude {
            return Self(.max)
        } else if lhs.magnitude < 0 && rhs.magnitude < Int.min - lhs.magnitude {
            return Self(.min)
        } else {
            return Self(lhs.magnitude + rhs.magnitude)
        }
    }

    public static func * (lhs: Self, rhs: Self) -> Self {
        if rhs.magnitude == 0 { return 0 }
        let result = rhs.magnitude &* lhs.magnitude
        if lhs.magnitude == result / rhs.magnitude {
            return Self(result)
        } else {
            if (lhs.magnitude > 0) == (rhs.magnitude > 0) {
                return Self(.max)
            } else {
                return Self(.min)
            }
        }
    }

    public static func *= (lhs: inout Self, rhs: Self) {
        lhs.magnitude *= rhs.magnitude
    }

    public static func - (lhs: Self, rhs: Self) -> Self {
        Self(integerLiteral: lhs.magnitude - rhs.magnitude)
    }
}

extension VirtualClockScheduler.SchedulerTimeType.Stride: Comparable {
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.magnitude < rhs.magnitude
    }
}

extension VirtualClockScheduler.SchedulerTimeType: SchedulerTimeIntervalConvertible {

    public static func seconds(_ s: Double) -> Self {
        switch s {
        case _ where s * 1000 > Double(Int.max): return milliseconds(Int.max)
        case _ where s * 1000 < Double(Int.min): return milliseconds(Int.min)
        default: return milliseconds(Int(s * 1000))
        }
    }

    public static func seconds(_ s: Int) -> Self {
        Self(s) * Self(1_000_000_000)
    }

    public static func milliseconds(_ ms: Int) -> Self {
        Self(ms) * Self(1_000_000)
    }

    public static func microseconds(_ us: Int) -> Self {
        Self(us) * Self(1_000)
    }

    public static func nanoseconds(_ ns: Int) -> Self {
        Self(ns)
    }
}

extension VirtualClockScheduler.SchedulerTimeType: Strideable {

    public func distance(to other: Self) -> Stride {
        Stride(magnitude.distance(to: other.magnitude))
    }

    public func advanced(by n: Stride) -> Self {
        return self + n
    }
}
