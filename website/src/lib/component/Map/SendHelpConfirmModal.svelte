<script>
    import { createEventDispatcher, onMount, onDestroy } from 'svelte';
    import { ArrowRight, ShieldAlert } from 'lucide-svelte';

    const dispatch = createEventDispatcher();

    export let initialCountdown = 10; 
    let countdownSeconds = initialCountdown;
    let interval;

    let sliderValue = 0; 
    let isSliding = false;
    let hasConfirmed = false;
    let sliderContainer;

    const BUTTON_WIDTH = 64; 

    function handleSlideStart(e) {
        if (hasConfirmed) return;
        isSliding = true;
        e.preventDefault();
    }

    function handleSliderMove(e) {
        if (!isSliding || hasConfirmed) return;

        const rect = sliderContainer.getBoundingClientRect();
        const clientX = e.type.includes('touch') 
            ? e.touches[0].clientX 
            : e.clientX;

        let position = clientX - rect.left - (BUTTON_WIDTH / 2);
        const maxPosition = rect.width - BUTTON_WIDTH;

        if (position < 0) position = 0;
        if (position > maxPosition) position = maxPosition;

        sliderValue = (position / maxPosition) * 100;

        if (sliderValue >= 95) {
            isSliding = false;
            hasConfirmed = true;
            sliderValue = 100; 
            dispatch('confirm');
        }
    }

    function handleSlideEnd() {
        if (isSliding && !hasConfirmed) {
            sliderValue = 0;
        }
        isSliding = false;
    }
    
    onMount(() => {
        countdownSeconds = initialCountdown; 
        interval = setInterval(() => {
            if (hasConfirmed) {
                clearInterval(interval);
                return;
            }
            countdownSeconds -= 1;
            if (countdownSeconds <= 0) {
                dispatch('close'); 
                clearInterval(interval);
            }
        }, 1000);
    });

    onDestroy(() => {
        clearInterval(interval);
    });
</script>

<div
    class="fixed inset-0 z-[90] bg-black/70 flex items-center justify-center p-4"
    on:click={() => dispatch('close')}
>
    <div
        class="w-full max-w-sm bg-white rounded-2xl p-6 shadow-xl modal-enter"
        on:click|stopPropagation
    >
        <div class="flex flex-col items-center text-center">
            <ShieldAlert class="w-16 h-16 text-red-500" />
            
            <h2 class="text-2xl font-bold mt-4">Confirm Emergency Request</h2>
            <p class="text-gray-600 mt-2">
                This will immediately alert security at your current location.
            </p>

            <div
                bind:this={sliderContainer}
                class="w-full h-16 bg-gray-200 rounded-full mt-6 relative overflow-hidden 
                       cursor-pointer select-none touch-none"
                on:mousedown={handleSlideStart}
                on:mousemove={handleSliderMove}
                on:mouseup={handleSlideEnd}
                on:mouseleave={handleSlideEnd}
                on:touchstart={handleSlideStart}
                on:touchmove={handleSliderMove}
                on:touchend={handleSlideEnd}
            >
                <div class="absolute inset-0 flex items-center justify-center">
                    <span class="text-lg font-medium text-gray-500 pointer-events-none">
                        Slide to Confirm
                    </span>
                </div>

                <div
                    class="absolute top-0 left-0 h-full w-16 bg-red-500 rounded-full 
                           flex items-center justify-center shadow-lg"
                    class:transition-transform={!isSliding}
                    class:duration-300={!isSliding}
                    class:ease-out={!isSliding}
                    style="transform: translateX({sliderValue}%);"
                >
                    <ArrowRight class="w-6 h-6 text-white" />
                </div>

                <div
                    class="absolute top-0 left-0 h-full bg-red-200 rounded-full pointer-events-none"
                    class:transition-all={!isSliding}
                    class:duration-300={!isSliding}
                    style="width: calc({sliderValue}% + 64px);"
                ></div>
            </div>

            <div class="mt-4 text-sm text-gray-500">
                Auto-cancel in <span class="font-bold text-red-500">{countdownSeconds}</span> seconds...
            </div>
        </div>
    </div>
</div>

<style>
    .modal-enter {
        animation: modal-scale-in 0.3s ease-out;
    }

    @keyframes modal-scale-in {
        from {
            transform: scale(0.95);
            opacity: 0;
        }
        to {
            transform: scale(1);
            opacity: 1;
        }
    }

    .select-none {
        user-select: none;
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
    }

    .touch-none {
        touch-action: none;
    }
</style>