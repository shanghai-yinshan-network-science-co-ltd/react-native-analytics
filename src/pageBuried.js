/**
 * Created by cleverdou on 17/9/18.
 */

'use strict';

import React, {useEffect,useCallback} from 'react';
import {getStrTime} from './utils';
import {
  page_entrance_event,
  page_leave_event,
} from './eventTypeConst';
import {sendBuriedData} from './nativeModule';
import {AppState} from 'react-native';
import {lastClickId, resetLastClickId} from './clickBuried';

let lastPageId;

let currentPageId;

function onPageStart(pageId) {
  currentPageId = pageId;
  const now = Date.now();
  const pageEntranceData = {
    action_type: page_entrance_event,
    page_id: pageId,
    start_time: getStrTime(now),
    log_time: getStrTime(now),
    referId: lastPageId,
    btnId: lastClickId,
  };
  lastPageId = undefined;
  resetLastClickId();
  sendBuriedData(pageEntranceData);
}

function onPageEnd(pageId) {
  lastPageId = pageId;
  const now = Date.now();
  const pageEntranceData = {
    action_type: page_leave_event,
    page_id: pageId,
    start_time: getStrTime(now),
    log_time: getStrTime(now),
  };
  sendBuriedData(pageEntranceData);
}

function handleAppStateChange(nextAppState) {
  if (nextAppState.match(/inactive|background/)) {
    onPageEnd(currentPageId);
  } else {
    onPageStart(currentPageId);
  }
}


const getActiveRouteName = state => {
  const route = state.routes[state.index];

  if (route.state) {
    return getActiveRouteName(route.state);
  }

  return route.name;
};

export function useAnalyticsScreen() {
  const routeNameRef = React.useRef();
  const navigationRef = React.useRef(null);
  useEffect(() => {
    const state = navigationRef.current.getRootState();
    routeNameRef.current = getActiveRouteName(state);
    onPageStart(routeNameRef.current);
    requestAnimationFrame(() => AppState.addEventListener('change', handleAppStateChange));
    return () => {
      AppState.removeEventListener('change', handleAppStateChange);
    };
  }, []);


  const onStateChange = useCallback(() => {
    requestAnimationFrame(() => {
      const previousRouteName = routeNameRef.current;
      let currentRouteName = '';
      if (navigationRef.current) {
        currentRouteName = getActiveRouteName(navigationRef.current.getRootState())
      }
      if (previousRouteName !== currentRouteName) {
        // The line below uses the @react-native-firebase/analytics tracker
        // Change this line to use another Mobile analytics SDK
        onPageEnd(previousRouteName);
        onPageStart(currentRouteName)
      }

      // Save the current route name for later comparision
      routeNameRef.current = currentRouteName;
    });

  }, []);

  return {
    navigationRef,
    onStateChange,
  };
}


export function getCurrentPageId() {
  return currentPageId;
}
