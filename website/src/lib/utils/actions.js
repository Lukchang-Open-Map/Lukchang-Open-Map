/**
 * Action สำหรับตรวจจับการคลิกนอก Element (ใช้ปิด Dropdown/Modal)
 * @param {HTMLElement} node 
 */
export function clickOutside(node) {
    const handleClick = (event) => {
        if (node && !node.contains(event.target) && !event.defaultPrevented) {
            node.dispatchEvent(new CustomEvent('clickoutside', node));
        }
    };

    document.addEventListener('click', handleClick, true);

    return {
        destroy() {
            document.removeEventListener('click', handleClick, true);
        }
    };
}