
import Combine

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
            scheduler: self,
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
            scheduler: self,
            after: date,
            interval: interval,
            action: action)

        add(actionRunner: actionRunner)

        return CancelHandler {
            actionRunner.cancelled = true
        }
    }

    private func add(actionRunner: ActionRunner) {
        let index = scheduledActions.firstIndex(where: { actionRunner < $0 })
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
            }

            scheduledActions.sort()
        }

        isPreformingActions = false
    }
}

extension VirtualTimeScheduler {
    internal class ActionRunner: Comparable {
        static func == (
            lhs: VirtualTimeScheduler.ActionRunner,
            rhs: VirtualTimeScheduler.ActionRunner
        ) -> Bool {
            ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
        }

        static func < (
            lhs: VirtualTimeScheduler.ActionRunner,
            rhs: VirtualTimeScheduler.ActionRunner
        ) -> Bool {
            lhs.nextDueTime < rhs.nextDueTime
        }

        let action: () -> ()
        weak var scheduler: VirtualTimeScheduler?
        let interval: SchedulerTimeType.Stride?
        var cancelled = false
        var nextDueTime: Time

        init(
            scheduler: VirtualTimeScheduler,
            after: SchedulerTimeType,
            interval: SchedulerTimeType.Stride? = nil,
            action: @escaping () -> ()
        ) {
            self.scheduler = scheduler
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

            let timeNs = time.timeInNanoseconds
            let nextDueTimeNs = nextDueTime.timeInNanoseconds
            let count = (timeNs.value - nextDueTimeNs.value) / interval.value

            for _ in 0..<count {
                guard !cancelled else { return }
                action()
            }

            let countPlusOne = Time.Stride(count + 1)
            nextDueTime = SchedulerTimeType(
                nextDueTimeNs + interval * countPlusOne)
        }
    }
}
