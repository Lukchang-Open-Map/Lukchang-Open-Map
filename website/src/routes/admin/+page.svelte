<script>
    import { onMount, mount } from 'svelte';
    import { fade, fly } from 'svelte/transition';
    import { userStore } from '$lib/stores/userStore.js';
    
    // Components
    import BaseMap from '$lib/component/map/BaseMap.svelte';
    import Navbar from '$lib/component/layout/Navbar.svelte';
    import CustomMarker from '$lib/component/map/CustomMarker.svelte';
    
    // Admin Components
    import { MessageSquare, Shield, Trash2, Search, ChevronLeft, ThumbsUp, ThumbsDown, CheckCircle, Filter } from 'lucide-svelte';
    
    // User View Components
    import PinCategoryPanel from '$lib/component/map/PinCategoryPanel.svelte';
    import PinDetailForm from '$lib/component/common/PinDetailForm.svelte';
    import MobileCategorySheet from '$lib/component/map/MobileCategorySheet.svelte';
    import SendHelpConfirmModal from '$lib/component/common/SendHelpConfirmModal.svelte';
    import FilterSidebar from '$lib/component/map/FilterSidebar.svelte';
    import PointOrLineModal from '$lib/component/common/PointOrLineModal.svelte';
    import { Crosshair } from 'lucide-svelte';

    // Config & Utils
    import { CATEGORY_STYLES, CATEGORY_DISPLAY_NAMES, BLOCKED_MODAL_CONFIG } from '$lib/constant/map-config.js';
    import { timeAgo } from '$lib/utils/formatting.js';
    import { generateUUID } from '$lib/utils/generators.js';
    import { initializeMapInteractions } from '$lib/utils/map-interactions.js';

    // --- COMMON STATE ---
    let mapInstance;
    let maplibreglInstance;
    let markers = {};
    let securityMarkers = []; // เก็บ Marker ยามแยกต่างหาก
    let isMobile = false;
    let viewMode = 'admin'; // 'admin' | 'user'
    let showNotification = false;
    let notificationMessage = '';

    // --- ADMIN STATE ---
    let posts = []; 
    let activeTab = 'posts';
    let isSidebarOpen = true;
    let selectedPost = null;
    let searchQuery = '';
    let activeFilter = 'All';
    const filters = ['All', 'Accident/Hazard', 'Blocked', 'Flood'];
    const SECURITY_LOCATIONS = [
		{ id: 0, name: 'ทางเข้าวงเวียน', lng: 98.95315768199401, lat: 18.795269111341696 },
		{ id: 1, name: 'สี่แยกสถาปัต', lng: 98.95043693938567, lat: 18.79684741671042 },
		{ id: 2, name: 'ทางเข้าหน้ามอ', lng: 98.95438058092196, lat: 18.80722761195173 },
		{ id: 3, name: 'ทางออกหน้ามอ', lng: 98.95315671360765, lat: 18.80615435722116 },
		{ id: 4, name: 'อ่างแก้ว', lng: 98.95043172833226, lat: 18.805220006467806 },
		{ id: 5, name: 'แมสคอม', lng: 98.94818999196912, lat: 18.80199061126453 },
		{ id: 6, name: 'อ่างตาด', lng: 98.94910352845847, lat: 18.803583664409146 },
		{ id: 7, name: 'อมช', lng: 98.95112492412699, lat: 18.79919173363757 },
		{ id: 9, name: 'สี่แยกสนามกีฬา', lng: 98.95594476882661, lat: 18.796233122362295 },
		{ id: 10, name: 'ศึกษา', lng: 98.95491536596535, lat: 18.79607521853582 },
		{ id: 11, name: 'ศึกษาเขตโรงเรียน', lng: 98.9545069281923, lat: 18.79354796618422 },
		{ id: 12, name: 'ที่จอดรถม่วง', lng: 98.9524127165368, lat: 18.799320534641495 },
		{ id: 13, name: 'ยาม econ', lng: 98.95010644217899, lat: 18.801270245348462 },
		{ id: 14, name: 'ยาม TLIC', lng: 98.95079215005626, lat: 18.799137061806817 },
		{ id: 16, name: 'สามแยกศูนย์กีฬา', lng: 98.95758652571425, lat: 18.798622542172552 },
		{ id: 17, name: 'ประตูไผ่ล้อม', lng: 98.95730726696297, lat: 18.801104176013 },
		{ id: 24, name: 'ศูนย์ไผ่ล้อม', lng: 98.95564704429125, lat: 18.799277269645202 },
		{ id: 28, name: 'ศูนย์รปภกลาง', lng: 98.95511177488146, lat: 18.80381114758015 },
		{ id: 29, name: 'ประตูวิศวะ', lng: 98.95033924794808, lat: 18.79427209698818 },
		{ id: 30, name: 'ห้องสมุด', lng: 98.95172301936992, lat: 18.80109868911734 },
		{ id: 20, name: 'ยามประตูข้างมอ', lng: 98.96096163583366, lat: 18.79565990804005 }
	];


    // --- USER VIEW STATE ---
    let selectedCategory = null;
    let showDetailForm = false;
    let pinCoordinates = null;
    let isMobileCategorySheetOpen = false;
    let showSendHelpModal = false;
    let isFilterSidebarOpen = false;
    let isPointOrLineModalOpen = false;
    let modalConfig = {};
    let isDrawingLine = false;
    let drawingLineCategory = '';
    let currentLinePoints = [];
    let lineVertexMarkers = [];
    let showToast = false;
    let toastMessage = '';
    let filterState = { accident: true, blocked: true, beware: true, flood: true, send_help: true, traffic_general: true, parking: true, events: true, map_chat: true, lost_found: true };


    // --- LOGIC: ADMIN FILTER ---
    $: filteredPosts = posts.filter(post => {
        const matchesSearch = post.title.toLowerCase().includes(searchQuery.toLowerCase()) || 
                              post.description.toLowerCase().includes(searchQuery.toLowerCase());
        const matchesFilter = activeFilter === 'All' || (CATEGORY_DISPLAY_NAMES[post.category] || post.category).includes(activeFilter.split('/')[0]);
        return matchesSearch && matchesFilter;
    });

    onMount(() => {
        initializeMapInteractions();
        isMobile = window.innerWidth < 768;

        // Mock Data
        posts = [
            { 
                id: 'post_001', 
                category: 'accident', 
                title: 'รถเครื่องชนกัน', 
                description: 'เกิดอุบัติเหตุที่หน้ามอ ต้องการความช่วยเหลือ', 
                coordinates: { lng: 98.9545, lat: 18.807 }, 
                reporter: { name: 'Somchai Lertsuk' }, 
                timestamp: new Date(Date.now() - 3600000).toISOString(), 
                likes: 12, dislikes: 2 
            },
            { 
                id: 'post_002', 
                category: 'map_chat', 
                title: 'ใครรู้พิกัดร้านกาแฟดีๆ', 
                description: 'แนะนำร้านกาแฟใกล้ห้องสมุดหน่อยครับ', 
                coordinates: { lng: 98.9517, lat: 18.8011 }, 
                reporter: { name: 'John Doe' }, 
                timestamp: new Date(Date.now() - 10800000).toISOString(), 
                likes: 15, dislikes: 1 
            }
        ];
    });

    function handleMapLoad({ detail }) {
        mapInstance = detail.map;
        maplibreglInstance = detail.maplibregl;

        // Setup Sources for User Drawing
        mapInstance.addSource('temp-line-source', { type: 'geojson', data: { type: 'Feature', geometry: { type: 'LineString', coordinates: [] } } });
        mapInstance.addLayer({ id: 'temp-line-layer', type: 'line', source: 'temp-line-source', paint: { 'line-color': '#F97316', 'line-width': 5, 'line-dasharray': [2, 2] } });

        updateMarkers();
        addSecurityMarkers(); // ✅ เพิ่มฟังก์ชันนี้
    }

    function handleMapClick({ detail: e }) {
        // Only active in User View logic for line drawing
        if (viewMode === 'user') {
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
    }

    // --- SECURITY MARKERS ---
    function addSecurityMarkers() {
        if (!mapInstance) return;
        
        SECURITY_LOCATIONS.forEach(location => {
            const el = document.createElement('div');
            // ใช้ icon ยาม (Security Icon)
            el.innerHTML = `<div class="w-10 h-10 bg-white rounded-full shadow-md flex items-center justify-center border-2 border-purple-200 p-1"><img src="/security.svg" alt="Security" class="w-full h-full object-contain" /></div>`;
            
            const popup = new maplibreglInstance.Popup({ offset: 25, className: 'cmu-popup', closeButton: false }).setHTML(`
                <div class="p-2 font-kanit text-center">
                    <h3 class="font-bold text-[#8F66FF]">${location.name}</h3>
                    <p class="text-xs text-gray-500">On Duty</p>
                </div>
            `);

            const marker = new maplibreglInstance.Marker({ element: el, anchor: 'bottom' })
                .setLngLat([location.lng, location.lat])
                .setPopup(popup)
                .addTo(mapInstance);
            
            securityMarkers.push(marker);
        });
    }

    function flyToSecurity(location) {
        if (mapInstance) mapInstance.flyTo({ center: [location.lng, location.lat], zoom: 17 });
    }

    // --- COMMON MARKER LOGIC ---
    function updateMarkers() {
        if (!mapInstance) return;
        posts.forEach(post => addMarker(post));
    }

    function addMarker(post) {
        if (markers[post.id]) return;
        const el = document.createElement('div');
        mount(CustomMarker, { target: el, props: { category: post.category } });
        
        // Admin & User share same popup style (or can be customized)
        const pinId = post.id;
        const popupHTML = `
            <div style="font-family: 'Kanit', sans-serif; min-width: 200px; padding: 4px;">
                ${post.photoPreviewUrl ? `<div style="width: 100%; height: 120px; background-image: url('${post.photoPreviewUrl}'); background-size: cover; background-position: center; border-radius: 12px; margin-bottom: 8px;"></div>` : ''}
                <h3 style="font-weight: 800; margin-bottom: 4px;">${post.title}</h3>
                <p style="font-size: 13px; color: #6B7280;">${post.description}</p>
                <div style="font-size: 11px; color: #9CA3AF; margin-top: 8px;">Reported by ${post.reporter.name || 'Anonymous'} • ${timeAgo(post.timestamp)}</div>
                <div style="display: flex; gap: 12px; margin-top: 8px; align-items: center;">
                     <div style="display: flex; align-items: center; gap: 4px;"><button onclick="window.handleLike('${pinId}')" style="background:none;border:none;cursor:pointer;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#374151" stroke-width="2"><path d="M7 10v12"/><path d="M15 5.88 14 10h5.83a2 2 0 0 1 1.92 2.56l-2.33 8A2 2 0 0 1 17.5 22H4a2 2 0 0 1-2-2v-8a2 2 0 0 1 2-2h2.76a2 2 0 0 0 1.79-1.11L12 2h0a3.13 3.13 0 0 1 3 3.88Z"/></svg></button><span id="like-count-${pinId}" style="font-weight:700; font-size:14px; color:#374151;">${post.likes}</span></div>
                </div>
            </div>`;
            
        const popup = new maplibreglInstance.Popup({ offset: 35, className: 'cmu-popup', closeButton: false }).setHTML(popupHTML);
        const marker = new maplibreglInstance.Marker({ element: el, anchor: 'bottom' })
            .setLngLat([post.coordinates.lng, post.coordinates.lat])
            .setPopup(popup)
            .addTo(mapInstance);
            
        markers[post.id] = marker;

        el.addEventListener('click', () => {
             selectedPost = post;
             // If Admin, open sidebar. If User, just show popup (default behavior)
             if (viewMode === 'admin') {
                 isSidebarOpen = true;
                 mapInstance.flyTo({ center: [post.coordinates.lng, post.coordinates.lat], zoom: 17 });
             }
        });
    }

    // --- ADMIN FUNCTIONS ---
    function flyToPost(post) {
        if (mapInstance) mapInstance.flyTo({ center: [post.coordinates.lng, post.coordinates.lat], zoom: 18 });
        selectedPost = post;
    }
    
    function deletePost(id) {
        if(markers[id]) { markers[id].remove(); delete markers[id]; }
        posts = posts.filter(p => p.id !== id);
        notificationMessage = 'Post deleted successfully';
        showNotification = true;
        setTimeout(() => showNotification = false, 3000);
    }

    function getCategoryColor(cat) { 
        if(cat === 'accident') return 'text-red-600';
        if(cat === 'blocked') return 'text-orange-600';
        if(cat === 'flood') return 'text-blue-600';
        return 'text-gray-700';
    }

    function getCategoryBg(cat) {
        if(cat === 'accident') return 'bg-red-100';
        if(cat === 'blocked') return 'bg-orange-100';
        if(cat === 'flood') return 'bg-blue-100';
        return 'bg-gray-100';
    }

    // --- USER VIEW FUNCTIONS ---
    function handleNextStep() {
        const center = mapInstance.getCenter();
        pinCoordinates = { lng: center.lng, lat: center.lat };
        showDetailForm = true;
    }

    function handlePinSubmit(e) {
        const formData = e.detail;
        const newPost = {
            id: formData.id,
            category: formData.category,
            title: formData.title,
            description: formData.description,
            coordinates: formData.coordinates,
            reporter: { name: 'Admin' }, // Admin creating post
            timestamp: new Date().toISOString(),
            likes: 0, dislikes: 0,
            photoUrl: formData.photoPreviewUrl
        };

        if (formData.visibility === 'public') {
            posts = [newPost, ...posts]; // Add to admin list
            addMarker(newPost); // Add to map
            toastMessage = 'Post published on map';
        } else {
            toastMessage = 'Report sent to security staff';
        }

        showDetailForm = false;
        selectedCategory = null;
        showToast = true;
        setTimeout(() => showToast = false, 3000);
    }

    function handleCategorySelect(e) {
        const category = e.detail;
        if (category === 'blocked') { modalConfig = BLOCKED_MODAL_CONFIG; isPointOrLineModalOpen = true; } 
        else if (category === 'traffic_general') { isPointOrLineModalOpen = false; isDrawingLine = true; drawingLineCategory = 'traffic_general-line'; currentLinePoints = []; mapInstance.getCanvas().style.cursor = 'crosshair'; if (mapInstance.getLayer('temp-line-layer')) mapInstance.setPaintProperty('temp-line-layer', 'line-color', '#EF4444'); } 
        else { selectedCategory = category; }
    }

    function startLineDrawing() {
        isPointOrLineModalOpen = false; isDrawingLine = true; drawingLineCategory = 'blocked-line'; currentLinePoints = []; mapInstance.getCanvas().style.cursor = 'crosshair'; mapInstance.setPaintProperty('temp-line-layer', 'line-color', '#F97316');
    }

    function cancelAll() {
        selectedCategory = null; showDetailForm = false; isDrawingLine = false; currentLinePoints = []; lineVertexMarkers.forEach(m => m.remove()); lineVertexMarkers = [];
        if(mapInstance) { mapInstance.getCanvas().style.cursor = ''; updateTempLine(); }
    }

    function updateTempLine() {
        mapInstance.getSource('temp-line-source').setData({ type: 'Feature', geometry: { type: 'LineString', coordinates: currentLinePoints } });
    }

    function addPermanentLineToMap(points, category) {
        const lineId = generateUUID();
        const lineColor = category.includes('blocked') ? '#F97316' : '#EF4444';
        mapInstance.addSource(`perm-line-source-${lineId}`, { type: 'geojson', data: { type: 'Feature', geometry: { type: 'LineString', coordinates: points } } });
        mapInstance.addLayer({ id: `perm-line-layer-${lineId}`, type: 'line', source: `perm-line-source-${lineId}`, layout: { 'line-join': 'round', 'line-cap': 'round' }, paint: { 'line-color': lineColor, 'line-width': 6, 'line-opacity': 0.8 } });
    }

    function finishLineDrawing() {
        if (currentLinePoints.length < 2) { alert("Click map to draw points"); return; }
        addPermanentLineToMap(currentLinePoints, drawingLineCategory);
        
        const newPost = {
             id: generateUUID(),
             category: drawingLineCategory.includes('traffic') ? 'traffic_general' : 'blocked',
             coordinates: { lng: currentLinePoints[0][0], lat: currentLinePoints[0][1] },
             title: drawingLineCategory.includes('traffic') ? 'Traffic Jam' : 'Road Off / Closed',
             description: 'Reported line area by Admin',
             reporter: { name: 'Admin' },
             timestamp: new Date().toISOString(),
             likes: 0, dislikes: 0
        };
        posts = [newPost, ...posts];
        addMarker(newPost);

        toastMessage = 'Route reported'; showToast = true; setTimeout(() => showToast = false, 3000); cancelAll();
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

    // Toggle Helper
    function switchView(mode) {
        viewMode = mode;
        cancelAll(); // Clear any pending actions
        if (mode === 'admin') {
            isSidebarOpen = true;
        } else {
            isSidebarOpen = false;
        }
    }
</script>

<div class="relative h-screen w-full flex font-kanit overflow-hidden bg-white">
    
    <!-- ✅ TOGGLE BAR (Left Top) -->
    <div class="absolute top-4 left-4 z-50 bg-white p-1 rounded-xl shadow-md flex items-center gap-1 border border-gray-100">
        <button 
            class="px-4 py-2 rounded-lg text-sm font-bold transition-all {viewMode === 'admin' ? 'bg-[#8F66FF] text-white shadow-sm' : 'text-gray-500 hover:bg-gray-50'}"
            on:click={() => switchView('admin')}
        >
            Admin
        </button>
        <button 
            class="px-4 py-2 rounded-lg text-sm font-bold transition-all {viewMode === 'user' ? 'bg-green-500 text-white shadow-sm' : 'text-gray-500 hover:bg-gray-50'}"
            on:click={() => switchView('user')}
        >
            User View
        </button>
    </div>

    <!-- Sidebar (Admin Only) -->
    {#if viewMode === 'admin'}
        <div class="absolute top-16 bottom-0 left-4 z-[60] w-full bg-white shadow-2xl transition-transform duration-300 md:w-[445px] {isSidebarOpen ? 'translate-x-0' : '-translate-x-[110%]'} rounded-2xl mb-4 overflow-hidden border border-gray-100 flex flex-col">
            
            <div class="flex items-center justify-between px-5 pt-4 pb-2">
                <div class="flex items-center gap-2">
                    <h2 class="text-2xl font-bold text-gray-900">Admin Management</h2>
                    {#if posts.length > 0}
                        <span class="flex h-6 w-6 items-center justify-center rounded-full bg-red-500 text-xs font-bold text-white">{posts.length}</span>
                    {/if}
                </div>
                <button on:click={() => (isSidebarOpen = false)} class="rounded-lg p-1.5 hover:bg-gray-100 md:hidden"><ChevronLeft class="h-5 w-5 text-gray-600" /></button>
            </div>

            <div class="px-5 pb-3">
                <div class="relative">
                    <Search class="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                    <input type="text" placeholder="Search posts, users..." bind:value={searchQuery} class="w-full rounded-xl border border-gray-200 py-2.5 pl-10 pr-4 text-sm focus:outline-none focus:ring-2 focus:ring-[#8F66FF]" />
                </div>
            </div>

            <div class="px-5 pb-4 border-b border-gray-100 overflow-x-auto no-scrollbar">
                <div class="flex gap-2">
                    {#each filters as filter}
                        <button 
                            class="px-4 py-1.5 rounded-full text-xs font-bold whitespace-nowrap border transition-all {activeFilter === filter ? 'bg-[#8F66FF] text-white border-[#8F66FF]' : 'bg-white text-gray-600 border-gray-200 hover:border-[#8F66FF]'}"
                            on:click={() => activeFilter = filter}
                        >
                            {filter}
                        </button>
                    {/each}
                </div>
            </div>

            <div class="flex border-b border-gray-200 bg-white">
                <button on:click={() => activeTab = 'posts'} class="flex-1 px-4 py-3 text-sm font-bold flex items-center justify-center gap-2 transition {activeTab === 'posts' ? 'text-[#8F66FF] border-b-2 border-[#8F66FF]' : 'text-gray-400 hover:text-gray-600'}">
                    <MessageSquare class="w-4 h-4" /> Posts ({filteredPosts.length})
                </button>
                <button on:click={() => activeTab = 'security'} class="flex-1 px-4 py-3 text-sm font-bold flex items-center justify-center gap-2 transition {activeTab === 'security' ? 'text-[#8F66FF] border-b-2 border-[#8F66FF]' : 'text-gray-400 hover:text-gray-600'}">
                    <Shield class="w-4 h-4" /> Security ({SECURITY_LOCATIONS.length})
                </button>
            </div>

            <div class="flex-1 overflow-y-auto p-5 space-y-4 bg-gray-50 custom-scrollbar">
                {#if activeTab === 'posts'}
                    {#each filteredPosts as post}
                        <div class="bg-white border rounded-2xl p-5 transition-all hover:shadow-md cursor-pointer relative overflow-hidden {selectedPost?.id === post.id ? 'border-[#8F66FF] ring-1 ring-purple-100' : 'border-gray-100'}" on:click={() => flyToPost(post)}>
                            <div class="absolute left-0 top-0 bottom-0 w-1 {getCategoryBg(post.category).replace('100', '500')}"></div>
                            <div class="flex items-start gap-3 mb-3 pl-2">
                                <div class="flex h-10 w-10 items-center justify-center rounded-full {getCategoryBg(post.category)} shrink-0">
                                    <svelte:component this={CATEGORY_STYLES[post.category].Icon} class="h-5 w-5 {CATEGORY_STYLES[post.category].text}" />
                                </div>
                                <div class="flex-1 min-w-0">
                                    <div class="flex flex-wrap items-center gap-x-2 mb-0.5">
                                        <span class="text-[10px] font-extrabold uppercase tracking-wide {getCategoryColor(post.category)}">{CATEGORY_DISPLAY_NAMES[post.category]}</span>
                                        <span class="text-[10px] text-gray-400">{timeAgo(post.timestamp)}</span>
                                    </div>
                                    <h3 class="text-base font-bold text-gray-900 leading-tight">{post.title}</h3>
                                </div>
                            </div>
                            <div class="flex gap-3 pl-2">
                                <button class="flex-1 rounded-xl border border-red-200 bg-white py-2.5 text-sm font-bold text-red-500 hover:bg-red-50 transition-colors uppercase tracking-wide" on:click|stopPropagation={() => deletePost(post.id)}>Delete</button>
                                <button class="flex-1 rounded-xl bg-[#8F66FF] py-2.5 text-sm font-bold text-white hover:bg-[#7a52e0] transition-colors uppercase tracking-wide" on:click|stopPropagation={() => flyToPost(post)}>View</button>
                            </div>
                        </div>
                    {/each}
                {:else}
                    {#each SECURITY_LOCATIONS as location}
                         <div class="border rounded-2xl p-4 flex items-center gap-3 hover:bg-white hover:shadow-sm cursor-pointer bg-white border-gray-200" on:click={() => flyToSecurity(location)}>
                            <div class="h-12 w-12 rounded-full bg-blue-50 flex items-center justify-center border border-blue-100">
                                <!-- Security Icon -->
                                <img src="/security.svg" alt="Security" class="w-8 h-8" />
                            </div>
                            <div><h4 class="font-bold text-gray-800">{location.name}</h4><p class="text-xs text-gray-500">Station #{location.id}</p></div>
                         </div>
                    {/each}
                {/if}
            </div>
        </div>
    {/if}

    <!-- Map Area -->
    <div class="flex-1 relative">
        <!-- Admin View Button to reopen sidebar -->
        {#if viewMode === 'admin' && !isSidebarOpen}
            <button class="absolute top-20 left-4 z-30 bg-white p-3 rounded-xl shadow-md" on:click={() => isSidebarOpen = true}><MessageSquare class="text-gray-600" /></button>
        {/if}
        
        <!-- Map -->
        <BaseMap on:load={handleMapLoad} on:click={handleMapClick} />

        <!-- User View UI (Overlays) -->
        {#if viewMode === 'user'}
            {#if !selectedCategory && !isDrawingLine}
                {#if isMobile}
                    <button class="absolute bottom-8 right-4 z-40 bg-[#8F66FF] text-white w-16 h-16 rounded-full shadow-xl text-3xl flex items-center justify-center" on:click={() => isMobileCategorySheetOpen = true}>+</button>
                {:else}
                    <PinCategoryPanel on:select={(e) => selectedCategory = e.detail} on:sendHelp={() => showSendHelpModal = true} on:showOptions={handleCategorySelect} />
                {/if}
                
                <!-- Filter Sidebar Button for User -->
                <button class="absolute top-20 right-4 z-40 flex items-center justify-center rounded-xl bg-white p-3 shadow-md hover:bg-gray-100" on:click={() => isFilterSidebarOpen = true}>
                     <Filter class="w-6 h-6 text-gray-600" />
                </button>
            {/if}

            {#if selectedCategory && !showDetailForm && !isDrawingLine}
                 <div class="absolute top-20 left-0 right-0 z-30 flex justify-center pointer-events-none"><div class="bg-white px-6 py-3 rounded-full shadow-lg border border-gray-100 flex items-center gap-2"><span class="text-gray-600 font-medium text-sm">Create post:</span><span class="font-bold text-[#8F66FF] text-sm uppercase">{CATEGORY_DISPLAY_NAMES[selectedCategory]}</span></div></div>
                 <div class="pointer-events-none absolute top-1/2 left-1/2 z-10 -translate-x-1/2 -translate-y-full pb-1 drop-shadow-xl"><svg width="48" height="48" viewBox="0 0 24 24" fill="none"><path d="M12 0C7.58 0 4 3.58 4 8C4 13.5 12 24 12 24C12 24 20 13.5 20 8C20 3.58 16.42 0 12 0Z" fill="#EF4444"/><circle cx="12" cy="8" r="3.5" fill="white"/></svg></div>
                 <div class="absolute bottom-8 left-0 right-0 z-50 flex justify-center gap-4 px-4"><button class="btn rounded-full bg-white shadow-lg px-8 text-gray-700 font-bold w-32" on:click={cancelAll}>Cancel</button><button class="btn rounded-full bg-[#8F66FF] text-white shadow-lg px-8 w-32 font-bold" on:click={handleNextStep}>Next</button></div>
            {/if}

            {#if isDrawingLine}
                <div class="absolute top-20 left-0 right-0 z-30 flex justify-center pointer-events-none"><div class="bg-white px-6 py-3 rounded-full shadow-lg border border-gray-100"><span class="font-bold text-orange-600 text-sm">Drawing {drawingLineCategory}</span></div></div>
                <div class="absolute bottom-8 left-0 right-0 z-50 flex justify-center gap-4 px-4"><button class="btn rounded-full bg-white shadow-lg px-8 text-black" on:click={cancelAll}>Cancel</button><button class="btn rounded-full bg-[#8F66FF] text-white shadow-lg px-8" on:click={finishLineDrawing}>Finish</button></div>
            {/if}

            <!-- Modals -->
            {#if showDetailForm} <PinDetailForm {isMobile} category={selectedCategory} coordinates={pinCoordinates} on:close={() => showDetailForm=false} on:submit={handlePinSubmit} /> {/if}
            {#if isMobileCategorySheetOpen} <MobileCategorySheet on:close={() => isMobileCategorySheetOpen = false} on:select={(e) => { isMobileCategorySheetOpen=false; selectedCategory=e.detail; }} on:showOptions={handleCategorySelect} /> {/if}
            {#if showSendHelpModal} <SendHelpConfirmModal on:close={() => showSendHelpModal = false} on:confirm={() => { showSendHelpModal=false; alert('Alert Sent!'); }} /> {/if}
            {#if isFilterSidebarOpen} <FilterSidebar bind:filters={filterState} on:close={() => isFilterSidebarOpen = false} /> {/if}
            {#if isPointOrLineModalOpen} <PointOrLineModal on:close={() => isPointOrLineModalOpen = false} on:selectPoint={() => { isPointOrLineModalOpen=false; selectedCategory='blocked'; }} on:selectLine={startLineDrawing} /> {/if}
        {/if}
    </div>

    <!-- Notifications -->
    {#if showNotification}<div class="fixed top-20 left-1/2 -translate-x-1/2 z-50 bg-[#10B981] text-white px-6 py-3 rounded-full shadow-xl flex items-center gap-3 animate-bounce"><CheckCircle class="w-5 h-5" /> <span class="font-bold">{notificationMessage}</span></div>{/if}
    {#if showToast}<div class="absolute z-50 top-20 left-0 right-0 flex justify-center pointer-events-none"><div class="bg-white px-6 py-3 rounded-full shadow-lg flex items-center gap-2 border border-gray-200 animate-bounce"><span class="font-bold text-green-600">{toastMessage}</span></div></div>{/if}
</div>

<style>
    :global(.cmu-popup .maplibregl-popup-content) { border-radius: 16px !important; padding: 0 !important; box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.1); border: none; overflow: hidden; }
    :global(.cmu-popup .maplibregl-popup-tip) { display: none !important; }
    .custom-scrollbar::-webkit-scrollbar { width: 4px; }
    .custom-scrollbar::-webkit-scrollbar-track { background: transparent; }
    .custom-scrollbar::-webkit-scrollbar-thumb { background: #e5e7eb; border-radius: 20px; }
    .no-scrollbar::-webkit-scrollbar { display: none; }
</style>