import structs/Array

import reincarnate/App

main: func (args: Array<String>) -> Int {
    app := App new()
    if(args size() < 3) {
        "Syntax: reincarnate install|update|remove name" println()
        return 1
    }
    name := args[2]
    match (args[1]) {
        case "install" => app install(name)
        case "update" => app update(name)
        case "remove" => app remove(name)
        case => "What's '%s'?" format(args[1]) println()
    }
    return 0
}
