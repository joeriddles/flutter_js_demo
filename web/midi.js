async function requestMidiAccess() {
    console.log('Requesting MIDI access')
    try {
        midiAccess = await navigator.requestMIDIAccess({ sysex: false, software: false });
        console.log(midiAccess)
        callDartOnMidiAccess(midiAccess)
    } catch (err) {
        const error = new Error(`Failed to get MIDI access for ${window.location.href}`, { cause: err })
        console.error(error)
        callDartOnMidiAccess(error)
    }
}

let retried = false;

async function callDartOnMidiAccess(midiAccess) {
    try {
        window.onMidiAccess(midiAccess)
    } catch (err) {
        if (retried) {
            throw err;
        }

        console.warn(err)

        // Try again in 3 seconds
        setTimeout(
            () => {
                retried = true
                callDartOnMidiAccess(midiAccess)
            },
            3_000,
        );
    }
}

(async () => {
    console.log('Starting midi.js')
    try {
        await requestMidiAccess()
    } catch (err) {
        throw err
    }
})()
