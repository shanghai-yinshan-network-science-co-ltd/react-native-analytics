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

  class HookTouchable extends React.Component {

    constructor(props, context) {
      super(props, context);
      this._onPress = function(...args) {
        this.pageId = this.pageId || getCurrentPageId()
        clickEvent(this, {type: 'press', ...this.props.pageInfo}, this.pageId);
        this.props.onPress(...args);
      }.bind(this);
      this._onPress = debounce(
          this._onPress,
          300,
          { leading: true, trailing: false } // 关键配置
      );
      this._onLongPress = function(...args) {
        this.pageId = this.pageId || getCurrentPageId()
        clickEvent(this, {type: 'longPress', ...this.props.pageInfo},this.pageId);
        this.props.onLongPress(...args);
      }.bind(this);
    }

    render() {
      const {forwardedRef, ...rest} = this.props;

      return (
          <Touchable
              ref={forwardedRef}
              {...rest}
              onPress={this.props.onPress && this._onPress}
              onLongPress={this.props.onLongPress && this._onLongPress}
          />
      );
    }
  }

  const component = hoistNonReactStatics(React.forwardRef((props, ref) => {

    return <HookTouchable {...props} forwardedRef={ref} />;
  }), Touchable);
  component.propTypes = Touchable.propTypes;
  paths.set(path, component);
  return component;
};
