/**
 * Created by cleverdou on 17/9/18.
 */
'use strict';


export function getStrTime(ticks) {
  const tm = new Date(ticks);
  const year = tm.getFullYear();
  let month = tm.getMonth() + 1;
  let day = tm.getDate();
  let hour = tm.getHours();
  let min = tm.getMinutes();
  let sec = tm.getSeconds();
  const mil = tm.getMilliseconds();

  if (hour < 10) {
    hour = '0' + hour;
  }
  if (month < 10) {
    month = '0' + month;
  }
  if (day < 10) {
    day = '0' + day;
  }
  if (min < 10) {
    min = '0' + min;
  }
  if (sec < 10) {
    sec = '0' + sec;
  }

  return year + "-" + month + "-" + day + " " + hour + ":" + min + ":" + sec + "." + mil;
}


export function getComponentPathInScreen(path, pageId) {
  const screenComponentName = pageId.split('##')[1];
  const index = path.indexOf(screenComponentName);
  if (index === -1) {
    return path;
  }
  return path.slice(index + screenComponentName.length);
}
