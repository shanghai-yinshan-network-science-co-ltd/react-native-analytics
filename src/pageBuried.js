/**
 * Created by cleverdou on 17/9/18.
 */

'use strict';

import React, {useEffect,useCallback,useRef} from 'react';
import {getFormatTimeZ, getStrTime} from './utils';
import {
  page_entrance_event,
  page_leave_event,
} from './eventTypeConst';
import {sendBuriedData, saveBusinessEvent} from './nativeModule';
import {AppState} from 'react-native';
import {lastClickId, resetLastClickId} from './clickBuried';
import {
  useNavigationContainerRef,
} from '@react-navigation/native';

let lastPageId;

let currentPageId;

/**
 * 录屏状态类型
 */
let recordingState = {
  isRecording: false,
  startTime: null,
  startPage: '',
  pagesVisited: [],
};

function onPageStart(pageId,isAppStateChange) {
  currentPageId = pageId;
  const now = Date.now();
  const pageEntranceData = {
    action_type: page_entrance_event,
    page_id: pageId,
    start_time: getStrTime(now),
    log_time: getStrTime(now),
    start_time_z: getFormatTimeZ(now),
    log_time_z: getFormatTimeZ(now),
    referId: lastPageId,
    btnId: lastClickId,
  };
  if (isAppStateChange) {
    pageEntranceData.page_info = {
      isAppStateChange
    }
  }

  // 如果正在录屏，记录页面访问
  if (recordingState.isRecording && pageId) {
    const pagesVisited = recordingState.pagesVisited;
    // 避免重复记录相同页面
    if (pagesVisited.length === 0 || pagesVisited[pagesVisited.length - 1] !== pageId) {
      recordingState.pagesVisited.push(pageId);
    }
  }

  lastPageId = undefined;
  resetLastClickId();
  sendBuriedData(pageEntranceData);
}

function onPageEnd(pageId,isAppStateChange) {
  lastPageId = pageId;
  const now = Date.now();
  const pageEntranceData = {
    action_type: page_leave_event,
    page_id: pageId,
    start_time: getStrTime(now),
    log_time: getStrTime(now),
    start_time_z: getFormatTimeZ(now),
    log_time_z: getFormatTimeZ(now),
  };
  if (isAppStateChange) {
    pageEntranceData.page_info = {
      isAppStateChange
    }
  }
  sendBuriedData(pageEntranceData);
}

function handleAppStateChange(nextAppState) {
  if (nextAppState.match(/inactive|background/)) {
    onPageEnd(currentPageId,true);
  } else {
    onPageStart(currentPageId,true);
  }
}

/*
actions: 这个方法数组，目前是承接三个方法，依次按照顺序是：
1：神策的页面浏览事件
2：神策的开始计时事件
3：神策的结束计时事件
*/
export function useAnalyticsScreen(actions = []) {
  const navigationRef = useNavigationContainerRef();
  const routeNameRef = useRef();


  useEffect(() => {
    // 加上防抖
    let debounceTimer = null;
    const debouncedHandleAppStateChange = (...args) => {
      if (debounceTimer) {
        clearTimeout(debounceTimer);
      }
      debounceTimer = setTimeout(() => {
        handleAppStateChange(...args);
        debounceTimer = null;
      }, 300); // 300ms防抖
    };
    const subscription = AppState.addEventListener('change', debouncedHandleAppStateChange)
    return () => {
      subscription.remove()
    };
  }, []);


  const onStateChange = useCallback(() => {
    const previousRouteName = routeNameRef.current;
    const currentRouteName = navigationRef.getCurrentRoute().name;

    if (previousRouteName !== currentRouteName) {
      // The line below uses the expo-firebase-analytics tracker
      // https://docs.expo.io/versions/latest/sdk/firebase-analytics/
      // Change this line to use another Mobile analytics SDK
      onPageEnd(previousRouteName);
      onPageStart(currentRouteName)

      if(actions?.[0]){
        actions?.[0]?.(currentRouteName);
      }
      if(actions?.[1]){
        actions?.[1]?.(`pageView_${currentRouteName}`);
      }
      if(actions?.[2]){
        actions?.[2]?.(`pageView_${previousRouteName}`, { pageName: previousRouteName });
      }
    }

    // Save the current route name for later comparison
    routeNameRef.current = currentRouteName;

  }, []);

  const onReady = useCallback(() => {
    routeNameRef.current = navigationRef.getCurrentRoute().name;
    onPageStart(routeNameRef.current)
  },[])

  return {
    navigationRef,
    onStateChange,
    onReady
  };
}


export function getCurrentPageId() {
  return currentPageId;
}

/**
 * 获取上一页页面ID
 */
export function getReferrerPageId() {
  return lastPageId || '';
}

/**
 * 发送截屏埋点
 */
export function trackScreenshot() {
  const pageId = getCurrentPageId() || '';
  const referrerPage = getReferrerPageId() || '';
  const screenshotTime = Date.now();

  saveBusinessEvent('screenshot', {
    infoData: {
      page_id: pageId,
      screenshot_time: screenshotTime,
      referrer_page: referrerPage,
    },
  });
}

/**
 * 初始化录屏状态
 */
export function initRecordingState() {
  const startTime = Date.now();
  const startPage = getCurrentPageId() || '';

  recordingState = {
    isRecording: true,
    startTime,
    startPage,
    pagesVisited: startPage ? [startPage] : [], // 记录开始页面
  };
}

/**
 * 结束录屏并发送埋点
 */
export function endRecordingAndTrack() {
  const { isRecording, startTime, startPage, pagesVisited } = recordingState;

  if (isRecording && startTime !== null) {
    const endTime = Date.now();
    const endPage = getCurrentPageId() || '';
    const duration = endTime - startTime;

    // 确保结束页面在访问列表中
    const finalPagesVisited = [...pagesVisited];
    if (endPage && finalPagesVisited[finalPagesVisited.length - 1] !== endPage) {
      finalPagesVisited.push(endPage);
    }

    // 发送录屏埋点
    saveBusinessEvent('screen_recording', {
      infoData: {
        start_time: startTime,
        end_time: endTime,
        duration: duration,
        start_page: startPage,
        end_page: endPage,
        pages_visited: finalPagesVisited,
      },
    });

    // 重置录屏状态
    recordingState = {
      isRecording: false,
      startTime: null,
      startPage: '',
      pagesVisited: [],
    };
  }
}

/**
 * 获取录屏状态
 */
export function getRecordingState() {
  return { ...recordingState };
}
