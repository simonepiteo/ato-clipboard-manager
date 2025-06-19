import { useState } from 'react';

export const useInteractiveElements = () => {
    const [isHovered, setIsHovered] = useState(false);
    const [isFocused, setIsFocused] = useState(false);

    const handleMouseEnter = () => setIsHovered(true);
    const handleMouseLeave = () => setIsHovered(false);
    const handleTouchStart = () => setIsFocused(true);
    const handleTouchEnd = () => setIsFocused(false);

    return {
        isHovered,
        isFocused,
        handleMouseEnter,
        handleMouseLeave,
        handleTouchStart,
        handleTouchEnd,
    };

 }