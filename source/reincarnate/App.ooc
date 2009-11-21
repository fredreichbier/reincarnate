import reincarnate/config

App: class {
    config: Config

    init: func {
        config = Config new("reincarnate.json")
    }
}
