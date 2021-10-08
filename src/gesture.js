/**
 * Created by cleverdou on 2021/10/8.
 */
'use strict';

import 'react-native-gesture-handler-proxy'
import * as gestures from 'react-native-gesture-handler-proxy'
import {createHookTouchable} from './clickBuried';


export * from 'react-native-gesture-handler-proxy'

export const TouchableOpacity = createHookTouchable(gestures.TouchableOpacity)
export const TouchableNativeFeedback = createHookTouchable(gestures.TouchableNativeFeedback)
export const TouchableWithoutFeedback = createHookTouchable(gestures.TouchableWithoutFeedback)
export const TouchableHighlight = createHookTouchable(gestures.TouchableHighlight)
export const BaseButton = createHookTouchable(gestures.BaseButton)
export const RectButton = createHookTouchable(gestures.RectButton)
export const BorderlessButton = createHookTouchable(gestures.BorderlessButton)
