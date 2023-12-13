(defn runner-fn []
  (import ./kb)
  (import ./mouse)
  (import ./record)
  (printf "%M" (eval-string (yield))))

(def runner
  (fiber/new runner-fn :y (make-env)))

# Imports must happen at compile time
(resume runner)

(defn- print-code* [lines]
  (def name (0 (dyn :args)))
  (map
    |(printf "\t%s '%N'" name $)
    lines))

(defmacro- print-code [& lines]
  ~(print-code* ',lines))

(defn- usage []
  (def [_ & args] (dyn :args))
  (when (or
          (not= 1 (length args))
          (= (0 args) "-h")
          (= (0 args) "--help"))
    (print "Docs:")
    (print-code
      (doc kb/type)
      (doc mouse/at))
    (print "Examples:")
    (print-code
      (kb/type 0.5 "Hello")
      (mouse/at 0.5 0.5 :right))
    (printf "\t%s '%N %N %N'" (0 (dyn :args))
      ;'[(mouse/to 0.25 0.5) (ev/sleep 1) (mouse/to 0.75 0.5)])
    (print-code
      (record/mouse-pos)
      (kb/on :lmb (os/shell "whoami"))
      (kb/on-pair :lmb (print "Pressed") (print "Released")))
    (print "\nFunctions:")
    (each e (sort (keys (fiber/getenv runner)))
      (printf "\t%N" e))
    (os/exit 1)))

(defn main [_ & args]
  (usage)
  (resume runner (0 args)))
