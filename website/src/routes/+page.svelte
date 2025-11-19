<script>
    import { onMount, mount } from 'svelte';
    import { fade, fly } from 'svelte/transition';
    import { userStore } from '$lib/stores/userStore.js';
    import { goto } from '$app/navigation';
    
    // Components
    import BaseMap from '$lib/component/Map/BaseMap.svelte';
    import Navbar from '$lib/component/layout/Navbar.svelte';
    import CustomMarker from '$lib/component/Map/CustomMarker.svelte';
    import PinCategoryPanel from '$lib/component/Map/PinCategoryPanel.svelte';
    import PinDetailForm from '$lib/component/common/PinDetailForm.svelte';
    import MobileCategorySheet from '$lib/component/Map/MobileCategorySheet.svelte';
    import SendHelpConfirmModal from '$lib/component/common/SendHelpConfirmModal.svelte';
    import FilterSidebar from '$lib/component/Map/FilterSidebar.svelte';
    import PointOrLineModal from '$lib/component/common/PointOrLineModal.svelte';
    
    // Icons & Config
    import { Crosshair } from 'lucide-svelte';
    import { CATEGORY_DISPLAY_NAMES, BLOCKED_MODAL_CONFIG } from '$lib/constant/map-config.js';
    import { generateUUID } from '$lib/utils/generators.js'; 
    import { timeAgo } from '$lib/utils/formatting.js';
    
    // Import Logic การกด Like/Dislike
    import { initializeMapInteractions } from '$lib/utils/map-interactions.js';

    // Map State
    let mapInstance;
    let maplibreglInstance;
    let isMobile = false;
    let showSplash = true;

    // UI State
    let selectedCategory = null;
    let showDetailForm = false;
    let pinCoordinates = null;
    let isMobileCategorySheetOpen = false;
    let showSendHelpModal = false;
    let isFilterSidebarOpen = false;
    let isPointOrLineModalOpen = false;
    let modalConfig = {};

    // Filter State
    let filterState = {
        accident: true, blocked: true, beware: true, flood: true, send_help: true,
        traffic_general: true, parking: true, events: true, map_chat: true, lost_found: true
    };

    // Line Drawing State
    let isDrawingLine = false;
    let drawingLineCategory = '';
    let currentLinePoints = [];
    let lineVertexMarkers = [];
    let showToast = false;
    let toastMessage = '';

    onMount(async () => {
        initializeMapInteractions();

        isMobile = window.innerWidth < 768;
        if(!$userStore) { goto('/login'); return; }
        if ($userStore.role === 'admin') { goto('/admin'); return; }
        if ($userStore.role === 'security') { goto('/security'); return; }
        await new Promise((resolve) => setTimeout(resolve, 3000));
        showSplash = false;
    });

    function handleMapLoad({ detail }) {
        mapInstance = detail.map;
        maplibreglInstance = detail.maplibregl;

        mapInstance.addSource('temp-line-source', { type: 'geojson', data: { type: 'Feature', geometry: { type: 'LineString', coordinates: [] } } });
        mapInstance.addLayer({ id: 'temp-line-layer', type: 'line', source: 'temp-line-source', paint: { 'line-color': '#F97316', 'line-width': 5, 'line-dasharray': [2, 2] } });
    }

    function handleMapClick({ detail: e }) {
        if (isDrawingLine) {
            const coords = e.lngLat.toArray();
            currentLinePoints.push(coords);
            updateTempLine();
            const el = document.createElement('div');
            el.className = 'w-3 h-3 bg-white rounded-full border-2 border-orange-500 shadow-md';
            const marker = new maplibreglInstance.Marker({ element: el }).setLngLat(coords).addTo(mapInstance);
            lineVertexMarkers.push(marker);
        } 
    }

    function findUserLocation() {
        if (!navigator.geolocation) return alert('Geolocation not supported');
        navigator.geolocation.getCurrentPosition(
            (pos) => {
                const { longitude, latitude } = pos.coords;
                new maplibreglInstance.Marker({ color: '#8F66FF' }).setLngLat([longitude, latitude]).addTo(mapInstance);
                mapInstance.flyTo({ center: [longitude, latitude], zoom: 16 });
            },
            () => alert('Could not get location')
        );
    }

    function handleNextStep() {
        if (mapInstance) {
            const center = mapInstance.getCenter();
            pinCoordinates = { lng: center.lng, lat: center.lat };
            showDetailForm = true;
        }
    }

    function updateTempLine() {
        mapInstance.getSource('temp-line-source').setData({ type: 'Feature', geometry: { type: 'LineString', coordinates: currentLinePoints } });
    }

    function addPermanentLineToMap(points, category) {
        const lineId = generateUUID();
        const lineColor = category.includes('blocked') ? '#F97316' : '#EF4444';

        mapInstance.addSource(`perm-line-source-${lineId}`, {
            type: 'geojson',
            data: { type: 'Feature', geometry: { type: 'LineString', coordinates: points } }
        });

        mapInstance.addLayer({
            id: `perm-line-layer-${lineId}`,
            type: 'line',
            source: `perm-line-source-${lineId}`,
            layout: { 'line-join': 'round', 'line-cap': 'round' },
            paint: { 'line-color': lineColor, 'line-width': 6, 'line-opacity': 0.8 }
        });
    }

    function addPinToMap(data) {
        const el = document.createElement('div');
        mount(CustomMarker, { target: el, props: { category: data.category } });
        
        const pinId = data.id || generateUUID();
        const likes = data.likes || 0;
        const dislikes = data.dislikes || 0;

        const imageHTML = data.photoPreviewUrl 
            ? `<div style="width: 100%; height: 140px; background-image: url('${data.photoPreviewUrl}'); background-size: cover; background-position: center; border-radius: 12px; margin-bottom: 12px;"></div>` 
            : '';

        const popupHTML = `
            <div style="font-family: 'Kanit', sans-serif; min-width: 200px; padding: 4px;">
                ${imageHTML}
                <h3 style="font-size: 20px; font-weight: 800; color: #000; margin: 0 0 12px 0; line-height: 1.2;">
                    ${data.title}
                </h3>
                <div style="display: flex; justify-content: space-between; align-items: flex-end;">
                    <div style="font-size: 12px; color: #6B7280; line-height: 1.4;">
                        <span style="color: #6B7280;">report by</span><br>
                        <span style="color: #1F2937; font-weight: 700; font-size: 13px;">${data.reporter || 'anonymous'}</span><br>
                        <span style="color: #6B7280;">${timeAgo(data.timestamp)}</span>
                    </div>
                    <div style="display: flex; gap: 16px; align-items: center;">
                        <div style="display: flex; align-items: center; gap: 6px;">
                            <button id="like-button-${pinId}" onclick="window.handleLike('${pinId}')" style="background: none; border: none; cursor: pointer; padding: 0; display: flex; align-items: center;">
                                <svg xmlns="http://www.w3.org/2000/svg" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#374151" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M7 10v12"/><path d="M15 5.88 14 10h5.83a2 2 0 0 1 1.92 2.56l-2.33 8A2 2 0 0 1 17.5 22H4a2 2 0 0 1-2-2v-8a2 2 0 0 1 2-2h2.76a2 2 0 0 0 1.79-1.11L12 2h0a3.13 3.13 0 0 1 3 3.88Z"/></svg>
                            </button>
                            <span id="like-count-${pinId}" style="font-weight: 700; font-size: 16px; color: #374151;">${likes}</span>
                        </div>
                        <div style="display: flex; align-items: center; gap: 6px;">
                            <button id="dislike-button-${pinId}" onclick="window.handleDislike('${pinId}')" style="background: none; border: none; cursor: pointer; padding: 0; display: flex; align-items: center;">
                                <svg xmlns="http://www.w3.org/2000/svg" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#374151" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="transform: scaleY(-1);"><path d="M7 10v12"/><path d="M15 5.88 14 10h5.83a2 2 0 0 1 1.92 2.56l-2.33 8A2 2 0 0 1 17.5 22H4a2 2 0 0 1-2-2v-8a2 2 0 0 1 2-2h2.76a2 2 0 0 0 1.79-1.11L12 2h0a3.13 3.13 0 0 1 3 3.88Z"/></svg>
                            </button>
                            <span id="dislike-count-${pinId}" style="font-weight: 700; font-size: 16px; color: #374151;">${dislikes}</span>
                        </div>
                    </div>
                </div>
            </div>
        `;

        const popup = new maplibreglInstance.Popup({ offset: 35, className: 'cmu-popup', closeButton: false, maxWidth: '320px' }).setHTML(popupHTML);
        new maplibreglInstance.Marker({ element: el, anchor: 'bottom' }).setLngLat([data.coordinates.lng, data.coordinates.lat]).setPopup(popup).addTo(mapInstance);
    }

    function handlePinSubmit(e) {
        const formData = e.detail;
        
        // เช็คว่าถ้าเป็น Public ถึงจะปักหมุดลง Map
        if (formData.visibility === 'public') {
            addPinToMap(formData);
            toastMessage = 'Post published on map';
        } else {
            // ถ้าส่งให้ Staff Only ไม่ต้องปักหมุด
            toastMessage = 'Report sent to security staff';
        }

        showDetailForm = false;
        selectedCategory = null;
        showToast = true;
        setTimeout(() => showToast = false, 3000);
    }

    function handleCategorySelect(e) {
        const category = e.detail;
        if (category === 'blocked') {
            modalConfig = BLOCKED_MODAL_CONFIG; 
            isPointOrLineModalOpen = true;
        } 
        else if (category === 'traffic_general') {
            isPointOrLineModalOpen = false; 
            isDrawingLine = true;
            drawingLineCategory = 'traffic_general-line';
            currentLinePoints = [];
            mapInstance.getCanvas().style.cursor = 'crosshair';
            if (mapInstance.getLayer('temp-line-layer')) {
                mapInstance.setPaintProperty('temp-line-layer', 'line-color', '#EF4444');
            }
        } 
        else {
            selectedCategory = category;
        }
    }

    function startLineDrawing() {
        isPointOrLineModalOpen = false;
        isDrawingLine = true;
        drawingLineCategory = 'blocked-line';
        currentLinePoints = [];
        mapInstance.getCanvas().style.cursor = 'crosshair';
        mapInstance.setPaintProperty('temp-line-layer', 'line-color', '#F97316');
    }

    function cancelAll() {
        selectedCategory = null;
        showDetailForm = false;
        isDrawingLine = false;
        currentLinePoints = [];
        lineVertexMarkers.forEach(m => m.remove());
        lineVertexMarkers = [];
        if(mapInstance) {
            mapInstance.getCanvas().style.cursor = '';
            updateTempLine();
        }
    }

    function finishLineDrawing() {
        if (currentLinePoints.length < 2) {
            alert("Please click on the map to draw at least 2 points.");
            return;
        }
        addPermanentLineToMap(currentLinePoints, drawingLineCategory);
        addPinToMap({
             category: drawingLineCategory.includes('traffic') ? 'traffic_general' : 'blocked',
             coordinates: { lng: currentLinePoints[0][0], lat: currentLinePoints[0][1] },
             title: drawingLineCategory.includes('traffic') ? 'Traffic Jam' : 'Road Off / Closed',
             description: drawingLineCategory.includes('traffic') ? 'Heavy traffic reported.' : 'Reported road closure area.',
             reporter: $userStore?.name || 'Anonymous',
             timestamp: new Date().toISOString(),
             likes: 0, dislikes: 0
        });
        toastMessage = 'Route reported successfully';
        showToast = true;
        setTimeout(() => showToast = false, 3000);
        cancelAll();
    }
