package com.reactysanalytics;

import android.app.ActivityManager;
import android.content.Context;
import android.content.SharedPreferences;
import android.content.pm.ApplicationInfo;
import android.location.LocationManager;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.pm.Signature;
import android.content.pm.SigningInfo;
import android.content.res.Configuration;
import android.hardware.camera2.CameraCharacteristics;
import android.hardware.camera2.CameraManager;
import android.os.BatteryManager;
import android.os.Build;
import android.os.Debug;
import android.os.Environment;
import android.os.StatFs;
import android.os.SystemClock;
import android.provider.Settings;
import android.util.DisplayMetrics;

import com.google.android.gms.ads.identifier.AdvertisingIdClient;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.lang.reflect.Method;
import java.security.MessageDigest;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;
import java.util.TimeZone;

final class DevicePropertyHelper {

    private static final String PREFS_NAME = "device_property_helper";
    private static final String PREF_HAS_LAUNCHED = "has_launched_before";
    private static final String PREF_CLIENT_ID_GENERATE_TIMESTAMP = "client_id_generate_timestamp";
    private static final String PREF_CLIENT_ID_GENERATE_TIME = "client_id_generate_time";
    private static final String PREF_CLIENT_ID_LEVEL = "client_id_level";
    private static final String PREF_CLIENT_ID_ALGORITHM = "client_id_algorithm";
    private static final String PREF_FIRST_INIT_SDK_TIMESTAMP = "first_init_sdk_timestamp";
    private static final String PREF_FIRST_INIT_SDK_TIME = "first_init_sdk_time";
    private static final String KEY_TIMEZONE_DISPLAY_NAME = "timezone_display_name";
    private static final String KEY_LANGUAGE_ISO3 = "language_iso3";
    private static final String KEY_LANGUAGE_COUNTRY = "language_country";
    private static final String KEY_LANGUAGE_ISO3_COUNTRY = "language_iso3_country";
    private static final String KEY_LANGUAGE_DISPLAY_COUNTRY = "language_display_country";
    private static final String KEY_LANGUAGE_DISPLAY = "language_display";
    private static final String KEY_BOOT_TIMESTAMP = "boot_timestamp";
    private static final String KEY_BOOT_TIME = "boot_time";
    private static final String KEY_BATTERY_IS_CHARGING = "battery_is_charging";
    private static final String KEY_USER_AGENT = "user_agent";
    private static final String KEY_OAID = "oaid";
    private static final String KEY_OAID_SDK_NAME = "oaid_sdk_name";
    private static final String KEY_OAID_SUPPORT = "oaid_support";
    private static final String KEY_IS_HARMONY_OS = "is_harmony_os";
    private static final String KEY_HARMONY_OS_VERSION = "harmony_os_version";
    private static final String KEY_HEAP_SIZE = "heap_size";
    private static final String KEY_HEAP_START_SIZE = "heap_start_size";
    private static final String KEY_HEAP_GROWTH_LIMIT = "heap_growth_limit";
    private static final String KEY_MARKET_NAME = "market_name";
    private static final String KEY_MARKET_NAME_TYPE = "market_name_type";
    private static final String KEY_ADID_LIMIT_TRACKING_ENABLE = "adid_limit_tracking_enable";
    private static final String KEY_SCREEN_DENSITY = "screen_density";
    private static final String KEY_SCREEN_DENSITY_DPI = "screen_density_dpi";
    private static final String KEY_RESOLUTION = "resolution";
    private static final String KEY_SCREEN_ORIENTATION = "screen_orientation";
    private static final String KEY_SCREEN_BRIGHTNESS = "screen_brightness";
    private static final String KEY_HAS_WIFI = "has_wifi";
    private static final String KEY_HAS_GPS = "has_gps";
    private static final String KEY_HAS_NFC = "has_nfc";
    private static final String KEY_HAS_NFC_HOST = "has_nfc_host";
    private static final String KEY_HAS_WIFI_DIRECT = "has_wifi_direct";
    private static final String KEY_HAS_BLUETOOTH = "has_bluetooth";
    private static final String KEY_HAS_TELEPHONY = "has_telephony";
    private static final String KEY_HAS_OTG = "has_otg";
    private static final String KEY_HAS_AOA = "has_aoa";
    private static final String KEY_CAMERA_CHARACTERISTICS = "camera_characteristics";
    private static final String KEY_CPU_ABI = "cpu_abi";
    private static final String KEY_CPU_ABI2 = "cpu_abi2";
    private static final String KEY_CPU_ABIS = "cpu_abis";
    private static final String KEY_CPU_ARCHITECTURE = "cpu_architecture";
    private static final String KEY_CPU_SERIAL = "cpu_serial";
    private static final String KEY_CPU_CORES = "cpu_cores";
    private static final String KEY_DISK_USED_SPACE = "disk_used_space";
    private static final String KEY_MEMORY_USED = "memory_used";
    private static final String KEY_BASE_BAND_VERSION = "base_band_version";
    private static final String KEY_BOARD = "board";
    private static final String KEY_BOOT_LOADER = "boot_loader";
    private static final String KEY_FINGER_PRINT = "finger_print";
    private static final String KEY_DISPLAY = "display";
    private static final String KEY_HARDWARE = "hardware";
    private static final String KEY_HOST = "host";
    private static final String KEY_BUILD_ID = "build_id";
    private static final String KEY_DEVICE = "device";
    private static final String KEY_INCREMENTAL = "incremental";
    private static final String KEY_RADIO_VERSION = "radio_version";
    private static final String KEY_CHARACTERISTIC = "characteristic";
    private static final String KEY_SIGNATURES = "signatures";
    private static final String KEY_TAGS = "tags";
    private static final String KEY_SYS_BUILD_TIME = "sys_build_time";
    private static final String KEY_SYS_BUILD_TYPE = "sys_build_type";
    private static final String KEY_SYS_BUILD_USER = "sys_build_user";
    private static final String KEY_SYS_CODE_NAME = "sys_code_name";
    private static final String KEY_IS_FIRST_LAUNCH = "is_first_launch";
    private static final String KEY_IS_OPEN_GPS = "is_open_gps";
    private static final String KEY_IS_ROOT_DESC = "is_root_desc";
    private static final String KEY_IS_EMULATOR = "is_emulator";
    private static final String KEY_IS_EMULATOR_DESC = "is_emulator_desc";
    private static final String KEY_IS_HOOK = "is_hook";
    private static final String KEY_IS_HOOK_DESC = "is_hook_desc";
    private static final String KEY_IS_CLONE = "is_clone";
    private static final String KEY_IS_CLONE_DESC = "is_clone_desc";
    private static final String KEY_ENABLE_DEBUG = "enable_debug";
    private static final String KEY_IS_DEBUG = "is_debug";
    private static final String KEY_ADB_ENABLED = "adb_enabled";
    private static final String KEY_DEVELOPMENT_SETTINGS_ENABLE = "development_settings_enable";
    private static final String KEY_APP_VERSION_CODE = "app_version_code";
    private static final String KEY_APP_NAME = "app_name";
    private static final String KEY_MANUFACTURER = "manufacturer";
    private static final String KEY_PRODUCT = "product";
    private static final String KEY_DEVICE_NAME = "device_name";
    private static final String KEY_OS_VERSION_INT = "os_version_int";
    private static final String KEY_CLIENT_ID = "client_id";
    private static final String KEY_RELATION_CLIENT_ID = "relation_client_id";
    private static final String KEY_CLLIENT_ID_GENERATE_TIME = "cllient_id_generate_time";
    private static final String KEY_CLLIENT_ID_GENERATE_TIMESTAN = "cllient_id_generate_timestan";
    private static final String KEY_CLLIENT_ID_LEVEL = "cllient_id_level";
    private static final String KEY_CLLIENT_ID_GENERATE_ALGORITHN = "cllient_id_generate_algorithn";
    private static final String KEY_COLLECT_TIME = "collect_time";
    private static final String KEY_COLLECT_TIMESTAMP = "collect_timestamp";
    private static final String KEY_SERVER_TIME = "server_time";
    private static final String KEY_STORAGE_TIME = "storage_time";
    private static final String KEY_FIRST_INIT_SDK_TIME = "first_init_sdk_time";
    private static final String KEY_FIRST_INIT_SDK_TIMESTAMP = "first_init_sdk_timestamp";

