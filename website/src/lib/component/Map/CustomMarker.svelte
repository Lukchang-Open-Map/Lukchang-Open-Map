<script>
    import { CATEGORY_STYLES } from '$lib/constant/map-config.js';
    export let category;
    $: style = CATEGORY_STYLES[category] || CATEGORY_STYLES['beware'];
</script>

<div class="relative w-12 h-12 flex justify-center items-center">
    {#if category === 'flood'}
        <div class="absolute w-10 h-10 rounded-full bg-blue-400 opacity-75 animate-ping"></div>
        <div class="absolute w-10 h-10 rounded-full bg-blue-500 opacity-20"></div>
    {/if}
    <div class="relative z-10 w-10 h-11">
        <div class="absolute top-0 left-0 w-10 h-10 rounded-full flex items-center justify-center shadow-lg {style.bg} border-2 border-white">
            <svelte:component this={style.Icon} class="w-6 h-6 {style.text}" />
        </div>
        <div class="absolute top-[38px] left-1/2 -translate-x-1/2"
             style="width: 0; height: 0; border-left: 6px solid transparent; border-right: 6px solid transparent; border-top: 10px solid white; filter: drop-shadow(0 1px 1px rgb(0 0 0 / 0.1));">
        </div>
    </div>
</div>