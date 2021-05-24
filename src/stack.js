/* eslint-disable */
/**
 * Created by cleverdou on 17/9/12.
 */
'use strict';

import React from 'react';
import { Image } from "react-native";
import {isWarning} from './config'

var ReactSharedInternals =
        React.__SECRET_INTERNALS_DO_NOT_USE_OR_YOU_WILL_BE_FIRED,
    REACT_ELEMENT_TYPE = 60103,
    REACT_PORTAL_TYPE = 60106,
    REACT_FRAGMENT_TYPE = 60107,
    REACT_STRICT_MODE_TYPE = 60108,
    REACT_PROFILER_TYPE = 60114,
    REACT_PROVIDER_TYPE = 60109,
    REACT_CONTEXT_TYPE = 60110,
    REACT_FORWARD_REF_TYPE = 60112,
    REACT_SUSPENSE_TYPE = 60113,
    REACT_SUSPENSE_LIST_TYPE = 60120,
    REACT_MEMO_TYPE = 60115,
    REACT_LAZY_TYPE = 60116,
    REACT_BLOCK_TYPE = 60121,
    REACT_DEBUG_TRACING_MODE_TYPE = 60129,
    REACT_OFFSCREEN_TYPE = 60130,
    REACT_LEGACY_HIDDEN_TYPE = 60131;
if ("function" === typeof Symbol && Symbol.for) {
  var symbolFor = Symbol.for;
  REACT_ELEMENT_TYPE = symbolFor("react.element");
  REACT_PORTAL_TYPE = symbolFor("react.portal");
  REACT_FRAGMENT_TYPE = symbolFor("react.fragment");
  REACT_STRICT_MODE_TYPE = symbolFor("react.strict_mode");
  REACT_PROFILER_TYPE = symbolFor("react.profiler");
  REACT_PROVIDER_TYPE = symbolFor("react.provider");
  REACT_CONTEXT_TYPE = symbolFor("react.context");
  REACT_FORWARD_REF_TYPE = symbolFor("react.forward_ref");
  REACT_SUSPENSE_TYPE = symbolFor("react.suspense");
  REACT_SUSPENSE_LIST_TYPE = symbolFor("react.suspense_list");
  REACT_MEMO_TYPE = symbolFor("react.memo");
  REACT_LAZY_TYPE = symbolFor("react.lazy");
  REACT_BLOCK_TYPE = symbolFor("react.block");
  symbolFor("react.scope");
  REACT_DEBUG_TRACING_MODE_TYPE = symbolFor("react.debug_trace_mode");
  REACT_OFFSCREEN_TYPE = symbolFor("react.offscreen");
  REACT_LEGACY_HIDDEN_TYPE = symbolFor("react.legacy_hidden");
}

function getComponentName(type) {
  if (null == type) return null;
  if ("function" === typeof type) return type.displayName || type.name || null;
  if ("string" === typeof type) return type;
  switch (type) {
    case REACT_FRAGMENT_TYPE:
      return "Fragment";
    case REACT_PORTAL_TYPE:
      return "Portal";
    case REACT_PROFILER_TYPE:
      return "Profiler";
    case REACT_STRICT_MODE_TYPE:
      return "StrictMode";
    case REACT_SUSPENSE_TYPE:
      return "Suspense";
    case REACT_SUSPENSE_LIST_TYPE:
      return "SuspenseList";
  }
  if ("object" === typeof type)
    switch (type.$$typeof) {
      case REACT_CONTEXT_TYPE:
        return (type.displayName || "Context") + ".Consumer";
      case REACT_PROVIDER_TYPE:
        return (type._context.displayName || "Context") + ".Provider";
      case REACT_FORWARD_REF_TYPE:
        var innerType = type.render;
        innerType = innerType.displayName || innerType.name || "";
        return (
            type.displayName ||
            ("" !== innerType ? "ForwardRef(" + innerType + ")" : "ForwardRef")
        );
      case REACT_MEMO_TYPE:
        return getComponentName(type.type);
      case REACT_BLOCK_TYPE:
        return getComponentName(type._render);
      case REACT_LAZY_TYPE:
        innerType = type._payload;
        type = type._init;
        try {
          return getComponentName(type(innerType));
        } catch (x) {}
    }
  return null;
}