    private DevicePropertyHelper() {
    }

    static String getTimezoneDisplayName(Context context) {
        try {
            if (context == null) {
                return "";
            }
            TimeZone timeZone = TimeZone.getDefault();
            if (timeZone == null) {
                return "";
            }
            String displayName = timeZone.getDisplayName(false, TimeZone.LONG, Locale.getDefault());
            return displayName != null ? displayName : "";
        } catch (Exception ignored) {
            return "";
        }
    }

    static String mergeCommonDevicePropertiesJson(Context context, String sdkJson) {
        try {
            JSONObject jsonObject = sdkJson != null && sdkJson.length() > 0
                    ? new JSONObject(sdkJson)
                    : new JSONObject();
            putExtendedDeviceProperties(jsonObject, context);
            return jsonObject.toString();
        } catch (Exception ignored) {
            JSONObject fallback = new JSONObject();
            try {
                putExtendedDeviceProperties(fallback, context);
                return fallback.toString();
            } catch (Exception innerIgnored) {
                return "{}";
            }
        }
    }

    private static void putExtendedDeviceProperties(JSONObject jsonObject, Context context) throws Exception {
        jsonObject.put(KEY_TIMEZONE_DISPLAY_NAME, getTimezoneDisplayName(context));
        putLanguageAndBootProperties(jsonObject, context);
        putMiscComplianceProperties(jsonObject, context);
        putScreenCapabilityProperties(jsonObject, context);
        putCpuDiskMemoryProperties(jsonObject, context);
        putBuildSystemHardwareProperties(jsonObject, context);
        putEnvironmentRiskProperties(jsonObject, context);
        putVersionChannelAppProperties(jsonObject, context);
        putDeviceFingerprintCollectTimeProperties(jsonObject, context);
    }

    static void recordFirstSdkInitIfNeeded(Context context) {
        try {
            if (context == null) {
                return;
            }
            SharedPreferences preferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
            if (preferences.contains(PREF_FIRST_INIT_SDK_TIMESTAMP)) {
                return;
            }
            long timestamp = System.currentTimeMillis();
            preferences.edit()
                    .putLong(PREF_FIRST_INIT_SDK_TIMESTAMP, timestamp)
                    .putString(PREF_FIRST_INIT_SDK_TIME, formatDateTime(timestamp))
                    .apply();
        } catch (Exception ignored) {
        }
    }

