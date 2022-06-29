/**
 * Created by cleverdou on 2020/6/18.
 */
'use strict';


let _isWarning=false;


export function setWarning(isWarning) {
  _isWarning = isWarning;
}

export function isWarning() {
  return _isWarning;
}
