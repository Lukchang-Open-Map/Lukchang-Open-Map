<script>
    import {
        AlertTriangle, TrafficCone, HelpCircle, Droplet, LifeBuoy,
        CarFront, ParkingSquare, Briefcase, PartyPopper, MessageSquare
    } from 'lucide-svelte';

    export let selectedCategory = null;

    function selectPinCategory(category) {
        selectedCategory = selectedCategory === category ? null : category;
        console.log('Selected Category:', selectedCategory);
    }
</script>

<div
    class="pointer-events-auto absolute top-20 left-5 z-40 flex w-72 flex-col gap-4 rounded-2xl border border-gray-200 bg-white p-4 shadow-lg"
>
    <h2 class="text-base font-bold text-gray-900 -mb-1 text-center">I want to post</h2> <div class="flex flex-col gap-2"> <h3 class="font-semibold text-sm text-gray-700">Incident Report</h3> <div class="grid grid-cols-3 gap-2"> <button
                class="flex flex-col items-center gap-1 p-1 rounded-lg text-center 
                        {selectedCategory === 'accident' ? 'bg-blue-50 text-blue-700' : 'hover:bg-gray-50'}"
                on:click={() => selectPinCategory('accident')}
            >
                <div class="flex h-10 w-10 items-center justify-center rounded-full bg-red-100">
                    <AlertTriangle class="h-5 w-5 text-red-600" /> </div>
                <span class="text-xs font-medium mt-1">Accident
                    <br>/Hazard</span>
            </button>

            <button
                class="flex flex-col items-center gap-1 p-1 rounded-lg text-center 
                        {selectedCategory === 'blocked' ? 'bg-blue-50 text-blue-700' : 'hover:bg-gray-50'}"
                on:click={() => selectPinCategory('blocked')}
            >
                <div class="flex h-10 w-10 items-center justify-center rounded-full bg-orange-100">
                    <TrafficCone class="h-5 w-5 text-orange-600" />
                </div>
                <span class="text-xs font-medium mt-1">Blocked</span>
            </button>

            <button
                class="flex flex-col items-center gap-1 p-1 rounded-lg text-center 
                        {selectedCategory === 'beware' ? 'bg-blue-50 text-blue-700' : 'hover:bg-gray-50'}"
                on:click={() => selectPinCategory('beware')}
            >
                <div class="flex h-10 w-10 items-center justify-center rounded-full bg-gray-200">
                    <HelpCircle class="h-5 w-5 text-gray-700" />
                </div>
                <span class="text-xs font-medium mt-1">Beware</span>
            </button>

            <button
                class="flex flex-col items-center gap-1 p-1 rounded-lg text-center 
                        {selectedCategory === 'flood' ? 'bg-blue-50 text-blue-700' : 'hover:bg-gray-50'}"
                on:click={() => selectPinCategory('flood')}
            >
                <div class="flex h-10 w-10 items-center justify-center rounded-full bg-blue-100">
                    <Droplet class="h-5 w-5 text-blue-600" />
                </div>
                <span class="text-xs font-medium mt-1">Flood</span>
            </button>

            <button
                class="flex flex-col items-center gap-1 p-1 rounded-lg text-center 
                        {selectedCategory === 'send_help' ? 'bg-blue-50 text-blue-700' : 'hover:bg-gray-50'}"
                on:click={() => selectPinCategory('send_help')}
            >
                <div class="flex h-10 w-10 items-center justify-center rounded-full bg-red-100">
                    <LifeBuoy class="h-5 w-5 text-red-600" />
                </div>
                <span class="text-xs font-medium mt-1">Send Help</span>
            </button>
        </div>
    </div>

    <div class="flex flex-col gap-2">
        <h3 class="font-semibold text-sm text-gray-700">General Report</h3>
        <div class="grid grid-cols-3 gap-2">
            
            <button
                class="flex flex-col items-center gap-1 p-1 rounded-lg text-center 
                        {selectedCategory === 'traffic_general' ? 'bg-blue-50 text-blue-700' : 'hover:bg-gray-50'}"
                on:click={() => selectPinCategory('traffic_general')}
            >
                <div class="flex h-10 w-10 items-center justify-center rounded-full bg-red-100">
                    <CarFront class="h-5 w-5 text-red-600" />
                </div>
                <span class="text-xs font-medium mt-1">Traffic</span>
            </button>

            <button
                class="flex flex-col items-center gap-1 p-1 rounded-lg text-center 
                        {selectedCategory === 'parking' ? 'bg-blue-50 text-blue-700' : 'hover:bg-gray-50'}"
                on:click={() => selectPinCategory('parking')}
            >
                <div class="flex h-10 w-10 items-center justify-center rounded-full bg-blue-100">
                    <ParkingSquare class="h-5 w-5 text-blue-600" />
                </div>
                <span class="text-xs font-medium mt-1">Parking</span>
            </button>

            <button
                class="flex flex-col items-center gap-1 p-1 rounded-lg text-center 
                        {selectedCategory === 'events' ? 'bg-blue-50 text-blue-700' : 'hover:bg-gray-50'}"
                on:click={() => selectPinCategory('events')}
            >
                <div class="flex h-10 w-10 items-center justify-center rounded-full bg-purple-100">
                    <PartyPopper class="h-5 w-5 text-purple-600" />
                </div>
                <span class="text-xs font-medium mt-1">Events</span>
            </button>

            <button
                class="flex flex-col items-center gap-1 p-1 rounded-lg text-center 
                        {selectedCategory === 'map_chat' ? 'bg-blue-50 text-blue-700' : 'hover:bg-gray-50'}"
                on:click={() => selectPinCategory('map_chat')}
            >
                <div class="flex h-10 w-10 items-center justify-center rounded-full bg-green-100">
                    <MessageSquare class="h-5 w-5 text-green-600" />
                </div>
                <span class="text-xs font-medium mt-1">Map Chat</span>
            </button>

                        <button
                class="flex flex-col items-center gap-1 p-1 rounded-lg text-center 
                        {selectedCategory === 'lost_found' ? 'bg-blue-50 text-blue-700' : 'hover:bg-gray-50'}"
                on:click={() => selectPinCategory('lost_found')}
            >
                <div class="flex h-10 w-10 items-center justify-center rounded-full bg-orange-200">
                    <Briefcase class="h-5 w-5 text-orange-600" />
                </div>
                <span class="text-xs font-medium mt-1">Lost & Found</span>
            </button>
        </div>
    </div>
</div>