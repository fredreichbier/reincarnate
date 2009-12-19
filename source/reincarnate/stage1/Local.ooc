import io/[File, FileReader]

import reincarnate/[FileSystem, Usefile]
import reincarnate/stage1/Stage1

LocalS1: class extends Stage1 {
    init: func (.app) {
        this(app)
    }

    getUsefile: func (location, ver: String) -> Usefile {
        reader := FileReader new(location)
        /* TODO: version check */
        usefile := Usefile new(reader)
        /* get the slug. TODO: please check */
        slug := File new(location) name()
        app fileSystem splitExt(slug, slug&, null)
        usefile put("_Slug", slug)
        reader close()
        return usefile
    }
}
