(import ./evemu)
(import ./kb-ev)

# Get a similar description with evemu-describe
# The first line is mandatory
(def- kb-device-desc
  (->>
    ``# EVEMU 1.3
    N: janet keyboard
    I: 0003 4711 0815 0001
    P: 00 00 00 00 00 00 00 00
    B: 00 0b 00 00 00 00 00 00 00
    B: 01 fe ff ff ff ff ff ff ff
    B: 01 ff ff ff ff ff ff ff ff
    B: 01 ff ff ff ff ff ff ff ff
    B: 01 ff ff ff ff ff ff ff 01
    B: 01 00 00 00 00 00 00 00 00
    B: 01 00 00 00 00 00 00 00 00
    B: 01 00 00 00 00 00 00 00 00
    B: 01 00 00 00 00 00 00 00 00
    B: 01 00 00 00 00 00 00 00 00
    B: 01 00 00 00 00 00 00 00 00
    B: 01 00 00 00 00 00 00 00 00
    B: 01 00 00 00 00 00 00 00 00
    B: 02 00 00 00 00 00 00 00 00
    B: 03 00 00 00 00 00 00 00 00
    B: 04 00 00 00 00 00 00 00 00
    B: 05 00 00 00 00 00 00 00 00
    B: 11 00 00 00 00 00 00 00 00
    B: 12 00 00 00 00 00 00 00 00
    B: 14 00 00 00 00 00 00 00 00
    B: 15 00 00 00 00 00 00 00 00
    B: 15 00 00 00 00 00 00 00 00
    ``
    (string/split "\n")
    (map string/trim)
    (mapcat |[$ "\n"])
    (string/join)))

(var *delay*
  "Delay in seconds after each keyboard event."
  0)

(def- kb-device (evemu/make-device kb-device-desc))
(comment
  (-> (kb-device :process) :kill :wait))

(defn- eval-cmds
  [device cmds]
  (each [key state] cmds
    (if (= :sleep key)
      (ev/sleep state)
      (do
        (evemu/event device "EV_KEY" key state true)
        (ev/sleep *delay*)))))

(defn type
  ``Simulate keyboard input.

  * "Hello, World!\n" -- type a string, using shift when nessessary

  * :enter -- type a key

  * [:ctrl :alt :del] -- type a key combo

  * [:ctrl [:c :v]] -- type two keys while holding :ctrl

  * 2.5 -- sleep for 2.5 seconds
  ``
  [& args]
  (pp (kb-ev/parse ;args))
  (eval-cmds kb-device (kb-ev/parse ;args)))

# Probably not useful
(comment
  (defn release-keys
    [& args]
    (def cmd-buf @[])
    (map
      |(:set-key cmd-buf $ false)
      args)
    (eval-cmds kb-device cmd-buf)))

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
    (type ``abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ 1234567890!@)))#$%^&*()-=_+`~[]{}\|;':",./<>?``)))
