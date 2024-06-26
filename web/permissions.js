async function _requestPermissions() {
    try {
        await navigator.mediaDevices.getUserMedia({ audio: true, video: true });
        const midiAccess = await navigator.requestMIDIAccess({ sysex: true, software: true });
        console.log({ midiAccess})
        await callDartOnMidiAccess(midiAccess)
    } catch (error) {
        // error = new Error(`Failed to get MIDI access for ${window.location.href}`, { cause: error })
        console.error(error)
        await callDartOnMidiAccess(error)
    }
}

let onMidiAccessRetried = false;

async function callDartOnMidiAccess(midiAccess) {
    try {
        window.onMidiAccess(midiAccess)
    } catch (err) {
        if (onMidiAccessRetried) {
            throw err;
        }

        console.warn(err)

        // Try again in 3 seconds
        setTimeout(
            () => {
                onMidiAccessRetried = true
                window.onMidiAccess(midiAccess)
            },
            3_000,
        );
    }
}

let requestMidiAccessRetried = false;

async function requestPermissions() {
    try {
        await _requestPermissions()
    } catch (err) {
        if (requestMidiAccessRetried) {
            throw err;
        }
    
        console.warn(err)
    
        // Try again in 3 seconds
        setTimeout(
            async () => {
                requestMidiAccessRetried = true
                await _requestPermissions(midiAccess)
            },
            10_000,
        );
    }
}
