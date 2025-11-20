<script>
	import { onMount, onDestroy, mount } from 'svelte';
	// ... imports ...

	// ... inside script ...

	import { fade, fly } from 'svelte/transition';
	import { userStore } from '$lib/stores/userStore.js';
	import { goto } from '$app/navigation';
	import { supabase } from '$lib/supabaseClient';

	// Components
	import BaseMap from '$lib/component/map/BaseMap.svelte';
	import Navbar from '$lib/component/layout/Navbar.svelte';
	import CustomMarker from '$lib/component/map/CustomMarker.svelte';
	import PinCategoryPanel from '$lib/component/map/PinCategoryPanel.svelte';
	import PinDetailForm from '$lib/component/common/PinDetailForm.svelte';
	import MobileCategorySheet from '$lib/component/map/MobileCategorySheet.svelte';
	import SendHelpConfirmModal from '$lib/component/common/SendHelpConfirmModal.svelte';
	import FilterSidebar from '$lib/component/map/FilterSidebar.svelte';
	import PointOrLineModal from '$lib/component/common/PointOrLineModal.svelte';

	// Icons & Config
	import { Crosshair } from 'lucide-svelte';
	import { CATEGORY_DISPLAY_NAMES, BLOCKED_MODAL_CONFIG } from '$lib/constant/map-config.js';
	import { timeAgo } from '$lib/utils/formatting.js';
	import { initializeMapInteractions } from '$lib/utils/map-interactions.js';
	import { distance, point } from '@turf/turf';

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
	let nearestSecurityDistance = null;

	// --- เติมบรรทัดนี้เข้าไปครับ ---
	let modalConfig = {};
	// Data State (Real Data)
	let categoriesDB = [];
	let securityZonesDB = [];
	let mapMarkers = [];
	let layersIds = [];

	// Filter State
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

	// Line Drawing State
	let isDrawingLine = false;
	let drawingLineCategory = '';
	let currentLinePoints = [];
	let lineVertexMarkers = [];
	let showToast = false;
	let toastMessage = '';

	// Security Zone State
	let showSecurityZone = false;

	// Hardcoded Fallback Area
	const focusAreaCoordinates = [
		[98.9601657275698, 18.79084270775664],
		[98.96211706674501, 18.795420821749346],
		[98.95910521714836, 18.803934176372266],
		[98.96025056840341, 18.80566088916268],
		[98.95049387252698, 18.81023860009296],
		[98.9480334883495, 18.810640147739676],
		[98.94858495376855, 18.80939534691305],
		[98.947863806682, 18.809074106494478],
		[98.94735476167983, 18.80939534691305],
		[98.94710023917867, 18.80803007089743],
		[98.94739718209661, 18.806383693906497],
		[98.94608214917417, 18.805620733252553],
		[98.94633667167534, 18.803934176372266],
		[98.94701539834494, 18.802609012678516],
		[98.94676087584384, 18.800079125740638],
		[98.94608214917417, 18.798512986198276],
		[98.94548826333823, 18.797830305426643],
		[98.94574278583934, 18.796705884002407],
		[98.94625183084156, 18.794898762407016],
		[98.96033540923719, 18.791163982975164]
	];

	const checkMobile = () => {
		if (typeof window !== 'undefined') {
			isMobile = window.innerWidth < 768;
		}
	};

	onMount(async () => {
		initializeMapInteractions();

		checkMobile();
		window.addEventListener('resize', checkMobile);

		// Wait for user session to hydrate
		await new Promise((r) => setTimeout(r, 500));

		if (!$userStore || !$userStore.id) {
			const {
				data: { user }
			} = await supabase.auth.getUser();
			if (user) {
				// Fetch profile data including role from profiles table
				const { data: profile } = await supabase
					.from('profiles')
					.select('full_name, role')
					.eq('id', user.id)
					.single();

				userStore.set({
					id: user.id,
					name: profile?.full_name || user.email?.split('@')[0] || 'User',
					email: user.email,
					role: profile?.role || 'member'
				});
			} else {
				goto('/login');
				return;
			}
		}

		await fetchCategories();
		await fetchSecurityZones();

		// Close Splash Screen
		await new Promise((resolve) => setTimeout(resolve, 100));
		showSplash = false;
	});

	onDestroy(() => {
		if (typeof window !== 'undefined') {
			window.removeEventListener('resize', checkMobile);
		}
	});

	// --- Supabase Data Fetching ---

	async function fetchCategories() {
		const { data, error } = await supabase
			.from('report_categories')
			.select('*')
			.eq('is_active', true);

		if (data) {
			categoriesDB = data;
		} else {
			console.error('Error fetching categories:', error);
		}
	}

	async function fetchSecurityZones() {
		console.log('🔍 Fetching security zones from database...');
		const { data, error } = await supabase.from('security_zones').select('*').eq('is_active', true);

		if (error) {
			console.error('❌ Error fetching security zones:', error);
			return;
		}

		if (data && data.length > 0) {
			securityZonesDB = data;
			console.log(`✅ Fetched ${data.length} security zone(s):`, data);
			data.forEach((zone, i) => {
				console.log(`  Zone ${i + 1}: ${zone.name} (ID: ${zone.id}, Active: ${zone.is_active})`);
				console.log(`    Geometry type: ${zone.geometry?.type}`);
			});
		} else {
			console.warn('⚠️  No security zones found in database');
			// Alert the user if no zones found - this helps debugging "not found" issues
			alert(
				'⚠️ Debug: No security zones found in database. Please check your internet connection or database policies.'
			);
		}
	}

	async function fetchReportsAndDraw() {
		if (!mapInstance) return;

		// Clear existing markers & lines
		mapMarkers.forEach((marker) => marker.remove());
		mapMarkers = [];
		layersIds.forEach((id) => {
			if (mapInstance.getLayer(id)) mapInstance.removeLayer(id);
			if (mapInstance.getSource(id)) mapInstance.removeSource(id);
		});
		layersIds = [];

		// Fetch Active Reports
		// FIX: Using ONLY 'pending' to ensure compatibility with DB Enum
		const { data: reports, error } = await supabase
			.from('reports')
			.select(
				`
					*,
					category:report_categories(name, icon),
					reporter:profiles!created_by_user_id(full_name),
					votes:report_verifications(vote)
				`
			)
			.eq('status', 'pending') // <--- ใช้ค่า pending อย่างเดียวเพื่อความชัวร์
			.order('created_at', { ascending: false });

		if (error) {
			console.error('Error loading reports:', error);
			// Do not return, let the code run so map stays usable
		}

		if (reports) {
			reports.forEach((report) => {
				const geo = report.geometry;
				const votes = report.votes || [];
				const likes = votes.filter((v) => v.vote === 1).length;
				const dislikes = votes.filter((v) => v.vote === -1).length;

				if (geo.type === 'Point') {
					addPinToMap({
						id: report.id,
						category: report.category?.name || 'general',
						coordinates: { lng: geo.coordinates[0], lat: geo.coordinates[1] },
						title: report.title,
						description: report.description,
						reporter: report.is_anonymous ? 'Anonymous' : report.reporter?.full_name || 'Unknown',
						timestamp: report.created_at,
						photoPreviewUrl: null,
						likes,
						dislikes
					});
				} else if (geo.type === 'LineString') {
					addPermanentLineToMap(geo.coordinates, report.category?.name || 'general', report.id);
					addPinToMap({
						id: report.id,
						category: report.category?.name || 'general',
						coordinates: { lng: geo.coordinates[0][0], lat: geo.coordinates[0][1] },
						title: report.title,
						description: report.description,
						reporter: report.is_anonymous ? 'Anonymous' : report.reporter?.full_name || 'Unknown',
						timestamp: report.created_at,
						photoPreviewUrl: null,
						likes,
						dislikes
					});
				}
			});
		}
	}

	// --- Map Logic ---

	function handleMapLoad({ detail }) {
		mapInstance = detail.map;
		maplibreglInstance = detail.maplibregl;

		// 1. Setup Temp Line (Dashed line for drawing)
		if (!mapInstance.getSource('temp-line-source')) {
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
		}

		// 2. Setup Focus Area (Purple Highlight)
		// FIX: We draw this BEFORE fetching data to ensure it exists even if DB fails
		const bounds = new maplibreglInstance.LngLatBounds();
		focusAreaCoordinates.forEach((coord) => {
			bounds.extend(coord);
		});

		mapInstance.fitBounds(bounds, {
			padding: 50,
			duration: 1500
		});

		const areaLineId = 'focus-area-line';
		const areaSourceId = 'focus-area-source';

		if (!mapInstance.getSource(areaSourceId)) {
			const areaFeature = {
				type: 'Feature',
				properties: {},
				geometry: {
					type: 'LineString',
					coordinates: focusAreaCoordinates
				}
			};

			mapInstance.addSource(areaSourceId, {
				type: 'geojson',
				data: areaFeature
			});

			mapInstance.addLayer({
				id: areaLineId,
				type: 'line',
				source: areaSourceId,
				layout: {
					'line-join': 'round',
					'line-cap': 'round'
				},
				paint: {
					'line-color': '#8F66FF',
					'line-width': 4,
					'line-opacity': 0.8
				}
			});
		}

		// 3. Setup Security Zones (Filled Polygons from DB)
		console.log('🗺️  Setting up security zones on map...');
		if (securityZonesDB && securityZonesDB.length > 0) {
			console.log(`📍 Creating ${securityZonesDB.length} security zone layer(s)`);
			securityZonesDB.forEach((zone, index) => {
				const securityZoneId = `security-zone-fill-${zone.id}`;
				const securityZoneSourceId = `security-zone-source-${zone.id}`;

				if (!mapInstance.getSource(securityZoneSourceId)) {
					try {
						// Convert PostGIS geometry to GeoJSON
						const securityZoneFeature = {
							type: 'Feature',
							properties: {
								name: zone.name,
								description: zone.description
							},
							geometry: zone.geometry
						};

						console.log(`  ✓ Creating layer for zone: ${zone.name}`);
						console.log(`    Layer ID: ${securityZoneId}`);
						console.log(`    Geometry:`, zone.geometry);

						mapInstance.addSource(securityZoneSourceId, {
							type: 'geojson',
							data: securityZoneFeature
						});

						mapInstance.addLayer({
							id: securityZoneId,
							type: 'fill',
							source: securityZoneSourceId,
							layout: {
								visibility: 'none'
							},
							paint: {
								'fill-color': '#8F66FF',
								'fill-opacity': 0.15
							}
						});

						// Add border/outline layer
						mapInstance.addLayer({
							id: `${securityZoneId}-outline`,
							type: 'line',
							source: securityZoneSourceId,
							layout: {
								visibility: 'none'
							},
							paint: {
								'line-color': '#8F66FF',
								'line-width': 2,
								'line-opacity': 0.6
							}
						});

						console.log(`  ✅ Successfully created layers for: ${zone.name}`);
					} catch (error) {
						console.error(`  ❌ Error creating layer for zone ${zone.name}:`, error);
					}
				}
			});
		} else {
			console.warn('⚠️  No security zones to render on map');
		}

		// 4. Load Data from DB
		fetchReportsAndDraw();
	}

	function toggleSecurityZone() {
		showSecurityZone = !showSecurityZone;
		console.log(`🔄 Toggling security zones: ${showSecurityZone ? 'SHOW' : 'HIDE'}`);

		if (mapInstance && securityZonesDB && securityZonesDB.length > 0) {
			securityZonesDB.forEach((zone) => {
				const layerId = `security-zone-fill-${zone.id}`;
				const outlineLayerId = `${layerId}-outline`;

				if (mapInstance.getLayer(layerId)) {
					mapInstance.setLayoutProperty(
						layerId,
						'visibility',
						showSecurityZone ? 'visible' : 'none'
					);
					console.log(`  ✓ ${zone.name} fill: ${showSecurityZone ? 'visible' : 'hidden'}`);
				}

				if (mapInstance.getLayer(outlineLayerId)) {
					mapInstance.setLayoutProperty(
						outlineLayerId,
						'visibility',
						showSecurityZone ? 'visible' : 'none'
					);
					console.log(`  ✓ ${zone.name} outline: ${showSecurityZone ? 'visible' : 'hidden'}`);
				}
			});
		} else {
			console.warn('⚠️  Cannot toggle: No security zones available or map not ready');
		}
	}

	function isPointInArea(point, polygon) {
		let x = point[0],
			y = point[1];
		let inside = false;
		for (let i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
			let xi = polygon[i][0],
				yi = polygon[i][1];
			let xj = polygon[j][0],
				yj = polygon[j][1];
			let intersect = yi > y !== yj > y && x < ((xj - xi) * (y - yi)) / (yj - yi) + xi;
			if (intersect) inside = !inside;
		}
		return inside;
	}

	function handleMapClick({ detail: e }) {
		if (isDrawingLine) {
			const coords = e.lngLat.toArray();
			if (!isPointInArea(coords, focusAreaCoordinates)) {
				toastMessage = 'Lines can only be drawn within the specified area';
				showToast = true;
				setTimeout(() => (showToast = false), 3000);
				return;
			}
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

	import { getUserLocation } from '$lib/utils/geolocation.js';

	// ... existing imports ...

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

	function handleNextStep() {
		if (mapInstance) {
			const center = mapInstance.getCenter();
			const currentCoords = [center.lng, center.lat];
			if (!isPointInArea(currentCoords, focusAreaCoordinates)) {
				toastMessage = 'Pins can only be placed within the specified area';
				showToast = true;
				setTimeout(() => (showToast = false), 3000);
				return;
			}
			pinCoordinates = { lng: center.lng, lat: center.lat };
			showDetailForm = true;
		}
	}

	function updateTempLine() {
		mapInstance.getSource('temp-line-source').setData({
			type: 'Feature',
			geometry: { type: 'LineString', coordinates: currentLinePoints }
		});
	}

	function addPermanentLineToMap(points, category, id) {
		const lineId = id || crypto.randomUUID();
		const lineColor = category.includes('blocked') ? '#F97316' : '#EF4444';

		layersIds.push(`perm-line-layer-${lineId}`);
		layersIds.push(`perm-line-source-${lineId}`);

		if (!mapInstance.getSource(`perm-line-source-${lineId}`)) {
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
	}

	function addPinToMap(data) {
		const el = document.createElement('div');
		mount(CustomMarker, { target: el, props: { category: data.category } });
		const pinId = data.id;

		// Popup Content
		const imageHTML = data.photoPreviewUrl
			? `<div style="width: 100%; height: 140px; background-image: url('${data.photoPreviewUrl}'); background-size: cover; background-position: center; border-radius: 12px; margin-bottom: 12px;"></div>`
			: '';

		window[`handleLike_${pinId}`] = () => handleVote(pinId, 1);
		window[`handleDislike_${pinId}`] = () => handleVote(pinId, -1);

		const popupHTML = `
            <div style="font-family: 'Kanit', sans-serif; min-width: 200px; padding: 4px;">
                ${imageHTML}
                <h3 style="font-size: 20px; font-weight: 400; color: #000; margin: 0 0 12px 0; line-height: 1.2;">${data.title}</h3>
                <div style="display: flex; justify-content: space-between; align-items: flex-end;">
                    <div style="font-size: 13px; line-height: 1.4; color: #6B7280;">
                        <span>report by</span><br><span style="color: #1F2937; font-weight: 700;">${data.reporter}</span><br><span>${timeAgo(data.timestamp)}</span>
                    </div>
                    <div style="display: flex; gap: 16px; align-items: center;">
                         <div style="display: flex; align-items: center; gap: 6px;">
                            <button onclick="window['handleLike_${pinId}']()" style="cursor: pointer; border: none; background: none;">
                                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#374151" stroke-width="2"><path d="M7 10v12"/><path d="M15 5.88 14 10h5.83a2 2 0 0 1 1.92 2.56l-2.33 8A2 2 0 0 1 17.5 22H4a2 2 0 0 1-2-2v-8a2 2 0 0 1 2-2h2.76a2 2 0 0 0 1.79-1.11L12 2h0a3.13 3.13 0 0 1 3 3.88Z"/></svg>
                            </button>
                            <span id="like-count-${pinId}" style="font-weight: 800;">${data.likes}</span>
                        </div>
                        <div style="display: flex; align-items: center; gap: 6px;">
                            <button onclick="window['handleDislike_${pinId}']()" style="cursor: pointer; border: none; background: none;">
                                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#374151" stroke-width="2" style="transform: scaleY(-1);"><path d="M7 10v12"/><path d="M15 5.88 14 10h5.83a2 2 0 0 1 1.92 2.56l-2.33 8A2 2 0 0 1 17.5 22H4a2 2 0 0 1-2-2v-8a2 2 0 0 1 2-2h2.76a2 2 0 0 0 1.79-1.11L12 2h0a3.13 3.13 0 0 1 3 3.88Z"/></svg>
                            </button>
                            <span id="dislike-count-${pinId}" style="font-weight: 800;">${data.dislikes}</span>
                        </div>
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
			.setLngLat([data.coordinates.lng, data.coordinates.lat])
			.setPopup(popup)
			.addTo(mapInstance);

		mapMarkers.push(marker);
	}

	async function handleVote(reportId, voteType) {
		const { error } = await supabase.from('report_verifications').upsert({
			report_id: reportId,
			user_id: $userStore.id,
			vote: voteType
		});

		if (!error) {
			console.log('Voted successfully');
		}
	}

	async function handlePinSubmit(e) {
		const formData = e.detail;
		const categoryObj = categoriesDB.find((c) => c.name === selectedCategory);
		if (!categoryObj) return alert('Category not found');

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

		const { data: reportData, error: reportError } = await supabase
			.from('reports')
			.insert({
				created_by_user_id: $userStore.id,
				category_id: categoryObj.id,
				title: formData.title,
				description: formData.description,
				geometry: {
					type: 'Point',
					coordinates: [pinCoordinates.lng, pinCoordinates.lat]
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
			toastMessage =
				formData.visibility === 'public' ? 'Post published on map' : 'Report sent to security';
			fetchReportsAndDraw();
		}

		showDetailForm = false;
		selectedCategory = null;
		showToast = true;
		setTimeout(() => (showToast = false), 3000);
	}

	async function finishLineDrawing() {
		if (currentLinePoints.length < 2) {
			alert('Please click on the map to draw at least 2 points.');
			return;
		}

		const allPointsInArea = currentLinePoints.every((point) =>
			isPointInArea(point, focusAreaCoordinates)
		);
		if (!allPointsInArea) {
			toastMessage = 'Lines can only be drawn within the specified area';
			showToast = true;
			setTimeout(() => (showToast = false), 3000);
			return;
		}

		const key = drawingLineCategory.includes('traffic') ? 'traffic_general' : 'blocked_line';
		const categoryObj = categoriesDB.find((c) => c.name === key);

		const { error } = await supabase.from('reports').insert({
			created_by_user_id: $userStore.id,
			category_id: categoryObj ? categoryObj.id : drawingLineCategory.includes('traffic') ? 6 : 11,
			title: drawingLineCategory.includes('traffic') ? 'Traffic Jam' : 'Road Closed',
			description: 'Reported route via map drawing',
			geometry: {
				type: 'LineString',
				coordinates: currentLinePoints
			},
			status: 'pending'
		});

		if (!error) {
			toastMessage = 'Route reported successfully';
			fetchReportsAndDraw();
		} else {
			toastMessage = 'Failed to report route';
			console.error(error);
		}

		showToast = true;
		setTimeout(() => (showToast = false), 3000);
		cancelAll();
	}

	async function calculateDistanceToNearestSecurity() {
		try {
			const { latitude, longitude } = await getUserLocation();
			const userPoint = point([longitude, latitude]);
			let minDistance = Infinity;

			if (securityZonesDB && securityZonesDB.length > 0) {
				securityZonesDB.forEach((zone) => {
					// For simplicity, we calculate distance to the first point of the polygon
					// A more accurate approach would be pointToPolygonDistance but that requires more complex logic
					// or using turf.pointOnFeature if available.
					// Given the zones are likely small, this approximation is acceptable for now.
					if (zone.geometry && zone.geometry.coordinates && zone.geometry.coordinates[0]) {
						// Handle MultiPolygon vs Polygon vs Point if needed, but assuming Polygon for zones
						// Polygon coordinates are usually [[[x,y], [x,y], ...]]
						const zonePoint = point(zone.geometry.coordinates[0][0]);
						const d = distance(userPoint, zonePoint, { units: 'meters' });
						if (d < minDistance) {
							minDistance = d;
						}
					}
				});
			}

			if (minDistance !== Infinity) {
				nearestSecurityDistance = Math.round(minDistance);
			} else {
				nearestSecurityDistance = null;
			}
		} catch (error) {
			console.error('Error calculating distance:', error);
			nearestSecurityDistance = null;
		}
	}

	function handleCategorySelect(e) {
		const category = e.detail;
		isMobileCategorySheetOpen = false;
		if (category === 'send_help') {
			calculateDistanceToNearestSecurity();
			showSendHelpModal = true;
			return;
		}
		if (category === 'blocked') {
			modalConfig = BLOCKED_MODAL_CONFIG;
			isPointOrLineModalOpen = true;
		} else if (category === 'traffic_general') {
			isPointOrLineModalOpen = false;
			isDrawingLine = true;
			drawingLineCategory = 'traffic_general-line';
			currentLinePoints = [];
			if (mapInstance) {
				mapInstance.getCanvas().style.cursor = 'crosshair';
				if (mapInstance.getLayer('temp-line-layer')) {
					mapInstance.setPaintProperty('temp-line-layer', 'line-color', '#EF4444');
				}
			}
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
</script>

<svelte:head>
	<script>
		if (!customElements.get('lottie-player')) {
			var script = document.createElement('script');
			script.src = 'https://unpkg.com/@lottiefiles/lottie-player@latest/dist/lottie-player.js';
			document.head.appendChild(script);
		}
	</script>
</svelte:head>

<div class="font-kanit relative h-screen w-full overflow-hidden bg-white">
	{#if showSplash}
		<div
			class="fixed inset-0 z-[100] flex flex-col items-center justify-center bg-white"
			out:fade={{ duration: 500 }}
		>
			<lottie-player
				src="/loading.json"
				background="transparent"
				speed="1"
				style="width: 450px; height: 450px;"
				loop
				autoplay
			></lottie-player>
			<div class="relative z-10 -mt-10 text-center">
				<h1 class="text-4xl font-bold tracking-wide text-[#8F66FF]">ลูกช้าง Maps</h1>
				<p class="mt-2 text-base font-light tracking-widest text-gray-400">
					COMMUNITY SAFETY PLATFORM
				</p>
			</div>
		</div>
	{/if}

	<BaseMap on:load={handleMapLoad} on:click={handleMapClick} />

	{#if !showSplash}
		{#if !selectedCategory && !isDrawingLine}
			<Navbar on:toggleSidebar={() => (isFilterSidebarOpen = true)} />
		{/if}

		{#if !selectedCategory && !isDrawingLine}
			{#if isMobile}
				<button
					class="absolute right-4 bottom-13 z-40 flex h-16 w-16 items-center justify-center rounded-full bg-[#8F66FF] text-3xl text-white shadow-xl transition-transform active:scale-95"
					on:click={() => (isMobileCategorySheetOpen = true)}>+</button
				>
			{:else}
				<PinCategoryPanel
					on:select={(e) => (selectedCategory = e.detail)}
					on:sendHelp={() => (showSendHelpModal = true)}
					on:showOptions={handleCategorySelect}
				/>
			{/if}
		{/if}

		{#if selectedCategory && !showDetailForm && !isDrawingLine}
			<div
				class="pt-safe pointer-events-none absolute top-24 right-0 left-0 z-30 flex justify-center"
				in:fly={{ y: -20, duration: 300 }}
			>
				<div
					class="flex items-center gap-2 rounded-full border border-gray-100 bg-white px-6 py-3 shadow-lg"
				>
					<span class="text-sm font-medium text-gray-600">Create post:</span>
					<span class="text-sm font-bold text-[#8F66FF] uppercase"
						>{CATEGORY_DISPLAY_NAMES[selectedCategory]}</span
					>
				</div>
			</div>
			<div
				class="pointer-events-none absolute top-1/2 left-1/2 z-10 -translate-x-1/2 -translate-y-full pb-1 drop-shadow-xl"
			>
				<svg
					width="48"
					height="48"
					viewBox="0 0 24 24"
					fill="none"
					xmlns="http://www.w3.org/2000/svg"
					><path
						d="M12 0C7.58 0 4 3.58 4 8C4 13.5 12 24 12 24C12 24 20 13.5 20 8C20 3.58 16.42 0 12 0Z"
						fill="#EF4444"
					/><circle cx="12" cy="8" r="3.5" fill="white" /></svg
				>
			</div>
			<div class="pb-safe absolute right-0 bottom-8 left-0 z-50 flex justify-center gap-4 px-4">
				<button
					class="btn w-32 rounded-full border-gray-200 bg-white px-8 font-bold text-gray-700 shadow-lg hover:bg-gray-50"
					on:click={cancelAll}>Cancel</button
				>
				<button
					class="btn w-32 rounded-full border-none bg-[#8F66FF] px-8 font-bold text-white shadow-lg hover:bg-[#7a52e0]"
					on:click={handleNextStep}>Next</button
				>
			</div>
		{/if}

		{#if isDrawingLine}
			<div
				class="pt-safe pointer-events-none absolute top-24 right-0 left-0 z-30 flex justify-center"
			>
				<div class="rounded-full border border-gray-100 bg-white px-6 py-3 shadow-lg">
					<span
						class="font-bold {drawingLineCategory.includes('traffic')
							? 'text-red-600'
							: 'text-orange-600'} text-sm"
					>
						Drawing {drawingLineCategory.includes('traffic') ? 'Traffic Jam' : 'Road Off'} (Tap map to
						add points)
					</span>
				</div>
			</div>
			<div class="pb-safe absolute right-0 bottom-8 left-0 z-50 flex justify-center gap-4 px-4">
				<button
					class="btn rounded-full border-gray-200 bg-white px-8 text-black shadow-lg"
					on:click={cancelAll}>Cancel</button
				>
				<button
					class="btn rounded-full bg-[#8F66FF] px-8 text-white shadow-lg hover:bg-[#7a52e0]"
					on:click={finishLineDrawing}>Finish</button
				>
			</div>
		{/if}

		{#if showToast}
			<div class="pointer-events-none absolute top-24 right-0 left-0 z-50 flex justify-center">
				<div
					class="flex animate-bounce items-center gap-2 rounded-full border border-gray-200 bg-white px-6 py-3 shadow-lg"
				>
					<span class="font-bold text-green-600">{toastMessage}</span>
				</div>
			</div>
		{/if}

		<button
			class="absolute z-40 flex items-center justify-center rounded-full bg-white shadow-md hover:bg-gray-100 active:scale-95 {isMobile
				? 'pb-safe-offset right-4 bottom-32 h-12 w-12'
				: 'right-4 bottom-38 h-10 w-10'}"
			on:click={findUserLocation}
			title="Find my location"
			disabled={isLocating}
		>
			{#if isLocating}
				<div
					class="h-5 w-5 animate-spin rounded-full border-2 border-gray-300 border-t-[#8F66FF]"
				></div>
			{:else}
				<Crosshair class="h-6 w-6 text-gray-600" />
			{/if}
		</button>

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
				on:select={handleCategorySelect}
				on:showOptions={handleCategorySelect}
			/>
		{/if}

		{#if showSendHelpModal}
			<SendHelpConfirmModal
				distance={nearestSecurityDistance}
				on:close={() => (showSendHelpModal = false)}
				on:confirm={() => {
					showSendHelpModal = false;
					toastMessage = 'Emergency alert sent to security!';
					showToast = true;
					setTimeout(() => (showToast = false), 3000);
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

		<img src="/logo.svg" alt="Logo" class="absolute bottom-4 left-4 z-30 h-8" />
	{/if}
</div>

<style>
	:global(.cmu-popup .maplibregl-popup-content) {
		border-radius: 20px !important;
		padding: 16px !important;
		box-shadow:
			0 10px 25px -5px rgba(0, 0, 0, 0.1),
			0 8px 10px -6px rgba(0, 0, 0, 0.1) !important;
		border: none !important;
	}

	.pt-safe {
		padding-top: max(0px, env(safe-area-inset-top));
	}

	.pb-safe {
		padding-bottom: max(0px, env(safe-area-inset-bottom));
	}

	.pb-safe-offset {
		margin-bottom: max(0px, env(safe-area-inset-bottom));
	}

	:global(.cmu-popup .maplibregl-popup-tip) {
		display: none !important;
	}
	.font-kanit {
		font-family: 'Kanit', sans-serif;
	}
</style>
