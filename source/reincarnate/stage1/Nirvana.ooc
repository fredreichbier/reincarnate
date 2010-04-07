import structs/ArrayList

import reincarnate/[App, Nirvana, Usefile, Version]
import reincarnate/stage1/Stage1

NirvanaS1: class extends Stage1 {
    init: func (.app) {
        init(app)
    }

    getUsefile: func (location, ver, variant: String) -> Usefile {
        if(ver == null) {
            ver = "latest"
        }
        usefile := Usefile new(app nirvana getUsefile(location, ver, variant))
        usefile put("_Slug", location) \
               .put("_ChecksumsURL", app nirvana getChecksumsURL(location, ver, variant)) \
               .put("_ChecksumsSignatureURL", app nirvana getChecksumsSignatureURL(location, ver, variant))
        return usefile
    }
}
