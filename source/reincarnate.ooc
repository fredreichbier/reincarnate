import structs/[Array, ArrayList]

import reincarnate/App

main: func (args: Array<String>) -> Int {
    app := App new()
    if(args size() < 3) {
        "Syntax: reincarnate install|update|remove|keep|unkeep|submit|add-key name" println()
        return 1
    }
    name := args[2]
    match (args[1]) {
        case "install" => app install(name)
        case "update" => app update(name)
        case "remove" => app remove(name)
        case "keep" => app keep(name)
        case "unkeep" => app unkeep(name)
        case "submit" => {
            archive := null
            if(args size() > 3)
                archive = args[3]
            app submit(name, archive)
        }
        case "add-key" => app addKey(name)
        case => "What's '%s'?" format(args[1]) println()
    }
    return 0
}
