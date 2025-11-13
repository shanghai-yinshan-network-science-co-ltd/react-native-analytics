declare module 'react-native-analytics' {
  export function openLog(isOpen: boolean): void;

  export function clearUserId(): void;

  export function setUserId(userId: string): void;

  export function getCurrentPageId(): string;

  export function setWarning(isWarning: boolean): string;

  export function setOtaVersion(version: string): string;

  export function saveBusinessEvent(
      businessName: string,
      data?: { infoData: Record<string, any>, needExtraData?: boolean },
  ): string;


  export function uploadLogImmediately(delay?: number): Promise<void>;

  export function updateLocation(longitude: string, latitude: string, locationType?: string): void;

  export function useAnalyticsScreen(customerAction: (string)=>void): {
    navigationRef: any;
    onStateChange: () => void;
    onReady: () => void;
  };
}
