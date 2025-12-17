// web/here_map.js
// window.updateMap(payloadJsonString, containerId)

let map = null;
let platform = null;
let ui = null;
let behavior = null;

let markersGroup = null;
let polylinesGroup = null;
let currentContainerId = null;

function ensureMap(containerId) {
  containerId = containerId || 'here_map_container';

  // Nếu hot restart/layout làm container đổi -> dispose map cũ
  if (map && currentContainerId && currentContainerId !== containerId) {
    try { map.dispose(); } catch (_) {}
    map = null;
    platform = null;
    ui = null;
    behavior = null;
    markersGroup = null;
    polylinesGroup = null;
    currentContainerId = null;
  }

  if (map) return true;

  const el = document.getElementById(containerId);
  if (!el) {
    console.error('[HERE] container not found:', containerId);
    return false;
  }

  if (!window.H || !H.service || !H.Map) {
    console.error('[HERE] HERE JS not loaded (window.H missing).');
    return false;
  }

  const apiKey = window.HERE_API_KEY;
  if (!apiKey || typeof apiKey !== 'string' || apiKey.trim() === '') {
    console.error('[HERE] window.HERE_API_KEY missing.');
    return false;
  }

  platform = new H.service.Platform({ apikey: apiKey });
  const layers = platform.createDefaultLayers();

  map = new H.Map(
    el,
    layers.vector?.normal?.map ?? layers.normal.map,
    { center: { lat: 10.776, lng: 106.700 }, zoom: 12, pixelRatio: window.devicePixelRatio || 1 }
  );

  behavior = new H.mapevents.Behavior(new H.mapevents.MapEvents(map));
  ui = H.ui.UI.createDefault(map, layers);

  markersGroup = new H.map.Group();
  polylinesGroup = new H.map.Group();
  map.addObject(markersGroup);
  map.addObject(polylinesGroup);

  window.addEventListener('resize', () => map.getViewPort().resize());
  currentContainerId = containerId;

  return true;
}

function markerSvgNumber(label, color) {
  const fill = color || '#1A73E8';
  const text = String(label || '');
  return `
  <svg xmlns="http://www.w3.org/2000/svg" width="34" height="34">
    <circle cx="17" cy="17" r="14" fill="${fill}" />
    <circle cx="17" cy="17" r="14" fill="none" stroke="white" stroke-width="3"/>
    <text x="17" y="22" text-anchor="middle" font-family="Arial"
          font-size="14" font-weight="700" fill="white">${text}</text>
  </svg>`;
}

function clearMarkers() { markersGroup?.removeAll(); }
function clearPolylines() { polylinesGroup?.removeAll(); }

function drawPolyline(polylinePayload) {
  if (!polylinePayload) return;

  // Flexible polyline string
  if (typeof polylinePayload === 'string') {
    try {
      const ls = H.geo.LineString.fromFlexiblePolyline(polylinePayload);
      const pl = new H.map.Polyline(ls, { style: { lineWidth: 6, strokeColor: '#1A73E8' } });
      polylinesGroup.addObject(pl);
      map.getViewModel().setLookAtData({ bounds: pl.getBoundingBox() }, true);
      return;
    } catch (e) {
      console.error('[HERE] flexible polyline decode failed', e);
    }
  }

  // Points array [{lat,lng},...]
  if (Array.isArray(polylinePayload)) {
    try {
      const ls = new H.geo.LineString();
      polylinePayload.forEach(p => {
        const lat = Number(p.lat);
        const lng = Number(p.lng);
        if (isFinite(lat) && isFinite(lng)) ls.pushPoint({ lat, lng });
      });
      if (ls.getPointCount() < 2) return;
      const pl = new H.map.Polyline(ls, { style: { lineWidth: 6, strokeColor: '#1A73E8' } });
      polylinesGroup.addObject(pl);
      map.getViewModel().setLookAtData({ bounds: pl.getBoundingBox() }, true);
      return;
    } catch (e) {
      console.error('[HERE] points polyline draw failed', e);
    }
  }

  console.warn('[HERE] Unsupported polyline format:', polylinePayload);
}

window.updateMap = function (payloadStr, containerId) {
  if (!ensureMap(containerId)) return;

  let payload;
  try { payload = JSON.parse(payloadStr); }
  catch (e) { console.error('[HERE] invalid payload json', e); return; }

  if (payload.clearMarkers) clearMarkers();
  if (payload.clearPolylines) clearPolylines();

  if (Array.isArray(payload.markers)) {
    payload.markers.forEach(m => {
      const lat = Number(m.lat);
      const lng = Number(m.lng);
      if (!isFinite(lat) || !isFinite(lng)) return;
      const icon = new H.map.Icon(markerSvgNumber(m.label, m.color || '#1A73E8'));
      const marker = new H.map.Marker({ lat, lng }, { icon });
      markersGroup.addObject(marker);
    });
  }

  if (payload.polyline) drawPolyline(payload.polyline);

  if (payload.center && payload.center.lat != null && payload.center.lng != null) {
    map.setCenter({ lat: Number(payload.center.lat), lng: Number(payload.center.lng) }, true);
  }
  if (payload.zoom != null) map.setZoom(Number(payload.zoom), true);
};
