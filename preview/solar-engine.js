/**
 * SolX Solar Ephemeris Engine (JavaScript Implementation)
 * Exact mathematical twin of Shared/SolarMath.swift and SolarModels.swift.
 * Rigorous spherical trigonometry & NOAA solar calculations.
 */

class SolarEngine {
  constructor() {
    this.DEG2RAD = Math.PI / 180.0;
    this.RAD2DEG = 180.0 / Math.PI;
  }

  calculatePosition(lat, lon, date = new Date(), tzOffsetHours = null) {
    const tz = tzOffsetHours !== null ? tzOffsetHours : -date.getTimezoneOffset() / 60.0;
    
    // Day of year
    const startOfYear = new Date(date.getFullYear(), 0, 0);
    const diff = date - startOfYear;
    const oneDay = 1000 * 60 * 60 * 24;
    const dayOfYear = Math.floor(diff / oneDay);
    
    const hour = date.getHours() + date.getMinutes() / 60.0 + date.getSeconds() / 3600.0;
    
    // Fractional year γ (radians)
    const gamma = (2.0 * Math.PI / 365.0) * (dayOfYear - 1.0 + ((hour - 12.0) / 24.0));
    
    // Equation of Time (minutes)
    const eqtime = 229.18 * (
      0.000075 +
      0.001868 * Math.cos(gamma) -
      0.032077 * Math.sin(gamma) -
      0.014615 * Math.cos(2.0 * gamma) -
      0.040849 * Math.sin(2.0 * gamma)
    );
    
    // Solar Declination δ (radians)
    const decl = 0.006918 -
      0.399912 * Math.cos(gamma) +
      0.070257 * Math.sin(gamma) -
      0.006758 * Math.cos(2.0 * gamma) +
      0.000907 * Math.sin(2.0 * gamma) -
      0.002697 * Math.cos(3.0 * gamma) +
      0.001480 * Math.sin(3.0 * gamma);
    
    // True Solar Time (TST in minutes)
    const timeOffset = eqtime + (4.0 * lon) - (60.0 * tz);
    const trueSolarTime = (hour * 60.0) + timeOffset;
    
    // Solar Hour Angle ω
    const hourAngleDeg = (trueSolarTime / 4.0) - 180.0;
    const hourAngle = hourAngleDeg * this.DEG2RAD;
    
    const latRad = lat * this.DEG2RAD;
    
    // Solar Zenith Angle θ
    let cosZenith = (Math.sin(latRad) * Math.sin(decl)) + (Math.cos(latRad) * Math.cos(decl) * Math.cos(hourAngle));
    cosZenith = Math.max(-1.0, Math.min(1.0, cosZenith));
    const zenith = Math.acos(cosZenith);
    
    // Solar Altitude α (degrees)
    const altitude = 90.0 - (zenith * this.RAD2DEG);
    
    // Solar Azimuth Angle A (degrees from North)
    let cosAzimuth = ((Math.sin(latRad) * Math.cos(zenith)) - Math.sin(decl)) / (Math.cos(latRad) * Math.sin(zenith));
    cosAzimuth = Math.max(-1.0, Math.min(1.0, cosAzimuth));
    let azimuth = Math.acos(cosAzimuth) * this.RAD2DEG;
    
    if (hourAngleDeg > 0) {
      azimuth = 360.0 - azimuth;
    }
    
    return { altitude, azimuth };
  }

