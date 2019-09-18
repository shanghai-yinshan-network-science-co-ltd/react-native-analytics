import NetworkInterceptor from './NetworkInterceptor'
import {sendBuriedData} from '../nativeModule'
import {getStrTime} from "../utils";

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
    log_time: getStrTime(Date.now())
}

export let NetworkLogger = function () {

    const log = {...DEFAULT};

    let start_time;
    let end_time;

    function onRequestHeaderCallback(header, value, xhr) {

    }

    function onOpen(method, url, xhr) {

    }

    function onSend(data, xhr) {

        start_time = new Date().getTime();

        log.request_type = xhr._method;
        log.request_url = xhr._url;
        log.request_params = data ? data : "";

    }

    function onResponse(status, timeout, response) {

        end_time = new Date().getTime();

        log.http_status = status;
        log.response_data = response;
        log.request_consuming = end_time - start_time;
        log.log_time = getStrTime(Date.now())

        if (__DEV__) {
            console.log("response -> log:", JSON.stringify(log));
        }

        // 发送数据到Native
        sendBuriedData(log);
    }

    // register our monkey-patch
    NetworkInterceptor.setRequestHeaderCallback(onRequestHeaderCallback())
    NetworkInterceptor.setOpenCallback(onOpen())
    NetworkInterceptor.setSendCallback(onSend)
    NetworkInterceptor.setResponseCallback(onResponse)
    NetworkInterceptor.enableInterception()

}();
