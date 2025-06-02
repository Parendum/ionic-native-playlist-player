import {registerPlugin} from '@capacitor/core';

import type {NativePlaylistPlayerPlugin} from './definitions';

const NativePlaylistPlayer = registerPlugin<NativePlaylistPlayerPlugin>('NativePlaylistPlayer', {
});

export * from './definitions';
export {NativePlaylistPlayer};