  createSnapshot(lat, lon, date = new Date(), tzOffsetHours = null) {
    const tz = tzOffsetHours !== null ? tzOffsetHours : -date.getTimezoneOffset() / 60.0;
    const { altitude, azimuth } = this.calculatePosition(lat, lon, date, tz);
    
    const startOfDay = new Date(date.getFullYear(), date.getMonth(), date.getDate());
    
    const sunrise = this.calculateAltitudeCrossing(lat, lon, startOfDay, -0.833, true, tz);
    const sunset = this.calculateAltitudeCrossing(lat, lon, startOfDay, -0.833, false, tz);
    const solarNoon = this.calculateSolarNoon(lat, lon, startOfDay, tz);
    
    // Golden Hour: -4° to +6°
    const morningGoldenStart = this.calculateAltitudeCrossing(lat, lon, startOfDay, -4.0, true, tz);
    const morningGoldenEnd = this.calculateAltitudeCrossing(lat, lon, startOfDay, 6.0, true, tz);
    const eveningGoldenStart = this.calculateAltitudeCrossing(lat, lon, startOfDay, 6.0, false, tz);
    const eveningGoldenEnd = this.calculateAltitudeCrossing(lat, lon, startOfDay, -4.0, false, tz);
    
    // Blue Hour: -6° to -4°
    const morningBlueStart = this.calculateAltitudeCrossing(lat, lon, startOfDay, -6.0, true, tz);
    const morningBlueEnd = morningGoldenStart;
    const eveningBlueStart = eveningGoldenEnd;
    const eveningBlueEnd = this.calculateAltitudeCrossing(lat, lon, startOfDay, -6.0, false, tz);
    
    // Next Golden Hour
    const nextGH = this.findNextGoldenHour(date, lat, lon, tz, morningGoldenStart, morningGoldenEnd, eveningGoldenStart, eveningGoldenEnd);
    const timeToNextGoldenHour = Math.max(0, (nextGH.start - date) / 1000);
    
    // Phase
    const phase = this.determinePhase(altitude, date, solarNoon);
    
    return {
      date,
      coordinate: { latitude: lat, longitude: lon },
      altitude,
      azimuth,
      altitudeString: `${altitude >= 0 ? '+' : ''}${Math.round(altitude)}°`,
      azimuthCompassString: this.formatCompass(azimuth),
      currentPhase: phase,
      sunrise,
      sunset,
      solarNoon,
      morningGoldenHourStart: morningGoldenStart,
      morningGoldenHourEnd: morningGoldenEnd,
      eveningGoldenHourStart: eveningGoldenStart,
      eveningGoldenHourEnd: eveningGoldenEnd,
      morningBlueHourStart: morningBlueStart,
      morningBlueHourEnd: morningBlueEnd,
      eveningBlueHourStart: eveningBlueStart,
      eveningBlueHourEnd: eveningBlueEnd,
      nextGoldenHourStart: nextGH.start,
      nextGoldenHourEnd: nextGH.end,
      isNextGoldenMorning: nextGH.isMorning,
      timeToNextGoldenHour,
      countdownFormatted: this.formatCountdown(timeToNextGoldenHour)
    };
  }

  calculateSolarNoon(lat, lon, startOfDay, tz) {
    const dayOfYear = this.getDayOfYear(startOfDay);
    const gamma = (2.0 * Math.PI / 365.0) * (dayOfYear - 1.0);
    const eqtime = 229.18 * (
      0.000075 +
      0.001868 * Math.cos(gamma) -
      0.032077 * Math.sin(gamma) -
      0.014615 * Math.cos(2.0 * gamma) -
      0.040849 * Math.sin(2.0 * gamma)
    );
    const solarNoonMinutes = 720.0 - (4.0 * lon) - eqtime + (tz * 60.0);
    return new Date(startOfDay.getTime() + solarNoonMinutes * 60000);
  }

  calculateAltitudeCrossing(lat, lon, startOfDay, targetAltitude, isRising, tz) {
    const dayOfYear = this.getDayOfYear(startOfDay);
    const gamma = (2.0 * Math.PI / 365.0) * (dayOfYear - 1.0);
    const decl = 0.006918 -
      0.399912 * Math.cos(gamma) +
      0.070257 * Math.sin(gamma) -
      0.006758 * Math.cos(2.0 * gamma) +
      0.000907 * Math.sin(2.0 * gamma) -
      0.002697 * Math.cos(3.0 * gamma) +
      0.001480 * Math.sin(3.0 * gamma);
      
    const eqtime = 229.18 * (
      0.000075 +
      0.001868 * Math.cos(gamma) -
      0.032077 * Math.sin(gamma) -
      0.014615 * Math.cos(2.0 * gamma) -
      0.040849 * Math.sin(2.0 * gamma)
    );
    
    const latRad = lat * this.DEG2RAD;
    const targetZenithRad = (90.0 - targetAltitude) * this.DEG2RAD;
    
    let cosHA = (Math.cos(targetZenithRad) - (Math.sin(latRad) * Math.sin(decl))) / (Math.cos(latRad) * Math.cos(decl));
    if (cosHA > 1.0) {
      return new Date(startOfDay.getTime() + (isRising ? 6 : 18) * 3600000);
    } else if (cosHA < -1.0) {
      return new Date(startOfDay.getTime() + (isRising ? 0 : 24) * 3600000);
    }
    
    cosHA = Math.max(-1.0, Math.min(1.0, cosHA));
    const haDeg = Math.acos(cosHA) * this.RAD2DEG;
    
    let timeMinutes;
    if (isRising) {
      timeMinutes = 720.0 - (4.0 * lon) - eqtime - (4.0 * haDeg) + (tz * 60.0);
    } else {
      timeMinutes = 720.0 - (4.0 * lon) - eqtime + (4.0 * haDeg) + (tz * 60.0);
    }
    return new Date(startOfDay.getTime() + timeMinutes * 60000);
  }

