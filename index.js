const path = require('path');
const core = require('@actions/core');
const exec = require('@actions/exec');

const setupPs1 = path.resolve(__dirname, '../setup.ps1');
const cleanupPs1 = path.resolve(__dirname, '../cleanup.ps1');

console.log('Setup path: ' + setupPs1);
console.log('Cleanup path: ' + cleanupPs1);

// Only one endpoint, so determine if this is the post action, and set it true so that
// the next time we're executed, it goes to the post action
let isPost = core.getState('IsPost');
core.saveState('IsPost', true);

let publishProfileEnvName = core.getInput('publish-profile-env-name');
let azureCredentials = core.getInput('azure-credentials');
let tagName = core.getInput('tag');

async function run() {

    try {

        if (!isPost) {

            console.log("Running setup action");

            let suffix = Math.round(10000000000 * Math.random());
            let AppName = 'psw-functions-' + suffix;
            let StorageName = 'pswfuncstorage' + suffix;
            core.saveState('AppName', AppName);
            core.saveState('StorageName', StorageName);

            console.log("AppName = " + AppName);

            await exec.exec('pwsh', [
                '-File', setupPs1,
                '-AppName', AppName,
                '-StorageName', StorageName,
                '-PublishProfileEnvName', publishProfileEnvName,
                '-tagName', tagName,
                '-azureCredentials', azureCredentials
            ]);

        } else { // Cleanup

            console.log("Running cleanup");

            let AppName = core.getState('AppName');

            await exec.exec('pwsh', [
                '-File', cleanupPs1,
                '-AppName', AppName,
                '-StorageName', StorageName
            ]);

        }

    } catch (err) {
        core.setFailed(err);
        console.log(err);
    }

}

run();