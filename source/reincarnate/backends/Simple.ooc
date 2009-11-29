import reincarnate/[Backend, Usefile, App, Net, FileSystem]

SimpleBackend: class extends Backend {
    installPackage: func (usefile: Usefile) {
        destination := app downloadPackage(usefile)
        app fileSystem copyContentsToLibdir(destination) /* TODO. */
    }

    removePackage: func (usefile: Usefile) {}
}
