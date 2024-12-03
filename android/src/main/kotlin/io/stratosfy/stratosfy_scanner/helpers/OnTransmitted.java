package io.stratosfy.stratosfy_scanner.helpers;

public interface OnTransmitted{
    void onSuccess(String message);
    void onFaliure(int errorCode,String message);
    void onUncapabelDevice(String message);
    void onUnknownAdvertiser(String message);
}
