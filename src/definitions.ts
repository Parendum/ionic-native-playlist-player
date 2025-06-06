import {PluginListenerHandle} from "@capacitor/core";

export interface NativePlaylistPlayerPlugin {
    echo(options: { value: string }): Promise<{ value: string }>;

    setPlaylist(options: { playlist: string[], duration_seconds: number, language_code: string}): Promise<void>;

    getPlaylist(): Promise<{ playlist: string[], duration_seconds: number }>;

    play(): Promise<void>;

    pause(): Promise<void>;

    stop(): Promise<void>;

    isPlaying(): Promise<IsPlayingResponse>;

    // Plugin framework provided API
    addListener(
        eventName: 'playerStateUpdate',
        listenerFunc: (event: NativePlaylistPlayerStatus) => void,
    ): Promise<PluginListenerHandle> & PluginListenerHandle;
    removeAllListeners(): Promise<void>;
    checkPermissions(): Promise<PermissionStatus>;
    requestPermissions(): Promise<PermissionStatus>;
}

export interface NativePlaylistPlayerStatus {
    isPlaying: boolean,
    currentTrackIndex: number,
    elapsedSeconds: number,
    durationSeconds: number,
}

export interface IsPlayingResponse {
    isPlaying: boolean,
}
