(import ./evemu)

# Get a similar description with evemu-describe
# The first line is mandatory
(def- device-desc
  (->>
    ``# EVEMU 1.3
    N: janet input device
    I: 0003 4711 0815 0001
    P: 00 00 00 00 00 00 00 00
    B: 00 0b 00 00 00 00 00 00 00
    B: 01 fe ff ff ff ff ff ff ff
    B: 01 ff ff ff ff ff ff ff ff
    B: 01 ff ff ff ff ff ff ff ff
    B: 01 ff ff ff ff ff ff ff 01
    B: 01 00 00 ff 00 00 00 00 00
    B: 02 43 19 00 00 00 00 00 00
    B: 03 03 00 00 00 00 00 00 00
    A: 00 0 10000 0 0 0
    A: 01 0 10000 0 0 0
    ``
    (string/split "\n")
    (map string/trim)
    (mapcat |[$ "\n"])
    (string/join)))

(def device (evemu/make-device device-desc))

(comment (-> (device :process) :kill :wait))