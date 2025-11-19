<script>
    import { onMount, createEventDispatcher, onDestroy } from 'svelte';
    import maplibregl from 'maplibre-gl';
    import 'maplibre-gl/dist/maplibre-gl.css';

    export let center = [98.954, 18.8];
    export let zoom = 15;
    export let interactive = true;

    let mapContainer;
    let map;
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
                layers: [{
                    id: 'osm-tiles',
                    type: 'raster',
                    source: 'osm-tiles',
                    minzoom: 0,
                    maxzoom: 19
                }]
            },
            center: center,
            zoom: zoom,
            maxBounds: [[98.93, 18.78], [98.97, 18.82]]
        });

        // Add Navigation Control only if not mobile (optional logic can be handled by parent)
        if (window.innerWidth >= 768 && interactive) {
             map.addControl(new maplibregl.NavigationControl(), 'bottom-right');
        }

        map.on('load', () => {
            dispatch('load', { map, maplibregl });
        });

        map.on('click', (e) => dispatch('click', e));
    });

    onDestroy(() => {
        if (map) map.remove();
    });
</script>

<div class="w-full h-full absolute inset-0 bg-gray-100" bind:this={mapContainer}></div>