/**
 * Created by cleverdou on 17/9/19.
 */
'use strict';


import { NativeModules } from 'react-native';

const { RNAnalytics } = NativeModules;

let isOpenLog=false;

export function openLog(isLog) {
    isOpenLog=isLog;
}

// eslint-disable-next-line import/prefer-default-export
export function sendBuriedData(data) {
    if (isOpenLog) {
        console.log(data);
    }
    if (RNAnalytics) {
        data.page_info = data.page_info && JSON.stringify(data.page_info);
        RNAnalytics.sendBuriedData(JSON.stringify(data));
    }
}

export function setUserId(userId) {
    NativeModules.setUserId(userId);
}


export function clearUserId() {
    NativeModules.clearUserId();
}