    private static void putLanguageAndBootProperties(JSONObject jsonObject, Context context) throws Exception {
        Locale locale = Locale.getDefault();
        if (locale == null) {
            jsonObject.put(KEY_LANGUAGE_ISO3, "");
            jsonObject.put(KEY_LANGUAGE_COUNTRY, "");
            jsonObject.put(KEY_LANGUAGE_ISO3_COUNTRY, "");
            jsonObject.put(KEY_LANGUAGE_DISPLAY_COUNTRY, "");
            jsonObject.put(KEY_LANGUAGE_DISPLAY, "");
            jsonObject.put(KEY_BOOT_TIMESTAMP, "");
            jsonObject.put(KEY_BOOT_TIME, "");
            return;
        }

        jsonObject.put(KEY_LANGUAGE_ISO3, safeString(getLanguageIso3(locale)));
        jsonObject.put(KEY_LANGUAGE_COUNTRY, safeString(locale.getCountry()));
        jsonObject.put(KEY_LANGUAGE_ISO3_COUNTRY, safeString(getLanguageIso3Country(locale)));
        jsonObject.put(KEY_LANGUAGE_DISPLAY_COUNTRY, safeString(locale.getDisplayCountry(Locale.getDefault())));
        jsonObject.put(KEY_LANGUAGE_DISPLAY, safeString(locale.getDisplayLanguage(Locale.getDefault())));

        long bootTimestamp = getBootTimestampMillis();
        if (bootTimestamp > 0) {
            jsonObject.put(KEY_BOOT_TIMESTAMP, bootTimestamp);
            jsonObject.put(KEY_BOOT_TIME, getBootTimeString(bootTimestamp));
        } else {
            jsonObject.put(KEY_BOOT_TIMESTAMP, "");
            jsonObject.put(KEY_BOOT_TIME, "");
        }
    }

    private static void putMiscComplianceProperties(JSONObject jsonObject, Context context) throws Exception {
        Object batteryIsCharging = getBatteryIsCharging(context);
        if (batteryIsCharging instanceof Boolean) {
            jsonObject.put(KEY_BATTERY_IS_CHARGING, batteryIsCharging);
        } else {
            jsonObject.put(KEY_BATTERY_IS_CHARGING, "");
        }

        jsonObject.put(KEY_USER_AGENT, safeString(getUserAgent()));
        jsonObject.put(KEY_OAID, "");
        jsonObject.put(KEY_OAID_SDK_NAME, "");
        jsonObject.put(KEY_OAID_SUPPORT, "");

        boolean isHarmonyOs = isHarmonyOs();
        jsonObject.put(KEY_IS_HARMONY_OS, isHarmonyOs);
        jsonObject.put(KEY_HARMONY_OS_VERSION, isHarmonyOs ? safeString(getHarmonyOsVersion()) : "");

        jsonObject.put(KEY_HEAP_SIZE, safeString(getHeapSize()));
        jsonObject.put(KEY_HEAP_START_SIZE, safeString(getSystemProperty("dalvik.vm.heapstartsize")));
        jsonObject.put(KEY_HEAP_GROWTH_LIMIT, safeString(getSystemProperty("dalvik.vm.heapgrowthlimit")));

        MarketNameInfo marketNameInfo = getMarketNameInfo();
        jsonObject.put(KEY_MARKET_NAME, safeString(marketNameInfo.name));
        jsonObject.put(KEY_MARKET_NAME_TYPE, safeString(marketNameInfo.type));

        Object adidLimitTrackingEnable = getAdidLimitTrackingEnable(context);
        if (adidLimitTrackingEnable instanceof Boolean) {
            jsonObject.put(KEY_ADID_LIMIT_TRACKING_ENABLE, adidLimitTrackingEnable);
        } else {
            jsonObject.put(KEY_ADID_LIMIT_TRACKING_ENABLE, "");
        }
    }

    private static void putScreenCapabilityProperties(JSONObject jsonObject, Context context) throws Exception {
        if (context == null) {
            putEmptyScreenCapabilityProperties(jsonObject);
            return;
        }

        DisplayMetrics displayMetrics = context.getResources().getDisplayMetrics();
        Configuration configuration = context.getResources().getConfiguration();
        PackageManager packageManager = context.getPackageManager();

        jsonObject.put(KEY_SCREEN_DENSITY, String.valueOf(displayMetrics.density));
        jsonObject.put(KEY_SCREEN_DENSITY_DPI, String.valueOf(displayMetrics.densityDpi));
        jsonObject.put(KEY_RESOLUTION, displayMetrics.widthPixels + "x" + displayMetrics.heightPixels);
        jsonObject.put(KEY_SCREEN_ORIENTATION, getScreenOrientationName(configuration));
        jsonObject.put(KEY_SCREEN_BRIGHTNESS, safeString(getScreenBrightness(context)));

        jsonObject.put(KEY_HAS_WIFI, hasSystemFeature(packageManager, PackageManager.FEATURE_WIFI));
        jsonObject.put(KEY_HAS_GPS, hasSystemFeature(packageManager, PackageManager.FEATURE_LOCATION_GPS));
        jsonObject.put(KEY_HAS_NFC, hasSystemFeature(packageManager, PackageManager.FEATURE_NFC));
        jsonObject.put(KEY_HAS_NFC_HOST, hasSystemFeature(packageManager, PackageManager.FEATURE_NFC_HOST_CARD_EMULATION));
        jsonObject.put(KEY_HAS_WIFI_DIRECT, hasSystemFeature(packageManager, PackageManager.FEATURE_WIFI_DIRECT));
        jsonObject.put(KEY_HAS_BLUETOOTH, hasSystemFeature(packageManager, PackageManager.FEATURE_BLUETOOTH));
        jsonObject.put(KEY_HAS_TELEPHONY, hasSystemFeature(packageManager, PackageManager.FEATURE_TELEPHONY));
        jsonObject.put(KEY_HAS_OTG, hasSystemFeature(packageManager, PackageManager.FEATURE_USB_HOST));
        jsonObject.put(KEY_HAS_AOA, hasSystemFeature(packageManager, PackageManager.FEATURE_USB_ACCESSORY));
        jsonObject.put(KEY_CAMERA_CHARACTERISTICS, safeString(getCameraCharacteristicsJson(context)));
    }

