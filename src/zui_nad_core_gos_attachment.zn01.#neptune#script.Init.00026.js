if (sap.n) {

    // Before Display
    sap.n.Shell.attachBeforeDisplay(function() {

        // Clear Upload Table
        modeltabAttachment.setData([]);
        modeltabAttachment.refresh();

        modelnewAttachment.setData([]);
        modelnewAttachment.refresh();

        barAttachmentNew.setCount(modelnewAttachment.oData.length);

        getOnlineGetList(sap.n.GOS.TYPEID + "|" + sap.n.GOS.INSTID);

        // Make Upload Global
        sap.n.GOS.upload = function(event) {
            upload(event);
        };
    });
}

// Custom Init - Happens only once
sap.ui.getCore().attachInit(function(data) {

    // IOS Support
    butAdd.onAfterRendering = function(oEvent) {
        var elem = butAdd.getDomRef();
        elem.setAttribute("onclick", "$('#fileUploader').click()");
    };
});
