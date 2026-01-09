// web/here_map.js
let platform = null;
let map = null;
let ui = null;
let behavior = null;
let currentEl = null;
let ro = null;

let markersGroup = null;
let polylinesGroup = null;

function _hereLog(...args) {
  if (window.HERE_DEBUG === false) return;
  console.log(...args);
}

function findInRoot(root, id) {
  if (!root) return null;
  try { return root.getElementById ? root.getElementById(id) : null; } catch (_) {}
  return null;
}

function findDeep(id) {
  let el = null;
  try { el = document.getElementById(id); } catch (_) {}
  if (el) return el;

  const all = document.querySelectorAll('*');
  const max = Math.min(all.length, 3500);
  for (let i = 0; i < max; i++) {
    const sr = all[i].shadowRoot;
    if (!sr) continue;
    el = findInRoot(sr, id);
    if (el) return el;
  }
  return null;
}

function getApiKey() {
  const v =
    window.HERE_API_KEY ||
    window.hereApiKey ||
    window.apiKey ||
    window.API_KEY ||
    (document.querySelector('meta[name="here-api-key"]')?.content) ||
    '';
  return (typeof v === 'string') ? v.trim() : '';
}

// Flutter Web có thể gọi để inject key runtime
window.setHereApiKey = function (k) {
  window.HERE_API_KEY = (k || '').toString();
};

function disposeMap() {
  try { ro?.disconnect(); } catch (_) {}
  try { map?.dispose(); } catch (_) {}
  platform = null;
  map = null;
  ui = null;
  behavior = null;
  markersGroup = null;
  polylinesGroup = null;
  currentEl = null;
}

function ensureMap(containerId) {
  containerId = containerId || 'here_map_container';

  if (!window.H || !H.service || !H.Map) {
    console.error('[HERE] HERE JS not loaded.');
    return false;
  }

  const key = getApiKey();
  if (!key || key.length < 10) {
    console.error('[HERE] API KEY missing.');
    return false;
  }

  const el = findDeep(containerId);
  if (!el) return false;

  if (map && currentEl && el !== currentEl) disposeMap();
  if (map) return true;

  platform = new H.service.Platform({ apikey: key });
  const layers = platform.createDefaultLayers();

  map = new H.Map(
    el,
    (layers.vector && layers.vector.normal && layers.vector.normal.map)
      ? layers.vector.normal.map
      : layers.normal.map,
    { center: { lat: 10.776, lng: 106.700 }, zoom: 12, pixelRatio: window.devicePixelRatio || 1 }
  );

  behavior = new H.mapevents.Behavior(new H.mapevents.MapEvents(map));
  ui = H.ui.UI.createDefault(map, layers);

  markersGroup = new H.map.Group();
  polylinesGroup = new H.map.Group();
  map.addObject(markersGroup);
  map.addObject(polylinesGroup);

  if (window.ResizeObserver) {
    ro = new ResizeObserver(() => { try { map.getViewPort().resize(); } catch (_) {} });
    ro.observe(el);
  }
  currentEl = el;

  try { map.getViewPort().resize(); } catch (_) {}
  _hereLog('[HERE] Map initialized');
  return true;
}

function clearMarkers() {
  try { markersGroup?.removeAll(); } catch (_) {}
}

function clearPolylines() {
  try { polylinesGroup?.removeAll(); } catch (_) {}
}

// ✅ DOM marker (đánh số) — ổn định hơn SVG
function createNumberedDomMarker(lat, lng, label, color) {
  const c = (color || '#1A73E8').toString();
  const text = (label ?? '').toString();

  const el = document.createElement('div');
  el.style.width = '28px';
  el.style.height = '28px';
  el.style.borderRadius = '999px';
  el.style.background = c;
  el.style.boxShadow = '0 6px 14px rgba(0,0,0,0.25)';
  el.style.display = 'flex';
  el.style.alignItems = 'center';
  el.style.justifyContent = 'center';
  el.style.transform = 'translate(-50%, -50%)';
  el.style.border = '2px solid white';

  const span = document.createElement('span');
  span.textContent = text;
  span.style.color = '#fff';
  span.style.fontWeight = '800';
  span.style.fontFamily = 'Arial, sans-serif';
  span.style.fontSize = '12px';
  span.style.lineHeight = '1';
  el.appendChild(span);

  if (H.map.DomMarker) {
    const icon = new H.map.DomIcon(el);
    const m = new H.map.DomMarker({ lat, lng }, { icon });
    m.setZIndex(9999);
    return m;
  }

  const m = new H.map.Marker({ lat, lng });
  m.setZIndex(9999);
  return m;
}

