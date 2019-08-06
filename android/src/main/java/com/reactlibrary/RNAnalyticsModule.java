
package com.reactlibrary;

import com.facebook.react.bridge.Callback;
import android.os.Bundle;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.maizijf.analytics.MZLogAgent;
import com.maizijf.analytics.manager.debugtool.DebugMenuView;
import com.maizijf.analytics.manager.debugtool.DebugViewManager;

public class RNAnalyticsModule extends ReactContextBaseJavaModule {

  private final ReactApplicationContext reactContext;

  public RNAnalyticsModule(ReactApplicationContext reactContext) {
    super(reactContext);
    this.reactContext = reactContext;
    DebugViewManager.addOnCatchModeStateChangeListener(new DebugMenuView.OnCatchModeStateChangeListener() {
      @Override
      public void onCatchModeStateChanged(boolean isCatchModeOpened) {
          Bundle bundle = new Bundle();
          bundle.putBoolean(IS_OPENED, isCatchModeOpened);
          RNAnalyticsModule.this.emit(reactContext, EVENT_NAME, bundle);
      }
    });
  }

  private static final String EVENT_NAME = "RNAnalytics.toggleBuriedView";
  private static final String IS_OPENED = "isCatchModeOpened";


    @ReactMethod
    public void sendBuriedData(String data) {
        MZLogAgent.saveRNEvent(data);
    }


    private void emit(ReactContext context, String event, Bundle bundle) {
        if (bundle == null) {
            bundle = new Bundle();
        }
        WritableMap params = Arguments.fromBundle(bundle);
        if (context != null) {
            context.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                   .emit(event, params);
        }
    }

  @Override
  public String getName() {
    return "RNAnalytics";
  }
}