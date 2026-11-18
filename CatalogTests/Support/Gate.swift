actor Gate {
    private var isOpen = false
    private var hasArrival = false
    private var waiters: [CheckedContinuation<Void, Never>] = []
    private var arrivalWaiters: [CheckedContinuation<Void, Never>] = []

    func wait() async {
        hasArrival = true
        arrivalWaiters.forEach { $0.resume() }
        arrivalWaiters.removeAll()
        guard !isOpen else { return }
        await withCheckedContinuation { waiters.append($0) }
    }

    func waitForArrival() async {
        guard !hasArrival else { return }
        await withCheckedContinuation { arrivalWaiters.append($0) }
    }

    func open() {
        isOpen = true
        waiters.forEach { $0.resume() }
        waiters.removeAll()
    }
}
