var context = oEvent.oSource.getBindingContext();
var value = context.getProperty("INSTID_B");

if (typeof cordova === "undefined") {
    // jQuery.sap.require("sap.m.URLHelper");
    sap.m.URLHelper.redirect("ZUI_NAD_CORE_GOS_ATTACHMENT?KEY_ID=GET_ATTACHMENT&KEY=" + value, true);
} else {
    sap.n.GOS.INSTID_B = value;
    AppCache.Load("ZUI_NAD_CORE_GOS_VIEWER", {
        dialogShow: true,
        dialogWidth: "400px",
        dialogHeight: "530px",
        dialogTitle: "View Attachment"
    });

}
