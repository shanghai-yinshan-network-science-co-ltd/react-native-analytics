/**
 * Created by cleverdou on 17/9/12.
 */
'use strict';

import React from 'react';
import {getViewPathByComponent, getComponentName} from './stack';
import {getCurrentPageId} from './pageBuried';
import {click_event} from './eventTypeConst';
import {getFormatTimeZ, getStrTime} from './utils';
import {sendBuriedData} from './nativeModule';
import hoistNonReactStatics from 'hoist-non-react-statics';
import {debounce} from "lodash/function";

let lastClickId;

let hostNode;

export function clickEvent(instance, pageInfo, pageId) {
  let {path: viewPath, description, vId} = getViewPathByComponent(
      instance._reactInternals || instance._reactInternalFiber,
      pageId);
  if (hostNode !== viewPath) {
    hostNode = viewPath;
    onClickEvent({viewPath: hostNode, description, vId, pageInfo, pageId});
    const id = setImmediate(() => {
      hostNode = undefined;
      clearImmediate(id);
    });
  }

}

function onClickEvent({viewPath, description, vId, pageInfo, pageId}) {
  if (!pageId) {
    return;
  }
  const now = Date.now();
  viewPath = pageId + '-' + viewPath;
  lastClickId = viewPath;
  const clickData = {
    action_type: click_event,
    page_id: pageId,
    start_time: getStrTime(now),
    start_time_z: getFormatTimeZ(now),
    view_path: viewPath,
    log_time: getStrTime(now),
    log_time_z: getFormatTimeZ(now),
    widget_id: vId,
  };
  if (pageInfo) {
    clickData.page_info = pageInfo;
  }
  if (description) {
    clickData.page_info = clickData.page_info ?
        {...clickData.page_info, description} :
        {description};
  }
  sendBuriedData(clickData);
}

function resetLastClickId() {
  lastClickId = undefined;
}

export function setBuried(toggle) {
}

export {lastClickId, resetLastClickId};

const paths = new Map();

export const createHookTouchable = function(path, Touchable) {

  if (paths.has(path)) {
    return paths.get(path);
  }

  // 处理默认导出的情况
  const Component = Touchable && Touchable.default ? Touchable.default : Touchable;

  class HookTouchable extends React.Component {

    constructor(props, context) {
      super(props, context);
      this._componentRef = null;
      this._onPress = function(...args) {
        this.pageId = this.pageId || getCurrentPageId();

        // 获取触摸事件的原生事件对象
        const event = args[0];
        let clickPositionInfo = null;

        if (event && event.nativeEvent) {
          const {pageX, pageY} = event.nativeEvent;

          // 如果组件 ref 存在，获取组件的尺寸和位置
          if (this._componentRef && this._componentRef.measure) {
            try {
              this._componentRef.measure((x, y, width, height, pageX_view, pageY_view) => {
                // 计算按钮的几何中心
                const centerX = pageX_view + width / 2;
                const centerY = pageY_view + height / 2;

                // 定义中心区域的半径（例如按钮宽高的 30%）
                const radiusX = width * 0.1;
                const radiusY = height * 0.1;

                // 判断触点是否在中心区域内
                const deltaX = Math.abs(pageX - centerX);
                const deltaY = Math.abs(pageY - centerY);

                const isInCenter = deltaX <= radiusX && deltaY <= radiusY;

                // 记录点击位置信息
                clickPositionInfo = {
                  isInCenter,
                  touchX: pageX,
                  touchY: pageY,
                  centerX,
                  centerY,
                };

                console.log('clickPositionInfo----', clickPositionInfo);
                console.log('inCenter----', isInCenter);

                // 将位置信息添加到 pageInfo 中
                const pageInfoWithPosition = {
                  type: 'press',
                  ...this.props.pageInfo,
                  clickPosition: clickPositionInfo,
                };

                clickEvent(this, pageInfoWithPosition, this.pageId);
                this.props.onPress(...args);
              });
            } catch (e) {
              // 如果 measure 失败，直接触发
              clickEvent(this, {type: 'press', ...this.props.pageInfo}, this.pageId);
              this.props.onPress(...args);
            }
          } else {
            // 如果无法获取 ref，直接触发
            clickEvent(this, {type: 'press', ...this.props.pageInfo}, this.pageId);
            this.props.onPress(...args);
          }
        } else {
          // 如果没有原生事件对象，直接触发
          clickEvent(this, {type: 'press', ...this.props.pageInfo}, this.pageId);
          this.props.onPress(...args);
        }
      }.bind(this);
      if (!this.props.disableDebounce) {
        this._onPress = debounce(
            this._onPress,
            300,
            { leading: true, trailing: false } // 关键配置
        );
      }
      this._onLongPress = function(...args) {
        this.pageId = this.pageId || getCurrentPageId()
        clickEvent(this, {type: 'longPress', ...this.props.pageInfo},this.pageId);
        this.props.onLongPress(...args);
      }.bind(this);
    }

    render() {
      const {forwardedRef, ...rest} = this.props;

      return (
          <Component
              ref={(ref) => {
                this._componentRef = ref;
                if (forwardedRef) {
                  if (typeof forwardedRef === 'function') {
                    forwardedRef(ref);
                  } else if (forwardedRef) {
                    forwardedRef.current = ref;
                  }
                }
              }}
              {...rest}
              onPress={this.props.onPress && this._onPress}
              onLongPress={this.props.onLongPress && this._onLongPress}
          />
      );
    }
  }

  const component = hoistNonReactStatics(React.forwardRef((props, ref) => {
    return <HookTouchable {...props} forwardedRef={ref} />;
  }), Component);
  component.propTypes = Component.propTypes;
  if(Touchable && Touchable.default){
    // 安全地拷贝所有属性并设置 default
    const wrappedTouchable = Object.assign({}, Touchable, {
      default: component
    });
    // 拷贝原型链上的属性
    Object.setPrototypeOf(wrappedTouchable, Object.getPrototypeOf(Touchable));
    paths.set(path, wrappedTouchable);
    return wrappedTouchable;
  } else {
    paths.set(path, component);
    return component;
  }
};
