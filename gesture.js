/**
 * Created by cleverdou on 2021/10/8.
 */
'use strict';

import 'react-native-gesture-handler-proxy'
import * as gestures from 'react-native-gesture-handler-proxy'
import {createHookTouchable} from './src/clickBuried';


export * from 'react-native-gesture-handler-proxy'

export const TouchableOpacity = createHookTouchable('g-TouchableOpacity',gestures.TouchableOpacity)
export const TouchableNativeFeedback = createHookTouchable('g-TouchableNativeFeedback',gestures.TouchableNativeFeedback)
export const TouchableWithoutFeedback = createHookTouchable('g-TouchableWithoutFeedback',gestures.TouchableWithoutFeedback)
export const TouchableHighlight = createHookTouchable('g-TouchableHighlight',gestures.TouchableHighlight)
export const BaseButton = createHookTouchable('g-BaseButton',gestures.BaseButton)
export const RectButton = createHookTouchable('g-RectButton',gestures.RectButton)
export const BorderlessButton = createHookTouchable('g-BorderlessButton',gestures.BorderlessButton)