window.updateMap = function (payloadStr, containerId) {
  containerId = containerId || 'here_map_container';
  if (!ensureMap(containerId)) return;

  let payload = null;
  try { payload = (typeof payloadStr === 'string') ? JSON.parse(payloadStr) : payloadStr; }
  catch (e) { console.error('[HERE] invalid payload', e); return; }

  const hasStops = Array.isArray(payload.stops) && payload.stops.length > 0;
  const hasMarkers = Array.isArray(payload.markers) && payload.markers.length > 0;
  const hasPolyline = Array.isArray(payload.polyline) && payload.polyline.length > 1; // legacy
  const hasPolylinesEncoded = Array.isArray(payload.polylinesEncoded) && payload.polylinesEncoded.length > 0;

  _hereLog('[HERE] Nhận payload', {
    clearMarkers: payload.clearMarkers === true,
    clearPolylines: payload.clearPolylines === true,
    markersLen: Array.isArray(payload.markers) ? payload.markers.length : 0,
    stopsLen: Array.isArray(payload.stops) ? payload.stops.length : 0,
    polylineLen: Array.isArray(payload.polyline) ? payload.polyline.length : 0,
    polylinesEncodedLen: Array.isArray(payload.polylinesEncoded) ? payload.polylinesEncoded.length : 0,
  });

  if (payload.clearMarkers === true || hasStops || hasMarkers) clearMarkers();
  if (payload.clearPolylines === true || hasPolyline || hasPolylinesEncoded) clearPolylines();

  let markers = [];
  if (Array.isArray(payload.markers)) markers = payload.markers;

  let lastLat = null, lastLng = null;

  if (markers.length > 0) {
    for (let i = 0; i < markers.length; i++) {
      const m = markers[i] || {};
      const lat = Number(m.lat);
      const lng = Number(m.lng);
      if (!isFinite(lat) || !isFinite(lng)) continue;

      const label = (m.label != null) ? String(m.label) : String(i + 1);
      const color = m.color || '#1A73E8';

      const markerObj = createNumberedDomMarker(lat, lng, label, color);
      markersGroup.addObject(markerObj);

      lastLat = lat;
      lastLng = lng;
    }
    _hereLog(`[HERE] Đã vẽ ${markers.length} marker(s)`);
  }

  // ----- POLYLINE -----
  let routeFitted = false;

  // Preferred: decode on JS using HERE native decoder
  if (hasPolylinesEncoded) {
    try {
      for (let i = 0; i < payload.polylinesEncoded.length; i++) {
        const enc = payload.polylinesEncoded[i];
        if (!enc || typeof enc !== 'string') continue;

        const ls = H.geo.LineString.fromFlexiblePolyline(enc);
        if (!ls || ls.getPointCount() < 2) continue;

        const pl = new H.map.Polyline(ls, { style: { lineWidth: 5, strokeColor: '#1A73E8' } });
        polylinesGroup.addObject(pl);
      }

      const bbox = polylinesGroup.getBoundingBox && polylinesGroup.getBoundingBox();
      if (bbox) {
        map.getViewModel().setLookAtData({ bounds: bbox }, true);
        routeFitted = true;
      }

      _hereLog(`[HERE] Đã vẽ polyline (encoded sections: ${payload.polylinesEncoded.length})`);
    } catch (e) {
      console.warn('[HERE] draw polyline (encoded) failed', e);
    }
  } else if (hasPolyline) {
    // legacy list-of-points
    try {
      const ls = new H.geo.LineString();
      for (let i = 0; i < payload.polyline.length; i++) {
        const pt = payload.polyline[i] || {};
        const lat = Number(pt.lat);
        const lng = Number(pt.lng);
        if (!isFinite(lat) || !isFinite(lng)) continue;
        if (lat < -90 || lat > 90 || lng < -180 || lng > 180) continue;
        ls.pushPoint({ lat, lng });
      }

      if (ls.getPointCount() > 1) {
        const pl = new H.map.Polyline(ls, { style: { lineWidth: 5, strokeColor: '#1A73E8' } });
        polylinesGroup.addObject(pl);

        const bbox = pl.getBoundingBox();
        if (bbox) {
          map.getViewModel().setLookAtData({ bounds: bbox }, true);
          routeFitted = true;
        }
        _hereLog(`[HERE] Đã vẽ polyline (${ls.getPointCount()} points)`);
      }
    } catch (e) {
      console.warn('[HERE] draw polyline failed', e);
    }
  }

  // center/zoom về marker
  if (!routeFitted && lastLat != null && lastLng != null) {
    map.setCenter({ lat: lastLat, lng: lastLng }, true);
    const z = (payload.zoom != null) ? Number(payload.zoom) : 15;
    map.setZoom(z, true);
  } else if (!routeFitted) {
    if (payload.center?.lat != null && payload.center?.lng != null) {
      map.setCenter({ lat: Number(payload.center.lat), lng: Number(payload.center.lng) }, true);
      if (payload.zoom != null) map.setZoom(Number(payload.zoom), true);
    }
  }

  try { map.getViewPort().resize(); } catch (_) {}
};

window.resizeHereMap = function (containerId) {
  containerId = containerId || 'here_map_container';
  if (!ensureMap(containerId)) return;
  try { map.getViewPort().resize(); } catch (_) {}
};
