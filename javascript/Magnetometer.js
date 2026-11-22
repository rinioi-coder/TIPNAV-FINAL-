// Global data structure read by Godot
  window.magnetometerData = { x: 0, y: 0, z: 0, timestamp: 0 };
  window.magStatus = 'uninitialized';

  // Debug info: how many readings arrived and from which source
  window.magDebug = { source: 'none', count: 0 };

  // Earth "up" axis in the device frame (unit vector). Used for tilt compensation.
  window.magUp = { x: 0, y: 0, z: 1 };

  // Single place where every source writes its reading
  window.pushMag = function(x, y, z, source, up) {
    const d = window.magnetometerData;
    d.x = x;
    d.y = y;
    d.z = z;

    // Timestamp of the latest sensor reading
    d.timestamp = performance.now();

    if (up) {
      window.magUp.x = up.x;
      window.magUp.y = up.y;
      window.magUp.z = up.z;
    }

    window.magDebug.source = source;
    window.magDebug.count++;
    window.magStatus = 'active (' + source + ')';
  };

  // Initialize magnetometer permission & event binding
  window.initMagnetometer = async function() {
    if (window.magStatus.startsWith('active')) {
      return; // Already receiving data
    }
    if (window._magSensor || window._magBound) {
      return; // Already set up, waiting for the first reading
    }

    console.log('[Sensors] Requesting magnetometer access...');

    // 1. iOS Safari 13+ (Requires explicit permission call in user gesture)
    // iOS has no raw magnetometer API, so we derive north direction from orientation.
    if (typeof DeviceOrientationEvent !== 'undefined' && typeof DeviceOrientationEvent.requestPermission === 'function') {
      try {
        const state = await DeviceOrientationEvent.requestPermission();
        if (state === 'granted') {
          window.bindDeviceOrientation();
          window.magStatus = 'waiting (iOS permission granted)';
          console.log('[Sensors] iOS DeviceOrientation permission granted.');
        } else {
          window.magStatus = 'denied';
          console.warn('[Sensors] DeviceOrientation permission denied by user.');
        }
      } catch (err) {
        window.magStatus = 'error: ' + err.message;
        console.error('[Sensors] Permission error:', err);
      }
      return;
    }

    // 2. Raw Magnetometer (Chromium only, needs the
    //    chrome://flags/#enable-generic-sensor-extra-classes flag, values in microtesla)
    if ('Magnetometer' in window) {
      try {
        if (navigator.permissions && navigator.permissions.query) {
          const result = await navigator.permissions.query({ name: 'magnetometer' });
          if (result.state === 'denied') {
            console.warn('[Sensors] Sensor permission denied, using deviceorientation fallback.');
            window.bindDeviceOrientation();
            return;
          }
        }

        const mag = new Magnetometer({ frequency: 60 });
        mag.addEventListener('reading', () => {
          window.pushMag(mag.x || 0, mag.y || 0, mag.z || 0, 'Generic Sensor');
        });
        mag.addEventListener('error', (event) => {
          console.warn('[Sensors] Magnetometer error, using fallback:', event.error.name);
          window._magSensor = null;
          window.bindDeviceOrientation();
        });
        window._magSensor = mag; // keep a strong reference so it is not garbage collected
        mag.start();
        console.log('[Sensors] Generic Sensor Magnetometer active.');
        return;
      } catch (err) {
        console.warn('[Sensors] Magnetometer init failed:', err.message);
      }
    }

    // 3. AbsoluteOrientationSensor (stock Chrome on Android, referenced to magnetic north)
    //    Gives a unit vector pointing to magnetic north in the device frame.
    if ('AbsoluteOrientationSensor' in window) {
      try {
        const s = new AbsoluteOrientationSensor({ frequency: 60, referenceFrame: 'device' });
        s.addEventListener('reading', () => {
          const q = s.quaternion;
          if (!q) return;
          const x = q[0], y = q[1], z = q[2], w = q[3];
          // Earth north axis expressed in the device frame (row 2 of the rotation matrix)
          window.pushMag(
            2 * (x * y + z * w),
            1 - 2 * (x * x + z * z),
            2 * (y * z - x * w),
            'AbsoluteOrientationSensor',
            { x: 2 * (x * z - y * w), y: 2 * (y * z + x * w), z: 1 - 2 * (x * x + y * y) }
          );
        });
        s.addEventListener('error', (event) => {
          console.warn('[Sensors] AbsoluteOrientationSensor error, using fallback:', event.error.name);
          window._magSensor = null;
          window.bindDeviceOrientation();
        });
        window._magSensor = s; // keep a strong reference
        s.start();
        console.log('[Sensors] AbsoluteOrientationSensor active.');
        return;
      } catch (err) {
        console.warn('[Sensors] AbsoluteOrientationSensor init failed:', err.message);
      }
    }

    // 4. Fallback for other browsers
    window.bindDeviceOrientation();
  };

  // Converts orientation angles into a unit vector pointing to magnetic north,
  // expressed in the device's coordinate frame (x = right, y = top, z = out of screen).
  window.northVectorFromOrientation = function(alphaDeg, betaDeg, gammaDeg) {
    const d2r = Math.PI / 180;
    const cA = Math.cos(alphaDeg * d2r), sA = Math.sin(alphaDeg * d2r);
    const cB = Math.cos(betaDeg * d2r),  sB = Math.sin(betaDeg * d2r);
    const cG = Math.cos(gammaDeg * d2r), sG = Math.sin(gammaDeg * d2r);

    // Second row of the device->earth rotation matrix (W3C DeviceOrientation spec),
    // i.e. the earth "north" axis seen from the device frame.
    return {
      x: cG * sA + cA * sB * sG,
      y: cA * cB,
      z: sA * sG - cA * cG * sB
    };
  };

  // Earth "up" axis in the device frame (third row of the same rotation matrix).
  window.upVectorFromOrientation = function(betaDeg, gammaDeg) {
    const d2r = Math.PI / 180;
    const cB = Math.cos(betaDeg * d2r),  sB = Math.sin(betaDeg * d2r);
    const cG = Math.cos(gammaDeg * d2r), sG = Math.sin(gammaDeg * d2r);
    return { x: -cB * sG, y: sB, z: cB * cG };
  };

  window.bindDeviceOrientation = function() {
    if (window._magBound) {
      return; // avoid duplicate listeners
    }
    window._magBound = true;

    const handler = (event) => {
      let alpha = event.alpha;

      // iOS: webkitCompassHeading is clockwise degrees from magnetic north
      if (typeof event.webkitCompassHeading === 'number') {
        alpha = 360 - event.webkitCompassHeading;
      }
      // Skip if there is no compass-referenced data
      if (alpha === null || alpha === undefined) return;

      const v = window.northVectorFromOrientation(alpha, event.beta || 0, event.gamma || 0);
      window.magDebug.absolute = event.absolute;
      window.magDebug.alpha = event.alpha;
      window.magDebug.beta = event.beta;
      window.magDebug.gamma = event.gamma;
      window.pushMag(v.x, v.y, v.z, 'deviceorientation',
                     window.upVectorFromOrientation(event.beta || 0, event.gamma || 0));
    };

    // Android Chrome: 'absolute' event is referenced to magnetic north
    if ('ondeviceorientationabsolute' in window) {
      window.addEventListener('deviceorientationabsolute', handler, true);
    } else {
      window.addEventListener('deviceorientation', handler, true);
    }
  };

  // Attempt auto-start on page load for browsers that do not require explicit gestures (e.g. Android Chrome)
  window.addEventListener('DOMContentLoaded', () => {
    window.initMagnetometer();
  });