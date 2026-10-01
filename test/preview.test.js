// Run with: npm test — checks the JS layer against a fake cordova/exec (no device needed).
const assert = require('assert');
const Module = require('module');

let calls = [];
let reply = null; // (success, error) => void, set per test
const realLoad = Module._load;
Module._load = function (request, ...rest) {
    if (request === 'cordova/exec') {
        return (success, error, service, action, args) => {
            calls.push({ action, args });
            if (reply) reply(success, error);
        };
    }
    return realLoad.call(this, request, ...rest);
};
const P = require('../www/preview.js');

(async () => {
    // callback style still works and passes name, mimeType, headers to native
    calls = [];
    const seen = [];
    reply = (ok) => { ok('SUCCESS'); ok('CLOSING'); };
    P.previewPath(s => seen.push(s), () => assert.fail('no error expected'), 'https://x/a', { name: 'a.pdf', headers: { A: '1' } });
    assert.deepStrictEqual(seen, ['SUCCESS', 'CLOSING']);
    assert.deepStrictEqual(calls[0], { action: 'previewPath', args: ['https://x/a', 'a.pdf', '', { A: '1' }, false] });

    // callback style without options sends empty defaults
    calls = [];
    P.previewBase64(() => {}, () => {}, 'data:x');
    assert.deepStrictEqual(calls[0].args, ['data:x', '', '', {}, false]);

    // disableShare is passed through as a boolean
    calls = [];
    P.previewPath(() => {}, () => {}, 'file:///a.pdf', { disableShare: true });
    assert.strictEqual(calls[0].args[4], true);

    // callback style with null callbacks does not throw
    reply = (ok) => ok('SUCCESS');
    P.previewPath(null, null, 'file:///a.pdf');

    // promise style resolves once with SUCCESS, CLOSING goes to onClose
    let closed = 0;
    reply = (ok) => { ok('SUCCESS'); ok('CLOSING'); };
    const status = await P.previewPath('file:///a.pdf', { onClose: () => closed++ });
    assert.strictEqual(status, 'SUCCESS');
    assert.strictEqual(closed, 1);

    // promise style resolves with NO_APP
    reply = (ok) => ok('NO_APP');
    assert.strictEqual(await P.previewPath('file:///a.xyz'), 'NO_APP');

    // promise style rejects with the native error
    reply = (ok, err) => err('Download failed with HTTP 404');
    await assert.rejects(P.previewPath('https://x/missing.pdf'), e => e === 'Download failed with HTTP 404');

    // canPreview: file name vs MIME type routing, boolean result in both styles
    calls = [];
    reply = (ok) => ok(true);
    assert.strictEqual(await P.canPreview('report.pdf'), true);
    assert.deepStrictEqual(calls[0], { action: 'canPreview', args: ['report.pdf', ''] });
    reply = (ok) => ok(false);
    assert.strictEqual(await P.canPreview('application/x-unknown'), false);
    assert.deepStrictEqual(calls[1].args, ['', 'application/x-unknown']);
    let cbResult;
    reply = (ok) => ok(1);
    P.canPreview(r => { cbResult = r; }, () => {}, 'image/png');
    assert.strictEqual(cbResult, true);

    console.log('preview.js: all checks passed');
})().catch(e => { console.error(e); process.exit(1); });
