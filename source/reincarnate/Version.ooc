import structs/ArrayList
import text/StringTokenizer

VersionParsingError: class extends Exception {
    init: func ~withMsg (.msg) {
        this(msg)
    }
}

Version: cover from String {
    new: static func ~withString (s: String) -> This {
        return s clone() as Version
    }
    
    fromLocation: static func (location: String) -> This {
        if(location contains('=')) {
            /* contains a version */
            splitted := location split('=', 1) toArrayList()
            package := splitted get(0)
            ver := splitted get(1)
            if(ver == null) {
                VersionParsingError new(This, "Invalid location: '%s'" format(location)) throw()
            }
            return Version new(ver)
        } else {
            /* no version. return null. */
            return null
        }
    }
}
