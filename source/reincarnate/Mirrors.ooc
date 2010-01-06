import io/[File, FileReader]
import structs/[ArrayList, HashMap]
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
                buf append(";")
            else
                first = false
            buf append(mirror)
        }
        buf toString()
    },
    func (value: String) -> MirrorList {
        value split(";") toArrayList() as MirrorList
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

    /** submit the package to the super mirror. */
    submitPackage: func (package, ver, archive: String) {
        superMirrorUrl := app config get("Meatshop.SuperMirrorSubmit", String) format( \
                            app config get("Meatshop.SuperMirror", String)
                        )
        post := HashMap<String> new()
        archiveFile := File new(archive)
        baseName := archiveFile name()
        post put("package", package) .put("version", ver) .put("filename", baseName) .put("@archive", archive)
        s := app net downloadString(superMirrorUrl, post) 
        s println()
    }
}
