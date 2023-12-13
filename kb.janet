(import ./evemu/event :as evemu-event)
(import ./evemu/keyconv)
(import ./cmd-queue)
(import ./event-monitor)
(import ./input-device)

(var *delay*
  "Delay in seconds after each keyboard event."
  0)

(defn- eval-cmd-queue
  [device cmd-q]
  (def held @{})
  (edefer
    (eachk key held
      (evemu-event/emit device "EV_KEY" (keyconv/kw->code key) "0" false)
      (evemu-event/sync device))
    (each [key state] cmd-q
      (if (= :sleep key)
        (ev/sleep state)
        (do
          (if state
            (put held key 1)
            (put held key nil))
          (evemu-event/emit device "EV_KEY" (keyconv/kw->code key) (if state "1" "0") true)
          (ev/sleep *delay*))))))

(defn type
  ``Simulate keyboard input.

  * "Hello, World!\\n" -- type a string, using shift when nessessary

  * :enter -- type a key

  * [:ctrl :alt :del] -- type a key combo

  * [:ctrl [:c :v]] -- type two keys while holding :ctrl

  * 2.5 -- wait for 2.5 seconds
  ``
  [& args]
  (eval-cmd-queue (input-device/device) (cmd-queue/parse ;args)))

# Probably not useful
(comment
  (defn release-keys
    [& args]
    (def cmd-buf @[])
    (map
      |(:set-key cmd-buf $ false)
      args)
    (eval-cmd-queue (input-device/device) cmd-buf)))

(defn- on*
  [key state func]
  (with [waiter (event-monitor/make-waiter state key)]
    (forever
      (:wait waiter)
      (func))))

(defn- spawn-runner
  [func err-sym]
  (ev/spawn
    (try (forever (func))
      ([err] (unless (= err err-sym)
               (error err))))))

(defn- until-pressed*
  [key state func]
  (with [waiter (event-monitor/make-waiter :down key)]
    (def err-sym (gensym))
    (def fib (spawn-runner func err-sym))
    (:wait waiter)
    (ev/cancel fib err-sym)))

(defn- toggle-on*
  [key func]
  (with [waiter (event-monitor/make-waiter :down key)]
    (def err-sym (gensym))
    (forever
      (:wait waiter)
      (def fib (spawn-runner func err-sym))
      (:wait waiter)
      (ev/cancel fib err-sym))))

(defn- while-held*
  [key func]
  (with [waiter-down (event-monitor/make-waiter :down key)]
    (with [waiter-up (event-monitor/make-waiter :up key)]
      (def err-sym (gensym))
      (forever
        (:wait waiter-down)
        (def fib (spawn-runner func err-sym))
        (:wait waiter-up)
        (ev/cancel fib err-sym)))))

(defn- on-pair*
  [key on-down on-up]
  (with [waiter-down (event-monitor/make-waiter :down key)]
    (with [waiter-up (event-monitor/make-waiter :up key)]
      (forever
        (:wait waiter-down)
        (on-down)
        (:wait waiter-up)
        (on-up)))))

(defmacro on
  "Evaluate body each time the key is pressed."
  [key & body]
  ~(,on* ,key :down (fn [] ,;body)))

(defmacro on-up
  "Evaluate body each time the key is released."
  [key & body]
  ~(,on* ,key :up (fn [] ,;body)))

(defmacro on-pair
  "Evaluate on-down and on-up accordingly."
  [key on-down on-up]
  ~(,on-pair* ,key (fn [] ,on-down) (fn [] ,on-up)))

(defmacro until
  "Repeatedly evaluate body until the key is pressed."
  [key & body]
  ~(,until-pressed* ,key :down (fn [] ,;body)))

(defmacro toggle-on
  ``Start repeatedly evaluating body after the key is pressed
  and stop when it is pressed again.
  ``
  [key & body]
  ~(,toggle-on* ,key (fn [] ,;body)))

(defmacro while-held
  "Repeatedly evaluate body while the key is held down."
  [key & body]
  ~(,while-held* ,key (fn [] ,;body)))

# Test for stuck keys after an exception
(comment
  (do
    (ev/sleep 1)
    (ev/deadline 1)
    (kb/type "a" [:shift [3 "b"]])))

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
