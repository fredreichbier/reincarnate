import structs/ArrayList

import reincarnate/[App, Usefile, Version]

/** Stage1: getting the usefile. */
Stage1: abstract class {
    app: App
    
    init: func (=app) {}

    getUsefile: abstract func (location, ver, variant: String) -> Usefile

    /* compare the versions! */
    hasUpdates: func (location: String, oldUsefile: Usefile) -> Bool {
        newUsefile := getUsefile(location, null, oldUsefile get("Variant"))
        oldVersion := oldUsefile get("Version") 
        newVersion := newUsefile get("Version") 
        /* (this also handles `head`.) */
        return Version isGreater(newVersion, oldVersion)
    }
}
