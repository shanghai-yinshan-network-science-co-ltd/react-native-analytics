import {setBuried,setClickPageInfo} from './src/clickBuried'
import {getCurrentPageId,useAnalyticsScreen} from './src/pageBuried'
import {openLog,clearUserId,setUserId} from './src/nativeModule'
import  './src/editBuried'
import {NetworkLogger} from './src/network/NetworkLogger'
import {setWarning} from './src/config'


export {openLog,clearUserId,setUserId,useAnalyticsScreen,getCurrentPageId,setClickPageInfo,setBuried,NetworkLogger,setWarning}
