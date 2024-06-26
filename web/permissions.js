async function _requestPermissions() {
  try {
    await navigator.mediaDevices.getUserMedia({ audio: true, video: true });
  } catch (e) {
    if (e.name === "NotFoundError") {
      // Either there's no camera, no microphone, or both. We'll retry getting
      // permissions for each device type separately.
      try {
        await navigator.mediaDevices.getUserMedia({
          audio: true,
        });
      } catch (_) {}

      try {
        await navigator.mediaDevices.getUserMedia({
          video: true,
        });
      } catch (_) {}
    }
  }

  try {
    const midiAccess = await navigator.requestMIDIAccess({
      sysex: true,
      software: true,
    });
    console.log({ midiAccess });
    await callDartOnMidiAccess(midiAccess);
  } catch (error) {
    // error = new Error(`Failed to get MIDI access for ${window.location.href}`, { cause: error })
    console.error(error);
    await callDartOnMidiAccess(error);
  }
}

let onMidiAccessRetried = false;

async function callDartOnMidiAccess(midiAccess) {
  try {
    window.onMidiAccess(midiAccess);
  } catch (err) {
    if (onMidiAccessRetried) {
      throw err;
    }

    console.warn(err);

    // Try again in 3 seconds
    setTimeout(() => {
      onMidiAccessRetried = true;
      window.onMidiAccess(midiAccess);
    }, 3_000);
  }
}

let requestMidiAccessRetried = false;

function timeout(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function requestPermissions() {
  try {
    await _requestPermissions();
  } catch (err) {
    if (requestMidiAccessRetried) {
      throw err;
    }

    console.warn(err);

    await timeout(3_000);
    requestMidiAccessRetried = true;
    await _requestPermissions();
  }
}
