import structs/ArrayList

import reincarnate/Nirvana

main: func {
    nirvana := Nirvana new("http://nirvana.ooc-lang.org/api%s")
    for(category: String in nirvana getCategories()) {
        "Category: %s" format(category) println()
        for(package: String in nirvana getPackages(category)) {
            " * %s" format(package) println()
        }
    }
}
