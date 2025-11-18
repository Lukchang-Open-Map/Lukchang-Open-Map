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
		Shield,User,Trash2,MapPin,Search,MessageSquare,CheckCircle,ChevronDown,ChevronLeft,AlertTriangle,TrafficCone,HelpCircle,
		Droplet,LifeBuoy,CarFront,ParkingSquare,Briefcase,PartyPopper,Menu,X,Crosshair,Construction,RouteOff
	} from 'lucide-svelte';

	// ============================================================================
	// MOCK DATA
	// ============================================================================
	const ADMIN_USER = {
		id: 'admin_001',
		name: 'admin',
		email: 'admin@cmu.ac.th',
		role: 'admin'
	};

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

	const categoryDisplayNames = {
		accident: 'Accident/Hazard',
		blocked: 'Blocked',
		beware: 'Beware',
		flood: 'Flood',
		send_help: 'Send Help',
		traffic_general: 'Traffic',
		parking: 'Parking',
		events: 'Events',
		map_chat: 'Map Chat',
		lost_found: 'Lost & Found'
	};

	const categoryStyles = {
		accident: { Icon: AlertTriangle, bg: 'bg-red-100', text: 'text-red-600' },
		blocked: { Icon: TrafficCone, bg: 'bg-orange-100', text: 'text-orange-600' },
		beware: { Icon: HelpCircle, bg: 'bg-gray-200', text: 'text-gray-700' },
		flood: { Icon: Droplet, bg: 'bg-blue-100', text: 'text-blue-600' },
		send_help: { Icon: LifeBuoy, bg: 'bg-red-100', text: 'text-red-600' },
		traffic_general: { Icon: CarFront, bg: 'bg-red-100', text: 'text-red-600' },
		parking: { Icon: ParkingSquare, bg: 'bg-blue-100', text: 'text-blue-600' },
		events: { Icon: PartyPopper, bg: 'bg-purple-100', text: 'text-purple-600' },
		map_chat: { Icon: MessageSquare, bg: 'bg-green-100', text: 'text-green-600' },
		lost_found: { Icon: Briefcase, bg: 'bg-orange-200', text: 'text-orange-600' }
	};

	let posts = $state([
		{
			id: 'post_001',
			category: 'accident',
			title: 'รถเครื่องชนกัน',
			description: 'เกิดอุบัติเหตุที่หน้ามอ ต้องการความช่วยเหลือ',
			coordinates: { lng: 98.9545, lat: 18.807 },
			reporter: { name: 'Somchai Lertsuk', displayAs: 'Anonymous' },
			timestamp: new Date(Date.now() - 3600000).toISOString(),
			likes: 12,
			dislikes: 2,
			status: 'active'
		},
		{
			id: 'post_002',
			category: 'flood',
			title: 'น้ำท่วมถนน',
			description: 'น้ำท่วมสูงประมาณ 20 ซม. ที่อ่างแก้ว',
			coordinates: { lng: 98.9504, lat: 18.8052 },
			reporter: { name: 'Nittaya P.', displayAs: 'Nittaya P.' },
			timestamp: new Date(Date.now() - 7200000).toISOString(),
			likes: 8,
			dislikes: 0,
			status: 'active'
		},
		{
			id: 'post_003',
			category: 'map_chat',
			title: 'ใครรู้พิกัดร้านกาแฟดีๆ',
			description: 'แนะนำร้านกาแฟใกล้ห้องสมุดหน่อยครับ',
			coordinates: { lng: 98.9517, lat: 18.8011 },
			reporter: { name: 'John Doe', displayAs: 'Anonymous' },
			timestamp: new Date(Date.now() - 10800000).toISOString(),
			likes: 15,
			dislikes: 1,
			status: 'active'
		},
		{
			id: 'post_004',
			category: 'parking',
			title: 'ที่จอดรถเต็ม',
			description: 'ที่จอดรถม่วงเต็มแล้ว ห้ามเข้า',
			coordinates: { lng: 98.9524, lat: 18.7993 },
			reporter: { name: 'Staff User', displayAs: 'Staff User' },
			timestamp: new Date(Date.now() - 14400000).toISOString(),
			likes: 20,
			dislikes: 3,
			photoUrl: 'https://via.placeholder.com/300x200',
			status: 'active'
		},
		{
			id: 'post_005',
			category: 'blocked',
			title: 'ต้นไม้ล้ม',
			description: 'ต้นไม้ล้มขวางทางที่หน้าวิศวะ',
			coordinates: { lng: 98.9503, lat: 18.7943 },
			reporter: { name: 'Anonymous Reporter', displayAs: 'Anonymous' },
			timestamp: new Date(Date.now() - 18000000).toISOString(),
			likes: 5,
			dislikes: 0,
			status: 'active'
		}
	]);

	// ============================================================================
	// STATE MANAGEMENT
	// ============================================================================
	let map = null;
	let maplibregl = null;
	let isMapLoaded = $state(false);
	let viewMode = $state('admin'); // 'admin' or 'user'
	let activeTab = $state('posts');
	let isSidebarOpen = $state(true);
	let selectedPost = $state(null);
	let selectedLocation = $state(null);
	let searchQuery = $state('');
	let categoryFilter = $state('all');
	let showNotification = $state(false);
	let notificationMessage = $state('');
	let isOpen = $state(false);
	let userLocationMarker = null;
	let navigationControl = null;
	let isMobile = false;

	// User mode states
	let isFilterSidebarOpen = $state(false);
	let selectedCategory = $state(null);
	let showDetailForm = $state(false);
	let pinCoordinates = $state(null);
	let isPointOrLineModalOpen = $state(false);
	let modalConfig = $state({});
	let isDrawingLine = $state(false);
	let drawingLineCategory = $state('blocked-line');
	let currentLinePoints = $state([]);
	let lineVertexMarkers = $state([]);
	let isMobileCategorySheetOpen = $state(false);
	let showSendHelpModal = $state(false);
	let showToast = $state(false);
	let toastMessage = $state('');
	let toastTimeout;
	let isAddingPin = $state(false);

	let filterState = $state({
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
	});

	// ============================================================================
	// DERIVED STATE
	// ============================================================================
	const currentStyle = $derived(categoryStyles[selectedCategory] || categoryStyles['accident']);

	const filteredPosts = $derived(
		posts.filter((post) => {
			const matchesSearch =
				post.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
				post.description.toLowerCase().includes(searchQuery.toLowerCase()) ||
				post.reporter.name.toLowerCase().includes(searchQuery.toLowerCase());
			const matchesCategory = categoryFilter === 'all' || post.category === categoryFilter;
			return matchesSearch && matchesCategory;
		})
	);

	const sortedPosts = $derived(filteredPosts.sort((a, b) => b.dislikes - a.dislikes));

	const categoryCount = $derived((category) => {
		if (category === 'all') return posts.length;
		return posts.filter((p) => p.category === category).length;
	});

	const categoryCounts = $derived(
		Object.keys(categoryDisplayNames).reduce((acc, cat) => {
			acc[cat] = posts.filter((p) => p.category === cat).length;
			return acc;
		}, {})
	);

	// Filtered posts for user view based on filter state
	const visiblePosts = $derived(posts.filter((post) => filterState[post.category]));

	// Update map cursor based on view mode and state
	$effect(() => {
		if (map && viewMode === 'user') {
			if (selectedCategory && selectedCategory !== 'send_help') {
				map.getCanvas().style.cursor = 'crosshair';
			} else if (!isDrawingLine) {
				map.getCanvas().style.cursor = '';
			}
		} else if (map && viewMode === 'admin') {
			map.getCanvas().style.cursor = '';
		}
	});

	// ============================================================================
	// UTILITY FUNCTIONS
	// ============================================================================
	function generateUUID() {
		return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
			const r = (Math.random() * 16) | 0;
			const v = c === 'x' ? r : (r & 0x3) | 0x8;
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
		return `${days} day${days > 1 ? 's' : ''} ago`;
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
	// ADMIN MODE HANDLERS
	// ============================================================================
	const showSuccess = (message) => {
		notificationMessage = message;
		showNotification = true;
		setTimeout(() => (showNotification = false), 3000);
	};

	const handleDeletePost = async (postId) => {
		console.log(`Deleting post ${postId}`);
		posts = posts.filter((p) => p.id !== postId);
		selectedPost = null;
		showSuccess('Post deleted successfully');
	};

	const flyToPost = (post) => {
		if (map) {
			map.flyTo({
				center: [post.coordinates.lng, post.coordinates.lat],
				zoom: 17,
				duration: 1500
			});
		}
		selectedPost = post;
	};

	const flyToLocation = (location) => {
		if (map) {
			map.flyTo({
				center: [location.lng, location.lat],
				zoom: 17,
				duration: 1500
			});
		}
		selectedLocation = location;
	};

	const toggleViewMode = (mode) => {
		viewMode = mode;
		if (mode === 'user') {
			isSidebarOpen = false;
			selectedPost = null;
			selectedLocation = null;
			cancelPinning();
		} else {
			cancelPinning();
			isSidebarOpen = true;
		}
	};

	// ============================================================================
	// USER MODE HANDLERS (From SecurityDashboard)
	// ============================================================================
	function cancelPinning() {
		selectedCategory = null;
		isAddingPin = false;
		isDrawingLine = false;
		currentLinePoints = [];

		for (const marker of lineVertexMarkers) {
			marker.remove();
		}
		lineVertexMarkers = [];

		if (map) {
			map.getCanvas().style.cursor = '';
			updateLineOnMap('temp-line-source', []);
			if (map.getPaintProperty('temp-line-layer', 'line-color')) {
				map.setPaintProperty('temp-line-layer', 'line-color', '#F97316');
			}
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
			// Close mobile sheet if open
			if (isMobileCategorySheetOpen) {
				isMobileCategorySheetOpen = false;
			}
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

		// For all other categories including accident, flood, beware, parking, events, map_chat, lost_found
		selectedCategory = category;
		// Close mobile sheet if open
		if (isMobileCategorySheetOpen) {
			isMobileCategorySheetOpen = false;
		}
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
				pointOption: {
					Icon: Construction,
					title: 'Obstacle',
					description: 'e.g., Fallen tree (Pin a point)'
				},
				lineOption: {
					Icon: RouteOff,
					title: 'Road Closed',
					description: 'e.g., Construction (Draw a line)'
				}
			};
			isPointOrLineModalOpen = true;
		} else if (category === 'traffic_general') {
			isPointOrLineModalOpen = false;
			if (map.getPaintProperty('temp-line-layer', 'line-color')) {
				map.setPaintProperty('temp-line-layer', 'line-color', '#EF4444');
			}
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
		if (map.getPaintProperty('temp-line-layer', 'line-color')) {
			map.setPaintProperty('temp-line-layer', 'line-color', '#F97316');
		}
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

		await new Promise((resolve) => setTimeout(resolve, 500));

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
			type: 'geojson',
			data: {
				type: 'Feature',
				geometry: {
					type: 'LineString',
					coordinates: points
				}
			}
		});
		map.addLayer({
			id: layerId,
			type: 'line',
			source: sourceId,
			layout: { 'line-join': 'round', 'line-cap': 'round' },
			paint: {
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
			title: lineCategory === 'blocked' ? 'Road Closed' : 'Traffic Jam',
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
                <div class="p-1" style="min-width: 240px; font-family: 'Kanit', sans-serif;">
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
		} else {
			popupHTML = `
                <div class="p-1" style="min-width: 220px; font-family: 'Kanit', sans-serif;">
                    <h3 class="font-bold text-lg">${formData.title || 'No Title'}</h3>
                    ${
											formData.photoPreviewUrl
												? `<img src="${formData.photoPreviewUrl}" alt="Pin image" class="w-full h-32 object-cover rounded-md my-2"/>`
												: ''
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
	// MAP INITIALIZATION
	// ============================================================================
	onMount(async () => {
		isMobile = window.innerWidth < 768;

		maplibregl = (await import('maplibre-gl')).default;

		map = new maplibregl.Map({
			container: 'admin-map',
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
		};

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
		};

		// Comment handler
		window.handleComment = (pinId) => {
			const inputElement = document.getElementById(`comment-input-${pinId}`);
			const listElement = document.getElementById(`comments-list-${pinId}`);
			const commentText = inputElement.value;

			if (!commentText || !listElement) return;

			const userName = $userStore?.name || 'User';

			const newComment = document.createElement('div');
			newComment.className = 'text-sm';

			const safeText = commentText.replace(/</g, '&lt;').replace(/>/g, '&gt;');

			newComment.innerHTML = `<strong>${userName}:</strong> ${safeText}`;

			listElement.appendChild(newComment);

			inputElement.value = '';
			listElement.scrollTop = listElement.scrollHeight;

			console.log(`MOCK: Adding comment to pin ${pinId}: ${commentText}`);
		};

		map.on('load', () => {
			isMapLoaded = true;

			// Add security locations
			SECURITY_LOCATIONS.forEach((location) => {
				const securityEl = document.createElement('div');
				securityEl.innerHTML = `<img src="/security.svg" alt="Security" style="width: 60px; height: 60px;" />`;
				securityEl.style.cssText = `
                cursor: pointer;
                filter: drop-shadow(0 2px 4px rgba(0,0,0,0.3));
            `;

				new maplibregl.Marker({ element: securityEl, anchor: 'center' })
					.setLngLat([location.lng, location.lat])
					.setPopup(
						new maplibregl.Popup({
							offset: 25,
							closeButton: false,
							className: 'cmu-popup'
						}).setHTML(`
                  <div class="p-1" style="min-width: 220px; font-family: 'Kanit', sans-serif;">
                    <h3 class="font-bold text-lg text-blue-600 flex items-center gap-2">
                      <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>
                      </svg>
                      Security Guard
                    </h3>
                    <p class="text-sm text-gray-600 mt-1">${location.name}</p>
                    <div class="mt-2 pt-2 border-t border-gray-200 text-xs text-gray-500">
                       Status: <span class="text-green-600 font-semibold">On Duty</span>
                       <br>
                       <span class="text-gray-400">ID: ${location.id}</span>
                    </div>
                  </div>
                `)
					)
					.addTo(map);
			});

			// Add posts markers
			posts.forEach((post) => {
				addPinToMap(post);
			});

			// Add temporary line source for drawing
			map.addSource('temp-line-source', {
				type: 'geojson',
				data: {
					type: 'Feature',
					geometry: {
						type: 'LineString',
						coordinates: []
					}
				}
			});

			map.addLayer({
				id: 'temp-line-layer',
				type: 'line',
				source: 'temp-line-source',
				paint: {
					'line-color': '#F97316',
					'line-width': 5,
					'line-dasharray': [2, 2]
				}
			});

			// Handle map clicks for line drawing and pin placement in user mode
			map.on('click', (e) => {
				// Only handle clicks in user mode when category is selected
				if (viewMode !== 'user') return;

				const coords = e.lngLat;

				// If drawing a line (blocked or traffic)
				if (isDrawingLine) {
					currentLinePoints.push(coords.toArray());

					// Create new vertex marker
					const vertexEl = document.createElement('div');
					vertexEl.className = 'w-3 h-3 bg-white rounded-full border-2 border-orange-500 shadow-md';
					const vertexMarker = new maplibregl.Marker({ element: vertexEl, anchor: 'center' })
						.setLngLat(coords)
						.addTo(map);

					lineVertexMarkers.push(vertexMarker);

					// Update line on map
					updateLineOnMap('temp-line-source', currentLinePoints);
				} else if (selectedCategory && !showDetailForm) {
					// For single point pins - only when category is selected and form not shown
					pinCoordinates = { lng: coords.lng, lat: coords.lat };
					showDetailForm = true;
				}
			});
		});

		return () => {
			if (map) map.remove();
		};
	});
</script>

<div class="font-kanit relative h-screen w-full overflow-hidden">
	<!-- Map Background -->
	<div id="admin-map" class="absolute inset-0 h-full w-full bg-gray-100" />

	<!-- Loading State -->
	{#if !isMapLoaded}
		<div class="absolute inset-0 z-50 flex items-center justify-center bg-white">
			<div class="flex flex-col items-center gap-3">
				<span class="loading loading-lg loading-spinner text-[#8F66FF]"></span>
				<p class="text-gray-600">Loading Map...</p>
			</div>
		</div>
	{/if}

	<!-- Top Bar with View Switcher and Profile -->
	<nav class="safe-top absolute top-0 right-0 left-0 z-50 flex items-center justify-between">
		<!-- Left: Menu/Sidebar Toggle -->
		{#if viewMode === 'admin'}
			<button
				class="flex items-center justify-center rounded-[12px] bg-white p-3 shadow-md hover:bg-gray-100"
				on:click={() => (isSidebarOpen = !isSidebarOpen)}
			>
				<Menu class="h-6 w-6" />
			</button>
		{:else}
			<button
				class="flex items-center justify-center rounded-[12px] bg-white p-3 shadow-md hover:bg-gray-100"
				on:click={() => (isFilterSidebarOpen = true)}
			>
				<Menu class="h-6 w-6" />
			</button>
		{/if}

		<!-- Center: View Mode Toggle -->
		<div
			class="absolute left-1/2 flex -translate-x-1/2 items-center gap-2 rounded-[12px] bg-white p-1 shadow-md"
		>
			<button
				on:click={() => toggleViewMode('admin')}
				class="rounded-lg px-3 py-2 text-sm font-medium transition-all {viewMode === 'admin'
					? 'bg-[#8F66FF] text-white'
					: 'text-gray-600 hover:bg-gray-100'}"
			>
				Admin
			</button>
			<button
				on:click={() => toggleViewMode('user')}
				class="rounded-lg px-3 py-2 text-sm font-medium transition-all {viewMode === 'user'
					? 'bg-green-600 text-white'
					: 'text-gray-600 hover:bg-gray-100'}"
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

	<!-- Success Notification -->
	{#if showNotification}
		<div
			class="fixed top-20 left-1/2 z-50 flex -translate-x-1/2 items-center gap-3 rounded-full bg-green-600 px-6 py-3 text-white shadow-2xl"
		>
			<CheckCircle class="h-5 w-5" />
			<span class="font-medium">{notificationMessage}</span>
		</div>
	{/if}

	<!-- Toast Notification -->
	{#if showToast}
		<div
			class="animate-slide-down fixed top-20 left-1/2 z-50 flex -translate-x-1/2 items-center gap-3 rounded-full border border-gray-200 bg-white px-6 py-3 shadow-2xl"
		>
			<span class="font-medium text-gray-700">Post success:</span>
			<span class="font-bold text-green-600">{toastMessage}</span>
		</div>
	{/if}

	<!-- Left Sidebar -->
	{#if viewMode === 'admin'}
		<div
			class="absolute top-0 bottom-0 left-0 z-[60] w-full bg-white shadow-2xl transition-transform duration-300 md:w-[445px] {isSidebarOpen
				? 'translate-x-0'
				: '-translate-x-full'}"
		>
			<!-- Header -->
			<div class="flex items-center justify-between border-b border-gray-200 bg-white p-4">
				<div class="flex items-center gap-2">
					<h2 class="text-xl font-bold text-gray-900">Admin Management</h2>
					{#if posts.length > 0}
						<span
							class="flex h-6 w-6 items-center justify-center rounded-full bg-red-500 text-xs font-bold text-white"
						>
							{posts.length}
						</span>
					{/if}
				</div>
				<button
					on:click={() => (isSidebarOpen = false)}
					class="rounded-lg p-1.5 transition-colors hover:bg-gray-100"
				>
					<ChevronLeft class="h-5 w-5 text-gray-600" />
				</button>
			</div>

			<!-- Search and Category Filter -->
			<div class="border-b border-gray-200 bg-gray-50 p-4">
				<div class="relative mb-3">
					<Search class="absolute top-1/2 left-3 h-4 w-4 -translate-y-1/2 text-gray-400" />
					<input
						type="text"
						placeholder="Search posts, users..."
						bind:value={searchQuery}
						class="w-full rounded-lg border border-gray-300 py-2 pr-4 pl-10 focus:border-transparent focus:ring-2 focus:ring-[#8F66FF]"
					/>
				</div>

				<div class="scrollbar-hide flex gap-2 overflow-x-auto pb-2">
					<button
						on:click={() => (categoryFilter = 'all')}
						class="rounded-full px-3 py-1.5 text-xs font-semibold whitespace-nowrap transition-all {categoryFilter ===
						'all'
							? 'bg-[#8F66FF] text-white'
							: 'border border-gray-300 bg-white text-gray-700 hover:bg-gray-100'}"
					>
						 All ({categoryCount('all')})
					</button>
					{#each Object.entries(categoryDisplayNames) as [cat, displayName]}
						{#if categoryCounts[cat] > 0}
							<button
								on:click={() => (categoryFilter = cat)}
								class="flex items-center gap-1 rounded-full px-3 py-1.5 text-xs font-semibold whitespace-nowrap transition-all {categoryFilter ===
								cat
									? 'bg-[#8F66FF] text-white'
									: 'border border-gray-300 bg-white text-gray-700 hover:bg-gray-100'}"
							>
								<svelte:component this={categoryStyles[cat].Icon} class="h-3 w-3" />
								{displayName} ({categoryCounts[cat]})
							</button>
						{/if}
					{/each}
				</div>
			</div>

			<!-- Tabs -->
			<div class="flex border-b border-gray-200 bg-white">
				<button
					on:click={() => (activeTab = 'posts')}
					class="flex-1 px-4 py-3 text-sm font-semibold transition {activeTab === 'posts'
						? 'border-b-2 border-[#8F66FF] text-[#8F66FF]'
						: 'text-gray-600 hover:text-gray-900'}"
				>
					<MessageSquare class="mr-2 inline h-4 w-4" />
					Posts ({sortedPosts.length})
				</button>
				<button
					on:click={() => (activeTab = 'security')}
					class="flex-1 px-4 py-3 text-sm font-semibold transition {activeTab === 'security'
						? 'border-b-2 border-[#8F66FF] text-[#8F66FF]'
						: 'text-gray-600 hover:text-gray-900'}"
				>
					<Shield class="mr-2 inline h-4 w-4" />
					Security ({SECURITY_LOCATIONS.length})
				</button>
			</div>

			<!-- Content Area -->
			<div class="custom-scrollbar flex-1 overflow-y-auto" style="height: calc(100vh - 200px);">
				{#if activeTab === 'posts'}
					<div class="space-y-4 p-4">
						{#if sortedPosts.length === 0}
							<div class="py-12 text-center">
								<MessageSquare class="mx-auto mb-3 h-16 w-16 text-gray-300" />
								<p class="text-gray-400">No posts found</p>
			</div>
						{:else}
							{#each sortedPosts as post (post.id)}
								{@const style = categoryStyles[post.category]}
								{@const Icon = style.Icon}
								<div
									class="cursor-pointer rounded-2xl border-2 bg-white p-4 transition-all hover:shadow-lg {selectedPost?.id ===
									post.id
										? 'border-[#8F66FF] shadow-lg'
										: 'border-gray-200'}"
									on:click={() => flyToPost(post)}
								>
									<!-- Category Badge & Time -->
									<div class="mb-3 flex items-center justify-between">
										<div class="flex items-center gap-2">
											<div
												class="flex h-10 w-10 items-center justify-center rounded-full {style.bg}"
											>
												<Icon class="h-5 w-5 {style.text}" />
											</div>
											<div>
												<span class="text-xs font-bold {style.text} uppercase">
													{categoryDisplayNames[post.category]}
												</span>
												<div class="text-xs text-gray-500">
													{new Date(post.timestamp).toLocaleString('en-GB', {
														day: '2-digit',
														month: '2-digit',
														year: 'numeric',
														hour: '2-digit',
														minute: '2-digit'
													})}
												</div>
											</div>
										</div>
									</div>

									<!-- Title & Description -->
									<h3 class="mb-1 text-base font-bold text-gray-900">{post.title}</h3>
									<p class="mb-3 text-sm text-gray-600">{post.description}</p>

									{#if post.photoUrl}
										<img
											src={post.photoUrl}
											alt="Post"
											class="mb-3 h-32 w-full rounded-lg object-cover"
										/>
									{/if}

									<!-- Reporter Info -->
									<div class="mb-3 text-xs text-gray-500">
										Reported by <span class="font-semibold">{post.reporter.name}</span>
										<span class="mx-1">•</span>
										{timeAgo(post.timestamp)}
									</div>

									<!-- Like/Dislike Buttons -->
									<div class="mb-3 flex items-center justify-between">
										<div class="flex items-center gap-3">
											<button
												class="rounded-full p-2 transition-colors hover:bg-green-50"
												on:click={(e) => {
													e.stopPropagation();
													post.likes += 1;
													showSuccess('Liked post');
												}}
											>
												<svg
													xmlns="http://www.w3.org/2000/svg"
													width="18"
													height="18"
													viewBox="0 0 24 24"
													fill="none"
													stroke="currentColor"
													stroke-width="2"
													stroke-linecap="round"
													stroke-linejoin="round"
													class="text-gray-600"
												>
													<path d="M7 10v12" />
													<path
														d="M15 5.88 14 10h5.83a2 2 0 0 1 1.92 2.56l-2.33 8A2 2 0 0 1 17.5 22H4a2 2 0 0 1-2-2v-8a2 2 0 0 1 2-2h2.76a2 2 0 0 0 1.79-1.11L12 2h0a3.13 3.13 0 0 1 3 3.88Z"
													/>
												</svg>
											</button>
											<span class="text-sm font-semibold text-gray-700">{post.likes}</span>

											<button
												class="rounded-full p-2 transition-colors hover:bg-red-50"
												on:click={(e) => {
													e.stopPropagation();
													post.dislikes += 1;
													showSuccess('Disliked post');
												}}
											>
												<svg
													xmlns="http://www.w3.org/2000/svg"
													width="18"
													height="18"
													viewBox="0 0 24 24"
													fill="none"
													stroke="currentColor"
													stroke-width="2"
													stroke-linecap="round"
													stroke-linejoin="round"
													class="text-gray-600"
												>
													<path d="M17 14V2" />
													<path
														d="M9 18.12 10 14H4.17a2 2 0 0 1-1.92-2.56l2.33-8A2 2 0 0 1 6.5 2H20a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2h-2.76a2 2 0 0 0-1.79 1.11L12 22h0a3.13 3.13 0 0 1-3-3.88Z"
													/>
												</svg>
											</button>
											<span class="text-sm font-semibold text-gray-700">{post.dislikes}</span>
										</div>
									</div>

									<!-- Action Buttons -->
									<div class="flex gap-2">
										<button
											on:click={(e) => {
												e.stopPropagation();
												handleDeletePost(post.id);
											}}
											class="flex-1 rounded-lg border border-red-300 bg-white px-4 py-2 text-sm font-semibold text-red-600 transition hover:bg-red-50"
										>
											Delete
										</button>
										<button
											on:click={(e) => {
												e.stopPropagation();
												flyToPost(post);
											}}
											class="flex-1 rounded-lg bg-[#8F66FF] px-4 py-2 text-sm font-semibold text-white transition hover:bg-[#7a52e0]"
										>
											View on Map
										</button>
									</div>
								</div>
							{/each}
						{/if}
					</div>
				{/if}

				{#if activeTab === 'security'}
					<div class="space-y-4 p-4">
						{#each SECURITY_LOCATIONS as location (location.id)}
							<div
								class="cursor-pointer rounded-2xl border-2 bg-white p-4 transition-all hover:shadow-lg {selectedLocation?.id ===
								location.id
									? 'border-blue-500 shadow-lg'
									: 'border-gray-200'}"
								on:click={() => flyToLocation(location)}
							>
								<div class="flex items-start gap-3">
									<div
										class="flex h-10 w-10 flex-shrink-0 items-center justify-center rounded-full bg-blue-100"
									>
										<Shield class="h-5 w-5 text-blue-600" />
									</div>
									<div class="flex-1">
										<h4 class="font-bold text-gray-900">{location.name}</h4>
										<p class="mt-1 text-xs text-gray-500">Station #{location.id}</p>
										<p class="mt-1 text-xs text-gray-400">
											📍 {location.lat.toFixed(5)}, {location.lng.toFixed(5)}
										</p>
									</div>
								</div>
							</div>
						{/each}
					</div>
				{/if}
			</div>
		</div>
	{/if}

	<!-- User View Interface -->
	{#if viewMode === 'user'}
		<!-- Show UI only when NOT in pin placement mode -->
		{#if !selectedCategory && !isDrawingLine && !showDetailForm}
			<!-- Filter Sidebar -->
			{#if isFilterSidebarOpen}
				<FilterSidebar bind:filters={filterState} on:close={() => (isFilterSidebarOpen = false)} />
			{/if}

			<!-- Pin Category Panel (Desktop) -->
			{#if !isMobile}
				<div class="absolute left-4 z-40" style="top: max(5rem, calc(5rem + env(safe-area-inset-top)));">
					<PinCategoryPanel
						on:selectPinCategory={(e) => handleCategorySelection(e.detail)}
						on:showOptions={(e) => onShowOptions(e)}
						on:sendHelp={() => {
							showSendHelpModal = true;
						}}
					/>
				</div>
			{/if}

			<!-- Mobile Add Button -->
			{#if isMobile}
				<button
					class="fixed z-50 flex h-16 w-16 items-center justify-center rounded-full bg-[#8F66FF] text-4xl text-white shadow-xl transition-all duration-150 hover:bg-[#7a52e0] active:scale-95"
					style="bottom: max(3rem, calc(3rem + env(safe-area-inset-bottom))); right: max(1rem, env(safe-area-inset-right));"
					on:click={() => (isMobileCategorySheetOpen = true)}
					title="Add Pin"
				>
					+
				</button>
			{/if}
		{/if}

		<!-- Mobile Category Sheet -->
		{#if isMobileCategorySheetOpen}
			<MobileCategorySheet
				on:close={() => (isMobileCategorySheetOpen = false)}
				on:select={handleMobileCategorySelect}
				on:showOptions={onShowOptions}
			/>
		{/if}

		<!-- Point or Line Modal -->
		{#if isPointOrLineModalOpen}
			<PointOrLineModal
				on:close={() => (isPointOrLineModalOpen = false)}
				on:selectPoint={onSelectPoint}
				on:selectLine={onSelectLine}
				bind:title={modalConfig.title}
				bind:pointOption={modalConfig.pointOption}
				bind:lineOption={modalConfig.lineOption}
			/>
		{/if}

		<!-- Send Help Modal -->
		{#if showSendHelpModal}
			<SendHelpConfirmModal on:confirm={handleSendHelpConfirm} on:close={handleSendHelpClose} />
		{/if}

		<!-- Crosshair when placing pin -->
		{#if selectedCategory && !showDetailForm && !isDrawingLine}
			<div
				class="pointer-events-none absolute top-1/2 left-1/2 z-10 -translate-x-1/2 -translate-y-1/2"
			>
				<svg class="h-12 w-12 drop-shadow-lg" viewBox="0 0 24 24" fill="#FF494C">
					<path
						d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5S10.62 6.5 12 6.5s2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z"
					/>
					<circle cx="12" cy="8.5" r="2.5" fill="white" />
				</svg>
			</div>

			<div
				class="pointer-events-none absolute top-4 right-4 left-4 z-30 flex justify-center"
				style="padding-top: max(1rem, env(safe-area-inset-top)); padding-left: max(1rem, env(safe-area-inset-left)); padding-right: max(1rem, env(safe-area-inset-right));"
			>
				<div class="flex items-center gap-2 rounded-full bg-white px-4 py-2 shadow-md">
					<span class="font-medium">Create post:</span>
					<span class="font-bold {currentStyle.text}">
						{categoryDisplayNames[selectedCategory] || selectedCategory}
					</span>
				</div>
			</div>

			<div
				class="absolute z-[100] flex justify-center gap-3"
				style="bottom: max(1.5rem, calc(1.5rem + env(safe-area-inset-bottom))); left: 0; right: 0; padding-left: max(1rem, env(safe-area-inset-left)); padding-right: max(1rem, env(safe-area-inset-right));"
			>
				<button
					on:click={cancelPinning}
					class="btn-clickable rounded-full bg-white text-black shadow-md {isMobile
						? 'max-w-[45%] flex-1'
						: 'w-48'} px-6 py-3 font-medium"
				>
					Cancel
				</button>
				<button
					on:click={goToNextStep}
					class="btn-clickable rounded-full bg-[#8F66FF] text-white shadow-md {isMobile
						? 'max-w-[45%] flex-1'
						: 'w-48'} px-6 py-3 font-medium"
				>
					Next
				</button>
			</div>
		{/if}

		<!-- Drawing line indicator -->
		{#if isDrawingLine}
			<div
				class="pointer-events-none absolute top-4 right-4 left-4 z-30 flex justify-center"
				style="padding-top: max(1rem, env(safe-area-inset-top)); padding-left: max(1rem, env(safe-area-inset-left)); padding-right: max(1rem, env(safe-area-inset-right));"
			>
				<div
					class="flex w-full max-w-md items-center justify-between gap-3 rounded-full bg-white px-4 py-2 shadow-md"
				>
					{#if drawingLineCategory === 'blocked-line'}
						<span class="font-medium text-gray-800">Drawing Road Closure...</span>
						<span class="text-sm font-bold whitespace-nowrap text-orange-600"
							>(Click to add points)</span
						>
					{:else}
						<span class="font-medium text-gray-800">Drawing Traffic Jam...</span>
						<span class="text-sm font-bold whitespace-nowrap text-red-600"
							>(Click to add points)</span
						>
					{/if}
				</div>
			</div>

			<div
				class="absolute z-[100] flex justify-center gap-3"
				style="bottom: max(1.5rem, calc(1.5rem + env(safe-area-inset-bottom))); left: 0; right: 0; padding-left: max(1rem, env(safe-area-inset-left)); padding-right: max(1rem, env(safe-area-inset-right));"
			>
				<button
					on:click={cancelPinning}
					class="btn-clickable rounded-full bg-white text-black shadow-md {isMobile
						? 'max-w-[45%] flex-1'
						: 'w-48'} px-6 py-3 font-medium"
				>
					Cancel
				</button>
				<button
					on:click={submitLineDrawing}
					class="btn-clickable rounded-full bg-[#8F66FF] text-white shadow-md {isMobile
						? 'max-w-[45%] flex-1'
						: 'w-48'} px-6 py-3 font-medium"
				>
					Finish Drawing
				</button>
			</div>
		{/if}

		<!-- Pin Detail Form -->
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
	{/if}

	<!-- Logo -->
	<img
		src="/logo.svg"
		alt="Logo"
		class="absolute z-30 h-8"
		style="bottom: max(1rem, env(safe-area-inset-bottom)); left: max(1rem, env(safe-area-inset-left));"
	/>
</div>

<style>
	.font-kanit {
		font-family: 'Kanit', sans-serif;
	}

	:global(.cmu-popup .maplibregl-popup-content) {
		border-radius: 12px;
		padding: 8px 12px;
		box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
		border: 1px solid #eee;
		max-width: 280px;
	}

	:global(.cmu-popup .maplibregl-popup-tip) {
		display: none;
	}

	.custom-scrollbar::-webkit-scrollbar {
		width: 6px;
	}

	.custom-scrollbar::-webkit-scrollbar-track {
		background: transparent;
	}

	.custom-scrollbar::-webkit-scrollbar-thumb {
		background: #d1d5db;
		border-radius: 10px;
	}

	.custom-scrollbar::-webkit-scrollbar-thumb:hover {
		background: #9ca3af;
	}

	.scrollbar-hide::-webkit-scrollbar {
		display: none;
	}

	.scrollbar-hide {
		-ms-overflow-style: none;
		scrollbar-width: none;
	}

	.safe-top {
		padding-top: max(1rem, env(safe-area-inset-top));
		padding-left: max(1rem, env(safe-area-inset-left));
		padding-right: max(1rem, env(safe-area-inset-right));
	}

	.bottom-38 {
		bottom: 9.5rem;
	}

	/* Mobile adjustments */
	@media (max-width: 768px) {
		.safe-top {
			padding-top: max(0.5rem, env(safe-area-inset-top));
			padding-left: max(0.75rem, env(safe-area-inset-left));
			padding-right: max(0.75rem, env(safe-area-inset-right));
		}
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

	@keyframes slide-down {
		from {
			transform: translateY(-100%) translateX(-50%);
			opacity: 0;
		}
		to {
			transform: translateY(0) translateX(-50%);
			opacity: 1;
		}
	}

	.animate-slide-down {
		animation: slide-down 0.3s ease-out;
	}
</style>