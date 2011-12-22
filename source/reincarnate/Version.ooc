import structs/ArrayList
import text/[StringTokenizer]

VersionParsingError: class extends Exception {
    init: super func
}

_digit?: func (s: String) -> Bool {
    for(c: Char in s) {
        if(!c digit?())
            return false
    }
    return true
}

_alpha?: func (s: String) -> Bool {
    for(c: Char in s) {
        if(!c alpha?())
            return false
    }
    return true
}

ALPHA_RANKS := ArrayList<String> new()
ALPHA_RANKS add("a") .add("alpha") .add("b") .add("beta") .add("dev")

Version: class extends String {
    init: func ~fromString (s: String) {
        _buffer = s clone() _buffer // we're evil like that
    }

    fromLocation: static func (location: String) -> This {
        if(location contains?('=')) {
            /* contains? a version */
            splitted := location split('=', 1)
            package := splitted get(0)
            ver := splitted get(1)
            if(ver == null) {
                VersionParsingError new(This, "Invalid location: '%s'" format(location)) throw()
            }
            return Version new(ver)
        } else {
            /* no version. return null. */
            return null as This
        }
    }

    /**
      * @return a splitted version. Every element is either a number (as string) or a name (as string).
      *         Example: "0.1-3beta" -> ["0", "1", "3", "beta"]
      */
    _splitVersion: func -> ArrayList<String> {
        DUNNO := const 0
        NUMBER := const 1
        NAME := const 2
        splitted := ArrayList<String> new()
        current := Buffer new()

        state := DUNNO
        for(i: SizeT in 0..length()) {
            chr := this[i]
            match state {
                case DUNNO => {
                    if(chr digit?()) {
                        state = NUMBER
                        current append(chr)
                    } else if(chr alpha?()) {
                        state = NAME
                        current append(chr)
                    }
                }
                case NUMBER => {
                    if(chr digit?()) {
                        current append(chr)
                    } else if(chr alpha?()) {
                        /* a name follows! */
                        splitted add(current toString())
                        current = Buffer new()
                        state = NAME
                        current append(chr)
                    } else {
                        /* dunno follows. */
                        splitted add(current toString())
                        current = Buffer new()
                        state = DUNNO
                    }
                }
                case NAME => {
                    if(chr alpha?()) {
                        current append(chr)
                    } else if(chr digit?()) {
                        /* a digit follows! */
                        splitted add(current toString())
                        current = Buffer new()
                        state = NUMBER
                        current append(chr)
                    } else {
                        /* dunno follows. */
                        splitted add(current toString())
                        current = Buffer new()
                        state = DUNNO
                    }
                }
            }
        }
        /* don't leave anything! */
        splitted add(current toString())
        return splitted
    }

    /**
      * @return true if `this` is greater than `other`.
      */
    isGreater: func (other: This) -> Bool {
        /* `head` beats everything, except `head`. */
        if(this == "head")
            return !(other == "head")
        /*
            "0.1" > "0.0.1"
            "0.1b" > "0.1a"
            "456" > "123"
            "0.1-123b" > "0.1-123a"
        */
        thisParts := toLower() as Version _splitVersion()
        otherParts := other toLower() as Version _splitVersion()
        thisPart := null as String
        otherPart := null as String
        i := 0
        while(true) {
            /* if `this` is shorter than `other`, `this` is greater than `other` IF:
             *  - `other`'s next part is "alpha", "beta", "a", "b" or "dev".
             * otherwise, `this` is smaller.
             */
            if(i == thisParts size && i < otherParts size) {
                match(otherParts[i]) {
                    case "a" => return true
                    case "b" => return true
                    case "alpha" => return true
                    case "beta" => return true
                    case "dev" => return true
                    case => return false
                }
            }
            else if(i == otherParts size && i < thisParts size) {
                match(thisParts[i]) {
                    case "a" => return false 
                    case "b" => return false
                    case "alpha" => return false
                    case "beta" => return false
                    case "dev" => return false
                    case => return true
                }
            }
            else if(i == otherParts size && i == thisParts size) {
                break
            }
            else {
                thisPart = thisParts get(i)
                otherPart = otherParts get(i)
                /* is `this` alpha and `other` numeric? then, `other` is greater. */ /* TODO: too easy? */
                if (_alpha?(thisPart) && !_alpha?(otherPart)) {
                    return false
                }
                /* vice-versa. */
                else if (!_alpha?(thisPart) && _alpha?(otherPart)) {
                    return true
                }
                /* are both alpha? */
                else if(_alpha?(thisPart) && _alpha?(otherPart)) {
                    for(rank: String in ALPHA_RANKS) {
                        if(rank equals?(thisPart)) {
                            /* this matches before other, this is smaller. */
                            return false
                        } else if(rank equals?(otherPart)) {
                            /* other matches before this, this is greater. */
                            return true
                        }
                    }
                    /* both are non-standard ranks. compare the first character. TODO? */
                    if(thisPart[0] > otherPart[0]) {
                        return true
                    } else if(thisPart[0] < otherPart[0]) {
                        return false
                    } else {
                        /* same characters. hmmmmmmmmm. skip. */
                    }
                }
                /* are both numeric? */
                else {
                    /* compare the integer values. */
                    thisInt := thisPart toInt()
                    otherInt := otherPart toInt()
                    if(thisInt > otherInt)
                        return true
                    else if(thisInt < otherInt)
                        return false
                    /* otherwise: skip. */
                }
            }
            i += 1
        }
        /* not greater, but equal => false. */
        return false
    }

    /*
     * @return -1 if other is greater, 0 if equal, 1 if this is greater.
     */
    compareVersions: func (other: This) -> Int {
        thisGreater := this isGreater(other)
        otherGreater := other isGreater(this)
        if(thisGreater && otherGreater) {
            Exception new(This, "WTF? Both greater? NNNNOOOOOOOO!") throw()
        } else if(thisGreater && !otherGreater) {
            return 1
        } else if(!thisGreater && otherGreater) {
            return -1
        }
        return 0
    }
}
