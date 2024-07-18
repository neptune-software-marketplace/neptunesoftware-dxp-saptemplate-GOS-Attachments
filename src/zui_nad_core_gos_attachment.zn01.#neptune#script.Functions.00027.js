function upload(event) {

    $.each(event.target.files, function(i, data) {

        try {
            var fileReader = new FileReader();

            fileReader.onload = function(event) {
                var newRec = {};
                newRec.INSTID = sap.n.GOS.INSTID;
                newRec.TYPEID = sap.n.GOS.TYPEID;
                newRec.FILE_SIZE = data.size / 1000;
                newRec.DESCRIPTION = data.name;
                newRec.CONTENT = event.target.result;
                ModelData.Add(newAttachment, newRec);
                barAttachmentNew.setCount(modelnewAttachment.oData.length);
                document.getElementById("fileUploader").value = '';
            };
            fileReader.readAsDataURL(data);

        } catch (e) {
            try {

            } catch (e) {

            }
        }
    });
}
