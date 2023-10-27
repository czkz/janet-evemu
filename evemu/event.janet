(defn- spawn-evemu-event
  [device-path sync? type code value]
  (os/spawn
    ["evemu-event" device-path
     ;(if sync? ["--sync"] [])
     "--type" type
     "--code" code
     "--value" value]
    :px))

(defn wait-for-unsynced
  "Wait for any unsynced events, but don't sync."
  [device]
  (def events (device :pending-events))
  (map :wait events)
  (array/clear events))

(defn emit [device type code value sync]
  "Spawn evemu-event asynchronously. Wait for any unsynced events if sync is true."
  (if sync
    (do
      (wait-for-unsynced device)
      (:wait (spawn-evemu-event (device :path) true type code value)))
    (array/push
      (device :pending-events)
      (spawn-evemu-event (device :path) false type code value)))
  nil)

# Worse than when the last event has --sync
(defn sync [device]
  "Sync any unsynced events."
  (unless (empty? (device :pending-events))
    (wait-for-unsynced device)
    (:wait (spawn-evemu-event (device :path) true "0" "0" "0"))))

