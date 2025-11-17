<script>
// ============================================================================
// IMPORTS
// ============================================================================
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
    AlertTriangle, TrafficCone, HelpCircle, Droplet, LifeBuoy,
    CarFront, ParkingSquare, Briefcase, PartyPopper, MessageSquare,
    Construction, RouteOff, Menu, User, ChevronDown, X, Crosshair
} from 'lucide-svelte';

// ============================================================================
// UUID GENERATOR
// ============================================================================
/**
 * Generate a random UUID v4
 * TODO: Replace with crypto.randomUUID() if available in your environment
 * @returns {string} UUID string
 */
function generateUUID() {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
        const r = Math.random() * 16 | 0;
        const v = c === 'x' ? r : (r & 0x3 | 0x8);
        return v.toString(16);
    });
}

// ============================================================================
// MAP INITIALIZATION & CONFIGURATION
// ============================================================================
let map;
let maplibregl;
let userLocationMarker = null;
let navigationControl = null;

// CMU Campus Bounds
// TODO BACKEND: Make this configurable via environment variables
// Example: VITE_MAP_BOUNDS_SW_LNG, VITE_MAP_BOUNDS_SW_LAT, etc.
const cmuBounds = [
    [98.93, 18.78], // Southwest [lng, lat]
    [98.97, 18.82]  // Northeast [lng, lat]
];

// ============================================================================
// STATE MANAGEMENT
// ============================================================================
let isMapLoaded = false;
let isMobile = false;
let isOpen = false; // User dropdown menu
let isFilterSidebarOpen = false;
let selectedCategory = null; // Currently selected pin category
let showDetailForm = false; // Show pin detail form modal
let pinCoordinates = null; // Coordinates for new pin
let isPointOrLineModalOpen = false; // Modal for choosing point/line for blocked category
let modalConfig = {}; // Configuration for point/line modal
let isDrawingLine = false; // User is currently drawing a line
let drawingLineCategory = 'blocked-line'; // Category of line being drawn
let currentLinePoints = []; // Array of coordinates for line being drawn
let lineVertexMarkers = []; // Map markers for line vertices
let isMobileCategorySheetOpen = false; // Mobile category selection sheet

// Toast notification state
let showToast = false;
let toastMessage = '';
let toastTimeout;

// Emergency modal state
let showSendHelpModal = false;

// ============================================================================
// FILTER CONFIGURATION
// TODO BACKEND: Sync this with user preferences from database
// API Endpoint: GET /api/user/preferences/filters
// API Response: { filters: { accident: true, blocked: false, ... } }
// 
// When filter changes:
// API Endpoint: POST /api/user/preferences/filters
// API Request: { filters: { accident: true, blocked: false, ... } }
// ============================================================================
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

