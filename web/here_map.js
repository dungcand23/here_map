// web/here_map.js
let platform = null;
let map = null;
let ui = null;
let behavior = null;
let currentEl = null;
let ro = null;

let markersGroup = null;
let polylinesGroup = null;

function findInRoot(root, id) {
  if (!root) return null;
  try { return root.getElementById ? root.getElementById(id) : null; } catch (_) {}
  return null;
}

function findDeep(id) {
  // normal DOM
  let el = null;
  try { el = document.getElementById(id); } catch (_) {}
  if (el) return el;

  // search shadow roots (Flutter web)
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
    console.error('[HERE] HERE JS not loaded. Check web/index.html includes mapsjs-core/service/ui/mapevents.');
    return false;
  }

  const key = getApiKey();
  if (!key || key.length < 10) {
    console.error('[HERE] API KEY missing. Set window.HERE_API_KEY = "xxxx" in web/index.html (before here_map.js).');
    return false;
  }

  const el = findDeep(containerId);
  if (!el) return false;

  // Flutter rebuild -> element đổi -> re-init
  if (map && currentEl && el !== currentEl) {
    disposeMap();
  }

  if (map) return true;

  platform = new H.service.Platform({ apikey: key });
  const layers = platform.createDefaultLayers();

  map = new H.Map(
    el,
    (layers.vector && layers.vector.normal && layers.vector.normal.map)
      ? layers.vector.normal.map
      : layers.normal.map,
    {
      center: { lat: 10.776, lng: 106.700 },
      zoom: 12,
      pixelRatio: window.devicePixelRatio || 1,
    }
  );

  behavior = new H.mapevents.Behavior(new H.mapevents.MapEvents(map));
  ui = H.ui.UI.createDefault(map, layers);

  markersGroup = new H.map.Group();
  polylinesGroup = new H.map.Group();
  map.addObject(markersGroup);
  map.addObject(polylinesGroup);

  window.addEventListener('resize', () => {
    try { map.getViewPort().resize(); } catch (_) {}
  });

  if (window.ResizeObserver) {
    ro = new ResizeObserver(() => {
      try { map.getViewPort().resize(); } catch (_) {}
    });
    ro.observe(el);
  }

  currentEl = el;
  try { map.getViewPort().resize(); } catch (_) {}

  return true;
}

function clearMarkers() {
  try { markersGroup?.removeAll(); } catch (_) {}
}

function clearPolylines() {
  try { polylinesGroup?.removeAll(); } catch (_) {}
}

function markerSvg(label, color) {
  const t = (label ?? '').toString();
  const c = (color ?? '#1A73E8').toString();
  return `
<svg xmlns="http://www.w3.org/2000/svg" width="34" height="44" viewBox="0 0 34 44">
  <path d="M17 1C9.3 1 3 7.3 3 15c0 10.6 14 28 14 28s14-17.4 14-28C31 7.3 24.7 1 17 1z"
        fill="${c}" stroke="#0B3D91" stroke-width="1"/>
  <circle cx="17" cy="15" r="10" fill="white" opacity="0.95"/>
  <text x="17" y="19" text-anchor="middle" font-family="Arial" font-size="12" font-weight="700" fill="#1A73E8">${t}</text>
</svg>`;
}

// ✅ Convert payload.stops -> markers (để tương thích code Flutter hiện tại của bạn)
function stopsToMarkers(stops) {
  if (!Array.isArray(stops)) return [];

  const markers = [];
  for (let i = 0; i < stops.length; i++) {
    const s = stops[i] || {};
    const name = (s.name ?? s.title ?? s.label ?? '').toString().trim();

    const lat = Number(
      s.lat ?? s.latitude ?? (s.position ? s.position.lat : undefined)
    );
    const lng = Number(
      s.lng ?? s.lon ?? s.longitude ?? (s.position ? s.position.lng : undefined)
    );

    // bỏ stop rỗng / chưa có tọa độ
    if (!name) continue;
    if (!isFinite(lat) || !isFinite(lng)) continue;
    if (lat === 0 && lng === 0) continue;

    markers.push({
      lat,
      lng,
      label: String(i + 1),
      title: name,
      color: '#1A73E8',
    });
  }
  return markers;
}

window.updateMap = function (payloadStr, containerId) {
  if (!ensureMap(containerId)) return;

  let payload = null;
  try { payload = JSON.parse(payloadStr); }
  catch (e) { console.error('[HERE] invalid payload', e); return; }

  // clear layers (đúng với phase bạn đang muốn: không để "ma")
  if (payload.clearMarkers || payload.stops || payload.markers) clearMarkers();
  if (payload.clearPolylines) clearPolylines();

  // ưu tiên markers nếu có, không thì lấy stops
  let markers = [];
  if (Array.isArray(payload.markers)) {
    markers = payload.markers;
  } else if (Array.isArray(payload.stops)) {
    markers = stopsToMarkers(payload.stops);
  }

  // draw markers
  if (Array.isArray(markers)) {
    markers.forEach((m, idx) => {
      const lat = Number(m.lat);
      const lng = Number(m.lng);
      if (!isFinite(lat) || !isFinite(lng)) return;

      const icon = new H.map.Icon(markerSvg(m.label ?? String(idx + 1), m.color || '#1A73E8'));
      const marker = new H.map.Marker({ lat, lng }, { icon });
      markersGroup.addObject(marker);
    });
  }

  // center map
  if (payload.center?.lat != null && payload.center?.lng != null) {
    map.setCenter({ lat: Number(payload.center.lat), lng: Number(payload.center.lng) }, true);
  } else if (markers.length > 0) {
    const last = markers[markers.length - 1];
    map.setCenter({ lat: Number(last.lat), lng: Number(last.lng) }, true);
  }

  if (payload.zoom != null) map.setZoom(Number(payload.zoom), true);

  try { map.getViewPort().resize(); } catch (_) {}
};

window.resizeHereMap = function (containerId) {
  if (!ensureMap(containerId)) return;
  try { map.getViewPort().resize(); } catch (_) {}
};
