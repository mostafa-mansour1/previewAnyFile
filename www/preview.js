var exec = require( "cordova/exec" );

var PreviewAnyFile = function () {

};
PreviewAnyFile.prototype.preview = function ( path, successCallback, errorCallback ) {
    exec( successCallback, errorCallback, "PreviewAnyFile", "preview", [ path ] );
};
module.exports = new PreviewAnyFile();