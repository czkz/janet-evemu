(import ./evemu)
(import ./cmd-gen)
(use ./input-device)

(var *delay*
  "Delay in seconds after each keyboard event."
  0)

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
  (eval-cmds device (cmd-gen/parse ;args)))

# Probably not useful
(comment
  (defn release-keys
    [& args]
    (def cmd-buf @[])
    (map
      |(:set-key cmd-buf $ false)
      args)
    (eval-cmds device cmd-buf)))

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
