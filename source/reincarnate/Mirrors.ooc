use curl
use gifnooc
use deadlogger

import io/[File, FileReader, FileWriter]
import structs/[ArrayList, HashMap]
import text/[Buffer, StringTokenizer, StringTemplate]

import curl/Highlevel
import gifnooc/Serialize
import deadlogger/Log

import reincarnate/[App, Net, Config]

logger := Log getLogger("reincarnate.Mirrors")

MirrorList: class extends ArrayList<String> {
    init: func ~withCapacity (.capacity) {
        T = String
        super(capacity)
    }

    init: func ~withData (.data, .size) {
        T = String
        super(data, size)
    }

    init: func {
        T = String
        super()
    }
}

//operator as (data: String*, size: SizeT) -> MirrorList {
//    MirrorList new(data, size)
//}

Registrar addEntry(MirrorList,
    func (value: MirrorList) -> String {
        buf := Buffer new()
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
    func (value: String) -> MirrorList { // TODO TODO TODO
        //list := value split(";") as ArrayList<String>
        //MirrorList new(list data, list size)
        
        list := MirrorList new()
        list add(value)
        list
    },
    func (value: MirrorList) -> Bool { true },
    func (value: String) -> Bool { true }
)

Mirrors: class {
    app: App
    
    init: func (=app) {}

    download: func (package, ver, variant: String) -> String { // TODO TODO TODO TODO TODO
    /*
        mirrorList := app config get("Meatshop.Mirrors", MirrorList)
        scheme := app config get("Meatshop.RelativeFilenameScheme", String)
        map := HashMap<String, String> new()
        map put("package", package) .put("version", ver) .put("variant", variant)
        types := app config get("Meatshop.FileTypes", ExtList)
        logger info("Trying to download %s=%s/%s from the meatshop" format(package, ver, variant))
        gotcha := false
        for(mirror in mirrorList) {
            for(type in types) {
                map put("type", type)
                dest := app fileSystem getPackageFilename("{{ package }}-{{ version }}-{{ variant }}.{{ type }}" formatTemplate(map)) // TODO: not nice.
                writer := FileWriter new(dest)
                url := mirror + scheme formatTemplate(map)
                logger debug("Trying %s to %s ..." format(url, dest))
                curl := HTTPRequest new(url, writer)
                Net _performRequest(curl)
                writer close()
                if(curl getResponseCode() == 200) {
                    // yay! gotcha! we can break now.
                    return dest
                }
                logger debug("No success.")
            }
        }
        Exception new(This, "Couldn't download %s=%s/%s from the meatshop." format(package, ver, variant)) throw()
        null*/
        ""
    }

    /** submit the package to the super mirror. */
    submitPackage: func (user, token, package, ver, variant, archive: String) {
        superMirrorUrl := app config get("Meatshop.SuperMirrorSubmit", String) format( \
                            app config get("Meatshop.SuperMirror", String)
                        )
        post := HashMap<String, String> new()
        /* figure out the extension. */
        archiveFile := File new(archive)
        baseName := archiveFile name()
        before := baseName
        ext_tmp := ""
        ext := ""
        /* TODO: that will only work for .tar.*. What about zip? */
        app fileSystem splitExt(baseName, before&, ext_tmp&)
        app fileSystem splitExt(before, null, ext&)
        ext = ext substring(1) + ext_tmp /* kick the first dot */
        /* Fill the POST data */
        post put("package", package) \
            .put("version", ver) \
            .put("variant", variant) \
            .put("ext", ext) \
            .put("user", user) \
            .put("token", token)
        formData := FormData new(post)
        formData addFieldFile("archive", archiveFile path)
        /* finally, do the request. */
        request := HTTPRequest new(superMirrorUrl)
        request setFormData(formData)
        Net _performRequest(request)
        request getString() println()
    }

    submitPackage: func ~defaultUser (package, ver, variant, archive: String) {
        user := app config get("Nirvana.User", String)
        apiToken := app config get("Nirvana.Token", String)
        if(user == "" || apiToken == "")
            Exception new(This, "No username and/or api key given in the config.") throw()
        submitPackage(user, apiToken, package, ver, variant, archive)    
    }
}
