import structs/ArrayList

import reincarnate/[App, FileSystem, Net, Usefile, Version]
import reincarnate/stage1/Stage1

URLS1: class extends Stage1 {
    init: func (.app) {
        this(app)
    }

    getUsefile: func (location, ver, variant: String) -> Usefile {
        /* TODO: version check */
        usefile := Usefile new(Net downloadString(location))
        slug := Net getBaseName(location)
        FileSystem splitExt(slug, slug&, null)
        usefile put("_Slug", slug)
        return usefile
    }
}
