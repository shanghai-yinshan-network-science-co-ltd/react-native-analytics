import NetworkInterceptor from './NetworkInterceptor'
import {sendBuriedData} from '../nativeModule'
import {getFormatTimeZ, getStrTime} from '../utils';

/*
    request_type	请求类型	请求类型 取值枚举：GET POST
    request_url	请求地址	请求地址	https://m.nonobank.com/msapi/app/discoveryPrompt
    request_params	请求参数	请求参数	{"sessionId":"feserver-c5608bae-2045-443c-8ebf-cf6d768387e5"}
    http_status	http返回码	http返回码	200
    response_data	接口返回信息	接口返回信息	{"errorCode":"000581","errorMessage":"..."}
                                        该字段只记录异常请求的错误返回信息，具体逻辑如下：
                                        1. 如果【error_code】不为约定的成功值，记录该字段
                                        2. 如果【http_status】不为2xx，3xx，记录改字段
                                        3. 其他情况该字段记为空
    request_consuming	请求耗时	请求开始到收到请求答复持续的毫秒数	235

*/

const DEFAULT = {
    request_type: "",
    request_url: "",
    request_params: "",
    http_status: "",
    response_data: "",
    request_consuming: "",
    action_type: "request_event",
    log_time: getStrTime(Date.now()),
    log_time_z: getFormatTimeZ(Date.now())
};

export let NetworkLogger = function () {

    function onOpen(method, url, xhr) {
        xhr._log = {...DEFAULT};
    }

    function onRequestHeaderCallback(header, value, xhr) {
    }

    function onSend(data, xhr) {

        xhr._log.start_time = getStrTime(Date.now());
        xhr._log.start_time_z = getFormatTimeZ(Date.now());

        xhr._log.request_type = xhr._method;
        xhr._log.request_url = xhr._url;

        if (typeof data === 'object'){
            data = JSON.stringify(data);
        }

        xhr._log.request_params = data ? data : "";

    }

    function onResponse(status, timeout, response, responseURL, responseType, xhr) {

        xhr._log.end_time = getStrTime(Date.now());
        xhr._log.end_time_z = getFormatTimeZ(Date.now());

        xhr._log.http_status = status;
        if (response&&(response.length>1024*2)) {
            xhr._log.response_data = "[filter]";
        }else {
            if (typeof response === 'string'){
                xhr._log.response_data = response;
            }else {
                xhr._log.response_data = "Blob";
            }
        }
        xhr._log.request_consuming = xhr._log.end_time - xhr._log.start_time;
        xhr._log.log_time = getStrTime(Date.now());
        xhr._log.log_time_z = getFormatTimeZ(Date.now());
        xhr._log.request_id = xhr.getResponseHeader('X_REQUEST_ID');

        if (/^http:\/\/localhost:\d+\/symbolicate/.test(responseURL)){
            return;
        }
        // 发送数据到Native
        sendBuriedData(xhr._log);
    }

    // register our monkey-patch
    NetworkInterceptor.setRequestHeaderCallback(onRequestHeaderCallback)
    NetworkInterceptor.setOpenCallback(onOpen)
    NetworkInterceptor.setSendCallback(onSend)
    NetworkInterceptor.setResponseCallback(onResponse)
    NetworkInterceptor.enableInterception()

}();
