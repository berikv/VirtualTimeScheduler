
import Combine

public final class VirtualTimeScheduler {

    @dynamicCallable
    struct ScheduledAction: Comparable {
        static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.after < rhs.after
        }

        static func == (lhs: Self, rhs: Self) -> Bool {
            false
        }

        let after: Time
        
        let action: () -> Void

        func dynamicallyCall(withArguments: [Never]) {
            action()
        }
    }

    /// A type that defines options accepted by the virtual clock scheduler.
    public typealias SchedulerOptions = Never

    /// Describes an instant in time for this scheduler.
    public typealias SchedulerTimeType = Time

    /// This scheduler’s definition of the current moment in time.
    public private(set) var now = Time.referenceTime

    /// The minimum tolerance allowed by the scheduler.
    public let minimumTolerance = Time.Stride.zero

    private var scheduledActions = [ScheduledAction]()

    /// Creates a scheduler instance
    public init() {}
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

        let newTime = max(now, action.after)
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

        while let first = scheduledActions.first, first.after <= now {
            let action = scheduledActions.removeFirst()
            action()
        }
    }
}

extension VirtualTimeScheduler: Scheduler {

    class IntervalActionRunner: Cancellable {
        let action: () -> ()
        weak var scheduler: VirtualTimeScheduler?
        let interval: SchedulerTimeType.Stride
        var cancelled = false

        init(
            scheduler: VirtualTimeScheduler,
            interval: SchedulerTimeType.Stride,
            action: @escaping () -> ()
        ) {
            self.scheduler = scheduler
            self.interval = interval
            self.action = action
        }

        func cancel() { cancelled = true }

        func run() {
            guard let scheduler = scheduler, !cancelled else { return }
            let nextTime = scheduler.now.advanced(by: interval)
            scheduler.schedule(after: nextTime) { [weak self] in
                self?.run()
            }

            action()
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
        let action = ScheduledAction(after: date, action: action)
        let index = scheduledActions.firstIndex(where: { action < $0 })
        scheduledActions.insert(action, at: index ?? scheduledActions.endIndex)
    }

    /// Schedule an action to run after a due time and repeat with frequency `interval`.
    public func schedule(
        after date: SchedulerTimeType,
        interval: SchedulerTimeType.Stride,
        tolerance: SchedulerTimeType.Stride,
        options: Never?,
        _ action: @escaping () -> Void
    ) -> Cancellable {
        let runner = IntervalActionRunner(
            scheduler: self,
            interval: interval,
            action: action)

        schedule(after: date) { runner.run() }

        return runner
    }
}
