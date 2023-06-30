(import ./key-utils)

(defn set-key
  "Enqueue setting key to state."
  [cmd-queue key state]
  (assert (keyword? key))
  (assert (boolean? state))
  (array/push cmd-queue [key state]))

(defn click-key
  "Press and release key."
  [cmd-queue key]
  (set-key cmd-queue key true)
  (set-key cmd-queue key false))

(defn sleep
  "Wait for sec seconds."
  [cmd-queue sec]
  (array/push cmd-queue [:sleep sec]))

(defn type-string
  "Generate commands to type text."
  [cmd-queue text]
  (var shift-on? false)
  (defn ensure-shift [state]
    (when (not= shift-on? state)
      (set-key cmd-queue :shift state)
      (set shift-on? state)))
  (each char text
    (ensure-shift (key-utils/needs-shift? char))
    (click-key cmd-queue (key-utils/char->kw char)))
  (ensure-shift false)
  cmd-queue)

(defn- parse-simple-action
  [cmd-queue arg]
  (def f
    (case (type arg)
      :string type-string
      :keyword click-key
      :number sleep
      (error (string "unexpected argument " arg))))
  (f cmd-queue arg))

(defn- parse-simple-action*
  "Like parse-simple-action but also accepts tuples."
  [cmd-queue arg]
  (def f (partial parse-simple-action cmd-queue))
  (if (tuple? arg)
    (map f arg)
    (f arg))
  cmd-queue)

(defn key-combo
  ``Type a key combo, for example:
  
  * [:ctrl :alt :del] -- press :del while holding :ctrl and :alt

  * [:shift "uppercase"] -- type while holding :shift

  * [:shift [:u :p "percase"]] -- same as above

  * [:ctrl :alt [:f1 :f2 :f3]] -- while holding :ctrl :alt,
    sequentially press :f1, :f2, :f3
  ``
  [cmd-queue tup]
  (def mods (slice tup 0 -2))
  (map |(set-key cmd-queue $ true) mods)
  (parse-simple-action* cmd-queue (last tup))
  (map |(set-key cmd-queue $ false) (reverse mods))
  cmd-queue)

(defn- parse-complex-action
  [cmd-queue arg]
  (def f
    (case (type arg)
      :string type-string
      :keyword click-key
      :number sleep
      :tuple key-combo
      (error (string "unexpected argument " arg))))
  (f cmd-queue arg))

(defn parse
  "Parse a series of commands into a cmd-queue."
  [& args]
  (def cmd-queue @[])
  (map
    |(parse-complex-action cmd-queue $)
    args)
  cmd-queue)

(comment
  (assert (deep=
            (parse [:ctrl :c] "Hi !")
            @[[:ctrl true] [:c true] [:c false] [:ctrl false]
              [:shift true] [:h true] [:h false] [:shift false]
              [:i true] [:i false] [:space true] [:space false]
              [:shift true] [:1 true] [:1 false] [:shift false]])))