</script>

<svelte:head>
    <script src="https://unpkg.com/@lottiefiles/lottie-player@latest/dist/lottie-player.js"></script>
</svelte:head>

<div class="relative h-screen w-full font-kanit overflow-hidden bg-white">
    
    {#if showSplash}
        <div class="fixed inset-0 z-[100] flex flex-col items-center justify-center bg-white" out:fade={{ duration: 500 }}>
            <lottie-player src="/loading.json" background="transparent" speed="1" style="width: 450px; height: 450px;" loop autoplay></lottie-player>
            <div class="relative z-10 -mt-10 text-center">
                <h1 class="text-4xl font-bold tracking-wide text-[#8F66FF]">ลูกช้าง Maps</h1>
                <p class="mt-2 text-base font-light tracking-widest text-gray-400">COMMUNITY SAFETY PLATFORM</p>
            </div>
        </div>
    {/if}

    <BaseMap on:load={handleMapLoad} on:click={handleMapClick} />

    {#if !showSplash}
        {#if !selectedCategory && !isDrawingLine}
            <Navbar on:toggleSidebar={() => isFilterSidebarOpen = true} />
        {/if}

        {#if !selectedCategory && !isDrawingLine}
            {#if isMobile}
                <button class="absolute bottom-13 right-4 z-40 bg-[#8F66FF] text-white w-16 h-16 rounded-full shadow-xl text-3xl flex items-center justify-center transition-transform active:scale-95" on:click={() => isMobileCategorySheetOpen = true}>+</button>
            {:else}
                <PinCategoryPanel on:select={(e) => selectedCategory = e.detail} on:sendHelp={() => showSendHelpModal = true} on:showOptions={handleCategorySelect} />
            {/if}
        {/if}

        {#if selectedCategory && !showDetailForm && !isDrawingLine}
            <div class="pointer-events-none absolute top-24 left-0 right-0 z-30 flex justify-center" in:fly={{ y: -20, duration: 300 }}>
                <div class="bg-white px-6 py-3 rounded-full shadow-lg border border-gray-100 flex items-center gap-2">
                    <span class="text-gray-600 font-medium text-sm">Create post:</span>
                    <span class="font-bold text-[#8F66FF] text-sm uppercase">{CATEGORY_DISPLAY_NAMES[selectedCategory]}</span>
                </div>
            </div>
            <div class="pointer-events-none absolute top-1/2 left-1/2 z-10 -translate-x-1/2 -translate-y-full pb-1 drop-shadow-xl">
                <svg width="48" height="48" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M12 0C7.58 0 4 3.58 4 8C4 13.5 12 24 12 24C12 24 20 13.5 20 8C20 3.58 16.42 0 12 0Z" fill="#EF4444"/><circle cx="12" cy="8" r="3.5" fill="white"/></svg>
            </div>
            <div class="absolute bottom-8 left-0 right-0 z-50 flex justify-center gap-4 px-4">
                <button class="btn rounded-full bg-white shadow-lg px-8 text-gray-700 border-gray-200 hover:bg-gray-50 w-32 font-bold" on:click={cancelAll}>Cancel</button>
                <button class="btn rounded-full bg-[#8F66FF] text-white shadow-lg px-8 hover:bg-[#7a52e0] w-32 font-bold border-none" on:click={handleNextStep}>Next</button>
            </div>
        {/if}

        {#if isDrawingLine}
            <div class="pointer-events-none absolute top-24 left-0 right-0 z-30 flex justify-center">
                <div class="bg-white px-6 py-3 rounded-full shadow-lg border border-gray-100">
                    <span class="font-bold {drawingLineCategory.includes('traffic') ? 'text-red-600' : 'text-orange-600'} text-sm">
                        Drawing {drawingLineCategory.includes('traffic') ? 'Traffic Jam' : 'Road Off'} (Tap map to add points)
                    </span>
                </div>
            </div>
            <div class="absolute bottom-8 left-0 right-0 z-50 flex justify-center gap-4 px-4">
                <button class="btn rounded-full bg-white shadow-lg px-8 text-black border-gray-200" on:click={cancelAll}>Cancel</button>
                <button class="btn rounded-full bg-[#8F66FF] text-white shadow-lg px-8 hover:bg-[#7a52e0]" on:click={finishLineDrawing}>Finish</button>
            </div>
        {/if}

        {#if showToast}
            <div class="absolute z-50 top-24 left-0 right-0 flex justify-center pointer-events-none">
                <div class="bg-white px-6 py-3 rounded-full shadow-lg flex items-center gap-2 border border-gray-200 animate-bounce">
                    <span class="font-bold text-green-600">{toastMessage}</span>
                </div>
            </div>
        {/if}

        <button class="absolute z-40 flex items-center justify-center rounded-full bg-white shadow-md hover:bg-gray-100 active:scale-95 {isMobile ? 'h-12 w-12 bottom-32 right-4' : 'h-10 w-10 bottom-38 right-4'}" on:click={findUserLocation} title="Find my location">
            <Crosshair class="w-6 h-6 text-gray-600" />
        </button>

        {#if showDetailForm} <PinDetailForm {isMobile} category={selectedCategory} coordinates={pinCoordinates} on:close={() => showDetailForm=false} on:submit={handlePinSubmit} /> {/if}
        {#if isMobileCategorySheetOpen} <MobileCategorySheet on:close={() => isMobileCategorySheetOpen = false} on:select={(e) => { isMobileCategorySheetOpen=false; selectedCategory=e.detail; }} on:showOptions={handleCategorySelect} /> {/if}
        {#if showSendHelpModal} <SendHelpConfirmModal on:close={() => showSendHelpModal = false} on:confirm={() => { showSendHelpModal=false; alert('Alert Sent!'); }} /> {/if}
        {#if isFilterSidebarOpen} <FilterSidebar bind:filters={filterState} on:close={() => isFilterSidebarOpen = false} /> {/if}
        {#if isPointOrLineModalOpen} <PointOrLineModal on:close={() => isPointOrLineModalOpen = false} on:selectPoint={() => { isPointOrLineModalOpen=false; selectedCategory='blocked'; }} on:selectLine={startLineDrawing} /> {/if}
        
        <img src="/logo.svg" alt="Logo" class="absolute z-30 h-8 bottom-4 left-4" />
    {/if}
</div>

<style>
    :global(.cmu-popup .maplibregl-popup-content) { border-radius: 12px; padding: 8px; box-shadow: 0 4px 12px rgba(0,0,0,0.1); }
    :global(.cmu-popup .maplibregl-popup-tip) { display: none; }
    .font-kanit { font-family: 'Kanit', sans-serif; }
</style>