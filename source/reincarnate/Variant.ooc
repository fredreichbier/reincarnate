VariantParsingError: class extends Exception {
    init: super func
}

Variant: class extends String {
    init: func ~fromString (s: String) {
        _buffer = s clone() _buffer // we're evil like that
    }

    // TODO: Use a path splitter function? File name?
    fromLocation: static func (location: String) -> This {
        if(location contains?('/')) {
            /* contains? a version */
            idx := location lastIndexOf('/')
            //package := location substring(0, idx)
            variant := location substring(idx + 1)
            if(variant empty?()) {
                VariantParsingError new(This, "Invalid location: '%s'" format(location)) throw()
            }
            return This new(variant)
        } else {
            /* no version. return null. */
            return null as Variant
        }
    }
}