  determinePhase(altitude, date, solarNoon) {
    const isAfternoon = date >= solarNoon;
    if (altitude > 6.0) {
      return { id: isAfternoon ? 'afternoon' : 'daylight', name: isAfternoon ? 'Afternoon' : 'Daylight', isGolden: false, isBlue: false, color: '#f5c542' };
    } else if (altitude >= -4.0) {
      return { id: isAfternoon ? 'eveningGolden' : 'morningGolden', name: isAfternoon ? 'Golden Hour' : 'Golden Hour (Dawn)', isGolden: true, isBlue: false, color: '#f8b426' };
    } else if (altitude >= -6.0) {
      return { id: isAfternoon ? 'eveningBlue' : 'morningBlue', name: isAfternoon ? 'Blue Hour' : 'Blue Hour (Dawn)', isGolden: false, isBlue: true, color: '#3878e0' };
    } else {
      return { id: 'night', name: 'Night', isGolden: false, isBlue: false, color: '#161e36' };
    }
  }

  findNextGoldenHour(now, lat, lon, tz, mStart, mEnd, eStart, eEnd) {
    if (now >= mStart && now <= mEnd) return { start: mStart, end: mEnd, isMorning: true };
    if (now < mStart) return { start: mStart, end: mEnd, isMorning: true };
    if (now >= eStart && now <= eEnd) return { start: eStart, end: eEnd, isMorning: false };
    if (now < eStart) return { start: eStart, end: eEnd, isMorning: false };
    
    // Tomorrow morning
    const tomorrow = new Date(now.getTime() + 24 * 3600000);
    const startOfTomorrow = new Date(tomorrow.getFullYear(), tomorrow.getMonth(), tomorrow.getDate());
    const tmStart = this.calculateAltitudeCrossing(lat, lon, startOfTomorrow, -4.0, true, tz);
    const tmEnd = this.calculateAltitudeCrossing(lat, lon, startOfTomorrow, 6.0, true, tz);
    return { start: tmStart, end: tmEnd, isMorning: true };
  }

  getDayOfYear(date) {
    const startOfYear = new Date(date.getFullYear(), 0, 0);
    const diff = date - startOfYear;
    return Math.floor(diff / (1000 * 60 * 60 * 24));
  }

  formatCompass(azimuth) {
    const directions = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE', 'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'];
    const idx = Math.round(azimuth / 22.5) % 16;
    return `${Math.round(azimuth)}° ${directions[idx]}`;
  }

  formatCountdown(seconds) {
    if (seconds <= 0) return 'Active Now';
    const hrs = Math.floor(seconds / 3600);
    const mins = Math.floor((seconds % 3600) / 60);
    const secs = Math.floor(seconds % 60);
    if (hrs > 0) return `${hrs}h ${mins}m`;
    if (mins > 0) return `${mins}m ${secs}s`;
    return `${secs}s`;
  }

  formatTime(date) {
    if (!date || isNaN(date.getTime())) return '--:--';
    const h = String(date.getHours()).padStart(2, '0');
    const m = String(date.getMinutes()).padStart(2, '0');
    return `${h}:${m}`;
  }
}

window.solarEngine = new SolarEngine();