function getText(children) {
  if (Array.isArray(children)) {
    let text = "";
    for (let i = 0; i < children.length; i++) {
      const child = children[i];
      text += getText(child);
    }
    return text;
  }
  if (typeof children === 'object' && children) {
    const props = children.props || children.pendingProps ||children.memoizedProps;
    if (props && props.children) {
      return getText(props.children);
    }
    if (props) {
      const name = getComponentName(children.type)
      if (props.source && name === 'Image') {
        const source = Image.resolveAssetSource(props.source);
        return `image(${source.uri})&&`
      }
      if (name && name.includes('TextInput')) {
        return `textInput(placeholder:${props.placeholder || ""};defaultValue:${props.defaultValue || ""})`
      }
    }
  }
  if (typeof children === 'string') {
    return children + "&&";
  }
  return "";
}

function isSvg(funcString) {
  return /default.createElement\((.+\.Pattern|.+\.Mask|.+\.RadialGradient|.+\.LinearGradient|.+\.ClipPath|.+\.Image|.+\.Defs|.+\.Symbol|.+\.Use|.+\.G|.+\.TextPath|.+\.Path|.+\.Rect|.+\.Circle|.+\.Ellipse|.+\.Line|.+\.Polygon|.+\.Polyline|.+\.TSpan|.+\.Text)/.test(funcString);
}


function createViewPathByFiber(component,pageId) {
  let fibernode = component;
  let text;
  const fibers = [];
  text = getText(component);
  let vId;
  let i = 0;
  while (fibernode) {
    const props = fibernode.props || fibernode.pendingProps ||fibernode.memoizedProps || {};
    if (!vId && props.vId) {
      vId = props.vId;
    }
    if (!vId) {
      i++;
    }
    if (typeof fibernode.key === 'string' && fibernode.key.includes('root-sibling')) {
      break;
    }
    fibers.unshift(fibernode.index ? fibernode.tag + "[" + fibernode.index + "]" : fibernode.tag);
    if (typeof fibernode.key === 'string' && fibernode.key.includes('scene_id')) {
      break;
    }
    if (props.hasOwnProperty('navigation') && props.hasOwnProperty('route') && props.route.hasOwnProperty('key') && props.route.name === pageId) {
      break;
    }
    fibernode = fibernode.return;
  }
  if(isWarning()){
    if (!vId) {
      console.warn(`vId is not set in the current operation component`)
    }else if (i > 0) {
      console.warn(`vId "${vId}" is not in the current operation component, please confirm it is correct`)
    }
  }

  return {
    path: fibers.join("-"),
    description: text,
    vId
  };
}


function getSimpleComponentName(componentName) {
  if (!componentName) {
    componentName = '';
  }
  componentName = componentName.startsWith('topsecret-') ? componentName.slice(10) : componentName;
  switch (componentName) {
    case 'TouchableOpacity':
      componentName = 'TO';
      break;
    case 'RCTView':
      componentName = 'RV';
      break;
    case 'TouchableHighlight':
      componentName = 'TH';
      break;
    case 'View':
      componentName = 'V';
      break;
  }
  return componentName;
}

// function createViewPath(component) {
//     let hierarchy = [];
//     traverseParentTreeUp(hierarchy, component);
//     // hierarchy = hierarchy.map(function (component) {
//     //
//     // });
//     return hierarchy.length > 0 && hierarchy.join('-');
// }


// export function getInspectorDataByComponent(component) {
//
//
//     let componentHierarchy = getOwnerHierarchy(component), instance = lastNotNativeInstance(componentHierarchy),
//         hierarchy = createHierarchy(componentHierarchy), props = getHostProps(instance),
//         hostNode = instance.getHostNode();
//     let viewPath = createViewPath(component);
//     return {
//         hierarchy: hierarchy,
//         props: props,
//         selection: componentHierarchy.indexOf(instance),
//         componentHierarchy: componentHierarchy,
//         instance,
//         hostNode
//     };
// };


export function getViewPathByComponent(component,pageId) {
  return createViewPathByFiber(component,pageId);
}

