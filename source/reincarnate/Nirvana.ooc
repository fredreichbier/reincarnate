import structs/ArrayList

import reincarnate/Net

Nirvana: class {
    urlTemplate: String

    init: func (=urlTemplate) {}

    _getUrl: func (path: String) -> String {
        urlTemplate format(path)
    }

    _downloadUrl: func (path: String) -> String {
        Net downloadString(_getUrl(path))
    }

    getCategories: func -> ArrayList<String> {
        _downloadUrl("/categories/") println()
        return ["Heya"] as ArrayList<String>
    }

    getPackages: func (category: String) -> ArrayList<String> {
    }
}
