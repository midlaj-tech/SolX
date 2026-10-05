/**
 * SolX Interactive Device Simulator Application Logic
 */

document.addEventListener('DOMContentLoaded', () => {
  // Preset locations
  const LOCATIONS = {
    kannur: { name: 'Kannur Coast, Kerala', lat: 11.8745, lon: 75.3704, tz: 5.5 },
    bigsur: { name: 'Big Sur, California', lat: 36.2704, lon: -121.8081, tz: -7.0 },
    santorini: { name: 'Santorini, Greece', lat: 36.3932, lon: 25.4615, tz: 3.0 },
    reykjavik: { name: 'Reykjavik, Iceland', lat: 64.1466, lon: -21.9426, tz: 0.0 },
    tokyo: { name: 'Tokyo, Japan', lat: 35.6762, lon: 139.6503, tz: 9.0 }
  };

  let activeLocation = LOCATIONS.kannur;
  let isScrubbing = false;
  let scrubbedTime = null; // Date object when scrubbing
  let watchCrownOffsetMinutes = 0;
  let isWebcamActive = false;
  let webcamStream = null;
  let currentGrid = 'ruleOfThirds';

  // DOM Elements
  const body = document.body;
  const themeSwitchInput = document.getElementById('theme-switch-input');
  const modalThemeToggle = document.getElementById('modal-theme-toggle');
  const phoneThemeToggle = document.getElementById('phone-theme-toggle');
  const phoneThemeText = document.getElementById('phone-theme-text');
  const phoneThemeIcon = document.getElementById('phone-theme-icon');

  const locationSelect = document.getElementById('location-select');
  const phoneLocationName = document.getElementById('phone-location-name');
  const ipadLocationLabel = document.getElementById('ipad-location-label');
  const statusClock = document.getElementById('status-clock');

  // Compass Elements
  const sunBeacon = document.getElementById('sun-beacon');
  const centerAzimuthVal = document.getElementById('center-azimuth-val');
  const telemetrySunAlt = document.getElementById('telemetry-sun-alt');
  const telemetrySunset = document.getElementById('telemetry-sunset');
  const telemetrySunrise = document.getElementById('telemetry-sunrise');
  const telemetryCountdown = document.getElementById('telemetry-countdown');

  // Timeline Slider Elements
  const timelineSlider = document.getElementById('timeline-slider');
  const sliderThumb = document.getElementById('slider-thumb');
  const resetLiveBtn = document.getElementById('reset-live-btn');
  const skyOverlay = document.getElementById('sky-overlay');

  // Columns
  const colAfternoon = document.getElementById('col-time-afternoon');
  const colGolden = document.getElementById('col-time-golden');
  const colBlue = document.getElementById('col-time-blue');
  const colNight = document.getElementById('col-time-night');

  // Shutter & Tools
  const btnShutter = document.getElementById('btn-shutter');
  const shutterFlash = document.getElementById('shutter-flash');
  const btnGridToggle = document.getElementById('btn-grid-toggle');
  const compGrid = document.getElementById('comp-grid');
  const btnTorchToggle = document.getElementById('btn-torch-toggle');
  const webcamToggleBtn = document.getElementById('webcam-toggle-btn');
  const viewfinderImg = document.getElementById('viewfinder-img');
  const viewfinderVideo = document.getElementById('viewfinder-video');

  // Modals
  const btnMapModal = document.getElementById('btn-map-modal');
  const modalTrajectory = document.getElementById('modal-trajectory');
  const closeTrajectoryBtn = document.getElementById('close-trajectory-btn');
  const btnSettingsModal = document.getElementById('btn-settings-modal');
  const modalSettings = document.getElementById('modal-settings');
  const closeSettingsBtn = document.getElementById('close-settings-btn');

  // iPad Elements
  const ipadCenterAzimuth = document.getElementById('ipad-center-azimuth');
  const ipadAltVal = document.getElementById('ipad-alt-val');
  const ipadGhVal = document.getElementById('ipad-gh-val');
  const ipadSunsetVal = document.getElementById('ipad-sunset-val');
  const ipadSunriseVal = document.getElementById('ipad-sunrise-val');

  // Widget Elements
  const wSmallAlt = document.getElementById('w-small-alt');
  const wSmallCountdown = document.getElementById('w-small-countdown');
  const wSmallWindow = document.getElementById('w-small-window');
  const wSmallLocation = document.getElementById('w-small-location');
  const wMedCountdown = document.getElementById('w-med-countdown');
  const wMedWindow = document.getElementById('w-med-window');
  const wMedLocation = document.getElementById('w-med-location');
  const wMedBearing = document.getElementById('w-med-bearing');
  const wMedAlt = document.getElementById('w-med-alt');
  const wMedSunset = document.getElementById('w-med-sunset');
  const wLockCircular = document.getElementById('w-lock-circular');
  const wLockRectCountdown = document.getElementById('w-lock-rect-countdown');
  const wLockRectWindow = document.getElementById('w-lock-rect-window');

  // Apple Watch Elements
  const watchCrown = document.getElementById('watch-crown');
  const watchPhaseBadge = document.getElementById('watch-phase-badge');
  const watchCountdownText = document.getElementById('watch-countdown-text');
  const watchAltitudeText = document.getElementById('watch-altitude-text');
  const watchBearingText = document.getElementById('watch-bearing-text');
  const watchSunsetText = document.getElementById('watch-sunset-text');
  const watchGaugeProgress = document.getElementById('watch-gauge-progress');
  const watchCrownPreviewTag = document.getElementById('watch-crown-preview-tag');

  // ========================================================
  // 1. Theme Management (Light / Dark Switch)
  // ========================================================
  function setTheme(isLight) {
    if (isLight) {
      body.classList.remove('theme-dark');
      body.classList.add('theme-light');
      themeSwitchInput.checked = true;
      modalThemeToggle.checked = true;
      phoneThemeText.textContent = 'LIGHT';
      phoneThemeIcon.textContent = '☀️';
    } else {
      body.classList.remove('theme-light');
      body.classList.add('theme-dark');
      themeSwitchInput.checked = false;
      modalThemeToggle.checked = false;
      phoneThemeText.textContent = 'DARK';
      phoneThemeIcon.textContent = '🌙';
    }
  }

  themeSwitchInput.addEventListener('change', (e) => setTheme(e.target.checked));
  modalThemeToggle.addEventListener('change', (e) => setTheme(e.target.checked));
  phoneThemeToggle.addEventListener('click', () => {
    const isLightNow = body.classList.contains('theme-light');
    setTheme(!isLightNow);
  });

  // ========================================================
  // 2. Device Tabs Switcher
  // ========================================================
  const tabButtons = document.querySelectorAll('.tab-btn');
  const deviceViews = document.querySelectorAll('.device-view');

  tabButtons.forEach(btn => {
    btn.addEventListener('click', () => {
      tabButtons.forEach(b => b.classList.remove('active'));
      deviceViews.forEach(v => v.classList.remove('active'));

      btn.classList.add('active');
      const targetId = btn.getAttribute('data-target');
      const targetView = document.getElementById(targetId);
      if (targetView) targetView.classList.add('active');
    });
  });

  // ========================================================
  // 3. Location Selector
  // ========================================================
  locationSelect.addEventListener('change', (e) => {
    const val = e.target.value;
    if (val === 'browser') {
      if (navigator.geolocation) {
        navigator.geolocation.getCurrentPosition(
          (pos) => {
            activeLocation = {
              name: 'My Exact Location',
              lat: pos.coords.latitude,
              lon: pos.coords.longitude,
              tz: -new Date().getTimezoneOffset() / 60.0
            };
            updateSolarData();
          },
          (err) => {
            alert('Location access denied. Reverting to Kannur.');
            locationSelect.value = 'kannur';
            activeLocation = LOCATIONS.kannur;
            updateSolarData();
          }
        );
      }
    } else if (LOCATIONS[val]) {
      activeLocation = LOCATIONS[val];
      updateSolarData();
    }
  });

  // ========================================================
  // 4. Solar Ephemeris Calculation & HUD Updates
  // ========================================================
  function updateSolarData() {
    const now = new Date();
    statusClock.textContent = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`;

    // Target calculation date
    const targetDate = isScrubbing && scrubbedTime ? scrubbedTime : now;

    // Calculate snapshot
    const snap = window.solarEngine.createSnapshot(
      activeLocation.lat,
      activeLocation.lon,
      targetDate,
      activeLocation.tz
    );

    // Update location labels
    phoneLocationName.textContent = activeLocation.name;
    ipadLocationLabel.textContent = activeLocation.name;
    wSmallLocation.textContent = activeLocation.name.split(',')[0];
    wMedLocation.textContent = activeLocation.name.split(',')[0];

    // Update Compass Dial & Beacon
    // Compass dial center is at (52px, 52px), radius = 42px
    const radius = 42;
    // Map Azimuth: 0° is North (top), 90° East (right), 180° South (bottom), 270° West (left)
    const angleRad = (snap.azimuth - 90) * (Math.PI / 180.0);
    const beaconX = 52 + radius * Math.cos(angleRad);
    const beaconY = 52 + radius * Math.sin(angleRad);

    sunBeacon.style.left = `${beaconX}px`;
    sunBeacon.style.top = `${beaconY}px`;
    centerAzimuthVal.textContent = snap.azimuthCompassString;

    // Compass Telemetry
    telemetrySunAlt.textContent = `Sun: ${snap.azimuthCompassString}, Alt: ${snap.altitudeString}`;
    telemetrySunset.textContent = `Sunset: ${window.solarEngine.formatTime(snap.sunset)}`;
    telemetrySunrise.textContent = `Sunrise: ${window.solarEngine.formatTime(snap.sunrise)}`;
    telemetryCountdown.textContent = snap.countdownFormatted;

    // Ephemeris Schedule Columns
    colAfternoon.textContent = window.solarEngine.formatTime(new Date(snap.sunset.getTime() - 79 * 60000));
    colGolden.textContent = `${window.solarEngine.formatTime(snap.eveningGoldenHourStart)}–${window.solarEngine.formatTime(snap.eveningGoldenHourEnd)}`;
    colBlue.textContent = `${window.solarEngine.formatTime(snap.eveningBlueHourStart)}–${window.solarEngine.formatTime(snap.eveningBlueHourEnd)}`;
    colNight.textContent = window.solarEngine.formatTime(new Date(snap.sunset.getTime() + 71 * 60000));

    // Slider thumb position if not manually scrubbing
    if (!isScrubbing) {
      const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate());
      const fraction = (now - startOfDay) / (24 * 3600 * 1000);
      sliderThumb.style.left = `${Math.max(4, Math.min(96, fraction * 100))}%`;
    }

    // Dynamic Atmospheric Lighting Wash
    updateSkyAtmosphere(snap);

    // iPad Updates
    ipadCenterAzimuth.textContent = snap.azimuthCompassString;
    ipadAltVal.textContent = snap.altitudeString;
    ipadGhVal.textContent = snap.countdownFormatted;
    ipadSunsetVal.textContent = window.solarEngine.formatTime(snap.sunset);
    ipadSunriseVal.textContent = window.solarEngine.formatTime(snap.sunrise);

    // Widget Updates
    wSmallAlt.textContent = snap.altitudeString;
    wSmallCountdown.textContent = snap.countdownFormatted;
    wSmallWindow.textContent = `${window.solarEngine.formatTime(snap.eveningGoldenHourStart)}–${window.solarEngine.formatTime(snap.eveningGoldenHourEnd)}`;
    wMedCountdown.textContent = snap.countdownFormatted;
    wMedWindow.textContent = `Window: ${window.solarEngine.formatTime(snap.eveningGoldenHourStart)}–${window.solarEngine.formatTime(snap.eveningGoldenHourEnd)}`;
    wMedBearing.textContent = snap.azimuthCompassString;
    wMedAlt.textContent = snap.altitudeString;
    wMedSunset.textContent = window.solarEngine.formatTime(snap.sunset);
    wLockCircular.textContent = snap.countdownFormatted;
    wLockRectCountdown.textContent = snap.countdownFormatted;
    wLockRectWindow.textContent = `${window.solarEngine.formatTime(snap.eveningGoldenHourStart)}–${window.solarEngine.formatTime(snap.eveningGoldenHourEnd)} • Alt ${snap.altitudeString}`;

    // Apple Watch Updates
    updateWatchView(now);

    // Modal Trajectory Updates
    document.getElementById('modal-m-golden').textContent = `${window.solarEngine.formatTime(snap.morningGoldenHourStart)}–${window.solarEngine.formatTime(snap.morningGoldenHourEnd)}`;
    document.getElementById('modal-noon').textContent = window.solarEngine.formatTime(snap.solarNoon);
    document.getElementById('modal-e-golden').textContent = `${window.solarEngine.formatTime(snap.eveningGoldenHourStart)}–${window.solarEngine.formatTime(snap.eveningGoldenHourEnd)}`;
    document.getElementById('modal-e-blue').textContent = `${window.solarEngine.formatTime(snap.eveningBlueHourStart)}–${window.solarEngine.formatTime(snap.eveningBlueHourEnd)}`;
  }

  function updateSkyAtmosphere(snap) {
    if (snap.altitude > 10) {
      // Daylight warm wash
      skyOverlay.style.background = 'linear-gradient(180deg, rgba(255, 230, 150, 0.15) 0%, rgba(0, 0, 0, 0.05) 100%)';
    } else if (snap.altitude >= -4) {
      // Golden Hour rich amber glow
      skyOverlay.style.background = 'linear-gradient(180deg, rgba(248, 180, 38, 0.28) 0%, rgba(255, 120, 20, 0.15) 50%, rgba(0, 0, 0, 0.3) 100%)';
    } else if (snap.altitude >= -6) {
      // Blue Hour twilight
      skyOverlay.style.background = 'linear-gradient(180deg, rgba(30, 80, 180, 0.35) 0%, rgba(10, 25, 60, 0.45) 100%)';
    } else {
      // Night dark atmosphere
      skyOverlay.style.background = 'linear-gradient(180deg, rgba(8, 12, 24, 0.65) 0%, rgba(0, 0, 0, 0.75) 100%)';
    }
  }

  function updateWatchView(now) {
    const watchDate = new Date(now.getTime() + watchCrownOffsetMinutes * 60000);
    const watchSnap = window.solarEngine.createSnapshot(activeLocation.lat, activeLocation.lon, watchDate, activeLocation.tz);

    watchPhaseBadge.textContent = watchSnap.currentPhase.name;
    watchCountdownText.textContent = watchSnap.countdownFormatted;
    watchAltitudeText.textContent = watchSnap.altitudeString;
    watchBearingText.textContent = watchSnap.azimuthCompassString;
    watchSunsetText.textContent = window.solarEngine.formatTime(watchSnap.sunset);

    // Watch Progress Gauge (Circumference ~ 264)
    // 0% alt -15° -> 100% alt +75°
    const norm = Math.max(0.05, Math.min(0.95, (watchSnap.altitude + 15) / 90));
    const offset = 264 * (1 - norm);
    watchGaugeProgress.style.strokeDashoffset = offset;

    if (watchCrownOffsetMinutes !== 0) {
      watchCrownPreviewTag.textContent = `${watchCrownOffsetMinutes > 0 ? '+' : ''}${watchCrownOffsetMinutes}m`;
    } else {
      watchCrownPreviewTag.textContent = 'LIVE';
    }
  }

  // ========================================================
  // 5. Interactive Time-Travel Scrubbing on Timeline
  // ========================================================
  let isDraggingSlider = false;

  function handleScrub(e) {
    const rect = timelineSlider.getBoundingClientRect();
    const clientX = e.touches ? e.touches[0].clientX : e.clientX;
    const fraction = Math.max(0, Math.min(1, (clientX - rect.left) / rect.width));

    sliderThumb.style.left = `${fraction * 100}%`;
    isScrubbing = true;
    resetLiveBtn.classList.add('visible');

    const now = new Date();
    const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    scrubbedTime = new Date(startOfDay.getTime() + fraction * 86400000);

    updateSolarData();
  }

  timelineSlider.addEventListener('mousedown', (e) => {
    isDraggingSlider = true;
    handleScrub(e);
  });

  window.addEventListener('mousemove', (e) => {
    if (isDraggingSlider) handleScrub(e);
  });

  window.addEventListener('mouseup', () => {
    isDraggingSlider = false;
  });

  // Touch support for mobile/tablet
  timelineSlider.addEventListener('touchstart', (e) => {
    isDraggingSlider = true;
    handleScrub(e);
  });

  window.addEventListener('touchmove', (e) => {
    if (isDraggingSlider) handleScrub(e);
  });

  window.addEventListener('touchend', () => {
    isDraggingSlider = false;
  });

  resetLiveBtn.addEventListener('click', () => {
    isScrubbing = false;
    scrubbedTime = null;
    resetLiveBtn.classList.remove('visible');
    updateSolarData();
  });

  // ========================================================
  // 6. Camera Controls: Shutter, Grid, Torch, Webcam
  // ========================================================
  btnShutter.addEventListener('click', () => {
    // Flash effect
    shutterFlash.classList.add('flashing');
    setTimeout(() => {
      shutterFlash.classList.remove('flashing');
    }, 150);
  });

  btnGridToggle.addEventListener('click', () => {
    if (currentGrid === 'ruleOfThirds') {
      compGrid.style.display = 'none';
      currentGrid = 'off';
    } else {
      compGrid.style.display = 'block';
      currentGrid = 'ruleOfThirds';
    }
  });

  let isTorchOn = false;
  btnTorchToggle.addEventListener('click', () => {
    isTorchOn = !isTorchOn;
    btnTorchToggle.classList.toggle('active', isTorchOn);
    if (isTorchOn) {
      viewfinderImg.style.filter = 'brightness(1.3) contrast(1.1)';
    } else {
      viewfinderImg.style.filter = 'none';
    }
  });

  // Live Webcam Toggle
  webcamToggleBtn.addEventListener('click', async () => {
    if (!isWebcamActive) {
      try {
        webcamStream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: 'environment' } });
        viewfinderVideo.srcObject = webcamStream;
        viewfinderVideo.style.display = 'block';
        viewfinderImg.style.display = 'none';
        webcamToggleBtn.innerHTML = '<span>Disable Cam</span>';
        webcamToggleBtn.style.color = '#f8b426';
        isWebcamActive = true;
      } catch (err) {
        alert('Could not access camera feed: ' + err.message);
      }
    } else {
      if (webcamStream) {
        webcamStream.getTracks().forEach(t => t.stop());
      }
      viewfinderVideo.style.display = 'none';
      viewfinderImg.style.display = 'block';
      webcamToggleBtn.innerHTML = '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z"></path><circle cx="12" cy="13" r="4"></circle></svg><span>Webcam Feed</span>';
      webcamToggleBtn.style.color = '';
      isWebcamActive = false;
    }
  });

  // ========================================================
  // 7. Apple Watch Digital Crown Interactive Rotation
  // ========================================================
  let isCrownDragging = false;
  let crownStartY = 0;

  watchCrown.addEventListener('mousedown', (e) => {
    isCrownDragging = true;
    crownStartY = e.clientY;
  });

  window.addEventListener('mousemove', (e) => {
    if (!isCrownDragging) return;
    const deltaY = crownStartY - e.clientY;
    watchCrownOffsetMinutes += Math.round(deltaY * 0.5);
    crownStartY = e.clientY;
    updateSolarData();
  });

  window.addEventListener('mouseup', () => {
    isCrownDragging = false;
  });

  watchCrown.addEventListener('wheel', (e) => {
    e.preventDefault();
    watchCrownOffsetMinutes += e.deltaY > 0 ? 5 : -5;
    updateSolarData();
  });

  watchCrownPreviewTag.addEventListener('click', () => {
    watchCrownOffsetMinutes = 0;
    updateSolarData();
  });

  // ========================================================
  // 8. Modals
  // ========================================================
  btnMapModal.addEventListener('click', () => modalTrajectory.classList.add('active'));
  closeTrajectoryBtn.addEventListener('click', () => modalTrajectory.classList.remove('active'));

  btnSettingsModal.addEventListener('click', () => modalSettings.classList.add('active'));
  closeSettingsBtn.addEventListener('click', () => modalSettings.classList.remove('active'));

  // Close modals on backdrop click
  window.addEventListener('click', (e) => {
    if (e.target === modalTrajectory) modalTrajectory.classList.remove('active');
    if (e.target === modalSettings) modalSettings.classList.remove('active');
  });

  // Grid buttons inside Settings
  document.querySelectorAll('[data-grid]').forEach(b => {
    b.addEventListener('click', () => {
      const mode = b.getAttribute('data-grid');
      if (mode === 'off') {
        compGrid.style.display = 'none';
        currentGrid = 'off';
      } else {
        compGrid.style.display = 'block';
        currentGrid = mode;
      }
      modalSettings.classList.remove('active');
    });
  });

  // ========================================================
  // 9. Initial Load & 1-Second Timer
  // ========================================================
  updateSolarData();
  setInterval(updateSolarData, 1000);
});
