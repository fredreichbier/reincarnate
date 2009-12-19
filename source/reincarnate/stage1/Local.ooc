import io/FileReader

import reincarnate/Usefile
import reincarnate/stage1/Stage1

LocalS1: class extends Stage1 {
    init: func (.app) {
        this(app)
    }

    getUsefile: func (location, ver: String) -> Usefile {
        reader := FileReader new(location)
        /* TODO: version check */
        usefile := Usefile new(reader)
        reader close()
        return usefile
    }
}
