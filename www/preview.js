var exec = require( "cordova/exec" ),
    channel = require( "cordova/channel" );

var PreviewAnyFile = function () {

};
PreviewAnyFile.prototype.preview = function ( path ) {
    exec( null, null, "PreviewAnyFile", "preview", [ path ] );
};
module.exports = new PreviewAnyFile();