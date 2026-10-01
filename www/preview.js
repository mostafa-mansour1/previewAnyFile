
var exec = require( "cordova/exec" );

var PreviewAnyFile = function () {

};

function nativeArgs( opt ) {
    opt = opt || {};
    return [ opt.name || '', opt.mimeType || '', opt.headers || {}, !!opt.disableShare ];
}

// Callback style: (success, error, source, opt) — success gets "SUCCESS"/"NO_APP" and later "CLOSING".
// Promise style: (source, opt) — resolves with "SUCCESS"/"NO_APP"; "CLOSING" goes to opt.onClose.
function call( args, run ) {
    if ( args.length >= 3 || typeof args[ 0 ] === 'function' )
        return run( args[ 0 ] || function () {}, args[ 1 ] || function () {}, args[ 2 ], args[ 3 ] );

    var source = args[ 0 ], opt = args[ 1 ] || {};
    return new Promise( function ( resolve, reject ) {
        var settled = false;
        run( function ( status ) {
            if ( status === 'CLOSING' ) {
                if ( typeof opt.onClose === 'function' ) opt.onClose();
            } else if ( !settled ) {
                settled = true;
                resolve( status );
            }
        }, function ( err ) {
            if ( !settled ) {
                settled = true;
                reject( err );
            }
        }, source, opt );
    } );
}

PreviewAnyFile.prototype.preview = function ( path, successCallback, errorCallback ) {
    console.warn( "preview method has been deprecated, kindly use previewPath, previewBase64 or previewAsset" )
    exec( successCallback, errorCallback, "PreviewAnyFile", "preview", [ path ] );
};

PreviewAnyFile.prototype.previewBase64 = function () {
    return call( arguments, function ( successCallback, errorCallback, base64, opt ) {
        exec( successCallback, errorCallback, "PreviewAnyFile", "previewBase64", [ base64 ].concat( nativeArgs( opt ) ) );
    } );
};

PreviewAnyFile.prototype.previewPath = function () {
    return call( arguments, function ( successCallback, errorCallback, path, opt ) {
        exec( successCallback, errorCallback, "PreviewAnyFile", "previewPath", [ path ].concat( nativeArgs( opt ) ) );
    } );
};

PreviewAnyFile.prototype.previewAsset = function () {
    return call( arguments, function ( successCallback, errorCallback, path, opt ) {
        let name = !!opt && opt.name ? opt.name : '';
        let mimeType = !!opt && opt.mimeType ? opt.mimeType : '';
        if ( !!path ) path = window.location.origin + path;

        fetch( path )
            .then( resp => {
                if ( !resp.ok ) throw new Error( 'HTTP ' + resp.status );
                return resp.blob();
            } )
            .then( blob => {
                let reader = new FileReader();
                reader.readAsDataURL( blob );
                reader.onloadend = function () {
                    let base64 = reader.result;
                    if ( !name ) name = path.split( '/' ).pop();
                    exec( successCallback, errorCallback, "PreviewAnyFile", "previewBase64", [ base64, name, mimeType, {}, !!( opt && opt.disableShare ) ] );
                }
            } )
            .catch( err => errorCallback && errorCallback( 'Cannot load asset ' + path + ': ' + err ) );
    } );
};

// canPreview('report.pdf') or canPreview('application/pdf'): can this device show the file type?
// Promise style returns Promise<boolean>; callback style is (success, error, nameOrMimeType).
PreviewAnyFile.prototype.canPreview = function () {
    var args = arguments;
    var run = function ( successCallback, errorCallback, type ) {
        type = type || '';
        var isMime = type.indexOf( '/' ) > 0;
        exec( function ( result ) {
            successCallback( result === true || result === 1 || result === 'true' );
        }, errorCallback, "PreviewAnyFile", "canPreview", [ isMime ? '' : type, isMime ? type : '' ] );
    };
    if ( args.length >= 3 || typeof args[ 0 ] === 'function' ) return run( args[ 0 ], args[ 1 ], args[ 2 ] );
    return new Promise( function ( resolve, reject ) { run( resolve, reject, args[ 0 ] ); } );
};

module.exports = new PreviewAnyFile();
