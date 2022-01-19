
import Combine
import ClampedInteger

extension VirtualTimeScheduler {
    public struct Time {

        public static let referenceTime = Time(Stride(0))

        var timeInNanoseconds: Stride

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

        init<Floating>(_ value: Floating) where Floating: BinaryFloatingPoint {
            self.value = ClampedInteger(value)
        }

        init<Integer>(_ value: Integer) where Integer: FixedWidthInteger {
            self.value = ClampedInteger(value)
        }

        var value: ClampedInteger<Int>
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
        self.value = ClampedInteger(value)
    }

    public init?<T>(exactly source: T) where T : BinaryInteger {
        guard let value = ClampedInteger<Int>(exactly: source) else {
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

extension VirtualTimeScheduler.Time.Stride: SchedulerTimeIntervalConvertible {

    public static func seconds(_ s: Double) -> Self {
        Self(s) * 1_000_000_000
    }

    public static func seconds(_ s: Int) -> Self {
        Self(s) * 1_000_000_000
    }

    public static func milliseconds(_ ms: Int) -> Self {
        Self(ms) * 1_000_000
    }

    public static func microseconds(_ us: Int) -> Self {
        Self(us) * 1_000
    }

    public static func nanoseconds(_ ns: Int) -> Self {
        Self(ns)
    }
}
