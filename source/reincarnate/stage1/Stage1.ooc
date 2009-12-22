import structs/ArrayList

import reincarnate/[App, Usefile, Version]

/** Stage1: getting the usefile. */
Stage1: abstract class {
    app: App
    
    init: func (=app) {
         
    }

    getUsefile: abstract func (location, ver: String) -> Usefile

    /* compare the versions! */
    hasUpdates: func (location: String, oldUsefile: Usefile) -> Bool {
        newUsefile := getUsefile(location, null)
        oldVersion := oldUsefile get("Version") as Version
        newVersion := newUsefile get("Version") as Version
        /* (this also handles `head`.) */
        return newVersion isGreater(oldVersion)
    }
}
