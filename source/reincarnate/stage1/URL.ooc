import reincarnate/[App, Net, Usefile]
import reincarnate/stage1/Stage1

URLS1: class extends Stage1 {
    init: func (.app) {
        this(app)
    }

    getUsefile: func (location, ver: String) -> Usefile {
        /* TODO: version check */
        Usefile new(Net downloadString(location))
    }
}
