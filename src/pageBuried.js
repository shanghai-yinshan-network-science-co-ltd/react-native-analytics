/**
 * Created by cleverdou on 17/9/18.
 */
'use strict';

import { getStrTime } from './utils'
import { other_event, page_entrance_event, typeViewEvent, page_leave_event } from './eventTypeConst'
import { sendBuriedData } from "./nativeModule";
import { getComponentName } from "./stack";
import { SPLITE } from './const'
import { AppState } from "react-native";
import { NavigationActions } from "react-navigation";


let currentPageId;


function onPageStart(pageId) {
  currentPageId = pageId;
  const now = Date.now();
  const pageEntranceData = {
    action_type: page_entrance_event,
    end_time: getStrTime(now),
    page_id: pageId,
    start_time: getStrTime(now),
  };
  sendBuriedData(pageEntranceData);
}

function onPageEnd(pageId) {
  const now = Date.now();
  const pageEntranceData = {
    action_type: page_leave_event,
    end_time: getStrTime(now),
    page_id: pageId,
    start_time: getStrTime(now),
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
  const componentName = getComponentName(component);
  return route.routeName + SPLITE + componentName;
}


export function createOnNavigationStateChange(AppContainer) {
  const getStateForAction = AppContainer.router.getStateForAction;
  AppContainer.router.getStateForAction = function (action, state) {
    const stateForAction = getStateForAction(action, state);
    if (action.type === NavigationActions.INIT) {
      if (!init) {
        AppState.addEventListener('change', handleAppStateChange);
        init = true;
        const currentScreen = getActiveRouteName(stateForAction, AppContainer.router);
        onPageStart(currentScreen);
      }
    }
    return stateForAction;
  };


  return (prevState, currentState, action) => {
    const currentScreen = getActiveRouteName(currentState, AppContainer.router);
    const prevScreen = getActiveRouteName(prevState, AppContainer.router);
    if (prevScreen !== currentScreen) {
      onPageEnd(prevScreen);
      onPageStart(currentScreen);
    }
  }
}


export function getCurrentPageId() {
  return currentPageId;
}

