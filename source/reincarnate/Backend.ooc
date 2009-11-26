import reincarnate/Usefile

Backend: abstract class {
    installPackage: abstract func (usefile: Usefile)
    removePackage: abstract func (usefile: Usefile)
}
