import structs/[ArrayList,HashMap]

import io/FileReader
import reincarnate/Usefile

main: func {
    usefile := Usefile new(FileReader new("yajl.use")) as HashMap<String>
    usefile get("Libs") println()
}
