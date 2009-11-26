import reincarnate/[Backend, Usefile, App, Net]

SimpleBackend: class extends Backend {
    installPackage: func (usefile: Usefile) {
        remoteLocation := usefile get("DownloadUrl") /* TODO: check! */
        localDestination := Net downloadPackage(remoteLocation)
        "%s is now at %s!" format(remoteLocation, localDestination) println()
    }

    removePackage: func (usefile: Usefile) {}
}
