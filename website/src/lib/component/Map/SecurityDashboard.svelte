<script>
    import { onMount, mount } from 'svelte';
    import { userStore } from '$lib/userStore.js';
    import PinCategoryPanel from './PinCategoryPanel.svelte';
    import FilterSidebar from './FilterSidebar.svelte';
    import PinDetailForm from './PinDetailForm.svelte';
    import CustomMarker from './CustomMarker.svelte';
    import PointOrLineModal from './PointOrLineModal.svelte';
    import MobileCategorySheet from './MobileCategorySheet.svelte';
    import SendHelpConfirmModal from './SendHelpConfirmModal.svelte';
    import {
        Shield, AlertTriangle, Clock, User, CheckCircle, XCircle, 
        Navigation, Bell, ChevronLeft, ChevronDown, Crosshair, Menu,
        TrafficCone, HelpCircle, Droplet, LifeBuoy, CarFront, 
        ParkingSquare, Briefcase, PartyPopper, MessageSquare, X,
        Construction, RouteOff
    } from 'lucide-svelte';

    // ============================================================================
    // SECURITY GUARD CONFIGURATION
    // ============================================================================
    const SECURITY_GUARD = {
        id: 'security_001',
        name: 'Security Guard 1',
        email: 'security@cmu.ac.th',
        role: 'security',
        position: {
            lng: 98.94818999196912,
            lat: 18.80199061126453,
            name: 'Masscom Building'
        }
    };

    // ============================================================================
    // MOCK INCIDENT DATA
    // ============================================================================
    const MOCK_INCIDENTS = [
        {
            id: 'inc_001', category: 'accident', title: 'รถเครื่องชนกันแยกทางฝ่ายคืบจ้าว',
            description: 'มีผู้บาดเจ็บ ต้องการความช่วยเหลือด่วน', reporter: 'Anonymous',
            coordinates: { lng: 98.9485, lat: 18.8025 }, distance: 120,
            timestamp: new Date(Date.now() - 24000).toISOString(), status: 'pending'
        },
        {
            id: 'inc_002', category: 'send_help', title: 'ต้องการความช่วยเหลือ',
            description: 'เจอคนบาดเจ็บที่ลานจอดรถ', reporter: 'Somchai L.',
            coordinates: { lng: 98.9478, lat: 18.8018 }, distance: 180,
            timestamp: new Date(Date.now() - 120000).toISOString(), status: 'pending'
        },
        {
            id: 'inc_003', category: 'blocked', title: 'ต้นไม้ล้ม',
            description: 'ต้นไม้ล้มขวางทาง หน้าคณะวิศวกรรมศาสตร์', reporter: 'Staff User',
            coordinates: { lng: 98.9490, lat: 18.8015 }, distance: 95,
            timestamp: new Date(Date.now() - 300000).toISOString(), status: 'pending'
        },
        {
            id: 'inc_004', category: 'flood', title: 'น้ำท่วมถนน',
            description: 'น้ำท่วมสูงประมาณ 20 ซม.', reporter: 'John Doe',
            coordinates: { lng: 98.9495, lat: 18.8020 }, distance: 150,
            timestamp: new Date(Date.now() - 450000).toISOString(), status: 'pending'
        }
    ];

    // ============================================================================
    // CATEGORY CONFIGURATION
    // ============================================================================
    const categoryDisplayNames = {
        'accident': 'Accident/Hazard', 'blocked': 'Blocked', 'beware': 'Beware', 'flood': 'Flood',
        'send_help': 'Send Help', 'traffic_general': 'Traffic', 'parking': 'Parking',
        'events': 'Events', 'map_chat': 'Map Chat', 'lost_found': 'Lost & Found'
    };

    const categoryStyles = {
        'accident': { Icon: AlertTriangle, bg: 'bg-red-100', text: 'text-red-600' },
        'blocked': { Icon: TrafficCone, bg: 'bg-orange-100', text: 'text-orange-600' },
        'beware': { Icon: HelpCircle, bg: 'bg-gray-200', text: 'text-gray-700' },
        'flood': { Icon: Droplet, bg: 'bg-blue-100', text: 'text-blue-600' },
        'send_help': { Icon: LifeBuoy, bg: 'bg-red-100', text: 'text-red-600' },
        'traffic_general': { Icon: CarFront, bg: 'bg-red-100', text: 'text-red-600' },
        'parking': { Icon: ParkingSquare, bg: 'bg-blue-100', text: 'text-blue-600' },
        'events': { Icon: PartyPopper, bg: 'bg-purple-100', text: 'text-purple-600' },
        'map_chat': { Icon: MessageSquare, bg: 'bg-green-100', text: 'text-green-600' },
        'lost_found': { Icon: Briefcase, bg: 'bg-orange-200', text: 'text-orange-600' }
    };

    // ============================================================================
    // STATE MANAGEMENT
    // ============================================================================
    let map = null;
    let maplibregl = null;
    let isMapLoaded = false;
    let userLocationMarker = null;
    let navigationControl = null;
    let isMobile = false;
    let securityMarker = null;

    // Security mode states
    let incidents = [...MOCK_INCIDENTS];
    let selectedIncident = null;
    let isSidebarOpen = true;
    let showNotification = false;
    let notificationMessage = '';
    let categoryFilter = 'all';
    let viewMode = 'security'; // 'security' or 'user'

    // User mode states (from original user map)
    let isOpen = false;
    let isFilterSidebarOpen = false;
    let selectedCategory = null;
    let showDetailForm = false;
    let pinCoordinates = null;
    let isPointOrLineModalOpen = false;
    let modalConfig = {};
    let isDrawingLine = false;
    let drawingLineCategory = 'blocked-line';
    let currentLinePoints = [];
    let lineVertexMarkers = [];
    let isMobileCategorySheetOpen = false;
    let showSendHelpModal = false;
    let showToast = false;
    let toastMessage = '';
    let toastTimeout;

    let filterState = {
        accident: true, blocked: true, beware: true, flood: true, send_help: true,
        traffic_general: true, parking: true, events: true, map_chat: true, lost_found: true
    };

    $: currentStyle = categoryStyles[selectedCategory] || categoryStyles['accident'];

    // ============================================================================
    // DERIVED STATE
    // ============================================================================
    let filteredIncidents = [];
    $: filteredIncidents = 
        categoryFilter === 'all' 
            ? incidents 
            : incidents.filter(inc => inc.category === categoryFilter);

    let categoryCounts = {};
    $: categoryCounts = 
        Object.keys(categoryDisplayNames).reduce((acc, cat) => {
            acc[cat] = incidents.filter(i => i.category === cat).length;
            return acc;
        }, {});

    // Update map cursor based on view mode and state
    $: if (map && viewMode === 'user') {
        if (selectedCategory && selectedCategory !== 'send_help') {
            map.getCanvas().style.cursor = 'crosshair';
        } else if (!isDrawingLine) {
            map.getCanvas().style.cursor = '';
        }
    } else if (map && viewMode === 'security') {
        map.getCanvas().style.cursor = '';
    }

    // ============================================================================
    // UTILITY FUNCTIONS
    // ============================================================================
    function generateUUID() {
        return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
            const r = Math.random() * 16 | 0;
            const v = c === 'x' ? r : (r & 0x3 | 0x8);
            return v.toString(16);
        });
    }

    function timeAgo(timestamp) {
        const now = new Date();
        const seconds = Math.floor((now - new Date(timestamp)) / 1000);
        
        if (seconds < 60) return `${seconds} sec ago`;
        const minutes = Math.floor(seconds / 60);
        if (minutes < 60) return `${minutes} min ago`;
        const hours = Math.floor(minutes / 60);
        if (hours < 24) return `${hours} hr ago`;
        const days = Math.floor(hours / 24);
        return `${days} day ago`;
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

    function handleLogout() {
        userStore.set(null);
    }

    function showSuccessToast(message) {
        toastMessage = message;
        showToast = true;
        
        if (toastTimeout) {
            clearTimeout(toastTimeout);
        }
        
        toastTimeout = setTimeout(() => {
            showToast = false;
        }, 3000);
    }

    function findUserLocation() {
        if (viewMode === 'security') {
            // Security mode: fly to security guard position
            if (map && securityMarker) {
                map.flyTo({
                    center: [SECURITY_GUARD.position.lng, SECURITY_GUARD.position.lat],
                    zoom: 17,
                    duration: 1500
                });
                securityMarker.togglePopup();
            }
        } else {
            // User mode: use geolocation
            if (!navigator.geolocation) {
                alert('Geolocation is not supported by your browser.');
                return;
            }
            navigator.geolocation.getCurrentPosition(
                (position) => {
                    const { longitude, latitude } = position.coords;
                    if (userLocationMarker) {
                        userLocationMarker.remove();
                    }
                    userLocationMarker = new maplibregl.Marker({ color: '#8F66FF' })
                        .setLngLat([longitude, latitude])
                        .addTo(map);
                    map.flyTo({
                        center: [longitude, latitude],
                        zoom: 16
                    });
                },
                (error) => {
                    console.error('Error getting location:', error.message);
                    alert('Could not get your location. Please ensure you have granted permission.');
                }
            );
        }
    }

    // ============================================================================
    // SECURITY MODE HANDLERS
    // ============================================================================
    async function handleApprove(incidentId) {
        console.log(`MOCK: Approving incident: ${incidentId}`);
        incidents = incidents.filter(inc => inc.id !== incidentId);
        selectedIncident = null;
        showSuccess('Approved');
    }

    async function handleReject(incidentId) {
        console.log(`MOCK: Rejecting incident: ${incidentId}`);
        incidents = incidents.filter(inc => inc.id !== incidentId);
        selectedIncident = null;
        showSuccess('Rejected');
    }

    function showSuccess(action) {
        notificationMessage = action;
        showNotification = true;
        setTimeout(() => {
            showNotification = false;
        }, 3000);
    }

    function flyToIncident(incident) {
        if (map) {
            map.flyTo({
                center: [incident.coordinates.lng, incident.coordinates.lat],
                zoom: 18.5, // Zoom in closer to see incident details
                duration: 1500
            });
        }
        selectedIncident = incident;
    }

    // ============================================================================
    // USER MODE HANDLERS (Pin Creation)
    // ============================================================================
    function cancelPinning() {
        selectedCategory = null;
        isDrawingLine = false;
        currentLinePoints = [];
        
        for (const marker of lineVertexMarkers) {
            marker.remove();
        }
        lineVertexMarkers = [];
        
        if (map) {
            map.getCanvas().style.cursor = '';
            updateLineOnMap('temp-line-source', []);
            map.setPaintProperty('temp-line-layer', 'line-color', '#F97316');
        }
    }

    function goToNextStep() {
        const center = map.getCenter();
        pinCoordinates = center;
        showDetailForm = true;
    }

    function onFormClose() {
        showDetailForm = false;
        selectedCategory = null;
    }

    function handleCategorySelection(category) {
        if (category === 'send_help') {
            showSendHelpModal = true;
            return;
        }
        
        if (category === 'blocked') {
            onShowOptions({ detail: category });
            return;
        }
        
        if (category === 'traffic_general') {
            onShowOptions({ detail: category });
            return;
        }
        
        selectedCategory = category;
    }

    function onShowOptions(event) {
        if (isMobileCategorySheetOpen) {
            isMobileCategorySheetOpen = false;
        }
        
        const category = event.detail;
        
        if (category === 'blocked') {
            modalConfig = {
                type: 'blocked',
                title: 'Report Blocked Path',
                pointOption: { Icon: Construction, title: 'Obstacle', description: 'e.g., Fallen tree (Pin a point)' },
                lineOption: { Icon: RouteOff, title: 'Road Closed', description: 'e.g., Construction (Draw a line)' }
            };
            isPointOrLineModalOpen = true;
        } 
        else if (category === 'traffic_general') {
            isPointOrLineModalOpen = false;
            map.setPaintProperty('temp-line-layer', 'line-color', '#EF4444');
            isDrawingLine = true;
            drawingLineCategory = 'traffic_general-line';
            currentLinePoints = [];
            map.getCanvas().style.cursor = 'crosshair';
        }
    }

    function handleMobileCategorySelect(event) {
        const category = event.detail;
        isMobileCategorySheetOpen = false;
        handleCategorySelection(category);
    }

    function onSelectPoint() {
        isPointOrLineModalOpen = false;
        selectedCategory = modalConfig.type;
    }

    function onSelectLine() {
        isPointOrLineModalOpen = false;
        map.setPaintProperty('temp-line-layer', 'line-color', '#F97316');
        isDrawingLine = true;
        drawingLineCategory = modalConfig.type === 'blocked' ? 'blocked-line' : 'traffic_general-line';
        currentLinePoints = [];
        map.getCanvas().style.cursor = 'crosshair';
    }

    function handleSendHelpConfirm() {
        if (userLocationMarker) {
            const lngLat = userLocationMarker.getLngLat();
            pinCoordinates = { lng: lngLat.lng, lat: lngLat.lat };
        } else {
            const center = map.getCenter();
            pinCoordinates = { lng: center.lng, lat: center.lat };
        }
        
        showSuccessToast('Security Alerted');
        showSendHelpModal = false;
    }

    function handleSendHelpClose() {
        showSendHelpModal = false;
    }

    async function onFormSubmit(event) {
        const formData = event.detail;
        
        console.log('MOCK: Sending to backend...', formData);
        
        await new Promise(resolve => setTimeout(resolve, 500));
        
        if (formData.visibility === 'public') {
            addPinToMap(formData);
            showSuccessToast(categoryDisplayNames[formData.category]);
        } else {
            showSuccessToast('Report sent to staff');
        }
        
        onFormClose();
    }

    function updateLineOnMap(sourceId, points) {
        if (!map) return;
        const source = map.getSource(sourceId);
        if (source) {
            source.setData({
                type: 'Feature',
                geometry: {
                    type: 'LineString',
                    coordinates: points
                }
            });
        }
    }

    function addPermanentLineToMap(points, lineCategory) {
        const lineId = generateUUID();
        const color = lineCategory === 'blocked-line' ? '#F97316' : '#EF4444';
        const layerId = `perm-line-layer-${lineId}`;
        const sourceId = `perm-line-source-${lineId}`;
        
        map.addSource(sourceId, {
            'type': 'geojson',
            'data': {
                'type': 'Feature',
                'geometry': {
                    'type': 'LineString',
                    'coordinates': points
                }
            }
        });
        map.addLayer({
            'id': layerId,
            'type': 'line',
            'source': sourceId,
            'layout': { 'line-join': 'round', 'line-cap': 'round' },
            'paint': {
                'line-color': color,
                'line-width': 5,
                'line-dasharray': [2, 2]
            }
        });
    }

    function submitLineDrawing() {
        if (currentLinePoints.length < 2) {
            cancelPinning();
            return;
        }
        
        const lineData = {
            id: generateUUID(),
            category: drawingLineCategory,
            coordinates: currentLinePoints,
            timestamp: new Date().toISOString(),
            reporter: $userStore?.name || 'anonymous',
            likes: 0
        };
        
        console.log(`MOCK: Submitting ${drawingLineCategory} to backend:`, lineData);
        
        const lineCategory = drawingLineCategory.replace('-line', '');
        const startCoordinates = { lng: currentLinePoints[0][0], lat: currentLinePoints[0][1] };
        
        const mockPinData = {
            id: lineData.id,
            category: lineCategory,
            coordinates: startCoordinates,
            title: (lineCategory === 'blocked' ? 'Road Closed' : 'Traffic Jam'),
            description: 'Reported as a line.',
            reporter: lineData.reporter,
            timestamp: lineData.timestamp,
            likes: lineData.likes,
            dislikes: 0,
            visibility: 'public'
        };
        addPinToMap(mockPinData);
        addPermanentLineToMap(currentLinePoints, drawingLineCategory);
        
        const categoryName = lineCategory === 'blocked' ? 'Road Closed' : 'Traffic Jam';
        showSuccessToast(categoryName);
        
        cancelPinning();
    }

    // ============================================================================
    // MAP PIN RENDERING
    // ============================================================================
    function addPinToMap(formData) {
        const el = document.createElement('div');
        
        mount(CustomMarker, {
            target: el,
            props: { category: formData.category }
        });
        
        const pinId = formData.id;
        let popupHTML = '';
        
        if (formData.category === 'map_chat') {
            const firstCommentHTML = `
                <div class="text-sm">
                    <strong>${formData.reporter}:</strong>
                    <p class="ml-2">${formData.description || '...'}</p>
                </div>
            `;
            
            popupHTML = `
                <div class="p-1" style="min-width: 240px; font-family: Inter, sans-serif;">
                    <h3 class="font-bold text-lg">${formData.title || 'Map Chat'}</h3>
                    <hr class="my-2">
                    
                    <div id="comments-list-${pinId}" class="mt-2 pt-2 max-h-32 overflow-y-auto flex flex-col gap-1">
                        ${firstCommentHTML}
                    </div>
                    
                    <hr class="my-2">
                    <div class="mt-2 pt-2">
                        <div class="flex gap-2">
                            <input 
                                type="text" 
                                id="comment-input-${pinId}" 
                                placeholder="Add a comment..." 
                                class="input input-bordered input-sm w-full" 
                            />
                            <button 
                                class="btn btn-primary btn-sm bg-[#8F66FF] border-[#8F66FF]" 
                                onclick="window.handleComment('${pinId}')"
                            >
                                Send
                            </button>
                        </div>
                    </div>
                </div>
            `;
        } 
        else {
            popupHTML = `
                <div class="p-1" style="min-width: 220px; font-family: Inter, sans-serif;">
                    <h3 class="font-bold text-lg">${formData.title || 'No Title'}</h3>
                    ${formData.photoPreviewUrl ? 
                        `<img src="${formData.photoPreviewUrl}" alt="Pin image" class="w-full h-32 object-cover rounded-md my-2"/>` : 
                        '' 
                    }
                    <p>${formData.description || ''}</p>
                    <div class="mt-2 flex justify-between items-center">
                        <div class="text-xs text-gray-500">
                            <span>report by ${formData.reporter}</span>
                            <br>
                            <span>${timeAgo(formData.timestamp)}</span>
                        </div>
                        <div class="flex items-center gap-3">
                            <div class="flex items-center gap-1">
                                <button 
                                    class="p-2 rounded-full hover:bg-green-50 transition-colors"
                                    id="like-button-${pinId}"
                                    onclick="window.handleLike('${pinId}')" 
                                    title="Like"
                                >
                                    <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="text-gray-600">
                                        <path d="M7 10v12"/>
                                        <path d="M15 5.88 14 10h5.83a2 2 0 0 1 1.92 2.56l-2.33 8A2 2 0 0 1 17.5 22H4a2 2 0 0 1-2-2v-8a2 2 0 0 1 2-2h2.76a2 2 0 0 0 1.79-1.11L12 2h0a3.13 3.13 0 0 1 3 3.88Z"/>
                                    </svg>
                                </button>
                                <span class="text-sm font-semibold text-gray-700" id="like-count-${pinId}">${formData.likes}</span>
                            </div>
                            
                            <div class="flex items-center gap-1">
                                <button 
                                    class="p-2 rounded-full hover:bg-red-50 transition-colors"
                                    id="dislike-button-${pinId}"
                                    onclick="window.handleDislike('${pinId}')" 
                                    title="Dislike"
                                >
                                    <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="text-gray-600">
                                        <path d="M17 14V2"/>
                                        <path d="M9 18.12 10 14H4.17a2 2 0 0 1-1.92-2.56l2.33-8A2 2 0 0 1 6.5 2H20a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2h-2.76a2 2 0 0 0-1.79 1.11L12 22h0a3.13 3.13 0 0 1-3-3.88Z"/>
                                    </svg>
                                </button>
                                <span class="text-sm font-semibold text-gray-700" id="dislike-count-${pinId}">${formData.dislikes || 0}</span>
                            </div>
                        </div>
                    </div>
                </div>
            `;
        }
        
        const popup = new maplibregl.Popup({
            offset: 25,
            closeButton: false,
            className: 'cmu-popup'
        }).setHTML(popupHTML);
        
        new maplibregl.Marker({
            element: el,
            anchor: 'bottom'
        })
        .setLngLat([formData.coordinates.lng, formData.coordinates.lat])
        .setPopup(popup)
        .addTo(map);
    }

    function addIncidentMarker(incident) {
        if (!map || !maplibregl) return;

        const el = document.createElement('div');
        
        mount(CustomMarker, {
            target: el,
            props: { category: incident.category }
        });

        const popup = new maplibregl.Popup({ 
            offset: 25, 
            closeButton: false,
            className: 'cmu-popup'
        }).setHTML(`
            <div style="font-family: 'Kanit', sans-serif; padding: 12px; min-width: 250px;">
                <h3 style="font-weight: 600; margin: 0 0 8px 0; font-size: 16px; color: #1F2937;">${incident.title}</h3>
                <p style="margin: 0 0 8px 0; font-size: 14px; color: #6B7280;">${incident.description}</p>
                <div style="padding-top: 8px; border-top: 1px solid #E5E7EB; font-size: 12px; color: #9CA3AF;">
                    <div style="margin-bottom: 4px;">report by ${incident.reporter}</div>
                    <div>${timeAgo(incident.timestamp)}</div>
                </div>
            </div>
        `);

        const marker = new maplibregl.Marker({ 
            element: el, 
            anchor: 'bottom' 
        })
        .setLngLat([incident.coordinates.lng, incident.coordinates.lat])
        .setPopup(popup)
        .addTo(map);

        if (viewMode === 'security') {
            el.addEventListener('click', () => {
                selectedIncident = incident;
                isSidebarOpen = true;
            });
        }
    }

    // ============================================================================
    // MAP INITIALIZATION
    // ============================================================================
    onMount(async () => {
        isMobile = window.innerWidth < 768;
        
        maplibregl = (await import('maplibre-gl')).default;

        map = new maplibregl.Map({
            container: 'security-map',
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
            center: [SECURITY_GUARD.position.lng, SECURITY_GUARD.position.lat],
            zoom: 16,
            minZoom: 14,
            maxZoom: 18,
            maxBounds: [[98.93, 18.78], [98.97, 18.82]]
        });

        navigationControl = new maplibregl.NavigationControl();
        if (!isMobile) {
            map.addControl(navigationControl, 'bottom-right');
        }

        window.addEventListener('resize', () => {
            const wasMobile = isMobile;
            isMobile = window.innerWidth < 768;
            
            if (wasMobile !== isMobile && navigationControl) {
                if (isMobile) {
                    try { map.removeControl(navigationControl); } catch (e) {}
                } else {
                    map.addControl(navigationControl, 'bottom-right');
                }
            }
        });

        // Security guard marker
        const securityEl = document.createElement('div');
        securityEl.innerHTML = `<img src="/security.svg" alt="Security" style="width: 60px; height: 60px;" />`;
        securityEl.style.cssText = `
            cursor: pointer;
            filter: drop-shadow(0 2px 4px rgba(0,0,0,0.3));
        `;

        securityMarker = new maplibregl.Marker({ element: securityEl, anchor: 'center' })
            .setLngLat([SECURITY_GUARD.position.lng, SECURITY_GUARD.position.lat])
            .setPopup(
                new maplibregl.Popup({ offset: 25, closeButton: false, className: 'cmu-popup' }).setHTML(`
                    <div class="p-1" style="min-width: 220px; font-family: 'Kanit', sans-serif;">
                        <h3 class="font-bold text-lg text-blue-600 flex items-center gap-2">
                            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>
                            </svg>
                            Security Guard
                        </h3>
                        <p class="text-sm text-gray-600 mt-1">${SECURITY_GUARD.position.name}</p>
                        <div class="mt-2 pt-2 border-t border-gray-200 text-xs text-gray-500">
                            Status: <span class="text-green-600 font-semibold">On Duty</span>
                        </div>
                    </div>
                `)
            )
            .addTo(map);

        // Like/Dislike handlers
        window.handleLike = (pinId) => {
            console.log(`MOCK: Liking pin ${pinId}!`);
            
            const countElement = document.getElementById(`like-count-${pinId}`);
            const buttonElement = document.getElementById(`like-button-${pinId}`);
            
            if (countElement && buttonElement) {
                let currentLikes = parseInt(countElement.innerText, 10);
                currentLikes++;
                countElement.innerText = currentLikes;
                
                const svg = buttonElement.querySelector('svg');
                if (svg) {
                    svg.style.fill = '#22c55e';
                    svg.style.stroke = '#22c55e';
                }
                buttonElement.style.backgroundColor = '#dcfce7';
                buttonElement.disabled = true;
                buttonElement.style.cursor = 'not-allowed';
            }
        }
        
        window.handleDislike = (pinId) => {
            console.log(`MOCK: Disliking pin ${pinId}!`);
            
            const countElement = document.getElementById(`dislike-count-${pinId}`);
            const buttonElement = document.getElementById(`dislike-button-${pinId}`);
            
            if (countElement && buttonElement) {
                let currentDislikes = parseInt(countElement.innerText, 10);
                currentDislikes++;
                countElement.innerText = currentDislikes;
                
                const svg = buttonElement.querySelector('svg');
                if (svg) {
                    svg.style.fill = '#ef4444';
                    svg.style.stroke = '#ef4444';
                }
                buttonElement.style.backgroundColor = '#fee2e2';
                buttonElement.disabled = true;
                buttonElement.style.cursor = 'not-allowed';
            }
        }

        // Comment handler
        window.handleComment = (pinId) => {
            const inputElement = document.getElementById(`comment-input-${pinId}`);
            const listElement = document.getElementById(`comments-list-${pinId}`);
            const commentText = inputElement.value;
            
            if (!commentText || !listElement) return;
            
            const userName = $userStore?.name || 'User';
            
            const newComment = document.createElement('div');
            newComment.className = 'text-sm';
            
            const safeText = commentText.replace(/</g, "&lt;").replace(/>/g, "&gt;");
            
            newComment.innerHTML = `<strong>${userName}:</strong> ${safeText}`;
            
            listElement.appendChild(newComment);
            
            inputElement.value = '';
            listElement.scrollTop = listElement.scrollHeight;
            
            console.log(`MOCK: Adding comment to pin ${pinId}: ${commentText}`);
        };

        map.on('load', () => {
            isMapLoaded = true;
            
            // Add temp line source for user mode
            map.addSource('temp-line-source', {
                'type': 'geojson',
                'data': {
                    'type': 'Feature',
                    'geometry': {
                        'type': 'LineString',
                        'coordinates': []
                    }
                }
            });
            map.addLayer({
                'id': 'temp-line-layer',
                'type': 'line',
                'source': 'temp-line-source',
                'layout': { 'line-join': 'round', 'line-cap': 'round' },
                'paint': {
                    'line-color': '#F97316',
                    'line-width': 5,
                    'line-dasharray': [2, 2]
                }
            });
            
            // Handle map clicks for line drawing in user mode
            map.on('click', (e) => {
                if (viewMode !== 'user' || !isDrawingLine) return;
                
                const newPoint = e.lngLat.toArray();
                currentLinePoints.push(newPoint);
                updateLineOnMap('temp-line-source', currentLinePoints);
                
                const vertexEl = document.createElement('div');
                vertexEl.className = 'w-3 h-3 bg-white rounded-full border-2 border-orange-500 shadow-md';
                const vertexMarker = new maplibregl.Marker({ element: vertexEl, anchor: 'center' })
                    .setLngLat(newPoint)
                    .addTo(map);
                
                lineVertexMarkers.push(vertexMarker);
            });
            
            // Load incident markers
            MOCK_INCIDENTS.forEach(incident => {
                addIncidentMarker(incident);
            });
        });

        return () => {
            if (map) map.remove();
        };
    });
</script>

<!-- ============================================================================
     TEMPLATE
     ============================================================================ -->
<div class="h-screen w-full relative overflow-hidden font-kanit">
    <!-- Map Container -->
    <div id="security-map" class="absolute inset-0 w-full h-full"></div>

    <!-- Loading State -->
    {#if !isMapLoaded}
        <div class="absolute inset-0 flex items-center justify-center bg-white z-50">
            <div class="flex flex-col items-center gap-3">
                <span class="loading loading-spinner loading-lg text-[#8F66FF]"></span>
                <p class="text-gray-600">Loading Map...</p>
            </div>
        </div>
    {/if}

    <!-- Top Navigation Bar -->
    <nav class="absolute top-0 right-0 left-0 z-40 flex items-center justify-between safe-top">
        <!-- Left: Menu/Sidebar Toggle -->
        <button
            class="flex items-center justify-center rounded-[12px] bg-white p-3 shadow-md hover:bg-gray-100"
            on:click={() => {
                if (viewMode === 'security') {
                    isSidebarOpen = !isSidebarOpen;
                } else {
                    isFilterSidebarOpen = true;
                }
            }}
        >
            <Menu class="h-6 w-6" />
        </button>

        <!-- Center: View Mode Toggle -->
        <div class="absolute left-1/2 -translate-x-1/2 flex items-center gap-2 bg-white rounded-[12px] shadow-md p-1">
            <button
                on:click={() => {
                    viewMode = 'security';
                    // Reset user mode states
                    cancelPinning();
                    selectedCategory = null;
                    showDetailForm = false;
                    isFilterSidebarOpen = false;
                    isMobileCategorySheetOpen = false;
                }}
                class="px-3 py-2 rounded-lg text-sm font-medium transition-all {viewMode === 'security' ? 'bg-blue-600 text-white' : 'text-gray-600 hover:bg-gray-100'}"
            >
                Security
            </button>
            <button
                on:click={() => {
                    viewMode = 'user';
                    // Reset security mode states
                    isSidebarOpen = false;
                    selectedIncident = null;
                }}
                class="px-3 py-2 rounded-lg text-sm font-medium transition-all {viewMode === 'user' ? 'bg-[#8F66FF] text-white' : 'text-gray-600 hover:bg-gray-100'}"
            >
                User View
            </button>
        </div>

        <!-- Right: User Profile Dropdown -->
        <div class="relative" use:clickOutside on:clickoutside={() => (isOpen = false)}>
            {#if $userStore}
                <button
                    on:click={() => (isOpen = !isOpen)}
                    class="flex items-center gap-2 rounded-[12px] bg-white p-3 pr-2 shadow-md hover:bg-gray-100"
                >
                    <div class="flex h-6 w-6 items-center justify-center rounded-full bg-gray-200">
                        <User class="h-4 w-4" />
                    </div>
                    <span class="hidden font-medium sm:block">{$userStore?.name ?? 'Security'}</span>
                    {#if $userStore?.role}
                        <span class="hidden rounded-full bg-[#EBE0F3] px-2 py-0.5 text-xs font-bold text-[#8F66FF] sm:block">
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
                            <div class="font-bold">{$userStore?.name ?? 'Security'}</div>
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
            {/if}
        </div>
    </nav>

    <!-- ========================================================================
         SECURITY MODE UI
         ======================================================================== -->
    {#if viewMode === 'security'}
        <!-- Incoming Alerts Sidebar -->
        <div
            class="absolute left-0 top-0 bottom-0 z-50 w-full sm:w-[450px] bg-white shadow-2xl transition-transform duration-300 {isSidebarOpen ? 'translate-x-0' : '-translate-x-full'}"
        >
            <!-- Sidebar Header -->
            <div class="flex items-center justify-between p-4 border-b border-gray-200">
                <div class="flex items-center gap-2">
                    <h2 class="text-xl font-bold text-gray-800">Incoming Alerts</h2>
                    {#if incidents.length > 0}
                        <span class="px-2 py-0.5 bg-red-500 text-white rounded-full text-xs font-bold">
                            {incidents.length}
                        </span>
                    {/if}
                </div>
                <button
                    on:click={() => (isSidebarOpen = false)}
                    class="p-2 hover:bg-gray-100 rounded-lg transition-colors"
                >
                    <ChevronLeft class="w-5 h-5 text-gray-600" />
                </button>
            </div>

            <!-- Category Filters -->
            <div class="p-4 border-b border-gray-200 bg-gray-50 overflow-x-auto">
                <div class="flex gap-2 flex-nowrap min-w-max">
                    <button
                        on:click={() => (categoryFilter = 'all')}
                        class="px-3 py-1.5 text-xs rounded-full font-medium transition-all whitespace-nowrap {categoryFilter === 'all' ? 'bg-[#8F66FF] text-white shadow-md' : 'bg-white text-gray-600 hover:bg-gray-100 border border-gray-300'}"
                    >
                        All ({incidents.length})
                    </button>
                    {#each Object.entries(categoryDisplayNames) as [cat, displayName]}
                        {#if categoryCounts[cat] > 0}
                            <button
                                on:click={() => (categoryFilter = cat)}
                                class="px-3 py-1.5 text-xs rounded-full font-medium transition-all whitespace-nowrap flex items-center gap-1 {categoryFilter === cat ? 'bg-[#8F66FF] text-white shadow-md' : 'bg-white text-gray-600 hover:bg-gray-100 border border-gray-300'}"
                            >
                                <svelte:component this={categoryStyles[cat].Icon} class="w-3 h-3" />
                                {displayName} ({categoryCounts[cat]})
                            </button>
                        {/if}
                    {/each}
                </div>
            </div>

            <!-- Incident List -->
            <div class="flex-1 overflow-y-auto p-4 space-y-3 h-[calc(100vh-200px)]">
                {#if filteredIncidents.length === 0}
                    <div class="text-center py-12">
                        <Shield class="w-16 h-16 mx-auto mb-3 text-gray-300" />
                        <p class="text-gray-400">No pending incidents</p>
                    </div>
                {:else}
                    {#each filteredIncidents as incident (incident.id)}
                        <div
                            on:click={() => flyToIncident(incident)}
                            class="p-4 bg-white border-2 rounded-xl cursor-pointer transition-all hover:shadow-lg {selectedIncident?.id === incident.id ? 'border-blue-500 bg-blue-50' : 'border-gray-200 hover:border-blue-300'}"
                        >
                            <div class="flex items-start gap-3 mb-3">
                                <div class="w-10 h-10 rounded-full flex items-center justify-center flex-shrink-0 {categoryStyles[incident.category]?.bg || 'bg-gray-100'}">
                                    <svelte:component this={categoryStyles[incident.category]?.Icon || HelpCircle} class="w-5 h-5 {categoryStyles[incident.category]?.text || 'text-gray-600'}" />
                                </div>
                                <div class="flex-1">
                                    <div class="flex items-center gap-2 mb-1">
                                        <span class="px-2 py-0.5 text-xs font-bold rounded-full {categoryStyles[incident.category]?.bg || 'bg-gray-100'} {categoryStyles[incident.category]?.text || 'text-gray-700'} uppercase">
                                            {categoryDisplayNames[incident.category] || incident.category}
                                        </span>
                                        <span class="text-xs text-gray-500">
                                            {new Date(incident.timestamp).toLocaleString('th-TH', { 
                                                day: '2-digit', 
                                                month: '2-digit', 
                                                year: 'numeric',
                                                hour: '2-digit',
                                                minute: '2-digit'
                                            })}
                                        </span>
                                    </div>
                                    <h3 class="font-bold text-gray-800 mb-1">
                                        {incident.title}
                                    </h3>
                                    <p class="text-sm text-gray-600 mb-2">
                                        {incident.description}
                                    </p>
                                </div>
                            </div>

                            <div class="flex items-center justify-between text-xs text-gray-500 mb-3">
                                <span>Reported by {incident.reporter}</span>
                                <span>{timeAgo(incident.timestamp)}</span>
                            </div>

                            <div class="flex gap-2">
                                <button
                                    on:click={(e) => { e.stopPropagation(); handleReject(incident.id); }}
                                    class="flex-1 px-4 py-2 bg-white hover:bg-red-50 text-red-600 border-2 border-red-200 rounded-lg font-medium transition-colors"
                                >
                                    reject
                                </button>
                                <button
                                    on:click={(e) => { e.stopPropagation(); handleApprove(incident.id); }}
                                    class="flex-1 px-4 py-2 bg-[#8F66FF] hover:bg-[#7a52e0] text-white rounded-lg font-medium transition-colors"
                                >
                                    approve
                                </button>
                            </div>
                        </div>
                    {/each}
                {/if}
            </div>
        </div>

        <!-- Success Notification -->
        {#if showNotification}
            <div class="fixed top-20 left-1/2 -translate-x-1/2 z-50 bg-green-600 text-white px-6 py-3 rounded-full shadow-2xl flex items-center gap-3 animate-bounce">
                <CheckCircle class="w-5 h-5" />
                <span class="font-medium">Incident {notificationMessage}!</span>
            </div>
        {/if}
    {/if}

    <!-- ========================================================================
         USER MODE UI (Same as regular user map)
         ======================================================================== -->
    {#if viewMode === 'user'}
        {#if !selectedCategory && !isDrawingLine}
            
            {#if isFilterSidebarOpen}
                <FilterSidebar
                    bind:filters={filterState}
                    on:close={() => isFilterSidebarOpen = false}
                />
            {/if}
            
            {#if !isMobile}
                <PinCategoryPanel
                    bind:selectedCategory
                    on:showOptions={onShowOptions}
                    on:sendHelp={() => {
                        selectedCategory = null;
                        showSendHelpModal = true;
                    }}
                />
            {/if}
            
            {#if isMobile}
                <button
                    class="fixed z-50 flex h-16 w-16 items-center justify-center rounded-full
                           bg-[#8F66FF] text-white text-4xl shadow-xl transition-all duration-150
                           hover:bg-[#7a52e0] active:scale-95 safe-bottom-right"
                    on:click={() => isMobileCategorySheetOpen = true}
                    title="Add Pin"
                >
                    +
                </button>
            {/if}
        {/if}
        
        {#if isMobileCategorySheetOpen}
            <MobileCategorySheet
                on:close={() => isMobileCategorySheetOpen = false}
                on:select={handleMobileCategorySelect}
                on:showOptions={onShowOptions}
            />
        {/if}
        
        {#if isPointOrLineModalOpen}
            <PointOrLineModal
                on:close={() => isPointOrLineModalOpen = false}
                on:selectPoint={onSelectPoint}
                on:selectLine={onSelectLine}
                bind:title={modalConfig.title}
                bind:pointOption={modalConfig.pointOption}
                bind:lineOption={modalConfig.lineOption}
            />
        {/if}
        
        {#if showSendHelpModal}
            <SendHelpConfirmModal
                on:confirm={handleSendHelpConfirm}
                on:close={handleSendHelpClose}
            />
        {/if}
        
        {#if selectedCategory && !showDetailForm}
            <div class="absolute top-1/2 left-1/2 z-10 -translate-x-1/2 -translate-y-1/2 pointer-events-none">
                <svg class="h-12 w-12 drop-shadow-lg" viewBox="0 0 24 24" fill="#FF494C">
                    <path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5S10.62 6.5 12 6.5s2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z"/>
                    <circle cx="12" cy="8.5" r="2.5" fill="white"/>
                </svg>
            </div>
            
            <div class="absolute top-4 left-4 right-4 z-30 flex justify-center safe-horizontal-banner pointer-events-none">
                <div class="flex items-center gap-2 bg-white rounded-full px-4 py-2 shadow-md">
                    <span class="font-medium">Create post:</span>
                    <span class="font-bold {currentStyle.text}">
                        {categoryDisplayNames[selectedCategory] || selectedCategory}
                    </span>
                </div>
            </div>
            
            <div class="absolute z-[100] flex justify-center gap-3 safe-bottom">
                <button
                    on:click={cancelPinning}
                    class="btn btn-clickable rounded-full bg-white text-black shadow-md {isMobile ? 'flex-1 max-w-[45%]' : 'w-48'}"
                >
                    Cancel
                </button>
                <button
                    on:click={goToNextStep}
                    class="btn btn-clickable rounded-full bg-[#8F66FF] text-white shadow-md {isMobile ? 'flex-1 max-w-[45%]' : 'w-48'}"
                >
                    Next
                </button>
            </div>
        {/if}
        
        {#if isDrawingLine}
            <div class="absolute top-4 left-4 right-4 z-30 flex justify-center safe-horizontal-banner pointer-events-none">
                <div class="flex items-center justify-between gap-3 bg-white rounded-full px-4 py-2 shadow-md w-full max-w-md">
                    {#if drawingLineCategory === 'blocked-line'}
                        <span class="font-medium text-gray-800">Drawing Road Closure...</span>
                        <span class="font-bold text-orange-600 text-sm whitespace-nowrap">(Click to add points)</span>
                    {:else}
                        <span class="font-medium text-gray-800">Drawing Traffic Jam...</span>
                        <span class="font-bold text-red-600 text-sm whitespace-nowrap">(Click to add points)</span>
                    {/if}
                </div>
            </div>
            
            <div class="absolute z-[100] flex justify-center gap-3 safe-bottom">
                <button
                    on:click={cancelPinning}
                    class="btn btn-clickable rounded-full bg-white text-black shadow-md {isMobile ? 'flex-1 max-w-[45%]' : 'w-48'}"
                >
                    Cancel
                </button>
                <button
                    on:click={submitLineDrawing}
                    class="btn btn-clickable rounded-full bg-[#8F66FF] text-white shadow-md {isMobile ? 'flex-1 max-w-[45%]' : 'w-48'}"
                >
                    Finish Drawing
                </button>
            </div>
        {/if}
        
        {#if showDetailForm}
            <PinDetailForm
                {isMobile}
                category={selectedCategory}
                coordinates={pinCoordinates}
                {categoryDisplayNames}
                on:close={onFormClose}
                on:submit={onFormSubmit}
            />
        {/if}
        
        {#if showToast}
            <div class="absolute z-50 flex justify-center safe-toast">
                <div class="bg-white px-4 py-2 rounded-full shadow-lg flex items-center gap-2 animate-slide-down border border-gray-200">
                    <span class="font-medium text-gray-700">Post success:</span>
                    <span class="font-bold text-green-600">{toastMessage}</span>
                </div>
            </div>
        {/if}
    {/if}

    <!-- Crosshair Button (Both modes) -->
    <button
        class="absolute z-40 flex items-center justify-center rounded-full
               bg-white shadow-md transition-all duration-150 hover:bg-gray-100 active:scale-95
               {isMobile 
            ? 'h-9 w-9 safe-top-right-crosshair'
            : 'h-10 w-10 bottom-38 right-2' 
        }"
        on:click={findUserLocation}
        title="Find my location"
    >
        <Crosshair class="{isMobile ? 'h-7 w-7' : 'h-6 w-6'}" />
    </button>

    <!-- Logo (Both modes) -->
    <img src="/logo.svg" alt="Logo" class="absolute z-30 h-8 safe-bottom-left" />
</div>

<style>
    .font-kanit {
        font-family: 'Kanit', sans-serif;
    }

    /* Safe area spacing */
    .safe-top {
        padding-top: max(1rem, env(safe-area-inset-top));
        padding-left: max(1rem, env(safe-area-inset-left));
        padding-right: max(1rem, env(safe-area-inset-right));
    }

    .safe-bottom {
        bottom: max(1.5rem, calc(1.5rem + env(safe-area-inset-bottom)));
        left: 0;
        right: 0;
        padding-left: max(1rem, env(safe-area-inset-left));
        padding-right: max(1rem, env(safe-area-inset-right));
    }

    .btn-clickable {
        pointer-events: auto !important;
        touch-action: manipulation !important;
        -webkit-tap-highlight-color: rgba(0, 0, 0, 0.1);
        user-select: none;
        cursor: pointer;
        position: relative;
        z-index: 1;
    }

    .btn-clickable:active {
        transform: scale(0.98);
    }

    .safe-bottom-right {
        bottom: max(3rem, calc(3rem + env(safe-area-inset-bottom)));
        right: max(1rem, env(safe-area-inset-right));
    }

    .safe-bottom-left {
        bottom: max(1rem, env(safe-area-inset-bottom));
        left: max(1rem, env(safe-area-inset-left));
    }

    .safe-top-right-crosshair {
        bottom: max(8rem, calc(8rem + env(safe-area-inset-bottom)));
        right: max(1rem, env(safe-area-inset-right));
        top: auto !important;
    }

    .safe-toast {
        top: max(5rem, calc(5rem + env(safe-area-inset-top)));
        left: 0;
        right: 0;
        padding-left: max(1rem, env(safe-area-inset-left));
        padding-right: max(1rem, env(safe-area-inset-right));
    }

    .safe-horizontal-banner {
        padding-top: max(1rem, env(safe-area-inset-top));
        padding-left: max(1rem, env(safe-area-inset-left));
        padding-right: max(1rem, env(safe-area-inset-right));
    }

    .bottom-38 {
        bottom: 9.5rem;
    }

    /* Custom popup styling */
    :global(.cmu-popup .maplibregl-popup-content) {
        border-radius: 12px;
        padding: 8px 12px;
        box-shadow: 0 4px 12px rgba(0,0,0,0.1);
        border: 1px solid #eee;
        max-width: 280px;
    }
    
    :global(.cmu-popup .maplibregl-popup-tip) {
        display: none;
    }

    /* Toast animation */
    @keyframes slide-down {
        from {
            transform: translateY(-100%);
            opacity: 0;
        }
        to {
            transform: translateY(0);
            opacity: 1;
        }
    }
    
    .animate-slide-down {
        animation: slide-down 0.3s ease-out;
    }
</style>