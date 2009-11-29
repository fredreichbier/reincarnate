import reincarnate/Usefile

Frontend: abstract class {
    downloadTo: abstract func (usefile: Usefile, destination: String)
    accept: abstract func (usefile: Usefile) -> Bool
}

SimpleFrontend: abstract class extends Frontend {
    slug: static String
    accept: func (usefile: Usefile) -> Bool {
        frontendSlug := usefile get("DownloadFrontend")
        if(!frontendSlug) {
            return false
        } else {
            return frontendSlug equals(slug)
        }
    }
}

FrontendError: class extends Exception {
    init: func ~withMsg (.msg) {
        super(msg)
    }
}
