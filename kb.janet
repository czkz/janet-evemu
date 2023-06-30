(import ./evemu/event :as evemu-event)
(import ./evemu/keyconv)
(import ./cmd-queue)
(import ./input-device)

(var *delay*
  "Delay in seconds after each keyboard event."
  0)

(defn- eval-cmd-queue
  [device cmd-q]
  (each [key state] cmd-q
    (if (= :sleep key)
      (ev/sleep state)
      (do
        (evemu-event/emit device "EV_KEY" (keyconv/kw->code key) (if state "1" "0") true)
        (ev/sleep *delay*)))))

(defn type
  ``Simulate keyboard input.

  * "Hello, World!\n" -- type a string, using shift when nessessary

  * :enter -- type a key

  * [:ctrl :alt :del] -- type a key combo

  * [:ctrl [:c :v]] -- type two keys while holding :ctrl

  * 2.5 -- wait for 2.5 seconds
  ``
  [& args]
  (eval-cmd-queue input-device/device (cmd-queue/parse ;args)))

# Probably not useful
(comment
  (defn release-keys
    [& args]
    (def cmd-buf @[])
    (map
      |(:set-key cmd-buf $ false)
      args)
    (eval-cmd-queue input-device/device cmd-buf)))

(comment
  (do
    (ev/sleep 0.5)
    (type [:alt :tab] "Hello, World!")
    (ev/sleep 0.25)
    (type [:ctrl :c] [:alt :tab]))

  (do
    (ev/sleep 0.25)
    (type [:win :enter] 0.5
             "Hello, World!"
             [:ctrl :c] 0.5
             "exit\n"))

  (do
    (ev/sleep 2)
    (type "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ 1234567890!@#$%^&*()-=_+`~[]{}\\|;':\",./<>?")))
