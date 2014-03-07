/**********************************************************\
|                                                          |
|                          hprose                          |
|                                                          |
| Official WebSite: http://www.hprose.com/                 |
|                   http://www.hprose.net/                 |
|                   http://www.hprose.org/                 |
|                                                          |
\**********************************************************/
/**********************************************************\
 *                                                        *
 * HproseFormatter.as                                     *
 *                                                        *
 * hprose formatter class for ActionScript 2.0.           *
 *                                                        *
 * LastModified: Mar 7, 2014                              *
 * Author: Ma Bingyao <andot@hprose.com>                  *
 *                                                        *
\**********************************************************/

import hprose.io.HproseReader;
import hprose.io.HproseWriter;
import hprose.io.HproseStringInputStream;
import hprose.io.HproseStringOutputStream;

class hprose.io.HproseFormatter {
    public static function serialize(o, stream:HproseStringOutputStream, simple:Boolean):HproseStringOutputStream {
        if (stream == null) {
            stream = new HproseStringOutputStream();
        }
        var writer = new HproseWriter(stream, simple);
        writer.serialize(o);
        return stream;
    }
    public static function unserialize(stream, simple:Boolean) {
        if (typeof(stream) == "string") {
            stream = new HproseStringInputStream(stream);
        }
        var reader = new HproseReader(stream, simple);
        return reader.unserialize();
    }
}