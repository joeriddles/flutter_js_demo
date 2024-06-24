let midiAccessObject = null;
async function midiAccess() {
    if (midiAccessObject == null) {
        try {
            midiAccessObject = await navigator.requestMIDIAccess({ sysex: true, software: true });
        } catch (err) {
            throw new Error(`Failed to get MIDI access for ${window.location.href}`, { cause: err })
        }
    }
    return midiAccessObject;
}

midiAccess().then((access) => {
  console.log(access)
});
