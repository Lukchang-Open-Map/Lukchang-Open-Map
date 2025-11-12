<script>
    import { onMount } from 'svelte';
    import { userStore } from '$lib/userStore.js';
    import PinCategoryPanel from './PinCategoryPanel.svelte';
    import FilterSidebar from './FilterSidebar.svelte';

    let map;

    let maplibregl;
    let userLocationMarker = null;

    let Menu, User, ChevronDown, X, Crosshair;
    let isMobile = false;
    let isOpen = false; 
    let isFilterSidebarOpen = false;
    let selectedCategory = null;

    let filterState = {
        accident: true,
        blocked: true,
        beware: true,
        flood: true,
        send_help: true,
        traffic_general: true,
        parking: true,
        events: true,
        map_chat: true,
        lost_found: true
    };

    function handleLogout() {
        userStore.set(null);
    }

    function clickOutside(node) {
        const handleClick = (event) => {
            if (node && !node.contains(event.target) && !event.defaultPrevented) {
                node.dispatchEvent(new CustomEvent('clickoutside'));
            }
        };
        document.addEventListener('click', handleClick, true);
        return {
            destroy() {
                document.removeEventListener('click', handleClick, true);
            }
        };
    }

    function findUserLocation() {
        if (!navigator.geolocation) {
            alert('Geolocation is not supported by your browser.');
            return;
        }

        // asks the user for permission
        navigator.geolocation.getCurrentPosition(
            (position) => {
                // Allow
                const { longitude, latitude } = position.coords;

                if (userLocationMarker) {
                    userLocationMarker.remove();
                }

                // Create a new marker
                userLocationMarker = new maplibregl.Marker({ color: '#8F66FF' })
                    .setLngLat([longitude, latitude])
                    .addTo(map);
                
                // Fly the map to the user's location
                map.flyTo({
                    center: [longitude, latitude],
                    zoom: 16
                });
            },
            (error) => {
                // User clicked "Block" or an error occurred
                console.error('Error getting location:', error.message);
                alert('Could not get your location. Please ensure you have granted permission.');
            }
        );
    }

    onMount(async () => {
        isMobile = window.innerWidth < 768;

        const icons = await import('lucide-svelte');
        Menu = icons.Menu;
        User = icons.User;
        ChevronDown = icons.ChevronDown;
        X = icons.X;
        Crosshair = icons.Crosshair; 

        maplibregl = (await import('maplibre-gl')).default;

        map = new maplibregl.Map({
            container: 'map',
            style: {
                version: 8,
                sources: {
                    'osm-tiles': {
                        type: 'raster',
                        tiles: [
                            'https://a.tile.openstreetmap.org/{z}/{x}/{y}.png',
                            'https://b.tile.openstreetmap.org/{z}/{x}/{y}.png',
                            'https://c.tile.openstreetmap.org/{z}/{x}/{y}.png'
                        ],
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
            center: [98.954, 18.8],
            zoom: 15,
            maxBounds: [
                [98.94111, 18.79058],
                [98.96806, 18.81146]
            ],
            minZoom: 14,
            maxZoom: 18
        });

        map.addControl(new maplibregl.NavigationControl(), 'bottom-right');

        window.addEventListener('resize', () => {
            isMobile = window.innerWidth < 768;
        });
    });
</script>

<div id="map-container" class="relative h-screen w-full">
    <div id="map" class="h-full w-full"></div>

    {#if isFilterSidebarOpen}
        <FilterSidebar 
            bind:filters={filterState} 
            on:close={() => isFilterSidebarOpen = false} 
        />
    {/if}

    {#if Menu && User && ChevronDown && X && Crosshair}
        <nav class="absolute top-4 right-0 left-0 z-40 flex items-center justify-between px-4">
            
            <button
                class="flex items-center justify-center rounded-[12px] bg-white p-3 shadow-md hover:bg-gray-100"
                on:click={() => isFilterSidebarOpen = true}
            >
                <Menu class="h-6 w-6" />
            </button>

            <div class="relative" use:clickOutside on:clickoutside={() => (isOpen = false)}>
                {#if $userStore}
                    <button
                        on:click={() => (isOpen = !isOpen)}
                        class="flex items-center gap-2 rounded-[12px] bg-white p-3 pr-2 shadow-md hover:bg-gray-100"
                    >
                        <div class="flex h-6 w-6 items-center justify-center rounded-full bg-gray-200">
                            <User class="h-4 w-4" />
                        </div>

                        <span class="hidden font-medium sm:block">{$userStore?.name ?? 'User'}</span>
                        {#if $userStore?.role}
                            <span
                                class="hidden rounded-full bg-[#EBE0F3] px-2 py-0.5 text-xs font-bold text-[#8F66FF] sm:block"
                            >
                                {$userStore.role}
                            </span>
                        {/if}
                        <ChevronDown
                            class="h-4 w-4 transition-transform duration-300"
                            style="transform: rotate({isOpen ? 180 : 0}deg)"
                        />
                    </button>

                    {#if isOpen}
                        <div class="absolute right-0 z-10 mt-2 w-60 rounded-xl border border-gray-200 bg-white p-2 shadow-lg">
                            <div class="p-2">
                                <div class="font-bold">{$userStore?.name ?? 'User'}</div>
                                <div class="text-sm text-gray-500">{$userStore?.email ?? ''}</div>
                            </div>
                            <div class="mt-1 border-t pt-1">
                                <button
                                    on:click={handleLogout}
                                    class="flex w-full items-center gap-3 rounded-lg px-3 py-2 text-left hover:bg-gray-100"
                                >
                                    Sign Out
                                </button>
                            </div>
                        </div>
                    {/if}
                {:else}
                    <a
                        href="/login"
                        class="flex items-center justify-center rounded-[12px] bg-white p-3 shadow-md hover:bg-gray-100"
                    >
                        <User class="h-6 w-6" />
                    </a>
                {/if}
            </div>
        </nav>
    {/if}

    {#if !isMobile}
        <PinCategoryPanel bind:selectedCategory />
    {/if}

    {#if Crosshair}
        <button
            class="absolute bottom-38 right-2 z-40 flex h-8 w-8 items-center justify-center rounded-full
                   bg-white shadow-md transition-all duration-150 hover:bg-gray-100 active:scale-95"
            on:click={findUserLocation}
            title="Find my location"
        >
            <Crosshair class="h-6 w-6" />
        </button>
    {/if}

    {#if isMobile}
        <button
            class="fixed right-12 bottom-15 z-50 flex h-16 w-16 items-center justify-center rounded-full
           bg-white text-3xl shadow-xl transition-all duration-150 hover:bg-gray-100 active:scale-95"
            on:click={() => console.log('add pin')}
            title="Add Pin"
        >
            +
        </button>
    {/if}
    
    <img src="/logo.svg" alt="Logo" class="absolute bottom-4 left-4 z-50 h-8" />
</div>

<style>
    #map {
        width: 100%;
        height: 100%;
    }
</style>