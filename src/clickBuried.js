/**
 * Created by cleverdou on 17/9/12.
 */
'use strict';
import {
  Touchable,
  View,
  DeviceEventEmitter,
  TextInput,
  StyleSheet
} from 'react-native';
import React from "react";
import { getViewPathByComponent, getComponentName } from './stack'
import { getCurrentPageId } from './pageBuried'
import { click_event } from './eventTypeConst'
import { getStrTime, getComponentPathInScreen } from './utils'
import normalizeColor from './normalizeColor'
import { sendBuriedData } from './nativeModule'


let IsShowBuriedView;
let prevBuried;
let prevBuriedStyle;
let hostNode;
let pageInfo;
const originalRenderDebugView = Touchable.renderDebugView;
const original_performSideEffectsForTransition = Touchable.Mixin._performSideEffectsForTransition;


class BuriedView extends React.Component {


  constructor(props) {
    super(props);
    this.state = {}
  }

  render() {
    let { hitSlop, color } = this.props;

    const debugHitSlopStyle = {};
    hitSlop = hitSlop || { top: 0, bottom: 0, left: 0, right: 0 };
    for (const key in hitSlop) {
      debugHitSlopStyle[key] = -hitSlop[key];
    }
    const normalizedColor = normalizeColor(color);
    if (typeof normalizedColor !== 'number') {
      return null;
    }
    const hexColor =
      '#' + ('00000000' + normalizedColor.toString(16)).substr(-8);
    return (
      IsShowBuriedView ? (this.state.selected ? (
        <View
          pointerEvents="none"
          style={[
            styles.debug,
            {
              borderColor: hexColor.slice(0, -2) + '55', // More opaque
              backgroundColor: hexColor.slice(0, -2) + '0F', // Less opaque
              ...debugHitSlopStyle,
            },
          ]}
        />
      ) : null) : originalRenderDebugView({ color, hitSlop })
    );
  }
}


/**
 * 查找无痕埋点的点击显示框
 * @param touchableView
 * @return {ReactCompositeComponent.getPublicInstance|ReactNativeBaseComponent.Mixin.getPublicInstance|getPublicInstance|*|ReactComponent}
 */
function findBuriedViewByFiber(touchableView) {
  let queue = [];
  queue.push(touchableView);
  let node;
  while (queue.length > 0) {
    node = queue.shift();
    if (node.stateNode instanceof BuriedView) {
      return node.stateNode;
    }
    if (node.child) {
      queue.push(node.child);
      let sibling = node.child.sibling;
      while (sibling) {
        queue.push(sibling);
        sibling = sibling.sibling;
      }
    }
  }
}


function findBuriedView(touchableView) {
  if (!touchableView) {
    return;
  }
  return findBuriedViewByFiber(touchableView);
}


/**
 * 查找有点击事件的Text
 * @param component
 * @return {*}
 */
function getTextInstance(component) {
  if (getComponentName(component._reactInternalFiber.type) === 'TouchableText') {
    return component
  }
  if (component._reactInternalFiber._renderedComponent && getComponentName(component._reactInternalFiber._renderedComponent.type) === 'TouchableText') {
    return component._reactInternalFiber._renderedComponent.getPublicInstance();
  }
  if (component._reactInternalFiber.child && getComponentName(component._reactInternalFiber.child.type) === 'TouchableText') {
    return component._reactInternalFiber.child.stateNode;
  }
}

//覆盖react原本的调试view
Touchable.renderDebugView = function ({ color, hitSlop }) {
  return (<BuriedView hitSlop={hitSlop} color={color} key={Date.now() + ""} />)
};

//对点击事件进行代理
Touchable.Mixin.withoutDefaultFocusAndBlur._performSideEffectsForTransition = Touchable.Mixin._performSideEffectsForTransition = function (...args) {


  const orginalHandlePress = this.touchableHandlePress;

  this.touchableHandlePress = function (e) {
    if (this) {
      //展示点击框
      if (IsShowBuriedView) {
        let text;
        if (prevBuried instanceof BuriedView) {
          prevBuried.setState({
            selected: false
          });
        }
        if (prevBuried && prevBuried._reactInternalFiber) {
          text = getTextInstance(prevBuried);
          if (text) {
            text.state.responseHandlers = {
              ...text.state.responseHandlers,
              style: [{
                borderColor: 'transparent', // More opaque
                borderWidth: 0,
                borderStyle: 'solid',
                backgroundColor: 'transparent', // Less opaque
              }, prevBuriedStyle]
            };
            text.setState({});
          }
        }
        prevBuried = this;
        prevBuriedStyle = this.props.style;
        text = getTextInstance(this);
        if (text) {
          text.state.responseHandlers = {
            ...text.state.responseHandlers,
            style: [{
              borderColor: 'black', // More opaque
              backgroundColor: '#ffff0F', // Less opaque
            }, prevBuriedStyle]
          };
          text.setState({});

        } else {
          Touchable.renderDebugView = ({ color, hitSlop }) => {
            return (
              <BuriedView ref={(ref) => prevBuried = ref} hitSlop={hitSlop} color={color} key={Date.now() + ""} />)
          };
          this.setState({}, () => prevBuried.setState({
            selected: true
          }));
        }
      }
      //获取点击信息进行埋点
      let viewPath = getViewPathByComponent(this._reactInternalFiber);
      viewPath = getComponentPathInScreen(viewPath, getCurrentPageId());
      if (!((this._reactInternalFiber.return && this._reactInternalFiber.return.stateNode instanceof TextInput) || viewPath.endsWith('TextInput-TouchableWithoutFeedback'))) {
        if (hostNode !== viewPath) {
          hostNode = viewPath;
          onClickEvent(hostNode);
          const id = setImmediate(() => {
            hostNode = undefined;
            clearImmediate(id);
          });
        }
      }
    }
    //执行原始回调
    if (!IsShowBuriedView) {
      orginalHandlePress(e);
    }
  };
  original_performSideEffectsForTransition.bind(this)(...args);
};

function onClickEvent(viewPath) {
  const pageId = getCurrentPageId();
  if (!pageId) {
    return;
  }
  const now = Date.now();
  const pages = pageId.split("-");
  if (pages.length > 0) {
    viewPath = pages[pages.length - 1] + "-" + viewPath;
  }
  const clickData = {
    action_type: click_event,
    end_time: getStrTime(now),
    page_id: pageId,
    start_time: getStrTime(now),
    view_path: viewPath
  };
  if (pageInfo) {
    clickData.page_info = pageInfo;
    pageInfo = undefined;
  }
  sendBuriedData(clickData);
}


export function setClickPageInfo(_pageInfo) {
  pageInfo = _pageInfo;
}

DeviceEventEmitter.addListener('RNAnalytics.toggleBuriedView',
  data => setBuried(data.isCatchModeOpened));


export function setBuried(toggle) {
  IsShowBuriedView = Touchable.TOUCH_TARGET_DEBUG = toggle;
  if (!toggle && prevBuried) {
    const buriedView = findBuriedView(prevBuried._reactInternalFiber);
    buriedView && buriedView.setState({
      selected: false
    });
  }
}


const styles = StyleSheet.create({
  debug: {
    position: 'absolute',
    borderWidth: 1,
    borderStyle: 'dashed',
  },
});
