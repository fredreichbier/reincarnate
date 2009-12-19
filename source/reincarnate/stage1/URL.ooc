import reincarnate/[App, FileSystem, Net, Usefile]
import reincarnate/stage1/Stage1

URLS1: class extends Stage1 {
    init: func (.app) {
        this(app)
    }

    getUsefile: func (location, ver: String) -> Usefile {
        /* TODO: version check */
        usefile := Usefile new(Net downloadString(location))
        slug := Net getBaseName(location)
        FileSystem splitExt(slug, slug&, null)
        usefile put("_Slug", slug)
        return usefile
    }
}
