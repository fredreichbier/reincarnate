import reincarnate/[App, Usefile]

/** Stage1: getting the usefile. */
Stage1: abstract class {
    app: App
    
    init: func (=app) {
         
    }

    getUsefile: abstract func (location, ver: String) -> Usefile
}
