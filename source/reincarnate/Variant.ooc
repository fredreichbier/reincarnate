import text/StringTokenizer
import structs/ArrayList

VariantParsingError: class extends Exception {
    init: super func
}

Variant: cover from String extends String {
    new: static func ~fromString (s: String) -> This {
        s clone() as Variant
    }

    // TODO: Use a path splitter function? File name?
    fromLocation: static func (location: String) -> This {
        if(location contains('/')) {
            /* contains a version */
            idx := location lastIndexOf('/')
            //package := location substring(0, idx)
            variant := location substring(idx + 1)
            if(variant isEmpty()) {
                VariantParsingError new(This, "Invalid location: '%s'" format(location)) throw()
            }
            return variant
        } else {
            /* no version. return null. */
            return ""
        }
    }
}
