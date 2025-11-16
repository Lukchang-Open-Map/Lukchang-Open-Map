<script>
    import {
        AlertTriangle, TrafficCone, HelpCircle, Droplet, LifeBuoy,
        CarFront, ParkingSquare, Briefcase, PartyPopper, MessageSquare
    } from 'lucide-svelte';

    export let category;

    // Map categories to their icons and colors
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

    $: style = categoryStyles[category] || categoryStyles['beware'];
</script>

<div class="relative w-12 h-12 flex justify-center items-center">

    {#if category === 'flood'}
        <div class="absolute w-10 h-10 rounded-full bg-blue-400 opacity-75 animate-ping"></div>
        <div class="absolute w-10 h-10 rounded-full bg-blue-500 opacity-20"></div>
    {/if}

    <div class="relative z-10 w-10 h-11">
        <!-- The circle part -->
        <div class="absolute top-0 left-0 w-10 h-10 rounded-full flex items-center justify-center shadow-lg {style.bg} border-2 border-white">
            <svelte:component this={style.Icon} class="w-6 h-6 {style.text}" />
        </div>
        
        <div class="absolute top-[38px] left-1/2 -translate-x-1/2"
             style="width: 0; height: 0; border-left: 6px solid transparent; border-right: 6px solid transparent; border-top: 10px solid white; filter: drop-shadow(0 1px 1px rgb(0 0 0 / 0.1));">
        </div>
    </div>
</div>