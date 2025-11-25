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
import {sendBuriedData} from './nativeModule';
import {AppState} from 'react-native';
import {lastClickId, resetLastClickId} from './clickBuried';
import {
  useNavigationContainerRef,
} from '@react-navigation/native';

let lastPageId;

let currentPageId;

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


export function useAnalyticsScreen(customAction?: (pageName: string)=>void ) {
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
      customAction?.(currentRouteName);
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
