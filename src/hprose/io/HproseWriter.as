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
 * HproseWriter.as                                        *
 *                                                        *
 * hprose writer class for ActionScript 2.0.              *
 *                                                        *
 * LastModified: Mar 7, 2014                              *
 * Author: Ma Bingyao <andot@hprose.com>                  *
 *                                                        *
\**********************************************************/

import hprose.common.Map;
import hprose.io.HproseClassManager;
import hprose.io.HproseStringOutputStream;
import hprose.io.HproseTags;

class hprose.io.HproseWriter {
    private static function isDigit(value):Boolean {
        switch (value) {
        case 0:
        case 1:
        case 2:
        case 3:
        case 4:
        case 5:
        case 6:
        case 7:
        case 8:
        case 9:
            return true;
        }
        return false;
    }

    private static function isInt32(value):Boolean {
        return (value >= -2147483648) &&
               (value <= 2147483647) &&
               (Math.floor(value) === value);
    }

    private static var fakeWriterRefer:Object = {
        set: function (val) {},
        write: function (stream, val) { return false; },
        reset: function () {}
    };

    private static function realWriterRefer() {
        var ref:Map = new Map();
        var refcount:Number = 0;
        return {
            set: function (val) {
                ref.set(val, refcount++);
            },
            write: function (stream, val) {
                var i:Number = ref.get(val);
                if (i !== undefined) {
                    stream.write(HproseTags.TagRef + i + HproseTags.TagSemicolon);
                    return true;
                }
                return false;
            },
            reset: function () {
                ref = new Map();
                refcount = 0;
            }
        };
    };

    private var classref:Object;
    private var fieldsref:Array;
    private var refer:Object;
    private var stream:HproseStringOutputStream;

    public function HproseWriter(stream:HproseStringOutputStream, simple:Boolean) {
        classref = {};
        fieldsref = [];
        refer = (simple ? fakeWriterRefer : realWriterRefer());
        this.stream = stream;
    }

    public function get outputStream():HproseStringOutputStream {
        return stream;
    }

    public function serialize(o):Void {
        if (o === undefined ||
            o === null ||
            o.constructor === Function) {
            writeNull();
            return;
        }
        if (o === '') {
            writeEmpty();
            return;
        }
        switch (o.constructor) {
        case Boolean:
            writeBoolean(o);
            break;
        case Number:
            writeNumber(o);
            break;
        case String:
            if (o.length === 1) {
                writeUTF8Char(o);
            }
            else {
                writeStringWithRef(o);
            }
            break;
        case Date:
            writeDateWithRef(o);
            break;
        case Array:
            writeListWithRef(o);
            break;
        default:
            var alias:String = HproseClassManager.getClassAlias(o);
            if (alias === "Object") {
                writeMapWithRef(o);
            }
            else {
                writeObjectWithRef(o);
            }
            break;
        }
    }

    private function writeNumber(n:Number) {
        if (isDigit(n)) {
            stream.write(n.toString());
        }
        else if (isInt32(n)) {
            writeInteger(n);
        }
        else {
            writeDouble(n);
        }
    }

    public function writeInteger(i):Void {
        stream.write(HproseTags.TagInteger + i + HproseTags.TagSemicolon);
    }

    public function writeLong(l):Void {
        stream.write(HproseTags.TagLong + l + HproseTags.TagSemicolon);
    }

    public function writeDouble(d):Void {
        if (isNaN(d)) {
            writeNaN();
        }
        else if (isFinite(d)) {
            stream.write(HproseTags.TagDouble + d + HproseTags.TagSemicolon);
        }
        else {
            writeInfinity(d > 0);
        }
    }

    public function writeNaN():Void {
        stream.write(HproseTags.TagNaN);
    }

    public function writeInfinity(positive):Void {
        stream.write(HproseTags.TagInfinity + (positive ?
                                               HproseTags.TagPos :
                                               HproseTags.TagNeg));
    }

    public function writeNull():Void {
        stream.write(HproseTags.TagNull);
    }

    public function writeEmpty():Void {
        stream.write(HproseTags.TagEmpty);
    }

    public function writeBoolean(bool):Void {
        stream.write(bool ? HproseTags.TagTrue : HproseTags.TagFalse);
    }

    public function writeUTCDate(date):Void {
        refer.set(date);
        var year = ('0000' + date.getUTCFullYear()).slice(-4);
        var month = ('00' + (date.getUTCMonth() + 1)).slice(-2);
        var day = ('00' + date.getUTCDate()).slice(-2);
        var hour = ('00' + date.getUTCHours()).slice(-2);
        var minute = ('00' + date.getUTCMinutes()).slice(-2);
        var second = ('00' + date.getUTCSeconds()).slice(-2);
        var millisecond = ('000' + date.getUTCMilliseconds()).slice(-3);
        if ((hour == '00') && (minute == '00') && (second == '00') && (millisecond == '000')) {
            stream.write(HproseTags.TagDate + year + month + day + HproseTags.TagUTC);
        }
        else if ((year == '1970') && (month == '01') && (day == '01')) {
            stream.write(HproseTags.TagTime + hour + minute + second);
            if (millisecond != '000') {
                stream.write(HproseTags.TagPoint + millisecond);
            }
            stream.write(HproseTags.TagUTC);
        }
        else {
            stream.write(HproseTags.TagDate + year + month + day +
                         HproseTags.TagTime + hour + minute + second);
            if (millisecond != '000') {
                stream.write(HproseTags.TagPoint + millisecond);
            }
            stream.write(HproseTags.TagUTC);
        }
    }

