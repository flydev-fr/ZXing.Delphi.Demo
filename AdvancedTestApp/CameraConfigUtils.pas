unit CameraConfigUtils;

interface

uses
  System.SysUtils,
  Androidapi.JNIBridge,
  Androidapi.JNI.Hardware,
  Androidapi.JNI.JavaTypes,
  Androidapi.Helpers,
  Androidapi.Log;

type
  TCameraConfigUtils = class sealed
  private
    class var Tms: TMarshaller;
    class function findSettableValue(name: string; const supportedValues: JList;
      desiredValues: TArray<JString>): JString;
  public
    class procedure setVideoStabilization(parameters
      : JCamera_Parameters); static;
    class procedure setBarcodeSceneMode(parameters: JCamera_Parameters); static;
    class procedure setFocus(parameters: JCamera_Parameters; autoFocus, disableContinuous,
      safeMode: Boolean);
  end;


implementation

class function TCameraConfigUtils.findSettableValue(name: string;
  const supportedValues: JList; desiredValues: TArray<JString>): JString;
var
  desiredValue: JString;
  s: string;
  I: Integer;
begin
  if supportedValues <> nil then
  begin
    for desiredValue in desiredValues do
    begin
      if supportedValues.contains(desiredValue) then
        Exit(desiredValue);
    end;
  end;
  Result := nil;
end;


class procedure TCameraConfigUtils.setVideoStabilization
  (parameters: JCamera_Parameters);
begin
  if (parameters.isVideoStabilizationSupported()) then
  begin
    if (parameters.getVideoStabilization()) then
    begin
      // Log.i(TAG, "Video stabilization already enabled");
    end
    else
    begin
      // Log.i(TAG, "Enabling video stabilization...");
      parameters.setVideoStabilization(true);
    end;
  end
  else
  begin
    // Log.i(TAG, "This device does not support video stabilization");
  end;
end;

class procedure TCameraConfigUtils.setBarcodeSceneMode
  (parameters: JCamera_Parameters);
var
  sceneMode: JString;
begin
  if SameText(JStringToString(parameters.getSceneMode),
    JStringToString(TJCamera_Parameters.JavaClass.SCENE_MODE_BARCODE)) then
  begin
    // Log.i(TAG, "Barcode scene mode already set");
    Exit;
  end;
  sceneMode := findSettableValue('scene mode',
    parameters.getSupportedSceneModes(),
    [TJCamera_Parameters.JavaClass.SCENE_MODE_BARCODE]);
  if (sceneMode <> nil) then
    parameters.setSceneMode(sceneMode);
end;

class procedure TCameraConfigUtils.setFocus
  (parameters: JCamera_Parameters; autoFocus, disableContinuous,
  safeMode: Boolean);
var
  supportedFocusModes: JList;
  focusMode: JString;
begin
  supportedFocusModes := parameters.getSupportedFocusModes();
  focusMode := nil;
  if (autoFocus) then
  begin
    if (safeMode or disableContinuous) then
    begin
      focusMode := findSettableValue('focus mode', supportedFocusModes,
        [TJCamera_Parameters.JavaClass.FOCUS_MODE_AUTO]);
    end
    else
    begin
      focusMode := findSettableValue('focus mode', supportedFocusModes,
        [// TJCamera_Parameters.JavaClass.FOCUS_MODE_MACRO,
        TJCamera_Parameters.JavaClass.FOCUS_MODE_CONTINUOUS_PICTURE,
        TJCamera_Parameters.JavaClass.FOCUS_MODE_CONTINUOUS_VIDEO,
        TJCamera_Parameters.JavaClass.FOCUS_MODE_AUTO]);
    end;
  end;
  // Maybe selected auto-focus but not available, so fall through here:
  if (not safeMode) and (focusMode = nil) then
  begin
    focusMode := findSettableValue('focus mode', supportedFocusModes,
      [TJCamera_Parameters.JavaClass.FOCUS_MODE_MACRO,
      TJCamera_Parameters.JavaClass.FOCUS_MODE_EDOF]);
  end;
  if (focusMode <> nil) then
  begin
    if (focusMode.equals(parameters.getFocusMode())) then
    begin
      Logi(Tms.asAnsi('Focus mode already set to ' + JStringToString(focusMode))
        .ToPointer);
    end
    else
    begin
      parameters.setFocusMode(focusMode);
    end;
  end;
end;

end.
