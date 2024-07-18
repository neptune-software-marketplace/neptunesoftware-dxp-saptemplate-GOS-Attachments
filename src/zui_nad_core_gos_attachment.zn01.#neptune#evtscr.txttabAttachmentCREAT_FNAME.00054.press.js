var context = oEvent.oSource.getBindingContext();
var value = context.getProperty("CREAT_NAME");
//openUserDialog(value);


if (sap.n) {    // Set Data

    sap.n.Apps.userName = value;

    // Open Dialog
    AppCache.Load("ZUI_NAD_MDM_USER_INFO", {
        dialogShow: true,
        dialogWidth: "400px",
        dialogHeight: "580px",
        dialogTitle: "User info"
    });
}



