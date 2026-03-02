import React, { useState } from 'react';
import { Camera, Maximize2 } from 'lucide-react';

const VideoFeed = ({ src, label, isActive }) => {
    return (
        <div className={`relative rounded-xl overflow-hidden border border-white/10 bg-dark-800 shadow-xl group ${isActive ? 'ring-2 ring-primary-500' : ''}`}>
            {/* Header Overlay */}
            <div className="absolute top-0 left-0 w-full p-3 bg-gradient-to-b from-black/80 to-transparent z-10 flex justify-between items-center">
                <div className="flex items-center gap-2 text-white/90">
                    <Camera size={16} className="text-primary-500" />
                    <span className="font-medium text-sm tracking-wide">{label}</span>
                </div>
                <div className="flex items-center gap-2">
                    <span className="px-2 py-0.5 rounded-full bg-red-500/20 text-red-400 text-[10px] font-bold uppercase border border-red-500/30 animate-pulse">
                        Live
                    </span>
                </div>
            </div>

            {/* Video Stream */}
            <div className="aspect-video bg-black flex items-center justify-center relative">
                <img
                    src={src}
                    alt={label}
                    className="w-full h-full object-cover"
                    onError={(e) => { e.target.style.display = 'none'; e.target.nextSibling.style.display = 'flex' }}
                />
                <div className="hidden absolute inset-0 flex flex-col items-center justify-center text-white/30 gap-2">
                    <Camera size={48} />
                    <span className="text-xs">Signal Lost</span>
                </div>
            </div>

            {/* Footer Controls */}
            <div className="absolute bottom-0 w-full p-2 bg-gradient-to-t from-black/90 to-transparent opacity-0 group-hover:opacity-100 transition-opacity flex justify-end">
                <button className="p-1.5 rounded-lg bg-white/10 hover:bg-white/20 text-white transition">
                    <Maximize2 size={16} />
                </button>
            </div>
        </div>
    );
};

export default VideoFeed;