    public function writeUTCDateWithRef(date):Void {
        if (!refer.write(stream, date)) writeUTCDate(date);
    }

    public function writeDate(date):Void {
        refer.set(date);
        var year = ('0000' + date.getFullYear()).slice(-4);
        var month = ('00' + (date.getMonth() + 1)).slice(-2);
        var day = ('00' + date.getDate()).slice(-2);
        var hour = ('00' + date.getHours()).slice(-2);
        var minute = ('00' + date.getMinutes()).slice(-2);
        var second = ('00' + date.getSeconds()).slice(-2);
        var millisecond = ('000' + date.getMilliseconds()).slice(-3);
        if ((hour == '00') && (minute == '00') && (second == '00') && (millisecond == '000')) {
            stream.write(HproseTags.TagDate + year + month + day + HproseTags.TagSemicolon);
        }
        else if ((year == '1970') && (month == '01') && (day == '01')) {
            stream.write(HproseTags.TagTime + hour + minute + second);
            if (millisecond != '000') {
                stream.write(HproseTags.TagPoint + millisecond);
            }
            stream.write(HproseTags.TagSemicolon);
        }
        else {
            stream.write(HproseTags.TagDate + year + month + day +
                         HproseTags.TagTime + hour + minute + second);
            if (millisecond != '000') {
                stream.write(HproseTags.TagPoint + millisecond);
            }
            stream.write(HproseTags.TagSemicolon);
        }
    }

    public function writeDateWithRef(date):Void {
        if (!refer.write(stream, date)) writeDate(date);
    }

    public function writeTime(time):Void {
        refer.set(time);
        var hour = ('00' + time.getHours()).slice(-2);
        var minute = ('00' + time.getMinutes()).slice(-2);
        var second = ('00' + time.getSeconds()).slice(-2);
        var millisecond = ('000' + time.getMilliseconds()).slice(-3);
        stream.write(HproseTags.TagTime + hour + minute + second);
        if (millisecond != '000') {
            stream.write(HproseTags.TagPoint + millisecond);
        }
        stream.write(HproseTags.TagSemicolon);
    }

    public function writeTimeWithRef(time):Void {
        if (!refer.write(stream, time)) writeTime(time);
    }

    public function writeUTF8Char(c):Void {
        stream.write(HproseTags.TagUTF8Char + c);
    }

    public function writeString(str):Void {
        refer.set(str);
        stream.write(HproseTags.TagString +
                     (str.length > 0 ? str.length : '') +
                     HproseTags.TagQuote + str + HproseTags.TagQuote);
    }

    public function writeStringWithRef(str):Void {
        if (!refer.write(stream, str)) writeString(str);
    }

    public function writeList(list):Void {
        refer.set(list);
        var count = list.length;
        stream.write(HproseTags.TagList + (count > 0 ? count : '') + HproseTags.TagOpenbrace);
        for (var i = 0; i < count; i++) {
            serialize(list[i]);
        }
        stream.write(HproseTags.TagClosebrace);
    }

    public function writeListWithRef(list):Void {
        if (!refer.write(stream, list)) writeList(list);
    }

    public function writeMap(map):Void {
        refer.set(map);
        var fields = [];
        for (var key in map) {
            if (typeof(map[key]) != 'function') {
                fields[fields.length] = key;
            }
        }
        var count = fields.length;
        stream.write(HproseTags.TagMap + (count > 0 ? count : '') + HproseTags.TagOpenbrace);
        for (var i = 0; i < count; i++) {
            serialize(fields[i]);
            serialize(map[fields[i]]);
        }
        stream.write(HproseTags.TagClosebrace);
    }

    public function writeMapWithRef(map):Void {
        if (!refer.write(stream, map)) writeMap(map);
    }

    public function writeObject(obj):Void {
        var alias = HproseClassManager.getClassAlias(obj);
        var fields;
        var index = classref[alias];
        if (index !== undefined) {
            fields = fieldsref[index];
        }
        else {
            fields = [];
            for (var key in obj) {
                if (typeof(obj[key]) != 'function') {
                    fields[fields.length] = key;
                }
            }
            index = writeClass(alias, fields);
        }
        stream.write(HproseTags.TagObject + index + HproseTags.TagOpenbrace);
        refer.set(obj);
        var count = fields.length;
        for (var i = 0; i < count; i++) {
            serialize(obj[fields[i]]);
        }
        stream.write(HproseTags.TagClosebrace);
    }

    public function writeObjectWithRef(obj):Void {
        if (!refer.write(stream, obj)) writeObject(obj);
    }

    private function writeClass(alias, fields):Number {
        var count = fields.length;
        stream.write(HproseTags.TagClass + alias.length +
                     HproseTags.TagQuote + alias + HproseTags.TagQuote +
                     (count > 0 ? count : '') + HproseTags.TagOpenbrace);
        for (var i = 0; i < count; i++) {
            writeString(fields[i]);
        }
        stream.write(HproseTags.TagClosebrace);
        var index = fieldsref.length;
        classref[alias] = index;
        fieldsref[index] = fields;
        return index;
    }

    public function reset():Void {
        classref = {};
        fieldsref.length = 0;
        refer.reset();
    }
}