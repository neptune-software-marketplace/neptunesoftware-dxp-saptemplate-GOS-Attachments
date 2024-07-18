// Close Dialog
var parent = oShell.getParent();
if (parent) {
    var dia = parent.getParent();
    if (dia) {
        dia.close();
    }
}
