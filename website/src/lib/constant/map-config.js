import {
	AlertTriangle,
	TrafficCone,
	HelpCircle,
	Droplet,
	LifeBuoy,
	CarFront,
	ParkingSquare,
	PartyPopper,
	MessageSquare,
	Briefcase,
	MapPin,
	Spline // Import Icon ให้ครบ
} from 'lucide-svelte';

export const CATEGORY_DISPLAY_NAMES = {
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

export const CATEGORY_STYLES = {
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

export const BLOCKED_MODAL_CONFIG = {
	type: 'blocked',
	title: 'Report Blocked Path',
	pointOption: {
		Icon: MapPin,
		title: 'Obstacle',
		description: 'e.g. Fallen tree, Car breakdown' // อธิบายจุดเดียว
	},
	lineOption: {
		Icon: Spline,
		title: 'Road Closed',
		description: 'e.g. Construction, Flooding' // อธิบายเป็นเส้น/พื้นที่
	}
};
