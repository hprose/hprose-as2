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
 * HproseFilter.as                                        *
 *                                                        *
 * hprose filter class for ActionScript 2.0.              *
 *                                                        *
 * LastModified: Mar 17, 2014                             *
 * Author: Ma Bingyao <andot@hprose.com>                  *
 *                                                        *
\**********************************************************/

import hprose.common.IHproseFilter;

class hprose.common.HproseFilter implements IHproseFilter {
    public function inputFilter(data: String, context: Object):String {
        return data;
    }
    public function outputFilter(data: String, context: Object):String {
        return data;
    }
}