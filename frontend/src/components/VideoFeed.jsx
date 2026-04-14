import React, { useState, useRef } from 'react';
import { Camera, Maximize2, X, AlertCircle, RefreshCw } from 'lucide-react';

const VideoFeed = ({ src, label, isActive }) => {
    const [hasError, setHasError] = useState(false);
    const [fullscreen, setFullscreen] = useState(false);
    const imgRef = useRef(null);

    const handleError = () => setHasError(true);
    const handleLoad  = () => setHasError(false);

    const retryFeed = () => {
        setHasError(false);
        if (imgRef.current) {
            // Force reload by appending a timestamp
            imgRef.current.src = src + '?t=' + Date.now();
        }
    };

    const FeedImage = ({ className = '' }) => (
        <img
            ref={imgRef}
            src={src}
            alt={label}
            className={`w-full h-full object-cover ${className}`}
            onError={handleError}
            onLoad={handleLoad}
            style={{ display: hasError ? 'none' : 'block' }}
        />
    );

    const ErrorState = () => (
        <div className="absolute inset-0 flex flex-col items-center justify-center gap-3 bg-black/80">
            <AlertCircle size={36} className="text-red-400" />
            <p className="text-white/70 text-sm font-medium">Camera unavailable</p>
            <p className="text-white/40 text-xs text-center px-4">
                Make sure <code className="bg-white/10 px-1 py-0.5 rounded">./start_full_system.sh</code> is running and camera permission is granted.
            </p>
            <button
                onClick={retryFeed}
                className="flex items-center gap-1.5 mt-1 px-4 py-2 rounded-lg bg-primary-600 hover:bg-primary-500 text-white text-xs font-bold transition"
            >
                <RefreshCw size={14} /> Retry
            </button>
        </div>
    );

    return (
        <>
            {/* ── Main card ── */}
            <div className={`relative rounded-xl overflow-hidden border bg-black shadow-xl group
                ${isActive ? 'border-primary-500/50' : 'border-white/10'}`}
            >
                {/* Header overlay */}
                <div className="absolute top-0 left-0 w-full px-3 py-2 bg-gradient-to-b from-black/80 to-transparent z-10 flex justify-between items-center">
                    <div className="flex items-center gap-2 text-white/90">
                        <Camera size={14} className="text-primary-400" />
                        <span className="font-medium text-xs tracking-wide">{label}</span>
                    </div>
                    <span className="px-2 py-0.5 rounded-full bg-red-500/20 text-red-400 text-[10px] font-bold uppercase border border-red-500/30 animate-pulse">
                        Live
                    </span>
                </div>

                {/* Video */}
                <div className="aspect-video bg-black relative">
                    <FeedImage />
                    {hasError && <ErrorState />}
                </div>

                {/* Fullscreen button — appears on hover */}
                <button
                    onClick={() => setFullscreen(true)}
                    title="Expand"
                    className="absolute bottom-2 right-2 z-20 p-1.5 rounded-lg bg-black/60 hover:bg-black/90 text-white opacity-0 group-hover:opacity-100 transition-opacity"
                >
                    <Maximize2 size={15} />
                </button>
            </div>

            {/* ── Fullscreen Modal ── */}
            {fullscreen && (
                <div
                    className="fixed inset-0 z-[999] bg-black/95 flex flex-col"
                    onClick={(e) => { if (e.target === e.currentTarget) setFullscreen(false); }}
                >
                    {/* Modal header */}
                    <div className="flex items-center justify-between px-6 py-3 bg-black/80 border-b border-white/10">
                        <div className="flex items-center gap-2">
                            <span className="w-2 h-2 rounded-full bg-red-500 animate-pulse" />
                            <span className="text-white font-semibold text-sm">{label} — LIVE</span>
                        </div>
                        <button
                            onClick={() => setFullscreen(false)}
                            className="p-2 rounded-lg bg-white/10 hover:bg-white/20 text-white transition"
                        >
                            <X size={18} />
                        </button>
                    </div>

                    {/* Full-size feed */}
                    <div className="flex-1 flex items-center justify-center p-4 relative">
                        <img
                            src={src}
                            alt={label}
                            className="max-w-full max-h-full object-contain rounded-xl"
                            onError={handleError}
                            style={{ display: hasError ? 'none' : 'block' }}
                        />
                        {hasError && (
                            <div className="flex flex-col items-center gap-3 text-white/50">
                                <AlertCircle size={48} />
                                <p>Camera stream unavailable</p>
                                <button onClick={retryFeed} className="flex items-center gap-2 px-4 py-2 rounded-lg bg-primary-600 hover:bg-primary-500 text-white text-sm font-bold">
                                    <RefreshCw size={14} /> Retry
                                </button>
                            </div>
                        )}
                    </div>
                </div>
            )}
        </>
    );
};

export default VideoFeed;
