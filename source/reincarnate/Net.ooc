use curl
use uriparser
 
import io/FileWriter
import structs/HashMap
import text/Buffer

import curl/Highlevel 
import uriparser/UriParser

import reincarnate/App
 
NetError: class extends Exception {
    init: func ~withMsg (.msg) {
        super(msg)
    }
}
 
Net: class {
    downloadString: static func (url: String) -> String {
        request := HTTPRequest new(url)
        _performRequest(request)
        request getString()
    }

    _performRequest: static func (request: HTTPRequest) {
        ret := request perform()
        if(ret != 0)
            NetError new(This, "Invalid CURL return value: %d" format(ret)) throw()
    }

    downloadFile: static func (url, fname: String) {
        writer := FileWriter new(fname)
        request := HTTPRequest new(url, writer)
        _performRequest(request)
        writer close()
    }

    getBaseName: static func (url: String) -> String {
        state := ParserState new()
        uri := Uri new()
        state@ uri = uri
        errorCode := state parse(url)
        if(!errorCode success()) {
            NetError new(This, "Error parsing URI '%s': %d" format(url, errorCode)) throw()
        }
        if(uri@ pathTail) {
           return uri@ pathTail@ text copy()
        } else {
            return uri@ hostText copy()
        }
    }

    getScheme: static func (url: String) -> String {
        state := ParserState new()
        uri := Uri new()
        state@ uri = uri
        errorCode := state parse(url)
        if(!errorCode success()) {
            NetError new(This, "Error parsing URI '%s': %d" format(url, errorCode)) throw()
        }
        return uri@ scheme copy()
    }

    app: App

    init: func (=app) {
    
    }
}