// ============================================================================
// CATEGORY CONFIGURATION
// TODO BACKEND: Store these in database for easy management
// Suggested Database Schema:
// 
// Table: categories
// - id: varchar(50) PRIMARY KEY (e.g., 'accident')
// - display_name: varchar(100)
// - icon_name: varchar(50) (e.g., 'AlertTriangle')
// - bg_color: varchar(50) (e.g., 'bg-red-100')
// - text_color: varchar(50) (e.g., 'text-red-600')
// - order: int (for sorting)
// - active: boolean (to enable/disable categories)
// 
// API Endpoint: GET /api/categories
// ============================================================================
const categoryDisplayNames = {
    'accident': 'Accident/Hazard',
    'blocked': 'Blocked',
    'beware': 'Beware',
    'flood': 'Flood',
    'send_help': 'Send Help',
    'traffic_general': 'Traffic',
    'parking': 'Parking',
    'events': 'Events',
    'map_chat': 'Map Chat',
    'lost_found': 'Lost & Found'
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

$: currentStyle = categoryStyles[selectedCategory] || categoryStyles['accident'];

// ============================================================================
// UI HELPER FUNCTIONS
// ============================================================================

/**
 * Show success toast notification
 * @param {string} message - Message to display
 */
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

/**
 * Calculate time ago from timestamp
 * @param {string} timestamp - ISO timestamp
 * @returns {string} Human-readable time difference
 */
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

// ============================================================================
// EMERGENCY HELP HANDLERS
// TODO BACKEND: Implement emergency alert system
// API Endpoint: POST /api/emergency/send-help
// API Request: {
//   coordinates: { lng: number, lat: number },
//   user_id: string,
//   timestamp: string
// }
// API Response: {
//   success: boolean,
//   alert_id: string,
//   message: string
// }
// 
// IMPORTANT: This should:
// 1. Send SMS/push notification to security team
// 2. Log to emergency database with high priority
// 3. Trigger real-time alert in security dashboard
// 4. Store user location for response team
// ============================================================================
function handleSendHelpConfirm() {
    // Use user's actual location if available, otherwise use map center
    if (userLocationMarker) {
        const lngLat = userLocationMarker.getLngLat();
        pinCoordinates = { lng: lngLat.lng, lat: lngLat.lat };
        console.log(`EMERGENCY ALERT: Send Help at user location:`, pinCoordinates);
    } else {
        const center = map.getCenter();
        pinCoordinates = { lng: center.lng, lat: center.lat };
        console.log(`EMERGENCY ALERT: Send Help at map center:`, pinCoordinates);
    }
    
    // TODO: Replace with actual API call
    // Example:
    // try {
    //     const response = await fetch('/api/emergency/send-help', {
    //         method: 'POST',
    //         headers: { 'Content-Type': 'application/json' },
    //         body: JSON.stringify({
    //             coordinates: pinCoordinates,
    //             user_id: $userStore?.id,
    //             timestamp: new Date().toISOString()
    //         })
    //     });
    //     const data = await response.json();
    //     if (data.success) {
    //         showSuccessToast('Security Alerted');
    //     } else {
    //         showSuccessToast('Failed to alert security');
    //     }
    // } catch (error) {
    //     console.error('Emergency alert failed:', error);
    //     showSuccessToast('Error: Could not send alert');
    // }
    
    showSuccessToast('Security Alerted');
    showSendHelpModal = false;
}

function handleSendHelpClose() {
    showSendHelpModal = false;
}

// ============================================================================
// AUTHENTICATION HANDLERS
// TODO BACKEND: Implement proper logout
// API Endpoint: POST /api/auth/logout
// Should invalidate session/token and clear cookies
// ============================================================================
function handleLogout() {
    // TODO: Call logout API endpoint
    // Example:
    // try {
    //     await fetch('/api/auth/logout', { method: 'POST' });
    //     userStore.set(null);
    //     window.location.href = '/login';
    // } catch (error) {
    //     console.error('Logout failed:', error);
    // }
    
    userStore.set(null);
}

// ============================================================================
// UI UTILITY FUNCTIONS
// ============================================================================

/**
 * Svelte action for detecting clicks outside an element
 * Used for closing dropdowns/modals
 */
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

// ============================================================================
// GEOLOCATION
// ============================================================================

/**
 * Find and display user's current location on map
 * Uses browser Geolocation API
 */
function findUserLocation() {
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

// ============================================================================
// PIN CREATION WORKFLOW
// ============================================================================

/**
 * Cancel pin creation process
 * Clears selected category, line drawing state, and map cursor
 */
function cancelPinning() {
    selectedCategory = null;
    isDrawingLine = false;
    currentLinePoints = [];
    
    // Remove all line vertex markers from map
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

/**
 * Move to next step in pin creation
 * Shows detail form for user to enter title, description, etc.
 */
function goToNextStep() {
    const center = map.getCenter();
    pinCoordinates = center;
    showDetailForm = true;
}

/**
 * Close pin detail form
 */
function onFormClose() {
    showDetailForm = false;
    selectedCategory = null;
}

// ============================================================================
// PIN SUBMISSION
// TODO BACKEND: Implement pin creation API
// API Endpoint: POST /api/pins
// API Request: {
//   category: string,
//   coordinates: { lng: number, lat: number },
//   title: string,
//   description: string,
//   is_anonymous: boolean,
//   visibility: 'public' | 'staff_only',
//   photo: File | null (use multipart/form-data),
//   reporter_id: string (from user session)
// }
// API Response: {
//   success: boolean,
//   pin_id: string,
//   pin_data: { ... } // Full pin object including created_at, etc.
// }
// 
// Database Schema Suggestion:
// Table: pins
// - id: uuid PRIMARY KEY
// - category: varchar(50)
// - coordinates_lng: decimal(10, 7)
// - coordinates_lat: decimal(10, 7)
// - title: varchar(200)
// - description: text
// - is_anonymous: boolean
// - visibility: enum('public', 'staff_only')
// - photo_url: varchar(500) (S3/storage URL)
// - reporter_id: uuid FOREIGN KEY (users.id)
// - likes_count: int DEFAULT 0
// - dislikes_count: int DEFAULT 0
// - created_at: timestamp
// - updated_at: timestamp
// - status: enum('active', 'resolved', 'deleted')
// 
// Table: pin_interactions
// - id: uuid PRIMARY KEY
// - pin_id: uuid FOREIGN KEY
// - user_id: uuid FOREIGN KEY
// - interaction_type: enum('like', 'dislike')
// - created_at: timestamp
// UNIQUE(pin_id, user_id) // One interaction per user per pin
// ============================================================================
async function onFormSubmit(event) {
    const formData = event.detail;
    
    console.log('MOCK: Sending to backend...', formData);
    
    // TODO: Replace with actual API call
    // Example:
    // try {
    //     const formDataObj = new FormData();
    //     formDataObj.append('category', formData.category);
    //     formDataObj.append('coordinates', JSON.stringify(formData.coordinates));
    //     formDataObj.append('title', formData.title);
    //     formDataObj.append('description', formData.description);
    //     formDataObj.append('is_anonymous', formData.isAnonymous);
    //     formDataObj.append('visibility', formData.visibility);
    //     if (formData.photo) {
    //         formDataObj.append('photo', formData.photo);
    //     }
    //
    //     const response = await fetch('/api/pins', {
    //         method: 'POST',
    //         body: formDataObj
    //     });
    //
    //     const data = await response.json();
    //     
    //     if (data.success) {
    //         if (formData.visibility === 'public') {
    //             addPinToMap(data.pin_data);
    //             showSuccessToast(categoryDisplayNames[formData.category]);
    //         } else {
    //             showSuccessToast('Report sent to staff');
    //         }
    //     } else {
    //         showSuccessToast('Failed to create pin');
    //     }
    // } catch (error) {
    //     console.error('Pin creation failed:', error);
    //     showSuccessToast('Error: Could not create pin');
    // }
    
    await new Promise(resolve => setTimeout(resolve, 500));
    console.log('MOCK: Save successful!');
    
    if (formData.visibility === 'public') {
        addPinToMap(formData);
        showSuccessToast(categoryDisplayNames[formData.category]);
    } else {
        showSuccessToast('Report sent to staff');
    }
    
    onFormClose();
}

// ============================================================================
// MAP PIN RENDERING
// TODO BACKEND: Load existing pins from API
// API Endpoint: GET /api/pins
// Query Parameters:
//   - bounds: southwest_lng,southwest_lat,northeast_lng,northeast_lat
//   - categories: comma-separated list (e.g., 'accident,blocked,flood')
//   - limit: int (pagination)
//   - offset: int (pagination)
// API Response: {
//   pins: [{
//     id: string,
//     category: string,
//     coordinates: { lng: number, lat: number },
//     title: string,
//     description: string,
//     reporter: string (anonymous or user name),
//     photo_url: string | null,
//     likes_count: int,
//     dislikes_count: int,
//     created_at: string,
//     comments_count: int (for map_chat pins)
//   }],
//   total: int
// }
// 
// TODO: Implement real-time updates using WebSocket
// WebSocket Endpoint: ws://your-domain/api/pins/updates
// Events:
//   - pin_created: { pin: {...} }
//   - pin_updated: { pin_id: string, updates: {...} }
//   - pin_deleted: { pin_id: string }
//   - pin_liked: { pin_id: string, likes_count: int }
//   - comment_added: { pin_id: string, comment: {...} }
// ============================================================================

/**
 * Add a pin marker to the map
 * @param {Object} formData - Pin data object
 */
function addPinToMap(formData) {
    const el = document.createElement('div');
    
    mount(CustomMarker, {
        target: el,
        props: { category: formData.category }
    });
    
    const pinId = formData.id;
    let popupHTML = '';
    
    // Map Chat category has special UI with comments
    if (formData.category === 'map_chat') {
        // TODO BACKEND: Load comments from API
        // API Endpoint: GET /api/pins/{pin_id}/comments
        // API Response: {
        //   comments: [{
        //     id: string,
        //     user_name: string,
        //     text: string,
        //     created_at: string
        //   }]
        // }
        
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
        // Standard pin popup with like/dislike buttons
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

// ============================================================================
// CATEGORY SELECTION HANDLERS
// ============================================================================

/**
 * Handle category selection - determines what happens when user picks a category
 * @param {string} category - Selected category ID
 */
function handleCategorySelection(category) {
    // Send Help: Show confirmation modal immediately (no map selection needed)
    if (category === 'send_help') {
        showSendHelpModal = true;
        return;
    }
    
    // Blocked category: Choose between point (obstacle) or line (road closure)
    if (category === 'blocked') {
        onShowOptions({ detail: category });
        return;
    }
    
    // Traffic category: Start line drawing directly
    if (category === 'traffic_general') {
        onShowOptions({ detail: category });
        return;
    }
    
    // All other categories: Normal pin placement on map
    selectedCategory = category;
}

/**
 * Handle special categories that need additional options
 * @param {CustomEvent} event - Event with category detail
 */
function onShowOptions(event) {
    if (isMobileCategorySheetOpen) {
        isMobileCategorySheetOpen = false;
    }
    
    const category = event.detail;
    
    // Blocked category: choose between point (obstacle) or line (road closure)
    if (category === 'blocked') {
        modalConfig = {
            type: 'blocked',
            title: 'Report Blocked Path',
            pointOption: { Icon: Construction, title: 'Obstacle', description: 'e.g., Fallen tree (Pin a point)' },
            lineOption: { Icon: RouteOff, title: 'Road Closed', description: 'e.g., Construction (Draw a line)' }
        };
        isPointOrLineModalOpen = true;
    } 
    // Traffic category: directly start line drawing
    else if (category === 'traffic_general') {
        isPointOrLineModalOpen = false;
        map.setPaintProperty('temp-line-layer', 'line-color', '#EF4444');
        isDrawingLine = true;
        drawingLineCategory = 'traffic_general-line';
        currentLinePoints = [];
        map.getCanvas().style.cursor = 'crosshair';
    }
}

/**
 * Handle category selection from mobile sheet
 * @param {CustomEvent} event - Event with category detail
 */
function handleMobileCategorySelect(event) {
    const category = event.detail;
    isMobileCategorySheetOpen = false;
    handleCategorySelection(category);
}

/**
 * User selected point option for blocked category
 */
function onSelectPoint() {
    isPointOrLineModalOpen = false;
    selectedCategory = modalConfig.type;
}

/**
 * User selected line option for blocked category
 */
function onSelectLine() {
    isPointOrLineModalOpen = false;
    map.setPaintProperty('temp-line-layer', 'line-color', '#F97316');
    isDrawingLine = true;
    drawingLineCategory = modalConfig.type === 'blocked' ? 'blocked-line' : 'traffic_general-line';
    currentLinePoints = [];
    map.getCanvas().style.cursor = 'crosshair';
}

// ============================================================================
// LINE DRAWING FUNCTIONALITY
// TODO BACKEND: Store line data
// API Endpoint: POST /api/lines
// API Request: {
//   category: 'blocked' | 'traffic_general',
//   coordinates: [[lng, lat], [lng, lat], ...],
//   reporter_id: string
// }
// API Response: {
//   success: boolean,
//   line_id: string,
//   line_data: { ... }
// }
// 
// Database Schema Suggestion:
// Table: lines
// - id: uuid PRIMARY KEY
// - category: varchar(50)
// - coordinates: jsonb (array of [lng, lat])
// - reporter_id: uuid FOREIGN KEY
// - created_at: timestamp
// - status: enum('active', 'resolved', 'deleted')
// ============================================================================

/**
 * Update temporary line on map as user draws
 * @param {string} sourceId - MapLibre source ID
 * @param {Array} points - Array of [lng, lat] coordinates
 */
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

/**
 * Add permanent line to map after submission
 * @param {Array} points - Array of [lng, lat] coordinates
 * @param {string} lineCategory - Category of line
 */
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

/**
 * Submit drawn line to backend
 */
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
    
    // TODO: Replace with actual API call (see TODO BACKEND comment above)
    
    const lineCategory = drawingLineCategory.replace('-line', '');
    const startCoordinates = { lng: currentLinePoints[0][0], lat: currentLinePoints[0][1] };
    
    // Create a pin marker at the start of the line
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

// Update map cursor based on state
$: if (map) {
    if (selectedCategory && selectedCategory !== 'send_help') {
        map.getCanvas().style.cursor = 'crosshair';
    } else if (!isDrawingLine) {
        map.getCanvas().style.cursor = '';
    }
}

// ============================================================================
// MAP INITIALIZATION
// ============================================================================

onMount(async () => {
    isMobile = window.innerWidth < 768;
    
    // Dynamically import MapLibre GL
    maplibregl = (await import('maplibre-gl')).default;
    
    // Initialize map
    map = new maplibregl.Map({
        container: 'map',
        
        // Using OpenStreetMap tiles
        // TODO PRODUCTION: Consider using Maptiler, Mapbox, or self-hosted tiles
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
        minZoom: 14,
        maxZoom: 18,
        maxBounds: cmuBounds
    });
    
    // Add navigation controls (zoom/compass) for desktop only
    navigationControl = new maplibregl.NavigationControl();
    if (!isMobile) {
        map.addControl(navigationControl, 'bottom-right');
    }
    
    // Handle responsive behavior
    window.addEventListener('resize', () => {
        const wasMobile = isMobile;
        isMobile = window.innerWidth < 768;
        
        // Add/remove controls when switching between mobile/desktop
        if (wasMobile !== isMobile && navigationControl) {
            if (isMobile) {
                try {
                    map.removeControl(navigationControl);
                } catch (e) {
                    // Control already removed
                }
            } else {
                map.addControl(navigationControl, 'bottom-right');
            }
        }
    });
    
    // ========================================================================
    // LIKE/DISLIKE HANDLERS
    // TODO BACKEND: Implement like/dislike API
    // API Endpoint: POST /api/pins/{pin_id}/interactions
    // API Request: { interaction_type: 'like' | 'dislike' }
    // API Response: {
    //   success: boolean,
    //   likes_count: int,
    //   dislikes_count: int,
    //   user_interaction: 'like' | 'dislike' | null
    // }
    // 
    // Business Logic:
    // 1. Check if user already interacted with this pin
    // 2. If same interaction: remove it (toggle off)
    // 3. If different interaction: change to new one
    // 4. Update counts in database using transaction
    // 5. Return new counts to update UI
    // ========================================================================
    
    /**
     * Handle like button click
     * TODO: Implement proper toggle and API integration
     */
    window.handleLike = (pinId) => {
        console.log(`MOCK: Liking pin ${pinId}!`);
        
        const countElement = document.getElementById(`like-count-${pinId}`);
        const buttonElement = document.getElementById(`like-button-${pinId}`);
        
        if (countElement && buttonElement) {
            let currentLikes = parseInt(countElement.innerText, 10);
            currentLikes++;
            countElement.innerText = currentLikes;
            
            // Visual feedback
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
    
    /**
     * Handle dislike button click
     * TODO: Implement proper toggle and API integration
     */
    window.handleDislike = (pinId) => {
        console.log(`MOCK: Disliking pin ${pinId}!`);
        
        const countElement = document.getElementById(`dislike-count-${pinId}`);
        const buttonElement = document.getElementById(`dislike-button-${pinId}`);
        
        if (countElement && buttonElement) {
            let currentDislikes = parseInt(countElement.innerText, 10);
            currentDislikes++;
            countElement.innerText = currentDislikes;
            
            // Visual feedback
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
    
    // ========================================================================
    // COMMENT HANDLER
    // TODO BACKEND: Implement comments API
    // API Endpoint: POST /api/pins/{pin_id}/comments
    // API Request: { text: string }
    // API Response: {
    //   success: boolean,
    //   comment: {
    //     id: string,
    //     user_name: string,
    //     text: string,
    //     created_at: string
    //   }
    // }
    // 
    // Database Schema:
    // Table: comments
    // - id: uuid PRIMARY KEY
    // - pin_id: uuid FOREIGN KEY
    // - user_id: uuid FOREIGN KEY
    // - text: text
    // - created_at: timestamp
    // 
    // Security: Sanitize text input server-side to prevent XSS
    // ========================================================================
    
    /**
     * Handle comment submission
     */
    window.handleComment = (pinId) => {
        const inputElement = document.getElementById(`comment-input-${pinId}`);
        const listElement = document.getElementById(`comments-list-${pinId}`);
        const commentText = inputElement.value;
        
        if (!commentText || !listElement) return;
        
        const userName = $userStore?.name || 'User';
        
        // TODO: Replace with API call
        // Example:
        // try {
        //     const response = await fetch(`/api/pins/${pinId}/comments`, {
        //         method: 'POST',
        //         headers: { 'Content-Type': 'application/json' },
        //         body: JSON.stringify({ text: commentText })
        //     });
        //     const data = await response.json();
        //     if (data.success) {
        //         // Add comment to UI
        //         const newComment = document.createElement('div');
        //         newComment.className = 'text-sm';
        //         newComment.innerHTML = `<strong>${data.comment.user_name}:</strong> ${escapeHtml(data.comment.text)}`;
        //         listElement.appendChild(newComment);
        //         inputElement.value = '';
        //         listElement.scrollTop = listElement.scrollHeight;
        //     }
        // } catch (error) {
        //     console.error('Failed to add comment:', error);
        // }
        
        const newComment = document.createElement('div');
        newComment.className = 'text-sm';
        
        // Sanitize text to prevent XSS
        const safeText = commentText.replace(/</g, "&lt;").replace(/>/g, "&gt;");
        
        newComment.innerHTML = `<strong>${userName}:</strong> ${safeText}`;
        
        listElement.appendChild(newComment);
        
        inputElement.value = '';
        listElement.scrollTop = listElement.scrollHeight;
        
        console.log(`MOCK: Adding comment to pin ${pinId}: ${commentText}`);
    };
    
    // Wait for map to load
    map.on('load', () => {
        isMapLoaded = true;
        console.log('MOCK: Map is fully loaded!');
        
        // Add temporary line source for drawing
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
        
        // Handle map clicks for line drawing
        map.on('click', (e) => {
            if (!isDrawingLine) return;
            
            const newPoint = e.lngLat.toArray();
            currentLinePoints.push(newPoint);
            updateLineOnMap('temp-line-source', currentLinePoints);
            
            // Add vertex marker
            const vertexEl = document.createElement('div');
            vertexEl.className = 'w-3 h-3 bg-white rounded-full border-2 border-orange-500 shadow-md';
            const vertexMarker = new maplibregl.Marker({ element: vertexEl, anchor: 'center' })
                .setLngLat(newPoint)
                .addTo(map);
            
            lineVertexMarkers.push(vertexMarker);
        });
        
        // TODO: Load existing pins from API here
        // Example:
        // try {
        //     const response = await fetch('/api/pins?bounds=...');
        //     const data = await response.json();
        //     data.pins.forEach(pin => addPinToMap(pin));
        // } catch (error) {
        //     console.error('Failed to load pins:', error);
        // }
        
        console.log('MOCK: Loading existing pins from backend...');
    });
});
</script>

<!-- Rest of your HTML template remains the same -->
<div id="map-container" class="relative h-screen w-full">
    <div id="map" class="h-full w-full"></div>
    
    <!-- Modals, UI components, etc. -->
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
    
    {#if isMapLoaded}
        {#if !selectedCategory && !isDrawingLine}
            
            {#if isFilterSidebarOpen}
                <FilterSidebar
                    bind:filters={filterState}
                    on:close={() => isFilterSidebarOpen = false}
                />
            {/if}
            
            {#if Menu && User && ChevronDown && X && Crosshair}
                <nav class="absolute top-0 right-0 left-0 z-40 flex items-center justify-between safe-top">
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
                <PinCategoryPanel
                    bind:selectedCategory
                    on:showOptions={onShowOptions}
                    on:sendHelp={() => {
                        selectedCategory = null; // Clear any selected category
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
        
        {#if Crosshair}
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
        {/if}
        
        {#if !selectedCategory && !isDrawingLine}
            <img src="/logo.svg" alt="Logo" class="absolute z-30 h-8 safe-bottom-left" />
        {/if}
        
        {#if showToast}
            <div class="absolute z-50 flex justify-center safe-toast">
                <div class="bg-white px-4 py-2 rounded-full shadow-lg flex items-center gap-2 animate-slide-down border border-gray-200">
                    <span class="font-medium text-gray-700">Post success:</span>
                    <span class="font-bold text-green-600">{toastMessage}</span>
                </div>
            </div>
        {/if}
        
    {:else}
        <div class="absolute inset-0 flex items-center justify-center bg-white">
            <span class="loading loading-spinner loading-lg text-[#8F66FF]"></span>
        </div>
    {/if}
</div>

<style>
    /* ========================================================================
       MAP CONTAINER
       ======================================================================== */
    #map {
        width: 100%;
        height: 100%;
    }
    
    /* ========================================================================
       CUSTOM POPUP STYLING
       Override MapLibre GL default popup styles
       ======================================================================== */
    :global(.cmu-popup .maplibregl-popup-content) {
        border-radius: 12px;
        padding: 8px 12px;
        box-shadow: 0 4px 12px rgba(0,0,0,0.1);
        border: 1px solid #eee;
        max-width: 240px;
    }
    :global(.cmu-popup .maplibregl-popup-tip) {
        display: none; /* Hide the arrow/tip */
    }
    
    /* ========================================================================
       SAFE AREA SPACING FOR MOBILE DEVICES
       Handles notches, rounded corners, and Dynamic Island on iOS
       Uses env(safe-area-inset-*) to respect device safe areas
       ======================================================================== */
    
    /* Top bar (menu + profile) */
    .safe-top {
        padding-top: max(1rem, env(safe-area-inset-top));
        padding-left: max(1rem, env(safe-area-inset-left));
        padding-right: max(1rem, env(safe-area-inset-right));
    }
    
    /* Bottom buttons (Cancel/Next/Finish Drawing) */
    .safe-bottom {
        bottom: max(1.5rem, calc(1.5rem + env(safe-area-inset-bottom)));
        left: 0;
        right: 0;
        padding-left: max(1rem, env(safe-area-inset-left));
        padding-right: max(1rem, env(safe-area-inset-right));
    }
    
    /* Make buttons fully clickable on mobile - CRITICAL FOR TOUCH EVENTS */
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
    
    /* Bottom-right FAB button (+) */
    .safe-bottom-right {
        bottom: max(3rem, calc(3rem + env(safe-area-inset-bottom)));
        right: max(1rem, env(safe-area-inset-right));
    }
    
    /* Bottom-left logo */
    .safe-bottom-left {
        bottom: max(1rem, env(safe-area-inset-bottom));
        left: max(1rem, env(safe-area-inset-left));
    }
    
    /* Crosshair button - Bottom-Right position (like Google Maps) */
    .safe-top-right-crosshair {
        bottom: max(8rem, calc(8rem + env(safe-area-inset-bottom)));
        right: max(1rem, env(safe-area-inset-right));
        top: auto !important;
    }
    
    /* Toast notification positioning */
    .safe-toast {
        top: max(5rem, calc(5rem + env(safe-area-inset-top)));
        left: 0;
        right: 0;
        padding-left: max(1rem, env(safe-area-inset-left));
        padding-right: max(1rem, env(safe-area-inset-right));
    }
    
    /* Prevent zoom control collapse on mobile */
    :global(.maplibregl-ctrl-top-right) {
        display: flex;
        flex-direction: column;
        gap: 8px;
    }
    
    :global(.maplibregl-ctrl-group) {
        display: flex !important;
        flex-direction: column !important;
    }
    
    :global(.maplibregl-ctrl-zoom-in),
    :global(.maplibregl-ctrl-zoom-out),
    :global(.maplibregl-ctrl-compass) {
        display: block !important;
        width: 29px;
        height: 29px;
    }
    
    /* Horizontal spacing for top banners */
    .safe-horizontal {
        padding-left: max(1rem, env(safe-area-inset-left));
        padding-right: max(1rem, env(safe-area-inset-right));
    }
    
    /* Top banners with extra padding for Dynamic Island */
    .safe-horizontal-banner {
        padding-top: max(1rem, env(safe-area-inset-top));
        padding-left: max(1rem, env(safe-area-inset-left));
        padding-right: max(1rem, env(safe-area-inset-right));
    }
    
    /* ========================================================================
       ANIMATIONS
       ======================================================================== */
    
    /* Toast slide-down animation */
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