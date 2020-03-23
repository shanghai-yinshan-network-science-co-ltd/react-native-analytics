/**
 * Created by cleverdou on 17/9/19.
 */
'use strict';
import React from 'react'
import { TextInput, Clipboard } from 'react-native'
import { sendBuriedData } from './nativeModule'
import { getCurrentPageId, getCurrentPageComponent } from "./pageBuried";
import { getStrTime } from "./utils";
import { getViewPathByComponent } from "./stack";

const originalcomponentWillMount = TextInput.prototype.componentWillMount;
const originalcomponentWillReceiveProps = TextInput.prototype.componentWillReceiveProps;
const originalcomponentWillUnmount = TextInput.prototype.componentWillUnmount;
const textfield_event = 'textfield_event';

function getCommenEvent(viewPath, pageId,vId) {
  if (!pageId) {
    return;
  }
  const now = Date.now();
  const pages = pageId.split("-");
  if (pages.length > 0) {
    viewPath = pages[pages.length - 1] + "-" + viewPath;
  }
  return {
    page_id: pageId,
    start_time: getStrTime(now),
    view_path: viewPath,
    action_type: textfield_event,
    log_time: getStrTime(now),
    widget_id: vId,
  };
}

TextInput.prototype.componentWillMount = function (...args) {
  originalcomponentWillMount && originalcomponentWillMount.bind(this)(...args);
  const originalOnChage = this._onChange;
  const originalOnBlur = this._onBlur;
  const originalOnFocus = this._onFocus;
  const originalOnSelectionChange = this._onSelectionChange;
  this._$selection = this.props.selection;
  const text = this._$onChangeText = this.props.value || this.props.defaultValue || "";
  this._$selection = {
    start: text.length,
    end: text.length,
  };
  this._sendEditBuriedData = function (editData, opType) {
    const _pageId = getCurrentPageId();
    let { path: viewPath, description ,vId} = getViewPathByComponent(this._reactInternalFiber, getCurrentPageComponent());
    if (opType === "inputEnd" || opType === "inputStart") {
      const text = editData;
      const data = getCommenEvent(viewPath, _pageId,vId);
      if (data) {
        data.page_info = {
          textLength: text ? text.length : 0,
          opType,
          sessionId: this._sessionId,
          description
        };
        sendBuriedData(data);
      }
    } else if (opType === "paste") {
      Clipboard.getString()
        .then((content) => {
          // console.log(editData);
          if (content.length > 1 && editData.diff === content) {
            const data = getCommenEvent(viewPath, _pageId,vId);
            if (data) {
              data.page_info = {
                newTextLength: editData.newTextLength,
                oldTextLength: editData.oldTextLength,
                opType,
                sessionId: this._sessionId,
                description
              };
              sendBuriedData(data);
            }
          }
        });
    }
  }.bind(this);
  this._onChange = function (e) {
    // console.log('_onChange', e.nativeEvent);
    let newText = e.nativeEvent.text || "";
    const newTextLength = newText.length;
    const oldTextLength = this._$onChangeText.length;
    let selection = Math.abs(e.timeStamp - this._$selectionTimeStamp) < 100 ? this._prevSelection : this._$selection;
    if (selection.start === selection.end && newText.length > this._$onChangeText.length) {
      const length = newText.length - this._$onChangeText.length;
      const diff = newText.substr(selection.start, length);
      this._sendEditBuriedData({ diff, newTextLength, oldTextLength }, "paste")
    } else if (selection.start !== selection.end) {
      const prefix = this._$onChangeText.substring(0, selection.start < selection.end ? selection.start : selection.end);
      const suffix = this._$onChangeText.substring(selection.start < selection.end ? selection.end : selection.start, this._$onChangeText.length);
      const diff = newText.substring(prefix.length, newText.length - suffix.length);
      this._sendEditBuriedData({ diff, newTextLength, oldTextLength }, "paste")
    }
    this._$onChangeText = this.props.value || newText;
    originalOnChage && originalOnChage(e);
  }.bind(this);
  this._onSelectionChange = function (e) {
    // console.log('_onSelectionChange', e.nativeEvent);
    // this._$selection = this.props.selection || e.nativeEvent.selection;
    this._prevSelection = this._$selection;
    this._$selection = e.nativeEvent.selection;
    this._$selectionTimeStamp = e.timeStamp;
    originalOnSelectionChange && originalOnSelectionChange(e);
  }.bind(this);
  this._onBlur = function (event) {
    // console.log('blur', event.nativeEvent);
    this._isInput = false;
    let text = this.props.value || this._$onChangeText || this.props.defaultValue || "";
    this._sendEditBuriedData(text, "inputEnd");
    originalOnBlur && originalOnBlur(event);
  }.bind(this);
  this._onFocus = function (event) {
    // console.log('focus', event.nativeEvent);
    this._isInput = true;
    let text = this.props.value || this._$onChangeText || this.props.defaultValue || "";
    this._sessionId = Date.now();
    this._sendEditBuriedData(text, "inputStart");
    this._$onChangeText = text;
    this._$selection = {
      start: text.length,
      end: text.length
    };
    originalOnFocus && originalOnFocus(event);
  }.bind(this);
};

TextInput.prototype.componentWillUnmount = function (...args) {
  originalcomponentWillUnmount && originalcomponentWillUnmount.bind(this)(...args);
  if (this._isInput) {
    let text = this.props.value || this._$onChangeText || this.props.defaultValue || "";
    this._sendEditBuriedData(text, "inputEnd");
    this._isInput = false;
  }
};

TextInput.prototype.componentWillReceiveProps = function (nextProps, ...args) {
  originalcomponentWillMount && originalcomponentWillReceiveProps.bind(this)(nextProps, ...args);
  // if (nextProps.selection !== this.props.selection) {
  //     this._$selection = nextProps.selection;
  // }
  if (nextProps.value !== this.props.value) {
    this._$onChangeText = nextProps.value;
  }
};
