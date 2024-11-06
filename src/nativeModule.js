/**
 * Created by cleverdou on 17/9/19.
 */
'use strict';


import { NativeModules } from 'react-native';
import {business_event} from './eventTypeConst';
import {getFormatTimeZ, getStrTime} from './utils';

const { RNAnalytics } = NativeModules;

let isOpenLog=false;

let otaVersion = '';

export function setOtaVersion(version) {
    otaVersion = version;
}

export function openLog(isLog) {
    isOpenLog=isLog;
}

// eslint-disable-next-line import/prefer-default-export
export function sendBuriedData(data) {
    if (isOpenLog) {
        console.log(data);
    }
    if (RNAnalytics) {
        if (!data.page_info) {
            data.page_info = {};
        }
        data.page_info = JSON.stringify({...data.page_info,otaVersion});
        RNAnalytics.sendBuriedData(JSON.stringify(data));
    }
}

export function setUserId(userId) {
    RNAnalytics.setUserId(userId);
}


export function clearUserId() {
    RNAnalytics.clearUserId();
}

/**
 *
 * @param businessName
 * @param infoData 使用JSON.stringify序列化后的字符串
 * @param needExtraData 额外传递外层设备数据
 */
export function saveBusinessEvent(businessName,{infoData,needExtraData= false} = {}) {

    const now = Date.now();

    const data = {
        action_type: business_event,
        start_time: getStrTime(now),
        start_time_z: getFormatTimeZ(now),
        log_time: getStrTime(now),
        log_time_z: getFormatTimeZ(now),
        event_name: businessName,
        page_info: infoData,
        needExtraData
    };
    sendBuriedData(data);
}

