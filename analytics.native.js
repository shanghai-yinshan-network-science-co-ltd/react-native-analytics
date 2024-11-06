import {setBuried,createHookTouchable,clickEvent} from './src/clickBuried';
import {getCurrentPageId, useAnalyticsScreen} from './src/pageBuried';
import {
  openLog,
  clearUserId,
  setUserId,
  saveBusinessEvent,
  setOtaVersion
} from './src/nativeModule';
import {createTextInput} from './src/editBuried';
import {NetworkLogger} from './src/network/NetworkLogger';
import {setWarning} from './src/config';

export {
  openLog,
  clearUserId,
  setUserId,
  useAnalyticsScreen,
  getCurrentPageId,
  setBuried,
  NetworkLogger,
  setWarning,
  saveBusinessEvent,
  clickEvent,
  createTextInput,
  createHookTouchable,
  setOtaVersion
};
