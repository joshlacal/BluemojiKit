/// A size-bounded cache with FIFO eviction — keeps memory bounded across a long
/// app session. Not thread-safe on its own; use only from an actor.
struct BoundedCache<Key: Hashable, Value> {
  private var storage: [Key: Value] = [:]
  private var insertionOrder: [Key] = []
  private let limit: Int

  init(limit: Int) { self.limit = max(1, limit) }

  func value(forKey key: Key) -> Value? { storage[key] }

  mutating func set(_ value: Value, forKey key: Key) {
    if storage[key] == nil {
      insertionOrder.append(key)
      if insertionOrder.count > limit {
        let evicted = insertionOrder.removeFirst()
        storage[evicted] = nil
      }
    }
    storage[key] = value
  }
}
