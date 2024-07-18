oApp.setBusy(false);
butCancel.firePress();

if (sap.n) {
    if (sap.n.GOS.callBack) {
        sap.n.GOS.callBack();
    }
}
