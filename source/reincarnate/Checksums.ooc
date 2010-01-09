import reincarnate/[FileSystem, Usefile]

Checksums: class extends Usefile {
    init: func ~dirtyWorkaroundSeeBug58 (pleasePassNullHere: Pointer) { /* TODO! */
        this T = String /* TODO: ugly :( */
        this as Usefile init() /* TODO: workaround. */
    }

    fill: func (fname: String) {
        "moo" println()
        sha512 := FileSystem getSha512(fname)
        sha512 println()
        put("SHA-512", sha512)
    }
}
 
