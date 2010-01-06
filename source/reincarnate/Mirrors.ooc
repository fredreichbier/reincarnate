import structs/ArrayList
import text/[StringBuffer, StringTokenizer]

import gifnooc/Serialize

import reincarnate/App

MirrorList: class extends ArrayList<String> {
    init: func ~withCapacity (.capacity) {
        T = String
        super(capacity)
    }

    init: func ~withData (.data, .size) {
        T = String
        super(data, size)
    }
}

operator as (data: String*, size: SizeT) -> MirrorList {
    MirrorList new(data, size)
}

Registrar addEntry(MirrorList,
    func (value: MirrorList) -> String {
        buf := StringBuffer new()
        first := true
        for(mirror: String in value) {
            if(!first)
                buf append(":")
            else
                first = false
            buf append(mirror)
        }
        buf toString()
    },
    func (value: String) -> MirrorList {
        value split(":") toArrayList() as MirrorList
    },
    func (value: MirrorList) -> Bool { true },
    func (value: String) -> MirrorList { true }
)

Mirrors: class {
    app: App
    
    init: func (=app) {
        
    }

    getRelativeUrl: func (package, ver, filename: String) -> String {
        scheme := app config get("Meatshop.RelativeFilenameScheme", String) 
        scheme format(package, ver, filename)
    }

    getUrl: func (package, ver, filename: String) -> String {
        mirrorList := app config get("Meatshop.Mirrors", MirrorList)
        mirrorList get(0) append(getRelativeUrl(package, ver, filename)) /* TODO: don't get 0 always */
    }
}
