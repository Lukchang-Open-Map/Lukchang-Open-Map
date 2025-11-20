<script>
	import { createEventDispatcher } from 'svelte';
	import {
		AlertTriangle,
		TrafficCone,
		HelpCircle,
		Droplet,
		LifeBuoy,
		CarFront,
		ParkingSquare,
		Briefcase,
		PartyPopper,
		MessageSquare,
		Camera,
		ChevronLeft
	} from 'lucide-svelte';
	import { userStore } from '$lib/stores/userStore.js';
	import { generateUUID } from '$lib/utils/generators.js';
	import { CATEGORY_STYLES, CATEGORY_DISPLAY_NAMES } from '$lib/constant/map-config.js';

	export let category;
	export let coordinates;
	export let isMobile = false;

	$: style = CATEGORY_STYLES[category] || CATEGORY_STYLES['beware'];

	let isAnonymous = true;
	let title = '';
	let description = '';
	let visibility = 'public';
	let photoFile = null;
	let photoPreviewUrl = null;
	let photoFileName = '';

	const dispatch = createEventDispatcher();

	function handleSubmit(e) {
		if (e) {
			e.preventDefault();
			e.stopPropagation();
		}

		const formData = {
			id: generateUUID(),
			category,
			coordinates,
			title,
			description,
			isAnonymous,
			visibility,
			photo: photoFile,
			photoPreviewUrl: photoPreviewUrl,
			reporter: isAnonymous ? 'anonymous' : $userStore?.name || 'User',
			timestamp: new Date().toISOString(),
			likes: 0,
			dislikes: 0
		};
		dispatch('submit', formData);
	}

	function handlePhotoChange(event) {
		const file = event.target.files[0];
		if (file) {
			photoFile = file;
			photoFileName = file.name;
			photoPreviewUrl = URL.createObjectURL(file);
			event.target.value = null;
		}
	}
</script>

<div
	on:click={() => dispatch('close')}
	class="absolute inset-0 z-[60] {isMobile
		? 'bg-white'
		: 'flex items-center justify-center bg-black/50 p-4'}"
>
	<div
		on:click|stopPropagation
		class="w-full bg-white {isMobile
			? 'safe-form-mobile flex h-full flex-col overflow-y-auto'
			: 'flex max-w-md flex-col gap-4 rounded-2xl p-6'}"
	>
		<div class="flex items-center gap-2 {isMobile ? 'safe-form-header' : ''}">
			<button
				on:click={() => dispatch('close')}
				class="btn-clickable {isMobile
					? '-ml-2 p-2 font-medium text-gray-600'
					: 'text-gray-500 hover:text-black'}"
			>
				&lt; Back
			</button>
			<h2 class="text-lg font-bold">Create post</h2>
		</div>

		<div class="flex flex-col gap-4 {isMobile ? 'safe-form-content' : ''}">
			<label
				class="flex items-center justify-between rounded-lg bg-[#EBE0F3] p-3 font-medium text-[#8F66FF]"
			>
				<span>Post anonymously</span>
				<input
					type="checkbox"
					class="toggle"
					bind:checked={isAnonymous}
					style="--tcb: #8F66FF; --tbc: #8F66FF;"
				/>
			</label>

			<div class="flex flex-col items-center gap-2 py-2">
				<div class="flex h-16 w-16 items-center justify-center rounded-full {style.bg}">
					<svelte:component this={style.Icon} class="h-8 w-8 {style.text}" />
				</div>
				<span class="text-lg font-semibold">{CATEGORY_DISPLAY_NAMES[category] || category}</span>
			</div>

			<label
				class="cursor-pointer rounded-lg border-2 border-dashed border-gray-300 p-6 text-center text-gray-500 transition-colors hover:bg-gray-50"
			>
				<input type="file" class="hidden" accept="image/*" on:change={handlePhotoChange} />
				{#if photoPreviewUrl}
					<img
						src={photoPreviewUrl}
						alt="Preview"
						class="mx-auto mb-2 h-24 rounded-md object-cover"
					/>
					<span class="text-sm text-black">{photoFileName}</span>
				{:else}
					<Camera class="mx-auto h-12 w-12 text-gray-400" />
					<span>Add Photo</span>
				{/if}
			</label>

			<div class="flex flex-col gap-1">
				<label class="font-medium">Title</label>
				<input
					type="text"
					placeholder="e.g., Free food at Ang Kaew"
					class="input-bordered input w-full"
					bind:value={title}
				/>
			</div>

			<div class="flex flex-col gap-1">
				<label class="font-medium">Description</label>
				<textarea
					placeholder="Add more details..."
					class="textarea-bordered textarea w-full"
					rows="3"
					bind:value={description}
				></textarea>
			</div>

			<div class="flex flex-col gap-2">
				<label class="flex cursor-pointer items-center gap-3 rounded-lg p-2 hover:bg-gray-50">
					<input
						type="radio"
						name="visibility"
						class="radio radio-primary"
						value="public"
						bind:group={visibility}
						style="--c-p: #8F66FF;"
					/>
					<span>Show on public map</span>
				</label>
				<label class="flex cursor-pointer items-center gap-3 rounded-lg p-2 hover:bg-gray-50">
					<input
						type="radio"
						name="visibility"
						class="radio radio-primary"
						value="staff_only"
						bind:group={visibility}
						style="--c-p: #8F66FF;"
					/>
					<span>Send only to staff (not shown on map)</span>
				</label>
			</div>

			{#if isMobile}
				<div class="min-h-[1rem] flex-1"></div>
			{/if}
		</div>

		<div class="flex gap-4 {isMobile ? 'safe-form-footer-buttons' : 'mt-2'}">
			<button
				on:click={() => dispatch('close')}
				class="btn-clickable btn flex-1 rounded-full"
				type="button"
			>
				Return
			</button>
			<button
				on:click={handleSubmit}
				class="btn-clickable btn flex-1 rounded-full bg-[#8F66FF] text-white hover:bg-[#7a52e0]"
				type="button"
			>
				Send
			</button>
		</div>
	</div>
</div>

<style>
	.safe-form-mobile {
		padding-top: max(0rem, env(safe-area-inset-top));
		padding-bottom: max(0rem, env(safe-area-inset-bottom));
	}
	.safe-form-header {
		padding-top: max(1rem, calc(1rem + env(safe-area-inset-top)));
		padding-left: max(1rem, env(safe-area-inset-left));
		padding-right: max(1rem, env(safe-area-inset-right));
		margin-bottom: 1rem;
	}
	.safe-form-content {
		padding-left: max(1rem, env(safe-area-inset-left));
		padding-right: max(1rem, env(safe-area-inset-right));
		flex: 1;
	}
	.safe-form-footer-buttons {
		padding-left: max(1rem, env(safe-area-inset-left));
		padding-right: max(1rem, env(safe-area-inset-right));
		padding-bottom: max(1rem, calc(1rem + env(safe-area-inset-bottom)));
		margin-top: auto;
		position: relative;
		z-index: 10;
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
		transition: transform 0.1s ease;
	}
</style>
