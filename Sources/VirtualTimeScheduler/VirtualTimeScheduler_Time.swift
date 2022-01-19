
import Foundation
import Combine

extension VirtualTimeScheduler {
    public struct Time {

        public static let referenceTime = Time(Stride(0))

        internal var value: Stride

        public init(_ stride: Stride) {
            value = stride
        }

        public var timeIntervalSinceReferenceTime: TimeInterval {
            value.magnitude
        }

        public mutating func advance(by interval: Stride) {
            assert(interval >= 0)
            value.magnitude += interval.magnitude
        }
    }
}

extension VirtualTimeScheduler.Time: Strideable {
    public struct Stride {
        public static let zero = Stride(0)

        public internal(set) var magnitude: Double

        internal init(_ value: Double) {
            self.magnitude = value
        }
    }

    public func distance(to other: VirtualTimeScheduler.Time) -> Stride {
        Stride(value.magnitude
                .distance(to: other.value.magnitude))
    }

    public func advanced(by n: Stride) -> VirtualTimeScheduler.Time {
        let time = Stride(value.magnitude + n.magnitude)
        return VirtualTimeScheduler.Time(time)
    }
}

extension VirtualTimeScheduler.Time.Stride: SchedulerTimeIntervalConvertible {

    public static func seconds(_ s: Double) -> Self {
        Self(s)
    }

    public static func seconds(_ s: Int) -> Self {
        Self(Double(s))
    }

    public static func milliseconds(_ ms: Int) -> Self {
        Self(Double(ms) / 1000)
    }

    public static func microseconds(_ us: Int) -> Self {
        Self(Double(us) / 1000_000)
    }

    public static func nanoseconds(_ ns: Int) -> Self {
        Self(Double(ns) / 1000_000_000)
    }
}

extension VirtualTimeScheduler.Time.Stride: Comparable, SignedNumeric {
    public typealias IntegerLiteralType = Int

    public static func + (lhs: Self, rhs: Self) -> Self {
        Self(lhs.magnitude + rhs.magnitude)
    }

    public static func - (lhs: Self, rhs: Self) -> Self {
        Self(lhs.magnitude - rhs.magnitude)
    }

    public static func * (lhs: Self, rhs: Self) -> Self {
        Self(lhs.magnitude * rhs.magnitude)
    }

    public static func *= (lhs: inout Self, rhs: Self) {
        lhs.magnitude *= rhs.magnitude
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.magnitude < rhs.magnitude
    }

    public init(integerLiteral value: Int) {
        self.magnitude = Double(value)
    }

    public init?<T>(exactly source: T) where T : BinaryInteger {
        guard let magnitude = Double(exactly: source) else {
            return nil
        }
        self.magnitude = magnitude
    }
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
