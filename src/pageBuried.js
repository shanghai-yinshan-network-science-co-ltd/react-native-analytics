/**
 * Created by cleverdou on 17/9/18.
 */

'use strict';

import React, {forwardRef, useImperativeHandle, useRef} from 'react';
import {getStrTime} from './utils';
import {
  other_event,
  page_entrance_event,
  typeViewEvent,
  page_leave_event,
} from './eventTypeConst';
import {sendBuriedData} from './nativeModule';
import {getComponentName} from './stack';
import {SPLITE} from './const';
import {AppState} from 'react-native';
import {NavigationActions} from 'react-navigation';
import {lastClickId, resetLastClickId} from './clickBuried';

let lastPageId;

let currentPageId;
let currentComponent;

function onPageStart(pageId, component) {
  currentPageId = pageId;
  currentComponent = component;
  const now = Date.now();
  const pageEntranceData = {
    action_type: page_entrance_event,
    end_time: getStrTime(now),
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
    end_time: getStrTime(now),
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
    onPageStart(currentPageId, currentComponent);
  }
}

let init = false;

function getActiveRouteName(navigationState, router) {
  if (!navigationState) {
    return null;
  }
  const route = navigationState.routes[navigationState.index];
  // dive into nested navigators
  if (route.routes) {
    router = router.childRouters[route.routeName];
    return getActiveRouteName(route, router);
  }
  const component = router.getComponentForRouteName(route.routeName);
  return {name: route.routeName, component};
}

export function createAnalyticsAppContainer(AppContainer) {
  const getStateForAction = AppContainer.router.getStateForAction;
  AppContainer.router.getStateForAction = function(action, state) {
    const stateForAction = getStateForAction(action, state);
    if (action.type === NavigationActions.INIT) {
      if (!init) {
        AppState.addEventListener('change', handleAppStateChange);
        init = true;
        const {name: currentScreen, component} = getActiveRouteName(
            stateForAction, AppContainer.router);
        onPageStart(currentScreen, component);
      }
    }
    return stateForAction;
  };

  function onNavigationStateChange(prevState, currentState, action) {
    const {name: currentScreen, component} = getActiveRouteName(currentState,
        AppContainer.router);
    const {name: prevScreen} = getActiveRouteName(prevState,
        AppContainer.router);
    if (prevScreen !== currentScreen) {
      onPageEnd(prevScreen);
      onPageStart(currentScreen, component);
    }
  }

  function AnalyticsAppContainer(props, ref) {
    const _ref = useRef();
    useImperativeHandle(ref, () => _ref.current);
    return (
        <AppContainer
            ref={_ref}
            onNavigationStateChange={onNavigationStateChange} {...props} />
    );
  }

  return forwardRef(AnalyticsAppContainer);
}

export function getCurrentPageId() {
  return currentPageId;
}

export function getCurrentPageComponent() {
  return currentComponent;
}
