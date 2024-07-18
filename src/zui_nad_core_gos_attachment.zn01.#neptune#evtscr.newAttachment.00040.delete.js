var deleteItem = oEvent.getParameter("listItem");
var context = deleteItem.getBindingContext();
var value = context.getProperty("DESCRIPTION");

ModelData.Delete(newAttachment,"DESCRIPTION",value);
modelnewAttachment.refresh();

barAttachmentNew.setCount(modelnewAttachment.oData.length);
