<script>
	import { onMount, createEventDispatcher, onDestroy } from 'svelte';
	import maplibregl from 'maplibre-gl';
	import 'maplibre-gl/dist/maplibre-gl.css';

	export let center = [98.954, 18.8];
	export let zoom = 15;
	export let interactive = true;

	let mapContainer;
	let map;
	let resizeObserver; // เพิ่มตัวแปรเก็บ Observer
	const dispatch = createEventDispatcher();

	onMount(() => {
		map = new maplibregl.Map({
			container: mapContainer,
			interactive: interactive,
			style: {
				version: 8,
				sources: {
					'osm-tiles': {
						type: 'raster',
						tiles: ['https://a.tile.openstreetmap.org/{z}/{x}/{y}.png'],
						tileSize: 256,
						attribution: '© OpenStreetMap'
					}
				},
				layers: [
					{
						id: 'osm-tiles',
						type: 'raster',
						source: 'osm-tiles',
						minzoom: 0,
						maxzoom: 19
					}
				]
			},
			center: [98.952, 18.8],
			zoom: 15,
			minZoom: 14,
			maxZoom: 18
		});

		if (window.innerWidth >= 768 && interactive) {
			map.addControl(new maplibregl.NavigationControl(), 'bottom-right');
		}

		map.on('load', () => {
			dispatch('load', { map, maplibregl });
			// สั่ง resize ทีหนึ่งตอนโหลดเสร็จ เพื่อความชัวร์
			map.resize();
		});

		map.on('click', (e) => dispatch('click', e));

		// ✅ เพิ่มส่วนนี้: สร้าง ResizeObserver เพื่อดักจับการเปลี่ยนแปลงขนาด
		resizeObserver = new ResizeObserver(() => {
			if (map) {
				map.resize(); // สั่งให้แมพคำนวณขนาดใหม่ทันที
			}
		});

		// เริ่มเฝ้าดู mapContainer
		resizeObserver.observe(mapContainer);
	});

	onDestroy(() => {
		// ✅ อย่าลืมทำลาย Observer เมื่อปิดหน้า
		if (resizeObserver) {
			resizeObserver.disconnect();
		}
		if (map) map.remove();
	});
</script>

<div class="absolute inset-0 h-full w-full bg-gray-100" bind:this={mapContainer}></div>
