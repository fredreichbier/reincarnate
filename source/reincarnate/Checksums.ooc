import reincarnate/[FileSystem, Usefile]

Checksums: class extends Usefile {
    init: func ~dirtyWorkaroundSeeBug58 (pleasePassNullHere: Pointer) { /* TODO! */
        this K = String /* TODO: ugly :( */
        this V = String
        this as Usefile init() /* TODO: workaround. */
    }

    fill: func (fname: String) {
        sha512 := FileSystem getSha512(fname)
        put("SHA-512", sha512)
    }

    check: func (fname: String) -> Bool {
        /* TODO: check if empty */
        for(key: String in this getKeys()) {
            match(key) {
                case "SHA-512" => {
                    if(this get(key) != FileSystem getSha512(fname)) {
                        return false
                    }
                }
                case => {
                    Exception new("Unknown checksum: %s" format(key))
                }
            }
        }
        return true
    }
}
 
