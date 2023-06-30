(import ./evdev-keys)

(defn- set-key
  [cmd-buf key state]
  (def keycode (evdev-keys/kw->code key))
  (assert keycode (string "invalid key " key))
  (array/push cmd-buf [keycode (if state "1" "0")]))

(defn- type-text
  [cmd-buf text]
  (var shift-on? false)
  (defn ensure-shift [state]
    (when (not= shift-on? state)
      (array/push cmd-buf ["KEY_LEFTSHIFT" (if state "1" "0")])
      (set shift-on? state)))
  (each char text
    (ensure-shift (evdev-keys/needs-shift? char))
    (def keycode (evdev-keys/char->code char))
    (assert keycode (string "invalid char " (string/from-bytes char)))
    (array/push cmd-buf [keycode "1"])
    (array/push cmd-buf [keycode "0"]))
  (ensure-shift false)
  cmd-buf)

(defn- press-key
  [cmd-buf key]
  (set-key cmd-buf key true)
  (set-key cmd-buf key false))

(defn- sleep
  [cmd-buf sec]
  (array/push cmd-buf [:sleep sec]))

(defn- simple-action
  [cmd-buf arg]
  (def f
    (case (type arg)
      :string type-text
      :keyword press-key
      :number sleep
      (error (string "unexpected argument " arg))))
  (f cmd-buf arg))

(defn- simple-action*
  "Like simple-action but also accepts tuples."
  [cmd-buf arg]
  (def f (partial simple-action cmd-buf))
  (if (tuple? arg)
    (map f arg)
    (f arg))
  cmd-buf)

(defn- combo
  ``Type a key combo, for example:
  
  * [:ctrl :alt :del] -- press :del while holding :ctrl and :alt

  * [:shift "uppercase"] -- type while holding :shift

  * [:shift [:u :p "percase"]] -- same as above

  * [:ctrl :alt [:f1 :f2 :f3]] -- while holding :ctrl :alt,
    sequentially press :f1, :f2, :f3
  ``
  [cmd-buf tup]
  (def mods (slice tup 0 -2))
  (map |(set-key cmd-buf $ true) mods)
  (simple-action* cmd-buf (last tup))
  (map |(set-key cmd-buf $ false) (reverse mods))
  cmd-buf)

(defn- complex-action
  [cmd-buf arg]
  (def f
    (case (type arg)
      :string type-text
      :keyword press-key
      :number sleep
      :tuple combo
      (error "Unexpected type")))
  (f cmd-buf arg))

(defn parse
  [& args]
  (def cmd-buf @[])
  (map
    |(complex-action cmd-buf $)
    args)
  cmd-buf)