    private static void putCpuDiskMemoryProperties(JSONObject jsonObject, Context context) throws Exception {
        String[] supportedAbis = Build.SUPPORTED_ABIS != null ? Build.SUPPORTED_ABIS : new String[0];
        jsonObject.put(KEY_CPU_ABI, supportedAbis.length > 0 ? safeString(supportedAbis[0]) : "");
        jsonObject.put(KEY_CPU_ABI2, supportedAbis.length > 1 ? safeString(supportedAbis[1]) : "");
        jsonObject.put(KEY_CPU_ABIS, getCpuAbisJson(supportedAbis));
        jsonObject.put(KEY_CPU_ARCHITECTURE, safeString(getCpuArchitecture()));
        jsonObject.put(KEY_CPU_SERIAL, safeString(getCpuSerial()));
        jsonObject.put(KEY_CPU_CORES, Runtime.getRuntime().availableProcessors());

        long diskUsedSpace = getDiskUsedSpaceBytes();
        if (diskUsedSpace >= 0) {
            jsonObject.put(KEY_DISK_USED_SPACE, diskUsedSpace);
        } else {
            jsonObject.put(KEY_DISK_USED_SPACE, "");
        }

        long memoryUsed = getMemoryUsedBytes(context);
        if (memoryUsed >= 0) {
            jsonObject.put(KEY_MEMORY_USED, memoryUsed);
        } else {
            jsonObject.put(KEY_MEMORY_USED, "");
        }
    }

    private static void putBuildSystemHardwareProperties(JSONObject jsonObject, Context context) throws Exception {
        String radioVersion = safeString(Build.getRadioVersion());
        jsonObject.put(KEY_BASE_BAND_VERSION, radioVersion);
        jsonObject.put(KEY_BOARD, safeString(Build.BOARD));
        jsonObject.put(KEY_BOOT_LOADER, safeString(Build.BOOTLOADER));
        jsonObject.put(KEY_FINGER_PRINT, safeString(Build.FINGERPRINT));
        jsonObject.put(KEY_DISPLAY, safeString(Build.DISPLAY));
        jsonObject.put(KEY_HARDWARE, safeString(Build.HARDWARE));
        jsonObject.put(KEY_HOST, safeString(Build.HOST));
        jsonObject.put(KEY_BUILD_ID, safeString(Build.ID));
        jsonObject.put(KEY_DEVICE, safeString(Build.DEVICE));
        jsonObject.put(KEY_INCREMENTAL, safeString(Build.VERSION.INCREMENTAL));
        jsonObject.put(KEY_RADIO_VERSION, radioVersion);
        jsonObject.put(KEY_CHARACTERISTIC, safeString(getSystemCharacteristicJson()));
        jsonObject.put(KEY_SIGNATURES, safeString(getAppSignaturesJson(context)));
        jsonObject.put(KEY_TAGS, safeString(Build.TAGS));
        jsonObject.put(KEY_SYS_BUILD_TIME, safeString(getSysBuildTimeString()));
        jsonObject.put(KEY_SYS_BUILD_TYPE, safeString(Build.TYPE));
        jsonObject.put(KEY_SYS_BUILD_USER, safeString(Build.USER));
        jsonObject.put(KEY_SYS_CODE_NAME, safeString(Build.VERSION.CODENAME));
    }

    private static String getSystemCharacteristicJson() {
        try {
            JSONObject characteristic = new JSONObject();
            characteristic.put("brand", safeString(Build.BRAND));
            characteristic.put("manufacturer", safeString(Build.MANUFACTURER));
            characteristic.put("product", safeString(Build.PRODUCT));
            characteristic.put("model", safeString(Build.MODEL));
            characteristic.put("device", safeString(Build.DEVICE));
            return characteristic.toString();
        } catch (Exception ignored) {
            return "";
        }
    }

