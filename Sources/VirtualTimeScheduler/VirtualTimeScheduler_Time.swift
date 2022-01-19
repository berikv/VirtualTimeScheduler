
import Combine

extension VirtualTimeScheduler {
    public struct Time {

        public static let referenceTime = Time(Stride(0))

        internal var timeInNanoseconds: Stride

        public init(_ stride: Stride) {
            timeInNanoseconds = stride
        }

        public mutating func advance(by interval: Stride) {
            assert(interval >= 0)
            timeInNanoseconds.value += interval.value
        }
    }
}

extension VirtualTimeScheduler.Time: Strideable {
    public struct Stride {
        public static let zero = Stride(0)

        internal var value: Int

        internal init(_ value: Int) {
            self.value = value
        }
    }

    public func distance(to other: VirtualTimeScheduler.Time) -> Stride {
        Stride(timeInNanoseconds.value
                .distance(to: other.timeInNanoseconds.value))
    }

    public func advanced(by n: Stride) -> VirtualTimeScheduler.Time {
        let time = Stride(timeInNanoseconds.value + n.value)
        return VirtualTimeScheduler.Time(time)
    }
}

extension VirtualTimeScheduler.Time.Stride: SchedulerTimeIntervalConvertible {

    public static func seconds(_ s: Double) -> Self {
        if s < Double(Int.min) { return Self(.min) }
        if s > Double(Int.max) { return Self(.max) }
        return .seconds(Int(s))
    }

    public static func seconds(_ s: Int) -> Self {
        let report = s.multipliedReportingOverflow(by: 1_000_000_000)
        if report.overflow {
            return Self(s < 0 ? .min : .max)
        } else {
            return Self(report.partialValue)
        }
    }

    public static func milliseconds(_ ms: Int) -> Self {
        let report = ms.multipliedReportingOverflow(by: 1_000_000)
        if report.overflow {
            return Self(ms < 0 ? .min : .max)
        } else {
            return Self(report.partialValue)
        }
    }

    public static func microseconds(_ us: Int) -> Self {
        let report = us.multipliedReportingOverflow(by: 1_000)
        if report.overflow {
            return Self(us < 0 ? .min : .max)
        } else {
            return Self(report.partialValue)
        }
    }

    public static func nanoseconds(_ ns: Int) -> Self {
        Self(ns)
    }
}

extension VirtualTimeScheduler.Time.Stride: Comparable, SignedNumeric {
    public typealias IntegerLiteralType = Int

    public static func + (lhs: Self, rhs: Self) -> Self {
        Self(lhs.value + rhs.value)
    }

    public static func - (lhs: Self, rhs: Self) -> Self {
        Self(lhs.value - rhs.value)
    }

    public static func * (lhs: Self, rhs: Self) -> Self {
        Self(lhs.value * rhs.value)
    }

    public static func *= (lhs: inout Self, rhs: Self) {
        lhs.value *= rhs.value
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.value < rhs.value
    }

    public init(integerLiteral value: Int) {
        self.value = value
    }

    public init?<T>(exactly source: T) where T : BinaryInteger {
        guard let value = Int(exactly: source) else {
            return nil
        }

        self.value = value
    }

    public var magnitude: UInt { value.magnitude }
}

extension VirtualTimeScheduler.Time: SchedulerTimeIntervalConvertible {

    public static func seconds(_ s: Double) -> Self {
        Self(.seconds(s))
    }

    public static func seconds(_ s: Int) -> Self {
        Self(.seconds(s))
    }

    public static func milliseconds(_ ms: Int) -> Self {
        Self(.milliseconds(ms))
    }

    public static func microseconds(_ us: Int) -> Self {
        Self(.microseconds(us))
    }

    public static func nanoseconds(_ ns: Int) -> Self {
        Self(.nanoseconds(ns))
    }
}
