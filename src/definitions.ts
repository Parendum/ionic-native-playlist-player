export interface NativePlaylistPlayerPlugin {
  echo(options: { value: string }): Promise<{ value: string }>;
}
