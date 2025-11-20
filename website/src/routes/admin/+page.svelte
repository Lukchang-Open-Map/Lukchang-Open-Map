<script>
	import { onMount, mount } from 'svelte';
	import { fade, fly } from 'svelte/transition';
	import { userStore } from '$lib/stores/userStore.js';

	// Components
	import BaseMap from '$lib/component/map/BaseMap.svelte';
	import Navbar from '$lib/component/layout/Navbar.svelte';
	import CustomMarker from '$lib/component/map/CustomMarker.svelte';

	// Admin Components
	import {
		MessageSquare,
		Shield,
		Trash2,
		Search,
		ChevronLeft,
		ThumbsUp,
		ThumbsDown,
		CheckCircle,
		Filter
	} from 'lucide-svelte';

	// User View Components
	import PinCategoryPanel from '$lib/component/map/PinCategoryPanel.svelte';
	import PinDetailForm from '$lib/component/common/PinDetailForm.svelte';
	import MobileCategorySheet from '$lib/component/map/MobileCategorySheet.svelte';
	import SendHelpConfirmModal from '$lib/component/common/SendHelpConfirmModal.svelte';
	import FilterSidebar from '$lib/component/map/FilterSidebar.svelte';
	import PointOrLineModal from '$lib/component/common/PointOrLineModal.svelte';
	import { Crosshair, Loader2 } from 'lucide-svelte';

	// Config & Utils
	import {
		CATEGORY_STYLES,
		CATEGORY_DISPLAY_NAMES,
		BLOCKED_MODAL_CONFIG
	} from '$lib/constant/map-config.js';
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

	import { supabase } from '$lib/supabaseClient';

	// ... existing imports ...

	// --- ADMIN STATE ---
	let posts = [];
	let activeTab = 'posts';
	let isSidebarOpen = true;
	let selectedPost = null;
	let searchQuery = '';
	let activeFilter = 'All';
	const filters = ['All', 'Accident/Hazard', 'Blocked', 'Flood'];
	let securityZones = []; // Renamed from SECURITY_LOCATIONS to be dynamic
	let categoriesDB = [];

	// --- MISSING STATE RESTORED ---
	let modalConfig = {};
	let isPointOrLineModalOpen = false;
	let isDrawingLine = false;
	let drawingLineCategory = '';
	let currentLinePoints = [];
	let lineVertexMarkers = [];
	let showToast = false;
	let toastMessage = '';
	let isMobileCategorySheetOpen = false;
	let showSendHelpModal = false;
	let isFilterSidebarOpen = false;
	let pinCoordinates = null;
	let showDetailForm = false;
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

	$: filteredPosts = posts.filter((post) => {
		const matchesSearch =
			post.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
			post.description.toLowerCase().includes(searchQuery.toLowerCase()) ||
			post.reporter.name.toLowerCase().includes(searchQuery.toLowerCase());
		const matchesFilter =
			activeFilter === 'All' ||
			(activeFilter === 'Accident/Hazard' && post.category === 'accident') ||
			(activeFilter === 'Blocked' && post.category === 'blocked') ||
			(activeFilter === 'Flood' && post.category === 'flood');
		return matchesSearch && matchesFilter;
	});

	// ... existing code ...

	onMount(async () => {
		initializeMapInteractions();
		isMobile = window.innerWidth < 768;

		await fetchReportsAndDraw();
		await fetchSecurityZones();
		await fetchCategories();
	});

	async function fetchCategories() {
		const { data, error } = await supabase.from('report_categories').select('*');
		if (data) {
			categoriesDB = data;
		} else {
			console.error('Error fetching categories:', error);
		}
	}

	async function fetchReportsAndDraw() {
		const { data, error } = await supabase
			.from('reports')
			.select(
				`
				*,
				category:report_categories(name, icon),
				reporter:profiles!created_by_user_id(full_name),
				votes:report_verifications(vote)
			`
			)
			.order('created_at', { ascending: false });

		if (data) {
			posts = data
				.map((post) => {
					// Handle different geometry types
					let coordinates;
					if (post.geometry.type === 'Point') {
						coordinates = {
							lng: post.geometry.coordinates[0],
							lat: post.geometry.coordinates[1]
						};
					} else if (post.geometry.type === 'LineString') {
						// Use first point of the line for marker position
						coordinates = {
							lng: post.geometry.coordinates[0][0],
							lat: post.geometry.coordinates[0][1]
						};
					} else {
						// Fallback for unknown geometry types
						console.warn(`Unknown geometry type: ${post.geometry.type}`, post);
						return null;
					}

					return {
						id: post.id,
						category: post.category?.name || 'general',
						title: post.title,
						description: post.description,
						coordinates: coordinates,
						reporter: {
							name: post.is_anonymous ? 'Anonymous' : post.reporter?.full_name || 'Unknown'
						},
						timestamp: post.created_at,
						likes: post.votes?.filter((v) => v.vote === 1).length || 0,
						dislikes: post.votes?.filter((v) => v.vote === -1).length || 0,
						photoUrl: post.photo_url,
						geometryType: post.geometry.type // Store for reference
					};
				})
				.filter((post) => post !== null); // Remove any null entries from unknown geometry types

			// Fetch photos for posts
			for (let post of posts) {
				const { data: photoData } = await supabase
					.from('report_photos')
					.select('storage_path')
					.eq('report_id', post.id)
					.single();

				if (photoData) {
					const { data: publicUrlData } = supabase.storage
						.from('report-photos')
						.getPublicUrl(photoData.storage_path);
					post.photoPreviewUrl = publicUrlData.publicUrl;
				}
			}
			$: filteredPosts = posts.filter((post) => {
				const matchesSearch =
					post.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
					post.description.toLowerCase().includes(searchQuery.toLowerCase()) ||
					post.reporter.name.toLowerCase().includes(searchQuery.toLowerCase());

				// Admin sidebar filter
				const matchesAdminFilter =
					activeFilter === 'All' ||
					(activeFilter === 'Accident/Hazard' && post.category === 'accident') ||
					(activeFilter === 'Blocked' && post.category === 'blocked') ||
					(activeFilter === 'Flood' && post.category === 'flood');

				// User view filter (using filterState)
				let matchesUserFilter = true;
				if (viewMode === 'user') {
					// Map post categories to filterState keys
					// Note: 'traffic' in post.category maps to 'traffic_general' in filterState
					const filterKey = post.category === 'traffic' ? 'traffic_general' : post.category;

					// Check if the category exists in filterState and is enabled
					// If category not in filterState (e.g. 'general'), default to true or handle as needed
					if (filterKey in filterState) {
						matchesUserFilter = filterState[filterKey];
					}
				}

				return matchesSearch && matchesAdminFilter && matchesUserFilter;
			});

			// Update markers when filteredPosts changes
			$: {
				if (mapInstance && filteredPosts) {
					updateMarkers();
				}
			}
		} else {
			console.error('Error fetching reports:', error);
		}
	}

	async function fetchSecurityZones() {
		const { data, error } = await supabase.from('security_zones').select('*').eq('is_active', true);

		if (data) {
			securityZones = data.map((zone) => ({
				id: zone.id,
				name: zone.name,
				// Use centroid or first point for marker if it's a polygon,
				// but for now let's assume we want to show a marker at a representative point.
				// Since we don't have a center point in DB, we'll calculate a simple center from geometry
				lng: zone.geometry.coordinates[0][0][0],
				lat: zone.geometry.coordinates[0][0][1]
			}));
			updateSecurityMarkers();
		} else {
			console.error('Error fetching security zones:', error);
		}
	}

	// --- HELPER FUNCTIONS ---
	function getCategoryBg(category) {
		return CATEGORY_STYLES[category]?.bg || 'bg-gray-100';
	}

	function getCategoryColor(category) {
		return CATEGORY_STYLES[category]?.text || 'text-gray-600';
	}

	function flyToPost(post) {
		if (!mapInstance) return;
		mapInstance.flyTo({ center: [post.coordinates.lng, post.coordinates.lat], zoom: 16 });
		selectedPost = post;
		isSidebarOpen = false;
	}

	function flyToSecurity(zone) {
		if (!mapInstance) return;
		mapInstance.flyTo({ center: [zone.lng, zone.lat], zoom: 16 });
		isSidebarOpen = false;
	}

	function updateMarkers() {
		if (!mapInstance) return;

		// Clear existing markers
		Object.values(markers).forEach((marker) => marker.remove());
		markers = {};

		// Use filteredPosts instead of posts to respect filters
		filteredPosts.forEach((post) => {
			const el = document.createElement('div');
			mount(CustomMarker, { target: el, props: { category: post.category } });

			const imageHTML = post.photoPreviewUrl
				? `<div style="width: 100%; height: 140px; background-image: url('${post.photoPreviewUrl}'); background-size: cover; background-position: center; border-radius: 12px; margin-bottom: 12px;"></div>`
				: '';

			const popupHTML = `
                <div style="font-family: 'Kanit', sans-serif; min-width: 200px; padding: 4px;">
                    ${imageHTML}
                    <h3 style="font-size: 20px; font-weight: 400; color: #000; margin: 0 0 12px 0; line-height: 1.2;">${post.title}</h3>
                    <div style="display: flex; justify-content: space-between; align-items: flex-end;">
                        <div style="font-size: 13px; line-height: 1.4; color: #6B7280;">
                            <span>report by</span><br><span style="color: #1F2937; font-weight: 700;">${post.reporter.name}</span><br><span>${timeAgo(post.timestamp)}</span>
                        </div>
                    </div>
                </div>`;

			const popup = new maplibreglInstance.Popup({
				offset: 35,
				className: 'cmu-popup',
				closeButton: false,
				maxWidth: '300px'
			}).setHTML(popupHTML);

			const marker = new maplibreglInstance.Marker({ element: el, anchor: 'bottom' })
				.setLngLat([post.coordinates.lng, post.coordinates.lat])
				.setPopup(popup)
				.addTo(mapInstance);

			markers[post.id] = marker;
		});
	}

	function handleMapLoad({ detail }) {
		mapInstance = detail.map;
		maplibreglInstance = detail.maplibregl;

		// Setup Sources for User Drawing
		mapInstance.addSource('temp-line-source', {
			type: 'geojson',
			data: { type: 'Feature', geometry: { type: 'LineString', coordinates: [] } }
		});
		mapInstance.addLayer({
			id: 'temp-line-layer',
			type: 'line',
			source: 'temp-line-source',
			paint: { 'line-color': '#F97316', 'line-width': 5, 'line-dasharray': [2, 2] }
		});

		// Initial draw
		updateMarkers();
		updateSecurityMarkers();
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
				const marker = new maplibreglInstance.Marker({ element: el })
					.setLngLat(coords)
					.addTo(mapInstance);
				lineVertexMarkers.push(marker);
			}
		}
	}

	// --- SECURITY MARKERS ---
	function updateSecurityMarkers() {
		if (!mapInstance) return;

		securityMarkers.forEach((marker) => marker.remove());
		securityMarkers = [];

		securityZones.forEach((location) => {
			const el = document.createElement('div');
			// ใช้ icon ยาม (Security Icon)
			el.innerHTML = `<div class="w-10 h-10 bg-white rounded-full shadow-md flex items-center justify-center border-2 border-purple-200 p-1"><img src="/security.svg" alt="Security" class="w-full h-full object-contain" /></div>`;

			const popup = new maplibreglInstance.Popup({
				offset: 25,
				className: 'cmu-popup',
				closeButton: false
			}).setHTML(`
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

	// ... existing code ...

	async function deletePost(id) {
		console.log('Attempting to delete post:', id);
		if (!confirm('Are you sure you want to delete this post?')) return;

		const { error } = await supabase.from('reports').delete().eq('id', id);

		if (error) {
			console.error('Error deleting post:', error);
			alert('Failed to delete post: ' + error.message);
			return;
		}

		console.log('Post deleted successfully:', id);

		if (markers[id]) {
			markers[id].remove();
			delete markers[id];
		}
		posts = posts.filter((p) => p.id !== id);
		notificationMessage = 'Post deleted successfully';
		showNotification = true;
		setTimeout(() => (showNotification = false), 3000);
	}

	// ... existing code ...

	async function handlePinSubmit(e) {
		const formData = e.detail;

		// Upload photo if exists
		let uploadedPhotoPath = null;
		if (formData.photoFile) {
			const fileName = `${Date.now()}_${Math.random().toString(36).substring(2)}.jpg`;
			const { data: uploadData, error: uploadError } = await supabase.storage
				.from('report-photos')
				.upload(fileName, formData.photoFile);

			if (uploadError) {
				console.error('Upload failed', uploadError);
				return alert('Photo upload failed');
			}
			uploadedPhotoPath = uploadData.path;
		}

		// Get category ID
		const { data: categoryData } = await supabase
			.from('report_categories')
			.select('id')
			.eq('name', formData.category)
			.single();

		if (!categoryData) return alert('Category not found');

		const { data: reportData, error: reportError } = await supabase
			.from('reports')
			.insert({
				created_by_user_id: $userStore.id,
				category_id: categoryData.id,
				title: formData.title,
				description: formData.description,
				geometry: {
					type: 'Point',
					coordinates: [formData.coordinates.lng, formData.coordinates.lat]
				},
				status: 'pending',
				is_anonymous: false,
				visibility: formData.visibility || 'public'
			})
			.select()
			.single();

		if (reportError) {
			console.error('Insert report failed', reportError);
			toastMessage = 'Failed to submit report';
		} else {
			if (uploadedPhotoPath) {
				await supabase.from('report_photos').insert({
					report_id: reportData.id,
					storage_path: uploadedPhotoPath
				});
			}

			if (formData.visibility === 'public') {
				// Refresh posts
				await fetchReportsAndDraw();
				toastMessage = 'Post published on map';
			} else {
				toastMessage = 'Report sent to security staff';
			}
		}

		showDetailForm = false;
		selectedCategory = null;
		showToast = true;
		setTimeout(() => (showToast = false), 3000);
	}

	import { getUserLocation } from '$lib/utils/geolocation.js';

	// --- USER VIEW FUNCTIONS ---
	function handleNextStep() {
		const center = mapInstance.getCenter();
		pinCoordinates = { lng: center.lng, lat: center.lat };
		showDetailForm = true;
	}

	function handleCategorySelect(e) {
		const category = e.detail;
		if (category === 'blocked') {
			modalConfig = BLOCKED_MODAL_CONFIG;
			isPointOrLineModalOpen = true;
		} else if (category === 'traffic_general') {
			isPointOrLineModalOpen = false;
			isDrawingLine = true;
			drawingLineCategory = 'traffic_general-line';
			currentLinePoints = [];
			mapInstance.getCanvas().style.cursor = 'crosshair';
			if (mapInstance.getLayer('temp-line-layer'))
				mapInstance.setPaintProperty('temp-line-layer', 'line-color', '#EF4444');
		} else {
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
		lineVertexMarkers.forEach((m) => m.remove());
		lineVertexMarkers = [];
		if (mapInstance) {
			mapInstance.getCanvas().style.cursor = '';
			updateTempLine();
		}
	}

	function updateTempLine() {
		mapInstance.getSource('temp-line-source').setData({
			type: 'Feature',
			geometry: { type: 'LineString', coordinates: currentLinePoints }
		});
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

	async function finishLineDrawing() {
		if (currentLinePoints.length < 2) {
			alert('Click map to draw points');
			return;
		}
		addPermanentLineToMap(currentLinePoints, drawingLineCategory);

		const newPost = {
			id: generateUUID(),
			category: drawingLineCategory.includes('traffic') ? 'traffic_general' : 'blocked',
			coordinates: { lng: currentLinePoints[0][0], lat: currentLinePoints[0][1] },
			title: drawingLineCategory.includes('traffic') ? 'Traffic Jam' : 'Road Off / Closed',
			description: 'Reported line area by Admin',
			reporter: { name: 'Admin' },
			timestamp: new Date().toISOString(),
			likes: 0,
			dislikes: 0
		};
		posts = [newPost, ...posts];
		addMarker(newPost);

		toastMessage = 'Route reported';
		showToast = true;
		setTimeout(() => (showToast = false), 3000);
		cancelAll();
	}

	let isLocating = false;

	async function findUserLocation() {
		isLocating = true;
		try {
			const { latitude, longitude } = await getUserLocation();
			new maplibreglInstance.Marker({ color: '#8F66FF' })
				.setLngLat([longitude, latitude])
				.addTo(mapInstance);
			mapInstance.flyTo({ center: [longitude, latitude], zoom: 16 });
		} catch (error) {
			alert(error.message);
		} finally {
			isLocating = false;
		}
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

<div class="font-kanit relative flex h-screen w-full overflow-hidden bg-white">
	<!-- ✅ TOGGLE BAR (Bottom Right - moved to avoid category panel overlap) -->
	<div
		class="absolute right-4 bottom-4 z-50 flex items-center gap-1 rounded-xl border border-gray-100 bg-white p-1 shadow-md"
	>
		<button
			class="rounded-lg px-4 py-2 text-sm font-bold transition-all {viewMode === 'admin'
				? 'bg-[#8F66FF] text-white shadow-sm'
				: 'text-gray-500 hover:bg-gray-50'}"
			on:click={() => switchView('admin')}
		>
			Admin
		</button>
		<button
			class="rounded-lg px-4 py-2 text-sm font-bold transition-all {viewMode === 'user'
				? 'bg-green-500 text-white shadow-sm'
				: 'text-gray-500 hover:bg-gray-50'}"
			on:click={() => switchView('user')}
		>
			User View
		</button>
	</div>

	<!-- Sidebar (Admin Only) -->
	{#if viewMode === 'admin'}
		<div
			class="absolute top-16 bottom-0 left-4 z-[60] w-full bg-white shadow-2xl transition-transform duration-300 md:w-[445px] {isSidebarOpen
				? 'translate-x-0'
				: '-translate-x-[110%]'} mb-4 flex flex-col overflow-hidden rounded-2xl border border-gray-100"
		>
			<div class="flex items-center justify-between px-5 pt-4 pb-2">
				<div class="flex items-center gap-2">
					<h2 class="text-2xl font-bold text-gray-900">Admin Management</h2>
					{#if posts.length > 0}
						<span
							class="flex h-6 w-6 items-center justify-center rounded-full bg-red-500 text-xs font-bold text-white"
							>{posts.length}</span
						>
					{/if}
				</div>
				<button
					on:click={() => (isSidebarOpen = false)}
					class="rounded-lg p-1.5 hover:bg-gray-100 md:hidden"
					><ChevronLeft class="h-5 w-5 text-gray-600" /></button
				>
			</div>

			<div class="px-5 pb-3">
				<div class="relative">
					<Search class="absolute top-1/2 left-3 h-4 w-4 -translate-y-1/2 text-gray-400" />
					<input
						type="text"
						placeholder="Search posts, users..."
						bind:value={searchQuery}
						class="w-full rounded-xl border border-gray-200 py-2.5 pr-4 pl-10 text-sm focus:ring-2 focus:ring-[#8F66FF] focus:outline-none"
					/>
				</div>
			</div>

			<div class="no-scrollbar overflow-x-auto border-b border-gray-100 px-5 pb-4">
				<div class="flex gap-2">
					{#each filters as filter}
						<button
							class="rounded-full border px-4 py-1.5 text-xs font-bold whitespace-nowrap transition-all {activeFilter ===
							filter
								? 'border-[#8F66FF] bg-[#8F66FF] text-white'
								: 'border-gray-200 bg-white text-gray-600 hover:border-[#8F66FF]'}"
							on:click={() => (activeFilter = filter)}
						>
							{filter}
						</button>
					{/each}
				</div>
			</div>

			<div class="flex border-b border-gray-200 bg-white">
				<button
					on:click={() => (activeTab = 'posts')}
					class="flex flex-1 items-center justify-center gap-2 px-4 py-3 text-sm font-bold transition {activeTab ===
					'posts'
						? 'border-b-2 border-[#8F66FF] text-[#8F66FF]'
						: 'text-gray-400 hover:text-gray-600'}"
				>
					<MessageSquare class="h-4 w-4" /> Posts ({filteredPosts.length})
				</button>
				<button
					on:click={() => (activeTab = 'security')}
					class="flex flex-1 items-center justify-center gap-2 px-4 py-3 text-sm font-bold transition {activeTab ===
					'security'
						? 'border-b-2 border-[#8F66FF] text-[#8F66FF]'
						: 'text-gray-400 hover:text-gray-600'}"
				>
					<Shield class="h-4 w-4" /> Security ({securityZones.length})
				</button>
			</div>

			<div class="custom-scrollbar flex-1 space-y-4 overflow-y-auto bg-gray-50 p-5">
				{#if activeTab === 'posts'}
					{#each filteredPosts as post}
						<!-- ... existing post card ... -->
						<div
							class="relative cursor-pointer overflow-hidden rounded-2xl border bg-white p-5 transition-all hover:shadow-md {selectedPost?.id ===
							post.id
								? 'border-[#8F66FF] ring-1 ring-purple-100'
								: 'border-gray-100'}"
							on:click={() => flyToPost(post)}
						>
							<!-- ... existing post content ... -->
							<div
								class="absolute top-0 bottom-0 left-0 w-1 {getCategoryBg(post.category).replace(
									'100',
									'500'
								)}"
							></div>
							<div class="mb-3 flex items-start gap-3 pl-2">
								<div
									class="flex h-10 w-10 items-center justify-center rounded-full {getCategoryBg(
										post.category
									)} shrink-0"
								>
									<svelte:component
										this={CATEGORY_STYLES[post.category]?.Icon || MessageSquare}
										class="h-5 w-5 {CATEGORY_STYLES[post.category]?.text || 'text-gray-500'}"
									/>
								</div>
								<div class="min-w-0 flex-1">
									<div class="mb-0.5 flex flex-wrap items-center gap-x-2">
										<span
											class="text-[10px] font-extrabold tracking-wide uppercase {getCategoryColor(
												post.category
											)}">{CATEGORY_DISPLAY_NAMES[post.category] || post.category}</span
										>
										<span class="text-[10px] text-gray-400">{timeAgo(post.timestamp)}</span>
									</div>
									<h3 class="text-base leading-tight font-bold text-gray-900">{post.title}</h3>
								</div>
							</div>
							<div class="flex gap-3 pl-2">
								<button
									class="flex-1 rounded-xl border border-red-200 bg-white py-2.5 text-sm font-bold tracking-wide text-red-500 uppercase transition-colors hover:bg-red-50"
									on:click|stopPropagation={() => deletePost(post.id)}>Delete</button
								>
								<button
									class="flex-1 rounded-xl bg-[#8F66FF] py-2.5 text-sm font-bold tracking-wide text-white uppercase transition-colors hover:bg-[#7a52e0]"
									on:click|stopPropagation={() => flyToPost(post)}>View</button
								>
							</div>
						</div>
					{/each}
				{:else}
					{#each securityZones as location}
						<div
							class="flex cursor-pointer items-center gap-3 rounded-2xl border border-gray-200 bg-white p-4 hover:bg-white hover:shadow-sm"
							on:click={() => flyToSecurity(location)}
						>
							<div
								class="flex h-12 w-12 items-center justify-center rounded-full border border-blue-100 bg-blue-50"
							>
								<!-- Security Icon -->
								<img src="/security.svg" alt="Security" class="h-8 w-8" />
							</div>
							<div>
								<h4 class="font-bold text-gray-800">{location.name}</h4>
								<p class="text-xs text-gray-500">Station #{location.id}</p>
							</div>
						</div>
					{/each}
				{/if}
			</div>
		</div>
	{/if}

	<!-- Map Area -->
	<div class="relative flex-1">
		<!-- Admin View Button to reopen sidebar -->
		{#if viewMode === 'admin' && !isSidebarOpen}
			<button
				class="absolute top-20 left-4 z-30 rounded-xl bg-white p-3 shadow-md"
				on:click={() => (isSidebarOpen = true)}><MessageSquare class="text-gray-600" /></button
			>
		{/if}

		<!-- Map -->
		<BaseMap on:load={handleMapLoad} on:click={handleMapClick} />

		<!-- User View UI (Overlays) -->
		{#if viewMode === 'user'}
			<!-- Add Navbar for user view to match real user experience -->
			{#if !selectedCategory && !isDrawingLine}
				<Navbar on:toggleSidebar={() => (isFilterSidebarOpen = true)} />
			{/if}

			<button
				class="absolute z-40 flex items-center justify-center rounded-full bg-white shadow-md hover:bg-gray-100 active:scale-95 {isMobile
					? 'right-4 bottom-32 h-12 w-12'
					: 'right-4 bottom-38 h-10 w-10'}"
				on:click={findUserLocation}
				title="Find my location"
				disabled={isLocating}
			>
				{#if isLocating}
					<Loader2 class="h-6 w-6 animate-spin text-[#8F66FF]" />
				{:else}
					<Crosshair class="h-6 w-6 text-gray-600" />
				{/if}
			</button>

			{#if !selectedCategory && !isDrawingLine}
				{#if isMobile}
					<button
						class="absolute right-4 bottom-8 z-40 flex h-16 w-16 items-center justify-center rounded-full bg-[#8F66FF] text-3xl text-white shadow-xl"
						on:click={() => (isMobileCategorySheetOpen = true)}>+</button
					>
				{:else}
					<PinCategoryPanel
						on:select={(e) => (selectedCategory = e.detail)}
						on:sendHelp={() => (showSendHelpModal = true)}
						on:showOptions={handleCategorySelect}
					/>
				{/if}

				<!-- Filter Sidebar Button for User -->
				<button
					class="absolute top-20 right-4 z-40 flex items-center justify-center rounded-xl bg-white p-3 shadow-md hover:bg-gray-100"
					on:click={() => (isFilterSidebarOpen = true)}
				>
					<Filter class="h-6 w-6 text-gray-600" />
				</button>
			{/if}

			{#if selectedCategory && !showDetailForm && !isDrawingLine}
				<div class="pointer-events-none absolute top-20 right-0 left-0 z-30 flex justify-center">
					<div
						class="flex items-center gap-2 rounded-full border border-gray-100 bg-white px-6 py-3 shadow-lg"
					>
						<span class="text-sm font-medium text-gray-600">Create post:</span><span
							class="text-sm font-bold text-[#8F66FF] uppercase"
							>{CATEGORY_DISPLAY_NAMES[selectedCategory]}</span
						>
					</div>
				</div>
				<div
					class="pointer-events-none absolute top-1/2 left-1/2 z-10 -translate-x-1/2 -translate-y-full pb-1 drop-shadow-xl"
				>
					<svg width="48" height="48" viewBox="0 0 24 24" fill="none"
						><path
							d="M12 0C7.58 0 4 3.58 4 8C4 13.5 12 24 12 24C12 24 20 13.5 20 8C20 3.58 16.42 0 12 0Z"
							fill="#EF4444"
						/><circle cx="12" cy="8" r="3.5" fill="white" /></svg
					>
				</div>
				<div class="absolute right-0 bottom-8 left-0 z-50 flex justify-center gap-4 px-4">
					<button
						class="btn w-32 rounded-full bg-white px-8 font-bold text-gray-700 shadow-lg"
						on:click={cancelAll}>Cancel</button
					><button
						class="btn w-32 rounded-full bg-[#8F66FF] px-8 font-bold text-white shadow-lg"
						on:click={handleNextStep}>Next</button
					>
				</div>
			{/if}

			{#if isDrawingLine}
				<div class="pointer-events-none absolute top-20 right-0 left-0 z-30 flex justify-center">
					<div class="rounded-full border border-gray-100 bg-white px-6 py-3 shadow-lg">
						<span class="text-sm font-bold text-orange-600">Drawing {drawingLineCategory}</span>
					</div>
				</div>
				<div class="absolute right-0 bottom-8 left-0 z-50 flex justify-center gap-4 px-4">
					<button class="btn rounded-full bg-white px-8 text-black shadow-lg" on:click={cancelAll}
						>Cancel</button
					><button
						class="btn rounded-full bg-[#8F66FF] px-8 text-white shadow-lg"
						on:click={finishLineDrawing}>Finish</button
					>
				</div>
			{/if}

			<!-- Modals -->
			{#if showDetailForm}
				<PinDetailForm
					{isMobile}
					category={selectedCategory}
					coordinates={pinCoordinates}
					on:close={() => (showDetailForm = false)}
					on:submit={handlePinSubmit}
				/>
			{/if}
			{#if isMobileCategorySheetOpen}
				<MobileCategorySheet
					on:close={() => (isMobileCategorySheetOpen = false)}
					on:select={(e) => {
						isMobileCategorySheetOpen = false;
						selectedCategory = e.detail;
					}}
					on:showOptions={handleCategorySelect}
				/>
			{/if}
			{#if showSendHelpModal}
				<SendHelpConfirmModal
					on:close={() => (showSendHelpModal = false)}
					on:confirm={() => {
						showSendHelpModal = false;
						alert('Alert Sent!');
					}}
				/>
			{/if}
			{#if isFilterSidebarOpen}
				<FilterSidebar bind:filters={filterState} on:close={() => (isFilterSidebarOpen = false)} />
			{/if}
			{#if isPointOrLineModalOpen}
				<PointOrLineModal
					on:close={() => (isPointOrLineModalOpen = false)}
					on:selectPoint={() => {
						isPointOrLineModalOpen = false;
						selectedCategory = 'blocked';
					}}
					on:selectLine={startLineDrawing}
				/>
			{/if}
		{/if}
	</div>

	<!-- Notifications -->
	{#if showNotification}<div
			class="fixed top-20 left-1/2 z-50 flex -translate-x-1/2 animate-bounce items-center gap-3 rounded-full bg-[#10B981] px-6 py-3 text-white shadow-xl"
		>
			<CheckCircle class="h-5 w-5" /> <span class="font-bold">{notificationMessage}</span>
		</div>{/if}
	{#if showToast}<div
			class="pointer-events-none absolute top-20 right-0 left-0 z-50 flex justify-center"
		>
			<div
				class="flex animate-bounce items-center gap-2 rounded-full border border-gray-200 bg-white px-6 py-3 shadow-lg"
			>
				<span class="font-bold text-green-600">{toastMessage}</span>
			</div>
		</div>{/if}
</div>

<style>
	:global(.cmu-popup .maplibregl-popup-content) {
		border-radius: 16px !important;
		padding: 0 !important;
		box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.1);
		border: none;
		overflow: hidden;
	}
	:global(.cmu-popup .maplibregl-popup-tip) {
		display: none !important;
	}
	.custom-scrollbar::-webkit-scrollbar {
		width: 4px;
	}
	.custom-scrollbar::-webkit-scrollbar-track {
		background: transparent;
	}
	.custom-scrollbar::-webkit-scrollbar-thumb {
		background: #e5e7eb;
		border-radius: 20px;
	}
	.no-scrollbar::-webkit-scrollbar {
		display: none;
	}
</style>
