import * as path from 'path';
import * as core from '@actions/core';
import * as exec from '@actions/exec';

const setupPs1 = path.resolve(__dirname, '../setup.ps1');
const cleanupPs1 = path.resolve(__dirname, '../cleanup.ps1');

console.log('Setup path: ' + setupPs1);
console.log('Cleanup path: ' + cleanupPs1);

// Only one endpoint, so determine if this is the post action, and set it true so that
// the next time we're executed, it goes to the post action
let isPost = core.getState('IsPost');
core.saveState('IsPost', true);

let azureCredentials = core.getInput('azure-credentials');
let tagName = core.getInput('tag');
let envVarsToPromote = core.getInput('env-vars-to-promote');
let skipCleanup = core.getInput('skip-cleanup') === 'true';

async function run() {

    try {

        if (!isPost) {

            console.log("Running setup action");

            let suffix = Math.round(10000000000 * Math.random()).toString();
            core.saveState('Suffix', suffix);

            await exec.exec('pwsh', [
                '-File', setupPs1,
                '-Suffix', suffix,
                '-envVarsToPromote', envVarsToPromote,
                '-tagName', tagName,
                '-azureCredentials', azureCredentials
            ]);

        } else { // Cleanup

            if (skipCleanup) {
                core.error('Skipping cleanup because skip-cleanup was set to true. This fails the workflow to prevent merging a test-only configuration.');
                core.setFailed('Failing because test-only skip-cleanup is set to true');
                return;
            }
            console.log("Running cleanup");

            let suffix = core.getState('Suffix');

            await exec.exec('pwsh', [
                '-File', cleanupPs1,
                '-Suffix', suffix
            ]);

        }

    } catch (err) {
        core.setFailed(err);
        console.log(err);
    }

}

run();