import structs/ArrayList

import reincarnate/[Frontend, Usefile, FileSystem, Net, App]

FileFrontend: class extends SimpleFrontend {
    supported: ArrayList<String>

    init: func {
        supported = ["http", "ftp", "file"] as ArrayList<String> /* TODO: Workaround */
    }

    downloadTo: func (usefile: Usefile, destination: String) {
        remoteLocation := usefile get("DownloadUrl") /* TODO: check! */
        localDestination := Net downloadPackage(remoteLocation)
        "%s is now at %s!" format(remoteLocation, localDestination) println()
        app fileSystem extract(localDestination, destination)
    }

    accept: func (usefile: Usefile) -> Bool {
        if(super accept(usefile)) {
           return true 
        } else {
            scheme := Net getScheme(usefile get("DownloadUrl"))
            /* TODO: workaround for indexOf */
            for(s: String in supported) {
                if(s == scheme) {
                    return true
                }
            }
            return false
        }
    }
}



