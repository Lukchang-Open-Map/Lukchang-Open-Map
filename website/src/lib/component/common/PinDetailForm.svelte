<script>
    import { createEventDispatcher } from 'svelte';
    import { Camera } from 'lucide-svelte';
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
        if (e) { e.preventDefault(); e.stopPropagation(); }
        const formData = {
            id: generateUUID(),
            category,
            coordinates,
            title,
            description,
            isAnonymous,
            visibility,
            photo: photoFile,
            photoPreviewUrl,
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
        }
    }
</script>
<div on:click={() => dispatch('close')} class="absolute inset-0 z-[60] {isMobile ? 'bg-white' : 'flex items-center justify-center bg-black/50 p-4'}">
    <div on:click|stopPropagation class="bg-white w-full {isMobile ? 'h-full flex flex-col overflow-y-auto safe-form-mobile' : 'rounded-2xl max-w-md p-6 flex flex-col gap-4'}">
        <div class="flex items-center gap-2 {isMobile ? 'safe-form-header' : ''}">
            <button on:click={() => dispatch('close')} class="text-gray-600 font-medium p-2 -ml-2">&lt; Back</button>
            <h2 class="text-lg font-bold">Create post</h2>
        </div>
        
        <div class="flex flex-col gap-4 flex-1 {isMobile ? 'safe-form-content' : ''}">
            <label class="flex justify-between items-center bg-[#EBE0F3] text-[#8F66FF] font-medium p-3 rounded-lg">
                <span>Post anonymously</span>
                <input type="checkbox" class="toggle" bind:checked={isAnonymous} style="--tcb: #8F66FF; --tbc: #8F66FF;" />
            </label>
            <div class="flex flex-col items-center gap-2 py-2">
                <div class="flex h-16 w-16 items-center justify-center rounded-full {style.bg}">
                    <svelte:component this={style.Icon} class="h-8 w-8 {style.text}" />
                </div>
                <span class="font-semibold text-lg">{CATEGORY_DISPLAY_NAMES[category]}</span>
            </div>
            <div class="flex flex-col gap-1">
                <label class="font-medium">Title</label>
                <input type="text" placeholder="Title..." class="input input-bordered w-full" bind:value={title} />
            </div>
            <div class="flex flex-col gap-1">
                <label class="font-medium">Description</label>
                <textarea placeholder="Details..." class="textarea textarea-bordered w-full" rows="3" bind:value={description}></textarea>
            </div>
             <label class="border-2 border-dashed border-gray-300 rounded-lg p-6 text-center cursor-pointer">
                <input type="file" class="hidden" accept="image/*" on:change={handlePhotoChange} />
                {#if photoPreviewUrl}
                    <img src={photoPreviewUrl} alt="Preview" class="mx-auto h-24 object-cover rounded-md" />
                {:else}
                    <Camera class="mx-auto h-8 w-8 text-gray-400" />
                    <span class="text-gray-500 text-sm">Add Photo</span>
                {/if}
            </label>
        </div>

        <div class="flex gap-4 mt-4 {isMobile ? 'safe-form-footer-buttons' : ''}">
            <button on:click={() => dispatch('close')} class="btn rounded-full flex-1">Cancel</button>
            <button on:click={handleSubmit} class="btn rounded-full flex-1 bg-[#8F66FF] text-white">Post</button>
        </div>
    </div>
</div>
<style>
    .safe-form-mobile { padding-top: env(safe-area-inset-top); padding-bottom: env(safe-area-inset-bottom); }
    .safe-form-header { padding-top: 1rem; padding-left: 1rem; }
    .safe-form-content { padding: 0 1rem; }
    .safe-form-footer-buttons { padding-bottom: 1rem; padding-left: 1rem; padding-right: 1rem; }
</style>