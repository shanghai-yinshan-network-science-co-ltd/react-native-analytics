/**
 * Created by cleverdou on 17/9/18.
 */
'use strict';


import dayjs from 'dayjs';

export function getStrTime(ticks) {
  return dayjs(new Date(ticks)).format("YYYY-MM-DD HH:mm:ss.SSS");
}

export function getFormatTimeZ(time){
  return dayjs(new Date(time)).format("YYYY-MM-DDTHH:mm:ss.SSSZZ");
}


export function getComponentPathInScreen(path, pageId) {
  const screenComponentName = pageId.split('##')[1];
  const index = path.indexOf(screenComponentName);
  if (index === -1) {
    return path;
  }
  return path.slice(index + screenComponentName.length);
}
