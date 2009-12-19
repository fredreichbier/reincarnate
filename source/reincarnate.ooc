import reincarnate/App

main: func {
    app := App new()
    "yay" println()
    app doStage1("file://yajl.use")
}
