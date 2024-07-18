var deleteItem = oEvent.getParameter("listItem");
var context = deleteItem.getBindingContext();
var value = context.getProperty("DELETE");
var instid = context.getProperty("INSTID_B");

ModelData.UpdateField(tabAttachment,"INSTID_B",instid,"DELETE",!value);
modeltabAttachment.refresh();
