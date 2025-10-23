
package com.reactysanalytics;

import android.os.Bundle;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;

import cn.yinshantech.analytics.MZLogAgent;
import cn.yinshantech.analytics.manager.debugtool.DebugMenuView;
import cn.yinshantech.analytics.manager.debugtool.DebugViewManager;

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
          RNAnalyticsModule.this.emit(RNAnalyticsModule.this.reactContext, EVENT_NAME, bundle);
      }
    });
  }

  private static final String EVENT_NAME = "RNAnalytics.toggleBuriedView";
  private static final String IS_OPENED = "isCatchModeOpened";


    @ReactMethod
    public void sendBuriedData(String data) {
        MZLogAgent.saveRNEvent(data);
    }

    @ReactMethod
    public void setUserId(String userId) {
        MZLogAgent.setUserId(userId);
    }

    @ReactMethod
    public void saveBusinessEvent(String businessName){
        MZLogAgent.saveBusinessEvent(businessName);
    }

    @ReactMethod
    public void clearUserId() {
        MZLogAgent.clearUserId();
    }


    @ReactMethod
    public void uploadLogImmediately() {
        MZLogAgent.uploadLogImmediately();
    }


    @ReactMethod
    public void updateLocation(String longitude, String latitude, String locationType) {
        MZLogAgent.updateLocation(longitude, latitude, locationType);
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
