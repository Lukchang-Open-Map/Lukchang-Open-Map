<script>
    import { createEventDispatcher } from 'svelte';
    import { 
        AlertTriangle, TrafficCone, HelpCircle, Droplet, LifeBuoy,
        CarFront, ParkingSquare, Briefcase, PartyPopper, MessageSquare, Camera
    } from 'lucide-svelte';
    import { userStore } from '$lib/userStore.js';

    export let category;
    export let coordinates;
    export let categoryDisplayNames;
    export let isMobile = false;

    const categoryStyles = {
        'accident': { Icon: AlertTriangle, bg: 'bg-red-100', text: 'text-red-600' },
        'blocked': { Icon: TrafficCone, bg: 'bg-orange-100', text: 'text-orange-600' },
        'beware': { Icon: HelpCircle, bg: 'bg-gray-200', text: 'text-gray-700' },
        'flood': { Icon: Droplet, bg: 'bg-blue-100', text: 'text-blue-600' },
        // 'traffic_general': { Icon: CarFront, bg: 'bg-red-100', text: 'text-red-600' },
        'parking': { Icon: ParkingSquare, bg: 'bg-blue-100', text: 'text-blue-600' },
        'events': { Icon: PartyPopper, bg: 'bg-purple-100', text: 'text-purple-600' },
        'lost_found': { Icon: Briefcase, bg: 'bg-orange-200', text: 'text-orange-600' }
    };

    $: style = categoryStyles[category] || categoryStyles['beware']; 

    let isAnonymous = true;
    let title = '';
    let description = '';
    let visibility = 'public';
    let photoFile = null;
    let photoPreviewUrl = null;
    let photoFileName = '';

    const dispatch = createEventDispatcher();

    function handleClose() {
        dispatch('close');
    }

    // ฟังก์ชันสร้าง UUID ที่ทำงานได้ทุก browser
    function generateUUID() {
        return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
            const r = Math.random() * 16 | 0;
            const v = c === 'x' ? r : (r & 0x3 | 0x8);
            return v.toString(16);
        });
    }

    function handleSubmit(e) {
        console.log('=== SEND BUTTON CLICKED ===');
        
        if (e) {
            e.preventDefault();
            e.stopPropagation();
        }
        
        try {
            const formData = {
                id: generateUUID(), // ใช้ฟังก์ชันของเราแทน crypto.randomUUID()
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
            
            console.log('Submitting Pin:', formData);
            dispatch('submit', formData);
        } catch (error) {
            console.error('Error in handleSubmit:', error);
        }
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
    on:click={handleClose} 
    class="absolute inset-0 z-[60] {isMobile 
        ? 'bg-white' 
        : 'flex items-center justify-center bg-black/50 p-4'}"
>
    <div 
        on:click|stopPropagation 
        class="bg-white w-full {isMobile 
            ? 'h-full flex flex-col overflow-y-auto safe-form-mobile' 
            : 'rounded-2xl max-w-md p-6 flex flex-col gap-4'}"
    >
        
        <div class="flex items-center gap-2 {isMobile ? 'safe-form-header' : ''}">
            <button 
                on:click={handleClose} 
                class="btn-clickable {isMobile 
                    ? 'text-gray-600 font-medium p-2 -ml-2' 
                    : 'text-gray-500 hover:text-black'}"
            >
                &lt; Back
            </button>
            <h2 class="text-lg font-bold">Create post</h2>
        </div>

        <div class="flex flex-col gap-4 {isMobile ? 'safe-form-content' : ''}">
            
            <label class="flex justify-between items-center bg-[#EBE0F3] text-[#8F66FF] font-medium p-3 rounded-lg">
                <span>Post anonymously</span>
                <input type="checkbox" class="toggle" bind:checked={isAnonymous} style="--tcb: #8F66FF; --tbc: #8F66FF;" />
            </label>

            <div class="flex flex-col items-center gap-2 py-2">
                <div class="flex h-16 w-16 items-center justify-center rounded-full {style.bg}">
                    <svelte:component 
                        this={style.Icon} 
                        class="h-8 w-8 {style.text}" 
                    />
                </div>
                <span class="font-semibold text-lg">{categoryDisplayNames[category] || category}</span>
            </div>

            <label for="photo-upload" class="border-2 border-dashed border-gray-300 rounded-lg p-6 text-center text-gray-500 hover:bg-gray-50 cursor-pointer transition-colors">
                <input id="photo-upload" type="file" class="hidden" accept="image/*" on:change={handlePhotoChange} />
                {#if photoPreviewUrl}
                    <img src={photoPreviewUrl} alt="Preview" class="mx-auto h-24 object-cover rounded-md mb-2" />
                    <span class="text-sm text-black">{photoFileName}</span>
                {:else}
                    <Camera class="mx-auto h-12 w-12 text-gray-400" />
                    <span>Add Photo</span>
                {/if}
            </label>

            <div class="flex flex-col gap-1">
                <label for="title" class="font-medium">Title</label>
                <input id="title" type="text" placeholder="e.g., Free food at Ang Kaew" class="input input-bordered w-full" bind:value={title} />
            </div>

            <div class="flex flex-col gap-1">
                <label for="description" class="font-medium">Description</label>
                <textarea id="description" placeholder="Add more details..." class="textarea textarea-bordered w-full" rows="3" bind:value={description}></textarea>
            </div>

            <div class="flex flex-col gap-2">
                <label class="flex items-center gap-3 p-2 rounded-lg hover:bg-gray-50 cursor-pointer">
                    <input type="radio" name="visibility" class="radio radio-primary" value="public" bind:group={visibility} style="--c-p: #8F66FF;" />
                    <span>Show on public map</span>
                </label>
                <label class="flex items-center gap-3 p-2 rounded-lg hover:bg-gray-50 cursor-pointer">
                    <input type="radio" name="visibility" class="radio radio-primary" value="staff_only" bind:group={visibility} style="--c-p: #8F66FF;" />
                    <span>Send only to staff (not shown on map)</span>
                </label>
            </div>

            {#if isMobile}
                <div class="flex-1 min-h-[1rem]"></div>
            {/if}
        </div>

        <div class="flex gap-4 {isMobile ? 'safe-form-footer-buttons' : 'mt-2'}">
            <button 
                on:click={handleClose} 
                class="btn btn-clickable rounded-full flex-1"
                type="button"
            >
                Return
            </button>
            <button 
                on:click={handleSubmit}
                on:touchend={handleSubmit}
                class="btn btn-clickable rounded-full flex-1 bg-[#8F66FF] text-white hover:bg-[#7a52e0]"
                type="button"
                disabled={false}
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
    
    /* CRITICAL: Make all buttons fully clickable on mobile */
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
    
    /* Force button to be clickable - override any DaisyUI disabled styles */
    button[type="button"] {
        pointer-events: auto !important;
    }
    
    button:disabled {
        pointer-events: none !important;
        opacity: 0.5;
    }
</style>