import { registerPlugin } from '@capacitor/core';

import type { NativePlaylistPlayerPlugin } from './definitions';

const NativePlaylistPlayer = registerPlugin<NativePlaylistPlayerPlugin>('NativePlaylistPlayer', {
  web: () => import('./web').then((m) => new m.NativePlaylistPlayerWeb()),
});

export * from './definitions';
export { NativePlaylistPlayer };
