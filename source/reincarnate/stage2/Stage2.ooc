import reincarnate/[App, Usefile, Package]

Stage2: abstract class {
    app: App

    getPackage: abstract func (usefile: Usefile) -> Package
}
