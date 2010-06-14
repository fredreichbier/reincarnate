import structs/ArrayList

import reincarnate/App

app := App new()

// TODO: Handling of no-param subcommands is hacky.

main: func (args: ArrayList<String>) -> Int {
    if(args size() < 2) {
        "Syntax: reincarnate install|update|remove|keep|unkeep|submit|add-key|build name" println()
        "        reincarnate list" println()
        return 1
    }
    
    match (args[1]) {
        case "list" =>
            "Installed packages:" println()
            for (info: ArrayList<String> in app installedPackages()) {
                "%s (%s, %s)" format(info[0], info[1], info[2]) println()
            }
            return 0
        
        case "update" =>
            if (args size() == 2) {
                app updateAll()
                return 0
            }
    }
    
    
    if(args size() < 3) {
        "Syntax: reincarnate install|update|remove|keep|unkeep|submit|add-key|build name" println()
        "        reincarnate list" println()
        println()
        "        Package name is required." println()
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
        case "build" => app build(name)
        case => "What's '%s'?" format(args[1]) println()
    }
    return 0
}
