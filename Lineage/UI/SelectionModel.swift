import Foundation

@MainActor
final class SelectionModel {

    typealias Observer = @MainActor (SelectionModel) -> Void

    private(set) var selected: Set<NodeID> = []
    private(set) var primary: NodeID?

    private var observers: [UUID: Observer] = [:]

    @discardableResult
    func addObserver(_ observer: @escaping Observer) -> UUID {
        let id = UUID()
        observers[id] = observer
        observer(self)
        return id
    }

    func removeObserver(_ id: UUID) {
        observers.removeValue(forKey: id)
    }

    func replace(with id: NodeID?) {
        if let id {
            selected = [id]
            primary = id
        } else {
            selected = []
            primary = nil
        }
        notify()
    }

    func replace(with ids: Set<NodeID>, primary: NodeID? = nil) {
        selected = ids
        if let primary, ids.contains(primary) {
            self.primary = primary
        } else {
            self.primary = ids.first
        }
        notify()
    }

    func extend(with id: NodeID) {
        selected.insert(id)
        primary = id
        notify()
    }

    func toggle(_ id: NodeID) {
        if selected.contains(id) {
            selected.remove(id)
            if primary == id { primary = selected.first }
        } else {
            selected.insert(id)
            primary = id
        }
        notify()
    }

    func clear() {
        selected.removeAll()
        primary = nil
        notify()
    }

    private func notify() {
        for observer in observers.values {
            observer(self)
        }
    }
}
