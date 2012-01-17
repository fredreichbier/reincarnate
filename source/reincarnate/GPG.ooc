import io/File
import os/[Pipe, Process]
import structs/ArrayList

import reincarnate/[App, Checksums]

GPG: class {
    app: App
    keyring, executable: File
    commonArgs: ArrayList<String>

    init: func (=app) {
        this keyring = app config get("GPG.Keyring", File)
        this executable = app config get("GPG.Executable", File)
        this commonArgs = [executable path, "--no-default-keyring", "--keyring", keyring path] as ArrayList<String>
        /* TODO: nice NullPointerExceptions without `this` */
    }

    _executeGPG: func (gpgArgs: ArrayList<String>, output: String*) -> Int {
        args := commonArgs clone()
        args addAll(gpgArgs)
        app fileSystem _executeWithOutput(args, output)
    }

    _ensureCorrect: func (code: Int) {
        if(code != 0)
            Exception new(This, "gpg returned an unhealthy return code: %d" format(code)) throw()
    }

    addKey: func (key: String) {
        output: String
        ret := _executeGPG(["--import", key] as ArrayList<String>, output&)
        _ensureCorrect(ret)
    }

    verify: func (signature: String, file: File) -> Bool {
        args := commonArgs clone()
        args add("--verify") .add(file getPath()) .add("-")
        proc := Process new(args)
        proc setStdin(Pipe new()) 
        proc executeNoWait()
        /* send the signature to stdin */
        result := proc communicate(signature, null, null)
        /* if result == 0, the signature was verified. */
        result == 0
    }
}
