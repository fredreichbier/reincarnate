import structs/[Array, ArrayList]

import reincarnate/App

main: func (args: Array<String>) -> Int {
    app := App new()
    if(args size() < 3) {
        "Syntax: reincarnate install|update|remove|keep|unkeep name" println()
        return 1
    }
    name := args[2]
    match (args[1]) {
        case "install" => app install(name)
        case "update" => app update(name)
        case "remove" => app remove(name)
        case "keep" => app keep(name)
        case "unkeep" => app unkeep(name)
        case "submit" => app submit(name, args size() > 3 ? args[3] : null)
        case => "What's '%s'?" format(args[1]) println()
    }
    return 0
}
