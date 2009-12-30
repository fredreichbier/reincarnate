use yajl
 
import yajl/Yajl

import structs/[ArrayList, HashMap]
 
import reincarnate/[App, Net, Usefile, Version]
 
APIException: class extends Exception {
    init: func ~withMsg (.msg) {
        super(msg)
    }
}
 
Nirvana: class {
    app: App
    usefileTemplate, apiTemplate, user, apiToken: String
 
    init: func (=app, =apiTemplate, =usefileTemplate) {}
    init: func ~fromConfig (=app) {
        apiTemplate = app config get("Nirvana.APITemplate", String) as String
        usefileTemplate = app config get("Nirvana.UsefileTemplate", String) as String
        user = app config get("Nirvana.User", String) as String
        apiToken = app config get("Nirvana.Token", String) as String
    }
 
    _getUrl: func (path: String) -> String {
        apiTemplate format(path)
    }
 
    _downloadUrl: func (path: String, post: HashMap<String>) -> String {
        Net downloadString(_getUrl(path), post)
    }

    _downloadUrl: func ~noPost (path: String) -> String { _downloadUrl(path, null) }
 
    _interpreteUrl: func (path: String, post: HashMap<String>) -> ValueMap {
        content := _downloadUrl(path, post)
        parser := SimpleParser new()
        parser parseAll(content)
        value := parser getValue(ValueMap) as ValueMap /* TODO: what if we don't get a ValueMap? */
        // did we get an error?
        s := value get("__result", String)
        if(s equals("error")) {
            APIException new(This, "Error when reading `%s`: %s" format(path, value get("__text", String))) throw()
        }
        value remove("__result")
        value
    }
    _interpreteUrl: func ~noPost (path: String) -> ValueMap { _interpreteUrl(path, null) }
 
    getCategories: func -> ArrayList<String> {
        map := _interpreteUrl("/categories/")
        return map keys
    }
 
    getPackages: func (category: String) -> ArrayList<String> {
        map := _interpreteUrl("/category/%s/" format(category))
        return map keys
    }
 
    getVersions: func (package: String) -> ArrayList<Version> {
        map := _interpreteUrl("/packages/%s/" format(package))
        return map keys as ArrayList<Version>
    }
 
    getUsefilePath: func (package: String, ver: String) -> String {
        map := _interpreteUrl("/packages/%s/%s/" format(package, ver))
        return map get("usefile", String)
    }
 
    getUsefile: func (package: String, ver: String) -> String {
        return Net downloadString(usefileTemplate format(getUsefilePath(package, ver)))
    }
 
    getLatestUsefile: func (package: String) -> String {
        getUsefile(package, "latest")
    }

    submitUsefile: func (user, apiToken, slug, versionName: String, usefile: Usefile, makeLatest: Bool) -> String {
        post := HashMap<String> new()
        post put("usefile", usefile dump()) \
            .put("user", user) \
            .put("token", apiToken) \
            .put("name", versionName) \
            .put("slug", slug) \
            .put("make_latest", makeLatest ? "true" : "false")
        map := _interpreteUrl("/submit/", post)
        /* errors were checked. */
        return _getUrl(map get("path"))
    }

    submitUsefile: func ~fromConfig (slug, versionName: String, usefile: Usefile, makeLatest: Bool) -> String {
        if(user == "" || apiToken == "")
            APIException new(This, "No username and/or api key given in the config.") throw()
        submitUsefile(user, apiToken, slug, versionName, usefile, makeLatest)
    }
}
 