    private static String getSysBuildTimeString() {
        try {
            if (Build.TIME <= 0) {
                return "";
            }
            SimpleDateFormat formatter = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault());
            return formatter.format(new Date(Build.TIME));
        } catch (Exception ignored) {
            return "";
        }
    }

    private static String getAppSignaturesJson(Context context) {
        try {
            if (context == null) {
                return "";
            }
            PackageManager packageManager = context.getPackageManager();
            PackageInfo packageInfo;
            JSONArray signatures = new JSONArray();
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                packageInfo = packageManager.getPackageInfo(context.getPackageName(), PackageManager.GET_SIGNING_CERTIFICATES);
                SigningInfo signingInfo = packageInfo.signingInfo;
                if (signingInfo == null) {
                    return "";
                }
                Signature[] apkSignatures = signingInfo.hasMultipleSigners()
                        ? signingInfo.getApkContentsSigners()
                        : signingInfo.getSigningCertificateHistory();
                if (apkSignatures == null) {
                    return "";
                }
                for (Signature signature : apkSignatures) {
                    signatures.put(hashSignature(signature));
                }
            } else {
                packageInfo = packageManager.getPackageInfo(context.getPackageName(), PackageManager.GET_SIGNATURES);
                if (packageInfo.signatures == null) {
                    return "";
                }
                for (Signature signature : packageInfo.signatures) {
                    signatures.put(hashSignature(signature));
                }
            }
            return signatures.length() > 0 ? signatures.toString() : "";
        } catch (Exception ignored) {
            return "";
        }
    }

    private static String hashSignature(Signature signature) throws Exception {
        MessageDigest messageDigest = MessageDigest.getInstance("SHA-256");
        byte[] digest = messageDigest.digest(signature.toByteArray());
        StringBuilder builder = new StringBuilder();
        for (byte value : digest) {
            builder.append(String.format(Locale.US, "%02x", value));
        }
        return builder.toString();
    }

    private static void putEnvironmentRiskProperties(JSONObject jsonObject, Context context) throws Exception {
        boolean isRooted = isDeviceRooted();
        boolean isEmulator = isEmulator();
        boolean isHook = isHookDetected();
        boolean isClone = isCloneApp(context);

        jsonObject.put(KEY_IS_FIRST_LAUNCH, isFirstLaunch(context));
        jsonObject.put(KEY_IS_OPEN_GPS, isGpsOpen(context));
        jsonObject.put(KEY_IS_ROOT_DESC, safeString(getRootDescription(isRooted)));
        jsonObject.put(KEY_IS_EMULATOR, isEmulator);
        jsonObject.put(KEY_IS_EMULATOR_DESC, safeString(getEmulatorDescription(isEmulator)));
        jsonObject.put(KEY_IS_HOOK, isHook);
        jsonObject.put(KEY_IS_HOOK_DESC, safeString(getHookDescription(isHook)));
        jsonObject.put(KEY_IS_CLONE, isClone);
        jsonObject.put(KEY_IS_CLONE_DESC, safeString(getCloneDescription(isClone)));
        jsonObject.put(KEY_ENABLE_DEBUG, isDebugBuildEnabled(context));
        jsonObject.put(KEY_IS_DEBUG, Debug.isDebuggerConnected());
        jsonObject.put(KEY_ADB_ENABLED, isAdbEnabled(context));
        jsonObject.put(KEY_DEVELOPMENT_SETTINGS_ENABLE, isDevelopmentSettingsEnabled(context));
    }

    private static void putVersionChannelAppProperties(JSONObject jsonObject, Context context) throws Exception {
        jsonObject.put(KEY_APP_VERSION_CODE, getAppVersionCode(context));
        jsonObject.put(KEY_APP_NAME, safeString(getAppName(context)));
        jsonObject.put(KEY_MANUFACTURER, safeString(Build.MANUFACTURER));
        jsonObject.put(KEY_PRODUCT, safeString(Build.PRODUCT));
        jsonObject.put(KEY_DEVICE_NAME, safeString(getDeviceName(context)));
        jsonObject.put(KEY_OS_VERSION_INT, Build.VERSION.SDK_INT);
    }

    private static void putDeviceFingerprintCollectTimeProperties(JSONObject jsonObject, Context context) throws Exception {
        String clientId = getClientId(context);
        ClientIdMetadata clientIdMetadata = getClientIdMetadata(context, clientId);
        long collectTimestamp = System.currentTimeMillis();

        jsonObject.put(KEY_CLIENT_ID, safeString(clientId));
        jsonObject.put(KEY_RELATION_CLIENT_ID, "");
        jsonObject.put(KEY_CLLIENT_ID_GENERATE_TIME, safeString(clientIdMetadata.generateTime));
        jsonObject.put(KEY_CLLIENT_ID_GENERATE_TIMESTAN, clientIdMetadata.generateTimestamp >= 0
                ? clientIdMetadata.generateTimestamp
                : "");
        jsonObject.put(KEY_CLLIENT_ID_LEVEL, safeString(clientIdMetadata.level));
        jsonObject.put(KEY_CLLIENT_ID_GENERATE_ALGORITHN, safeString(clientIdMetadata.algorithm));
        jsonObject.put(KEY_COLLECT_TIME, formatDateTime(collectTimestamp));
        jsonObject.put(KEY_COLLECT_TIMESTAMP, collectTimestamp);
        jsonObject.put(KEY_SERVER_TIME, "");
        jsonObject.put(KEY_STORAGE_TIME, "");
        putIfAbsent(jsonObject, KEY_FIRST_INIT_SDK_TIME, safeString(getFirstInitSdkTime(context)));
        putIfAbsent(jsonObject, KEY_FIRST_INIT_SDK_TIMESTAMP, getFirstInitSdkTimestamp(context));
    }

    private static void putIfAbsent(JSONObject jsonObject, String key, Object value) throws Exception {
        if (!jsonObject.has(key) || jsonObject.isNull(key) || isEmptyJsonValue(jsonObject.get(key))) {
            jsonObject.put(key, value);
        }
    }

    private static boolean isEmptyJsonValue(Object value) {
        if (value == null || value == JSONObject.NULL) {
            return true;
        }
        if (value instanceof String) {
            return ((String) value).length() == 0;
        }
        return false;
    }

    private static String getClientId(Context context) {
        try {
            if (context == null) {
                return "";
            }
            return safeString(Settings.Secure.getString(context.getContentResolver(), Settings.Secure.ANDROID_ID));
        } catch (Exception ignored) {
            return "";
        }
    }

    private static ClientIdMetadata getClientIdMetadata(Context context, String clientId) {
        ClientIdMetadata metadata = new ClientIdMetadata("", -1, "", "");
        try {
            if (context == null || clientId.length() == 0) {
                return metadata;
            }
            SharedPreferences preferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
            long generateTimestamp = preferences.getLong(PREF_CLIENT_ID_GENERATE_TIMESTAMP, -1);
            if (generateTimestamp < 0) {
                generateTimestamp = System.currentTimeMillis();
                preferences.edit()
                        .putLong(PREF_CLIENT_ID_GENERATE_TIMESTAMP, generateTimestamp)
                        .putString(PREF_CLIENT_ID_GENERATE_TIME, formatDateTime(generateTimestamp))
                        .putString(PREF_CLIENT_ID_LEVEL, "system")
                        .putString(PREF_CLIENT_ID_ALGORITHM, "android_id")
                        .apply();
            }
            metadata.generateTimestamp = generateTimestamp;
            metadata.generateTime = safeString(preferences.getString(PREF_CLIENT_ID_GENERATE_TIME, ""));
            metadata.level = safeString(preferences.getString(PREF_CLIENT_ID_LEVEL, "system"));
            metadata.algorithm = safeString(preferences.getString(PREF_CLIENT_ID_ALGORITHM, "android_id"));
            if (metadata.generateTime.length() == 0 && generateTimestamp >= 0) {
                metadata.generateTime = formatDateTime(generateTimestamp);
            }
            return metadata;
        } catch (Exception ignored) {
            return metadata;
        }
    }

    private static String getFirstInitSdkTime(Context context) {
        try {
            if (context == null) {
                return "";
            }
            recordFirstSdkInitIfNeeded(context);
            return safeString(context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                    .getString(PREF_FIRST_INIT_SDK_TIME, ""));
        } catch (Exception ignored) {
            return "";
        }
    }

    private static Object getFirstInitSdkTimestamp(Context context) {
        try {
            if (context == null) {
                return "";
            }
            recordFirstSdkInitIfNeeded(context);
            SharedPreferences preferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
            if (!preferences.contains(PREF_FIRST_INIT_SDK_TIMESTAMP)) {
                return "";
            }
            return preferences.getLong(PREF_FIRST_INIT_SDK_TIMESTAMP, 0);
        } catch (Exception ignored) {
            return "";
        }
    }

    private static String formatDateTime(long timestampMillis) {
        try {
            SimpleDateFormat formatter = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault());
            return formatter.format(new Date(timestampMillis));
        } catch (Exception ignored) {
            return "";
        }
    }

    private static final class ClientIdMetadata {
        private String generateTime;
        private long generateTimestamp;
        private String level;
        private String algorithm;

        private ClientIdMetadata(String generateTime, long generateTimestamp, String level, String algorithm) {
            this.generateTime = generateTime;
            this.generateTimestamp = generateTimestamp;
            this.level = level;
            this.algorithm = algorithm;
        }
    }

    private static Object getAppVersionCode(Context context) {
        try {
            if (context == null) {
                return "";
            }
            PackageManager packageManager = context.getPackageManager();
            PackageInfo packageInfo = packageManager.getPackageInfo(context.getPackageName(), 0);
            if (packageInfo == null) {
                return "";
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                return packageInfo.getLongVersionCode();
            }
            return packageInfo.versionCode;
        } catch (Exception ignored) {
            return "";
        }
    }

    private static String getAppName(Context context) {
        try {
            if (context == null) {
                return "";
            }
            PackageManager packageManager = context.getPackageManager();
            CharSequence label = packageManager.getApplicationLabel(context.getApplicationInfo());
            return label != null ? label.toString() : "";
        } catch (Exception ignored) {
            return "";
        }
    }

    private static String getDeviceName(Context context) {
        try {
            if (context == null) {
                return safeString(Build.MODEL);
            }
            String deviceName = Settings.Global.getString(context.getContentResolver(), Settings.Global.DEVICE_NAME);
            if (deviceName != null && deviceName.length() > 0) {
                return deviceName;
            }
            return safeString(Build.MODEL);
        } catch (Exception ignored) {
            return safeString(Build.MODEL);
        }
    }

    private static boolean isFirstLaunch(Context context) {
        try {
            if (context == null) {
                return false;
            }
            SharedPreferences preferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
            if (preferences.getBoolean(PREF_HAS_LAUNCHED, false)) {
                return false;
            }
            preferences.edit().putBoolean(PREF_HAS_LAUNCHED, true).apply();
            return true;
        } catch (Exception ignored) {
            return false;
        }
    }

    private static boolean isGpsOpen(Context context) {
        try {
            if (context == null) {
                return false;
            }
            LocationManager locationManager = (LocationManager) context.getSystemService(Context.LOCATION_SERVICE);
            if (locationManager == null) {
                return false;
            }
            return locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER);
        } catch (Exception ignored) {
            return false;
        }
    }

    private static boolean isDeviceRooted() {
        try {
            String[] paths = new String[]{
                    "/system/app/Superuser.apk",
                    "/sbin/su",
                    "/system/bin/su",
                    "/system/xbin/su",
                    "/data/local/xbin/su",
                    "/data/local/bin/su",
                    "/system/sd/xbin/su",
                    "/system/bin/failsafe/su",
                    "/data/local/su",
                    "/su/bin/su"
            };
            for (String path : paths) {
                if (new File(path).exists()) {
                    return true;
                }
            }
            return false;
        } catch (Exception ignored) {
            return false;
        }
    }

    private static String getRootDescription(boolean isRooted) {
        return isRooted ? "rooted" : "not_rooted";
    }

    private static boolean isEmulator() {
        try {
            return Build.FINGERPRINT.startsWith("generic")
                    || Build.FINGERPRINT.startsWith("unknown")
                    || Build.MODEL.contains("google_sdk")
                    || Build.MODEL.contains("Emulator")
                    || Build.MODEL.contains("Android SDK built for x86")
                    || Build.MANUFACTURER.contains("Genymotion")
                    || (Build.BRAND.startsWith("generic") && Build.DEVICE.startsWith("generic"))
                    || "google_sdk".equals(Build.PRODUCT)
                    || safeString(Build.HARDWARE).contains("goldfish")
                    || safeString(Build.HARDWARE).contains("ranchu");
        } catch (Exception ignored) {
            return false;
        }
    }

    private static String getEmulatorDescription(boolean isEmulator) {
        return isEmulator ? "emulator" : "physical_device";
    }

    private static boolean isHookDetected() {
        try {
            return Debug.isDebuggerConnected() || isXposedPresent() || hasSuspiciousMapsEntry();
        } catch (Exception ignored) {
            return false;
        }
    }

    private static boolean isXposedPresent() {
        try {
            Class.forName("de.robv.android.xposed.XposedBridge");
            return true;
        } catch (Exception ignored) {
            return false;
        }
    }

    private static boolean hasSuspiciousMapsEntry() {
        BufferedReader reader = null;
        try {
            reader = new BufferedReader(new FileReader("/proc/self/maps"));
            String line;
            while ((line = reader.readLine()) != null) {
                String lowerLine = line.toLowerCase(Locale.US);
                if (lowerLine.contains("frida")
                        || lowerLine.contains("xposed")
                        || lowerLine.contains("substrate")
                        || lowerLine.contains("libsubstrate")) {
                    return true;
                }
            }
            return false;
        } catch (Exception ignored) {
            return false;
        } finally {
            if (reader != null) {
                try {
                    reader.close();
                } catch (Exception ignored) {
                }
            }
        }
    }

    private static String getHookDescription(boolean isHook) {
        if (!isHook) {
            return "not_hooked";
        }
        StringBuilder builder = new StringBuilder();
        if (Debug.isDebuggerConnected()) {
            builder.append("debugger_attached");
        }
        if (isXposedPresent()) {
            appendHookReason(builder, "xposed");
        }
        if (hasSuspiciousMapsEntry()) {
            appendHookReason(builder, "suspicious_maps");
        }
        return builder.length() > 0 ? builder.toString() : "hooked";
    }

    private static void appendHookReason(StringBuilder builder, String reason) {
        if (builder.length() > 0) {
            builder.append(",");
        }
        builder.append(reason);
    }

    private static boolean isCloneApp(Context context) {
        try {
            if (context == null) {
                return false;
            }
            String dataDir = context.getApplicationInfo() != null ? context.getApplicationInfo().dataDir : "";
            if (dataDir != null) {
                String lowerDataDir = dataDir.toLowerCase(Locale.US);
                if (lowerDataDir.contains("parallel")
                        || lowerDataDir.contains("clone")
                        || lowerDataDir.contains("dual")) {
                    return true;
                }
            }
            int userId = android.os.Process.myUid() / 100000;
            return userId > 0;
        } catch (Exception ignored) {
            return false;
        }
    }

    private static String getCloneDescription(boolean isClone) {
        return isClone ? "cloned_app" : "normal_app";
    }

    private static boolean isDebugBuildEnabled(Context context) {
        try {
            if (context == null) {
                return false;
            }
            return (context.getApplicationInfo().flags & ApplicationInfo.FLAG_DEBUGGABLE) != 0;
        } catch (Exception ignored) {
            return false;
        }
    }

    private static boolean isAdbEnabled(Context context) {
        try {
            if (context == null) {
                return false;
            }
            return Settings.Global.getInt(context.getContentResolver(), Settings.Global.ADB_ENABLED, 0) == 1;
        } catch (Exception ignored) {
            return false;
        }
    }

    private static boolean isDevelopmentSettingsEnabled(Context context) {
        try {
            if (context == null) {
                return false;
            }
            return Settings.Global.getInt(context.getContentResolver(), Settings.Global.DEVELOPMENT_SETTINGS_ENABLED, 0) == 1;
        } catch (Exception ignored) {
            return false;
        }
    }

    private static String getCpuAbisJson(String[] supportedAbis) {
        try {
            if (supportedAbis == null || supportedAbis.length == 0) {
                return "";
            }
            JSONArray jsonArray = new JSONArray();
            for (String abi : supportedAbis) {
                jsonArray.put(safeString(abi));
            }
            return jsonArray.toString();
        } catch (Exception ignored) {
            return "";
        }
    }

    private static String getCpuArchitecture() {
        try {
            String hardware = safeString(Build.HARDWARE);
            if (hardware.length() > 0) {
                return hardware;
            }
            return safeString(System.getProperty("os.arch"));
        } catch (Exception ignored) {
            return "";
        }
    }

    private static String getCpuSerial() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                return safeString(Build.getSerial());
            }
            return safeString(Build.SERIAL);
        } catch (Exception ignored) {
            return "";
        }
    }

    private static long getDiskUsedSpaceBytes() {
        try {
            StatFs statFs = new StatFs(Environment.getDataDirectory().getPath());
            long total = statFs.getBlockCountLong() * statFs.getBlockSizeLong();
            long available = statFs.getAvailableBlocksLong() * statFs.getBlockSizeLong();
            if (total <= 0 || available < 0 || total < available) {
                return -1;
            }
            return total - available;
        } catch (Exception ignored) {
            return -1;
        }
    }

    private static long getMemoryUsedBytes(Context context) {
        try {
            if (context == null) {
                return -1;
            }
            ActivityManager activityManager = (ActivityManager) context.getSystemService(Context.ACTIVITY_SERVICE);
            if (activityManager == null) {
                return -1;
            }
            ActivityManager.MemoryInfo memoryInfo = new ActivityManager.MemoryInfo();
            activityManager.getMemoryInfo(memoryInfo);
            long total = memoryInfo.totalMem;
            long available = memoryInfo.availMem;
            if (total <= 0 || available < 0 || total < available) {
                return -1;
            }
            return total - available;
        } catch (Exception ignored) {
            return -1;
        }
    }

    private static void putEmptyScreenCapabilityProperties(JSONObject jsonObject) throws Exception {
        jsonObject.put(KEY_SCREEN_DENSITY, "");
        jsonObject.put(KEY_SCREEN_DENSITY_DPI, "");
        jsonObject.put(KEY_RESOLUTION, "");
        jsonObject.put(KEY_SCREEN_ORIENTATION, "");
        jsonObject.put(KEY_SCREEN_BRIGHTNESS, "");
        jsonObject.put(KEY_HAS_WIFI, "");
        jsonObject.put(KEY_HAS_GPS, "");
        jsonObject.put(KEY_HAS_NFC, "");
        jsonObject.put(KEY_HAS_NFC_HOST, "");
        jsonObject.put(KEY_HAS_WIFI_DIRECT, "");
        jsonObject.put(KEY_HAS_BLUETOOTH, "");
        jsonObject.put(KEY_HAS_TELEPHONY, "");
        jsonObject.put(KEY_HAS_OTG, "");
        jsonObject.put(KEY_HAS_AOA, "");
        jsonObject.put(KEY_CAMERA_CHARACTERISTICS, "");
    }

    private static String getScreenOrientationName(Configuration configuration) {
        if (configuration == null) {
            return "";
        }
        if (configuration.orientation == Configuration.ORIENTATION_PORTRAIT) {
            return "portrait";
        }
        if (configuration.orientation == Configuration.ORIENTATION_LANDSCAPE) {
            return "landscape";
        }
        return "";
    }

    private static String getScreenBrightness(Context context) {
        try {
            int brightness = Settings.System.getInt(context.getContentResolver(), Settings.System.SCREEN_BRIGHTNESS, -1);
            if (brightness < 0) {
                return "";
            }
            return String.format(Locale.US, "%.4f", brightness / 255.0f);
        } catch (Exception ignored) {
            return "";
        }
    }

    private static boolean hasSystemFeature(PackageManager packageManager, String feature) {
        try {
            return packageManager != null && packageManager.hasSystemFeature(feature);
        } catch (Exception ignored) {
            return false;
        }
    }

    private static String getCameraCharacteristicsJson(Context context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP || context == null) {
            return "";
        }
        try {
            CameraManager cameraManager = (CameraManager) context.getSystemService(Context.CAMERA_SERVICE);
            if (cameraManager == null) {
                return "";
            }
            JSONArray cameras = new JSONArray();
            for (String cameraId : cameraManager.getCameraIdList()) {
                CameraCharacteristics characteristics = cameraManager.getCameraCharacteristics(cameraId);
                JSONObject camera = new JSONObject();
                camera.put("cameraId", cameraId);
                Integer lensFacing = characteristics.get(CameraCharacteristics.LENS_FACING);
                camera.put("lensFacing", lensFacing == null ? "" : lensFacing);
                cameras.put(camera);
            }
            return cameras.length() > 0 ? cameras.toString() : "";
        } catch (Exception ignored) {
            return "";
        }
    }

    private static Object getBatteryIsCharging(Context context) {
        try {
            if (context == null) {
                return "";
            }
            IntentFilter filter = new IntentFilter(Intent.ACTION_BATTERY_CHANGED);
            Intent batteryStatus = context.registerReceiver(null, filter);
            if (batteryStatus == null) {
                return "";
            }
            int status = batteryStatus.getIntExtra(BatteryManager.EXTRA_STATUS, -1);
            if (status == -1) {
                return "";
            }
            return status == BatteryManager.BATTERY_STATUS_CHARGING
                    || status == BatteryManager.BATTERY_STATUS_FULL;
        } catch (Exception ignored) {
            return "";
        }
    }

    private static String getUserAgent() {
        try {
            return safeString(System.getProperty("http.agent"));
        } catch (Exception ignored) {
            return "";
        }
    }

    private static boolean isHarmonyOs() {
        try {
            Class<?> buildExClass = Class.forName("com.huawei.system.BuildEx");
            Method getOsBrand = buildExClass.getMethod("getOsBrand");
            Object brand = getOsBrand.invoke(null);
            return brand != null && "harmony".equalsIgnoreCase(brand.toString());
        } catch (Exception ignored) {
            return safeString(getSystemProperty("ro.build.version.harmony")).length() > 0;
        }
    }

    private static String getHarmonyOsVersion() {
        String version = getSystemProperty("ro.build.version.harmony");
        if (version.length() > 0) {
            return version;
        }
        return getSystemProperty("hw_sc.build.platform.version");
    }

    private static String getHeapSize() {
        try {
            Runtime runtime = Runtime.getRuntime();
            return String.valueOf(runtime.totalMemory());
        } catch (Exception ignored) {
            return "";
        }
    }

    private static MarketNameInfo getMarketNameInfo() {
        String marketName = getSystemProperty("ro.product.marketname");
        if (marketName.length() > 0) {
            return new MarketNameInfo(marketName, "marketname");
        }
        if (Build.MODEL != null && Build.MODEL.length() > 0) {
            return new MarketNameInfo(Build.MODEL, "model");
        }
        return new MarketNameInfo("", "");
    }

    private static Object getAdidLimitTrackingEnable(Context context) {
        try {
            if (context == null) {
                return "";
            }
            AdvertisingIdClient.Info info = AdvertisingIdClient.getAdvertisingIdInfo(context);
            if (info == null) {
                return "";
            }
            return info.isLimitAdTrackingEnabled();
        } catch (Exception ignored) {
            return "";
        }
    }

    private static String getSystemProperty(String key) {
        try {
            Class<?> clazz = Class.forName("android.os.SystemProperties");
            Method get = clazz.getMethod("get", String.class, String.class);
            Object value = get.invoke(null, key, "");
            return value != null ? value.toString() : "";
        } catch (Exception ignored) {
            return "";
        }
    }

    private static String getLanguageIso3(Locale locale) {
        try {
            return locale.getISO3Language();
        } catch (Exception ignored) {
            return "";
        }
    }

    private static String getLanguageIso3Country(Locale locale) {
        try {
            return locale.getISO3Country();
        } catch (Exception ignored) {
            return "";
        }
    }

    private static long getBootTimestampMillis() {
        try {
            long elapsedRealtime = SystemClock.elapsedRealtime();
            if (elapsedRealtime <= 0) {
                return 0;
            }
            return System.currentTimeMillis() - elapsedRealtime;
        } catch (Exception ignored) {
            return 0;
        }
    }

    private static String getBootTimeString(long bootTimestampMillis) {
        try {
            SimpleDateFormat formatter = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault());
            return formatter.format(new Date(bootTimestampMillis));
        } catch (Exception ignored) {
            return "";
        }
    }

    private static String safeString(String value) {
        return value != null ? value : "";
    }

    private static final class MarketNameInfo {
        final String name;
        final String type;

        MarketNameInfo(String name, String type) {
            this.name = name;
            this.type = type;
        }
    }
}
