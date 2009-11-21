use curl
import text/StringBuffer

import curl/Curl

Net: cover {
    downloadString: static func (url: String) -> String {
        buffer := StringBuffer new()
        handle := Curl new()
        handle setOpt(CurlOpt url, url)
        handle setOpt(CurlOpt writeData, buffer)
        handle setOpt(CurlOpt writeFunction,
            func (data: Pointer, size: SizeT, nmemb: SizeT, buffer: Pointer) -> SizeT {
                buffer as StringBuffer append(data, size * nmemb)
                return size * nmemb    
            })
        handle perform()
        return buffer toString()
    }
}
