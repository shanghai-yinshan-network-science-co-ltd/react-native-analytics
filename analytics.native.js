import {setBuried,createHookTouchable,clickEvent,setClickPositionIsCenterListener} from './src/clickBuried';
import {
  getCurrentPageId,
  useAnalyticsScreen,
  trackScreenshot,
  initRecordingState,
  endRecordingAndTrack,
  getRecordingState,
  getReferrerPageId
} from './src/pageBuried';
import {
  openLog,
  clearUserId,
  setUserId,
  saveBusinessEvent,
  setOtaVersion,
  uploadLogImmediately,
  updateLocation,
  updateGpsAddress,
  refreshCommonDeviceProperties,
  getCommonDeviceProperties
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
  getReferrerPageId,
  setBuried,
  NetworkLogger,
  setWarning,
  saveBusinessEvent,
  clickEvent,
  createTextInput,
  createHookTouchable,
  setOtaVersion,
  uploadLogImmediately,
  updateLocation,
  updateGpsAddress,
  refreshCommonDeviceProperties,
  getCommonDeviceProperties,
  setClickPositionIsCenterListener,
  trackScreenshot,
  initRecordingState,
  endRecordingAndTrack,
  getRecordingState
};
