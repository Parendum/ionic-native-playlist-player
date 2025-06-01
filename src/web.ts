import { WebPlugin } from '@capacitor/core';

import type { NativePlaylistPlayerPlugin } from './definitions';

export class NativePlaylistPlayerWeb extends WebPlugin implements NativePlaylistPlayerPlugin {
  async echo(options: { value: string }): Promise<{ value: string }> {
    console.log('ECHO', options);
    return options;
  }
}
