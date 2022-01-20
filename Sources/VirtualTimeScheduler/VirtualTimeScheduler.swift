
import Combine


/// A Combine Scheduler that executes actions based on a virtual clock.
/// Ideal for testing custom Publishers or testing time-dependent Pub-sub code.
///
/// The scheduler will run scheduled actions when they are due, based on a
/// "virtual" clock. The schedulers clock can be adjusted using one of these
/// methods.
///
/// - run() - run until there are no more actions scheduled
/// - step() - set the time to the due time of the first action that is due
/// - advanceTime(by:) - advance the internal clock by a specified value
/// - setTime(to:) - set the time to a value, the clock starts at `.referenceTime`
///
/// Actions can schedule other actions. The scheduler will run those actions if
/// they are due, in the same time update call.
///
/// ```
///     let scheduler = VirtualTimeScheduler()
///
///     let cancellable = Just(42)
///         .delay(for: .seconds(3), scheduler: scheduler)
///         .measureInterval(using: scheduler)
///         .sink { value in
///             print("Recieved \(value.magnitude) seconds later")
///         }
///
///     print("Before run \(Date())")
///     scheduler.run()
///     print("After run \(Date())")
///
///     //  Before run 2022-01-20 14:13:11 +0000
///     //  Recieved 3.0 seconds later
///     //  After run 2022-01-20 14:13:11 +0000
/// ```
///
public final class VirtualTimeScheduler {

    /// This scheduler’s definition of the current moment in time.
    public private(set) var now = Time.referenceTime

    /// The minimum tolerance allowed by the scheduler.
    public let minimumTolerance = Time.Stride.zero

    private var scheduledActions = [ActionRunner]()

    private var isPreformingActions = false

    /// Creates a scheduler instance
    public init() {}
}

extension VirtualTimeScheduler: Scheduler {
    /// A type that defines options accepted by the virtual clock scheduler.
    public typealias SchedulerOptions = Never

    /// Describes an instant in time for this scheduler.
    public typealias SchedulerTimeType = Time

    internal class CancelHandler: Cancellable {
        let handler: () -> ()

        init(handler: @escaping () -> ()) {
            self.handler = handler
        }

        func cancel() {
            handler()
        }

        deinit {
            cancel()
        }
    }

    /// Schedule an action to run as soon as the time is updated.
    public func schedule(options: Never?, _ action: @escaping () -> Void) {
        schedule(after: now, action)
    }

    /// Schedule an action to run after a due time.
    public func schedule(
        after date: SchedulerTimeType,
        tolerance: SchedulerTimeType.Stride = .zero,
        options: Never?,
        _ action: @escaping () -> Void
    ) {
        add(actionRunner: ActionRunner(
            after: date,
            action: action))
    }

    /// Schedule an action to run after a due time and repeat with frequency `interval`.
    public func schedule(
        after date: SchedulerTimeType,
        interval: SchedulerTimeType.Stride,
        tolerance: SchedulerTimeType.Stride,
        options: Never?,
        _ action: @escaping () -> Void
    ) -> Cancellable {
        let actionRunner = ActionRunner(
            after: date,
            interval: interval,
            action: action)

        add(actionRunner: actionRunner)

        return CancelHandler {
            actionRunner.cancelled = true
        }
    }

    private func add(actionRunner: ActionRunner) {
        let index = scheduledActions.firstIndex(where: {
            byNextDueTime(lhs: actionRunner, rhs: $0)
        })

        scheduledActions
            .insert(actionRunner, at: index ?? scheduledActions.endIndex)
    }
}

extension VirtualTimeScheduler {
    /// Runs all scheduled actions while updating the current moment in time
    /// chronologically.
    public func run() {
        while !scheduledActions.isEmpty {
            step()
        }
    }

    /// Advances the schedulers definition of the current moment in time
    /// so that at least one scheduled action will run.
    ///
    /// - If no actions where scheduled the time is not advanced.
    /// - Actions with a due date in the past will run.
    /// - Actions scheduled by other actions will run if they are due.
    public func step() {
        guard let action = scheduledActions.first
        else { return }

        let newTime = max(now, action.nextDueTime)
        setTime(to: newTime)
    }

    /// Advances the schedulers definition of the current moment in time and
    /// runs all actions due up to that time. Actions scheduled by the running
    /// actions are also run if they are due.
    public func advanceTime(by interval: Time.Stride) {
        let newTime = max(now, now.advanced(by: interval))
        setTime(to: newTime)
    }

    /// Sets the schedulers definition of time and runs all actions due by the
    /// new time. Actions scheduled by the running actions are also run if
    /// they are due.
    public func setTime(to time: Time) {
        now = time

        guard !isPreformingActions else { return }
        isPreformingActions = true

        while let action = scheduledActions.first, action.nextDueTime <= now {
            action.setTime(to: now)

            if action.nextDueTime <= time  {
                let index = scheduledActions.firstIndex(of: action)
                scheduledActions.remove(at: index!)
            } else {
                // 'interval' actions can their due time during setTime(to:)
                scheduledActions.sort(by: byNextDueTime(lhs:rhs:))
            }
        }

        isPreformingActions = false
    }
}

extension VirtualTimeScheduler {
    internal func byNextDueTime(lhs: ActionRunner, rhs: ActionRunner) -> Bool {
        lhs.nextDueTime < rhs.nextDueTime
    }

    internal class ActionRunner: Equatable {
        static func == (
            lhs: ActionRunner,
            rhs: ActionRunner
        ) -> Bool {
            ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
        }

        let action: () -> ()
        let interval: SchedulerTimeType.Stride?
        var cancelled = false
        private(set) var nextDueTime: Time

        init(
            after: SchedulerTimeType,
            interval: SchedulerTimeType.Stride? = nil,
            action: @escaping () -> ()
        ) {
            self.nextDueTime = after
            self.interval = interval
            self.action = action
        }

        func setTime(to time: Time) {
            guard !cancelled else { return }
            guard time >= nextDueTime else { return }

            action()

            guard let interval = interval else {
                return
            }

            let timeM = time.value.magnitude
            let nextDueTimeM = nextDueTime.value.magnitude
            let count = Int((timeM - nextDueTimeM) / interval.magnitude)

            for _ in 0..<count {
                guard !cancelled else { return }
                action()
            }

            let countPlusOne = Time.Stride(integerLiteral: count + 1)
            nextDueTime.advance(by: interval * countPlusOne)
        }
    }
}
